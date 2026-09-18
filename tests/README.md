# Platform verification staging area

These checks are intentionally divided by safety boundary. Module tests run without AWS credentials and are part of the Terraform quality workflow. Post-deployment checks use AWS CLI read APIs or public HTTPS requests only; they never mutate routes, VPNs, identities, data, state, or application traffic. Controlled fault injection and production failover remain manual, change-approved operations described in the runbooks.

| Layer | Evidence | When it runs | Mutation boundary |
|---|---|---|---|
| Module contract | `terraform/modules/**/tests/*.tftest.hcl` | Pull request and release | Provider mocks with `command = plan`; no AWS credentials. |
| Static infrastructure policy | Checkov and Trivy in `terraform-quality.yml` | Pull request | Source-only scan; HIGH/CRITICAL findings fail. |
| Network/hybrid deployment | [`post_deploy/verify_network_read_only.sh`](post_deploy/verify_network_read_only.sh) | Approved post-deployment and game day | AWS CLI `Describe`/`Get` read calls only. |
| Security baseline deployment | [`post_deploy/verify_security_read_only.sh`](post_deploy/verify_security_read_only.sh) | Approved post-deployment and daily operations | AWS CLI read calls only; fails on active HIGH/CRITICAL Security Hub findings. |
| Public availability | [`post_deploy/verify_public_synthetics.sh`](post_deploy/verify_public_synthetics.sh) | Approved post-deployment and regional game day | HTTPS GET/HEAD only; no user credentials. |
| AuthN/AuthZ and failover journey | [`post_deploy/auth-api-synthetic-contract.md`](post_deploy/auth-api-synthetic-contract.md) and [regional failover runbook](../docs/runbooks/regional-failover.md) | Staging before production and every material change | Uses an approved isolated synthetic identity; no production user data or secrets in output. |

The shell checks intentionally require concrete deployed identifiers as command-line arguments. None have defaults, so a developer cannot accidentally test an invented account or Region. Run `--help` first. Use a short-lived read-only role in the target account/Region and collect only the pass/fail output plus approved change/incident evidence.
