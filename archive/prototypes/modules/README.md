# Disabled prototype modules

The Terraform modules in this directory are historical prototypes. They are
not supported reusable modules and must not be introduced into a deployment
root. The current Terraform source is under [`infra/`](../../../infra/README.md);
this directory is never a module source for an active root.

The boundary is enforced by [ADR 0014](../../../docs/adr/0014-canonical-architecture-and-iac-boundary.md).
