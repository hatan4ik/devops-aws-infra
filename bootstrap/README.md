# Management Organization bootstrap

This directory contains the single CloudFormation prerequisite for the direct
AWS Organizations control-plane root. It creates that root's isolated state
backend and least-privilege GitHub OIDC delivery policies before Terraform can
use the backend it does not yet own.

It is not a routine delivery path and it is not a replacement for the active
Terraform Organization root. Its authority, one-time IAM Identity Center
execution boundary, and successors are defined by [ADR 0019](../docs/adr/0019-direct-organizations-account-vending.md) and the
[Organization root README](../infra/active/roots/organization/global/README.md).
