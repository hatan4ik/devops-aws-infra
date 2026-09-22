# Historical prototype only. The canonical delivery tree is terraform/; see
# docs/adr/0014-canonical-architecture-and-iac-boundary.md.
resource "terraform_data" "prototype_disabled" {
  lifecycle {
    precondition {
      condition     = terraform.workspace != terraform.workspace
      error_message = "This prototype module is disabled by ADR 0014. Use the canonical terraform/ module catalog."
    }
  }
}
