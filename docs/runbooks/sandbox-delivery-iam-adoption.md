# Sandbox delivery IAM Terraform adoption

This runbook implements [ADR 0022](../adr/0022-terraform-owned-sandbox-delivery-identity.md).
It transfers the **existing** sandbox GitHub OIDC provider, six roles, four
delivery policies, and existing role attachments from CloudFormation to the
Terraform root. It does not create a VPC, workload, account, user, access key,
or public endpoint.

## Preconditions

- Review and merge the Terraform identity root on `main`.
- Use the short-lived `AWS-hatan4ik-sandbox` IAM Identity Center profile; do
  not use an IAM-user key.
- Confirm the sandbox account and bucket default encryption:

```bash
aws sts get-caller-identity --profile AWS-hatan4ik-sandbox
aws s3api get-bucket-encryption \
  --profile AWS-hatan4ik-sandbox \
  --bucket platform-tf-state-shared-f3ddb8cc
```

The expected account is `448871779014`; the bucket must report its approved
customer-managed KMS key as default encryption.

## Controlled handoff

1. Produce the declarative import plan. This does not mutate AWS.

```bash
bash scripts/adopt-sandbox-delivery-iam.sh \
  --profile AWS-hatan4ik-sandbox
```

2. Review the plan. It must import one OIDC provider, six roles, four existing
   policies, and six existing attachments; it may create only the two new
   Terraform delivery-identity policies and their three attachments.

3. Apply the reviewed adoption from `main`.

```bash
bash scripts/adopt-sandbox-delivery-iam.sh \
  --profile AWS-hatan4ik-sandbox \
  --apply \
  --confirm adopt-sandbox-delivery-iam
```

4. Configure non-secret role-ARN GitHub variables, then dispatch **Sandbox
   delivery IAM plan** from `main`. It must report no unreviewed changes.

```bash
bash scripts/configure-sandbox-delivery-iam-github.sh \
  --profile AWS-hatan4ik-sandbox \
  --repository hatan4ik/devops-aws-infra
```

5. Only after that protected OIDC plan is clean, retire the three historical
   stacks. The script first records `Retain` metadata, verifies Terraform
   state, deletes the stacks, and confirms the physical resources remain.

```bash
bash scripts/retire-sandbox-delivery-cloudformation.sh \
  --profile AWS-hatan4ik-sandbox \
  --confirm retire-sandbox-delivery-cloudformation
```

6. Dispatch the protected **Sandbox delivery IAM plan** and **Sandbox delivery
   IAM drift detection** workflows. Both must report no change. The only
   remaining CloudFormation source is historical evidence under
   [`archive/cloudformation-sandbox-bootstrap`](../../archive/cloudformation-sandbox-bootstrap/).

## Rollback boundary

Before stack retirement, the CloudFormation stacks still own the live policy
objects and can be left unchanged if the import plan differs. After retirement,
Terraform is the sole owner; roll forward with a reviewed Terraform policy
revision. Do not recreate an archived CloudFormation stack or detach a policy
manually.
