# Sandbox network GitOps delivery

This is the sole approved procedure for the first sandbox VPC. It creates no
landing zone or production component, and it must never be replaced by console
or ad hoc AWS CLI resource creation.

## Scope

| Property | Approved value |
|---|---|
| AWS account | Sandbox `448871779014` |
| Region | `us-east-2` |
| Terraform state key | `gitops/sandbox-network/us-east-2/dev/terraform.tfstate` |
| VPC CIDR | `10.64.0.0/16` |
| Private subnets | `10.64.0.0/20` in `us-east-2a`, `10.64.16.0/20` in `us-east-2b` |
| Internet/NAT/public subnets | Not created |
| Network connection | No TGW, peering, VPN, BGP, endpoint, or external route |

Terraform owns every VPC resource. The only preliminary mutable AWS operation
is the separately versioned CloudFormation policy stack, which makes the
existing GitHub OIDC roles capable of running this root. It does not create
network resources.

## Preconditions

1. `main` contains the approved ADR 0018 source and branch-protection checks
   are green.
2. Obtain a fresh IAM Identity Center login for `AWS-hatan4ik-sandbox`; do not
   use a legacy key profile.
3. Verify the session resolves to sandbox before changing policy:

   ```sh
   aws sts get-caller-identity --profile AWS-hatan4ik-sandbox
   ```

4. Confirm the state key is new. Do not print state data; an object must not be
   copied or renamed from any historical key.

## One-time versioned bootstrap

Run these commands from the reviewed `main` checkout only. They create/update
the named CloudFormation policy stack and non-secret GitHub variables; neither
command runs Terraform or creates VPC resources.

```sh
scripts/bootstrap-sandbox-network-delivery-policy.sh \
  --profile AWS-hatan4ik-sandbox \
  --region us-east-2

scripts/configure-sandbox-network-github.sh \
  --profile AWS-hatan4ik-sandbox \
  --repository hatan4ik/devops-aws-infra
```

Record the CloudFormation stack ARN, its three policy output ARNs, and the
GitHub variable update as the bootstrap evidence. Treat role ARNs as ordinary
configuration, never AWS credentials. The bootstrap script refuses its initial
run if the dedicated state object already exists; that protects this slice from
accidentally adopting another root's state. A later reviewed policy-only update
must use its explicit `--allow-existing-state-key` override.

## GitOps execution

1. Run **Sandbox network plan** from `main`, or open a same-repository pull
   request changing the root/module. Fork pull requests never receive AWS
   credentials.
2. Review the plan. It may contain only the VPC, two private subnets, empty
   route tables and associations, encryption control, default-security-group
   change, dedicated KMS key/alias, CloudWatch Log Group, flow-log role/policy,
   and VPC Flow Log. Stop for any public route, gateway, endpoint, TGW, VPN,
   workload, data, identity, or unrelated state change.
3. Dispatch **Apply sandbox network** from protected `main`, select `dev`, and
   type exactly `apply`. The workflow re-plans and applies that one plan with
   its dedicated OIDC role. It validates the non-secret role-ARN variable only
   after the protected environment is entered, so a missing variable fails
   visibly instead of silently skipping delivery. Do not run `terraform apply`
   from a laptop.
4. Preserve the successful GitHub run URL and CloudTrail evidence. Confirm the
   weekday **Sandbox network drift detection** workflow is enabled; it must
   alert by failing on drift and must not repair resources automatically.

## Stop and rollback

Stop before apply if a state lock is active, the caller account is not
`448871779014`, policy bootstrap differs from this repository source, a plan
is not limited to this root, or GitHub is not executing protected `main`.

Do not delete the state key or use the AWS console to “undo” a resource. For a
post-apply problem, open a dedicated rollback pull request that changes this
root, inspect its plan, and use the same protected manual apply workflow. A
future destroy procedure needs its own explicit approval and backup evidence.
