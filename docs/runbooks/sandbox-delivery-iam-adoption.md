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

5. The historical CloudFormation retirement has already completed. The three
   stack records are deleted; retained IAM resources are Terraform-owned. Its
   source and the retired helper are audit-only under
   [`archive/cloudformation-sandbox-bootstrap`](../../archive/cloudformation-sandbox-bootstrap/)
   and must not be run.

6. Dispatch the protected **Sandbox delivery IAM plan** and **Sandbox delivery
   IAM drift detection** workflows. Both must report no change. The only
   remaining CloudFormation source is historical evidence under
   [`archive/cloudformation-sandbox-bootstrap`](../../archive/cloudformation-sandbox-bootstrap/).

7. If this root was initialized before its backend KMS alias was introduced,
   re-encrypt only its versioned state object. The guarded script checks the
   account, bucket default key, and an empty lock table; it never displays or
   edits state content.

```bash
bash scripts/reencrypt-sandbox-delivery-state.sh \
  --profile AWS-hatan4ik-sandbox \
  --confirm reencrypt-sandbox-delivery-state
```

## Rollback boundary

The CloudFormation handoff is complete and Terraform is the sole owner. Roll
forward with a reviewed Terraform policy revision. Do not recreate an archived
CloudFormation stack or detach a policy manually.
