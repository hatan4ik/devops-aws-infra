# Runbook: hybrid VPN/BGP onboarding

## Trigger and scope

Use for a new or changed on-premises routing domain connected to a regional Transit Gateway. This runbook covers the initial dual Site-to-Site VPN/BGP baseline selected in ADR 0005. Direct Connect requires a separate costed/approved design decision.

## Preflight

1. Record the change ticket, owner contacts, concrete Region/account/TGW/route-domain, two customer-gateway public IPs, device model/software, BGP ASNs, BGP peer addresses, MTU/MSS policy, encryption/IKE proposals, and maintenance/rollback window. Treat tunnel shared secrets as confidential configuration: exchange them through the approved secret channel and never commit or log them.
2. Approve exact advertised/accepted IPv4/IPv6 prefixes and explicit deny list. Prove no overlap with IPAM pools, workload VPCs, other on-premises domains, or reserved ranges.
3. Confirm each customer gateway has independent power/provider/path where possible and supports two active BGP sessions. Decide BGP timers, MED/local preference, ECMP intent, route limits, and failover owner.
4. Validate that the attachment is associated only with its approved TGW route domain and propagates only to explicitly allowed route tables. Default association/propagation and implicit broad routes remain disabled.

## Controlled execution

1. Create customer-gateway and VPN resources through the protected network pipeline using secrets from the approved runtime store. Bind the attachment to the approved route table and install only the approved static/propagated routes.
2. Configure both on-premises devices from the generated vendor configuration through the approved change process. Do not expose PSKs in tickets, terminals, screen captures, or CI logs.
3. Bring up one tunnel/path at a time, verify IKE/IPsec and BGP establishment, then bring up the second. Confirm received/advertised prefix counts and route selection against the signed prefix matrix.
4. Execute allowed-path probes and negative probes from an approved non-production source. A denied production/non-production, shared/inspection, or undeclared on-premises route must remain denied.

## Acceptance evidence

Run the following only with real approved identifiers substituted; it makes AWS read-only calls:

```bash
tests/post_deploy/verify_network_read_only.sh --region <AWS_REGION> --tgw-attachment-id <ATTACHMENT_ID> --tgw-route-table-id <ROUTE_TABLE_ID> --vpn-connection-id <VPN_CONNECTION_ID> --vpc-id <VPC_ID> --endpoint-service <VPC_ENDPOINT_SERVICE>
```

Attach the redacted pass/fail output, tunnel/BGP telemetry, approved prefix matrix, actual route-table association/propagation evidence, allowed/denied probe matrix, on-premises device confirmation, and rollback result to the change record.

## Abort and rollback

Stop immediately for unexpected prefixes, asymmetric routing, cross-environment reachability, a degraded security control, or a tunnel secret exposure. Withdraw the newly advertised prefixes at the customer edge, disable/remove only the new attachment through the approved network change, confirm the previous route state, preserve logs, and rotate exposed secrets. Do not make broad TGW default-route changes as a rollback shortcut.
