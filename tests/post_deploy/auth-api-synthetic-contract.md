# AuthN/AuthZ and API synthetic contract

The public smoke script does not prove authentication or authorization. Before production approval and after each identity, authorization, routing, or regional-failover change, run this contract in the staging environment from two approved regional runners.

## Required synthetic identity boundary

- Create one dedicated non-human synthetic user in the approved test directory and give it no production entitlements or customer data.
- Store its credential, refresh token, or client secret only in the staging runner's protected secret store. Never put it in Terraform variables, source control, test logs, curl command lines, or artifacts.
- Use a separate least-privilege synthetic role/group for an **allow** case and an intentionally unauthorized role/group for a **deny** case. Delete/revoke the identity and secrets after a game day if it is not an approved standing synthetic.
- The test runner records correlation IDs, HTTP status, Region, latency, and a redacted result only. It never writes tokens, authorization headers, cookies, claims, customer identifiers, or request bodies to logs.

## Required assertions

| Journey | Expected result | Evidence |
|---|---|---|
| OIDC discovery and JWKS retrieval | HTTPS, valid issuer expected for that Region, and current signing-key endpoint reachable. | HTTP status, issuer host (not token), key-set response status, latency. |
| Supported sign-in + token refresh | Synthetic user completes the approved Cognito flow; token is accepted by the regional API. | Redacted pass/fail, Region, trace/correlation ID, p50/p95/p99. |
| Authorization allow | Synthetic principal with the intended claim/group/action receives the permitted result only for its scoped resource. | HTTP status, policy decision ID, trace ID; no resource payload. |
| Authorization deny | Synthetic principal lacking the privilege receives 401/403 and cannot infer data existence. | HTTP status, policy decision ID, trace ID. |
| Replay/expiry | Expired/revoked token and invalid audience/issuer are rejected. | Redacted status and validation reason class. |
| Regional API failover | Both regional APIs validate tokens according to the approved issuer/replica routing contract; Global Accelerator routing converges within the approved RTO. | Endpoint health, selected Region, synthetic results, latency series, incident/change timeline. |
| Cognito MRR failover | Only run after the provider-supported MRR blocker in ADR 0011 is resolved and MRR is demonstrably deployed. Signup/password/profile-write primary-only behavior is explicitly tested. | MRR status, custom-domain health, supported login result, documented feature-limit result. |

The execution method belongs to the application team because callback URL, authorization-code/PKCE flow, API route, authorization model, and secrets are not available in this platform workspace. A test that merely receives a token is not sufficient; it must call an authorized and denied API route and correlate the request in centralized traces.
