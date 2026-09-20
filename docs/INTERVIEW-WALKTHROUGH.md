# Interview Walkthrough Guide

Use this as a conversation map. Each section is a natural discussion stop.
Point to real files — don't describe from memory.

---

## 1. What is this repo and why does it exist?

**Say:**
> "This is a GitOps source repository for a proposed AWS-native, multi-account,
> two-Region platform. It holds Terraform modules, roots, CI/CD pipelines,
> architecture decisions, and runbooks. It does not hold credentials, state,
> or customer data."

**Key point to make early:**
- The repo is the single source of truth. Nothing is applied outside of it.
- Every decision is recorded as an ADR in `docs/adr/`.
- The only active delivery scope right now is one isolated VPC in a sandbox account.

**Show:** `README.md` → repository map table.

---

## 2. Architecture decisions — how the team makes choices

**Say:**
> "Every significant decision — credential strategy, network topology, state
> backend, module boundaries — is an ADR. It records context, options considered,
> a quorum review, the decision, and consequences. Nothing is implicit."

**Walk through one ADR as an example — ADR 0012:**
- File: `docs/adr/0012-oidc-gated-terraform-delivery.md`
- 5 reviewers, each owning a pillar (Security, Network, SRE, Architect, Platform Lead)
- Result: 5–0 for OIDC + separated roles + protected environments
- Rejected: static keys, broad admin role, automatic drift remediation

**Why this matters to an interviewer:**
- Shows you don't make infrastructure decisions unilaterally
- Shows you document trade-offs, not just outcomes

---

## 3. Security foundation — no static AWS keys, ever

**Say:**
> "The first thing we solved was credential strategy. GitHub Actions authenticates
> to AWS using OIDC — short-lived tokens only. No access key or secret key exists
> in the repository source or is used by these workflows."

**Walk the bootstrap chain:**

```
Human (SSO session)
  → CloudFormation: bootstrap/github-oidc/template.yaml
      → Creates IAM OIDC provider
      → Creates 4 roles: plan, apply, drift, landing-zone
          → All start with ZERO permissions (permissionless)
  → CloudFormation: bootstrap/sandbox-network-delivery-policy/template.yaml
      → Attaches least-privilege policies to those roles
          → plan role: read + state lock only
          → apply role: exact EC2/KMS/IAM/logs actions, scoped by resource tag
```

**Show:** `bootstrap/sandbox-network-delivery-policy/template.yaml`
- Point to `ManageOnlyTheSandboxNetworkVpcResources` — exact EC2 actions, no wildcards
- Point to `CreateDedicatedSandboxNetworkFlowLogKey` — condition on `aws:RequestTag/Root`
- Point to the IAM role resource scoped to `sandbox-network-dev-vpc-flow-logs` only

**Key point:** The apply role cannot touch Organizations, Control Tower, TGW,
workloads, or any other account. Blast radius is one VPC in one sandbox account.

---

## 4. CI/CD pipeline — how a change flows from PR to AWS

**Say:**
> "There are three separate GitHub workflows for this root. Each uses a different
> IAM role with different permissions. No workflow can escalate to another's role."

### PR opened → Plan workflow
- File: `.github/workflows/sandbox-network-plan.yml`
- Trigger: PR against `main` touching the root or module paths
- OIDC exchange → plan-only role (read + state lock)
- Runs `terraform plan -out=tfplan`
- Fork PRs are explicitly blocked: `github.event.pull_request.head.repo.full_name == github.repository`
- Every action is SHA-pinned — e.g. `actions/checkout@fbc6f3992...`

### PR merged → Manual apply workflow
- File: `.github/workflows/sandbox-network-apply.yml`
- Trigger: `workflow_dispatch` only — someone must type `apply` to confirm
- Runs in the protected `dev` GitHub environment (requires environment approval)
- OIDC exchange → apply role (scoped create/update/delete)
- Re-plans from protected `main` first, then applies that exact binary plan
- `cancel-in-progress: false` — concurrent applies are blocked

### Scheduled → Drift workflow
- File: `.github/workflows/sandbox-network-drift.yml`
- Runs on weekdays, uses the plan role (read-only)
- Exits non-zero if drift is detected — creates an incident signal
- Never remediates automatically (ADR 0012 decision)

**Key point to make:** Plan ≠ apply authorization. A passing plan is a review
artifact. Apply requires a separate human dispatch in a protected environment.

---

## 5. Terraform structure — modules and roots

**Say:**
> "The Terraform tree follows a strict two-layer pattern: reusable modules and
> backend-externalized roots. Roots call modules only — no bare resources in roots."

### Module layer
```
terraform/modules/
  internal/sandbox-network/    ← composition module for this root
  terraform-aws-vpc-workload/  ← reusable workload VPC module
  terraform-aws-tgw-hub/
  terraform-aws-cognito-userpool/
```

**Show:** `terraform/modules/internal/sandbox-network/main.tf`
- VPC with `enable_dns_hostnames`, `enable_dns_support`
- `aws_vpc_encryption_control` set to `enforce` — all traffic in the VPC is encrypted
- `aws_default_security_group` with empty ingress/egress — deny-all by default
- Private subnets only — no IGW, no NAT, no public subnet
- Empty route tables — intentionally isolated until a TGW attachment is approved
- KMS key with rotation enabled, scoped policy for CloudWatch Logs
- Flow logs → CloudWatch → encrypted with that KMS key, 365-day retention

**Show:** `terraform/modules/terraform-aws-vpc-workload/variables.tf`
- `type = any` is banned — every variable is typed
- `object({})` with `optional()` fields
- `validation` blocks enforce values at plan time, not apply time
- Tag keys enforced as PascalCase, values enforced non-empty

### Root layer
```
terraform/roots/sandbox-network/us-east-2/dev/
  main.tf        ← module call only
  variables.tf   ← typed, validated inputs
  locals.tf      ← default_tags computed once
  providers.tf   ← allowed_account_ids pins to sandbox account
  backend.tf     ← terraform { backend "s3" {} } — externalized
  backend.hcl    ← passed at init, never committed with secrets
  terraform.tfvars
```

**Show:** `providers.tf`
- `allowed_account_ids = [var.aws_account_id]` — Terraform refuses to run against
  the wrong account. Hard stop at plan.

**Show:** `locals.tf`
- All tags computed once: `Environment`, `ManagedBy`, `Repository`, `Root`
  merged with caller-supplied `Application`, `CostCenter`, `Owner`
- Provider `default_tags` block applies them to every resource automatically

**Show:** `variables.tf` — tags variable
- Typed as `object({ Application, CostCenter, Owner })` — missing keys are a
  type error at plan, not a runtime surprise

---

## 6. State management

**Say:**
> "State is S3-backed with SSE-KMS, versioning, DynamoDB locking. Each root has
> its own dedicated state key — no shared state objects between roots."

- Key: `gitops/sandbox-network/us-east-2/dev/terraform.tfstate`
- Backend config is passed via `backend.hcl` at `terraform init` — never hardcoded
- The apply role can only read/write that exact key prefix (enforced by IAM policy)
- State never contains secrets — no passwords, tokens, or private keys in outputs

---

## 7. What actually got deployed

**Say:**
> "The first GitHub apply created a partial state and then stopped on IAM denials
> — which is the correct behaviour for a least-privilege role. We iteratively
> tightened the policy, not the security boundary."

Resources confirmed in AWS (sandbox account `448871779014`, `us-east-2`):
- VPC `10.64.0.0/16` with DNS enabled, encryption enforced
- 2 private subnets: `10.64.0.0/20` (us-east-2a), `10.64.16.0/20` (us-east-2b)
- Empty route tables per AZ — no routes, intentionally isolated
- Deny-all default security group
- KMS key with rotation, scoped to flow logs
- CloudWatch Log Group `/aws/vpc/sandbox-network-dev/flow-logs`, 365-day retention
- IAM role for flow log delivery (narrowly scoped)
- VPC Flow Logs capturing ALL traffic

**Not deployed (by design):**
- No Internet Gateway, NAT Gateway, public subnet
- No TGW attachment, VPN, BGP
- No endpoints, workloads, identity, or data plane resources

---

## 8. Quality gates — what runs on every PR

**Show:** `.github/workflows/terraform-quality.yml`

Every PR runs, credential-free:
| Gate | Tool |
|---|---|
| Format | `terraform fmt` |
| Validate | `terraform validate` (mocked, no AWS auth) |
| Lint | TFLint |
| IaC security scan | Checkov — fails on any HIGH/CRITICAL |
| IaC security scan | Trivy — fails on any HIGH/CRITICAL |
| Docs drift | terraform-docs — fails if README is out of sync |
| Workflow lint | actionlint + ShellCheck |
| Pipeline contracts | custom Ruby validators |

**Key point:** Quality is machine-enforced. Humans review logic and architecture,
not style or formatting.

---

## 9. What comes next (honest answer)

**Say:**
> "The sandbox network is the tracer bullet — one account, one region, one
> isolated VPC delivered end-to-end through the full GitOps pipeline. The next
> gates before expanding are:"

1. Preserve CloudTrail + drift evidence for the completed sandbox apply
2. Review scheduled drift evidence before any next infrastructure slice
3. Separately gate: Control Tower, landing zone, TGW, production networking
4. Add independent reviewers before claiming four-eyes control
5. IPAM migration for the sandbox VPC (currently uses direct CIDR as approved exception)

---

## Common interview questions — short answers

**"Why not just use Terraform Cloud?"**
> GitHub Actions + OIDC + S3 backend keeps the delivery plane inside the same
> trust boundary as the code. No third-party SaaS holds AWS credentials or state.

**"Why separate plan/apply/drift roles?"**
> A plan role that can also apply is a privilege escalation path. Drift that
> auto-remediates turns a monitoring signal into an unreviewed mutation.
> ADR 0012, 5–0 quorum decision.

**"How do you prevent someone from applying locally?"**
> The apply role's trust policy binds `sub` to the protected `dev` environment
> subject in GitHub. A local `terraform apply` with a developer's SSO session
> uses a different identity with no apply permissions.

**"What happens if drift is detected?"**
> The drift workflow exits non-zero, creates a failed GitHub Actions run, and
> that becomes the incident input. A human reviews, opens a PR, goes through
> normal plan → apply gates. No automatic remediation.

**"How do you handle secrets in Terraform?"**
> We don't put secrets in Terraform. KMS key ARNs, role ARNs, and bucket names
> are non-secret variables. Passwords and tokens are out of scope for this
> infrastructure layer — they belong in Secrets Manager and are referenced by
> ARN only. This root defines no secret-valued inputs or outputs.
