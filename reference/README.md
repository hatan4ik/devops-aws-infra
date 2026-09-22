# Read-only reference material

`reference/github/` contains shallow, unmodified copies of public repositories
used during architecture review. They are not Terraform modules, dependencies,
or deployment inputs. Do not initialize, plan, apply, edit, or publish them as
part of this platform.

Their provenance and refresh procedure are recorded in the
[GitHub reference inventory](../docs/reference/github-repos.md). Executable
Terraform exists only under [`infra/active/`](../infra/active/) and approved
future composition exists under [`infra/candidates/`](../infra/candidates/).
