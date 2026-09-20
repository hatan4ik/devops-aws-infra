## Change summary

Describe the user-visible or operator-visible outcome.

## Evidence

- [ ] `scripts/validate-terraform-quality.sh`
- [ ] `scripts/verify-adr-boundary.sh`
- [ ] Terraform plan evidence attached when a remote-state or infrastructure change is proposed
- [ ] Generated module documentation is current

## Security and operations

- [ ] No credentials, state, plans, customer data, or backend keys are included
- [ ] Required ADR/runbook/assumption/traceability updates are included
- [ ] Security, platform, SRE, network, or FinOps review is requested where the change affects its boundary
