# Disabled prototype roots

This directory is retained as historical prototype material only. It is not a
Terraform deployment entry point, has no configured remote state or provider
profile, and every root contains a guard that makes a normal Terraform plan
fail.

Never use this directory. Candidate roots are under
[`infra/candidates/roots`](../../../infra/candidates/roots/) and active roots
are under [`infra/active/roots`](../../../infra/active/roots/).
The authoritative rationale is
[ADR 0014](../../../docs/adr/0014-canonical-architecture-and-iac-boundary.md).
