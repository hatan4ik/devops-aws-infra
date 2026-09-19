# Chapter 2 — Architecture Reference

**Status:** Stakeholder-approved 2026-09-18 · No application-platform resources created; see ADR 0015 for the separately observed state bootstrap

---

## 2.1 Architecture at a glance

The platform is an active-active, two-Region, multi-account AWS architecture. Stateless application traffic and DynamoDB data are fully active in both Regions. Cognito identity is primary/secondary: the secondary Region can authenticate and issue tokens but cannot create users or perform profile writes.

```mermaid
flowchart TB
  user([End Users])
  dns[Route 53\nLatency + Health Routing]
  cf[CloudFront + WAF\nStatic web & downloads]
  ga[Global Accelerator\nDynamic HTTPS API]
  auth[auth.example.com\nCognito Custom Domain]

  subgraph org[AWS Organization]
    subgraph primary[Primary Region — 2 AZs]
      alb1[Public ALB\nTLS 1.2+ · WAF]
      app1[ECS Fargate\nPrivate subnets]
      cog1[Cognito Essentials\nPrimary user pool]
      ddb1[(DynamoDB\nGlobal table replica)]
      cache1[(ElastiCache\nOptional)]
      tgw1[TGW Hub\nSegmented route tables]
      vpce1[VPC Endpoints\nPrivateLink]
    end
    subgraph secondary[Secondary Region — 2 AZs]
      alb2[Public ALB\nTLS 1.2+ · WAF]
      app2[ECS Fargate\nPrivate subnets]
      cog2[Cognito MRR\nSecondary user pool]
      ddb2[(DynamoDB\nGlobal table replica)]
      cache2[(ElastiCache\nOptional)]
      tgw2[TGW Hub\nSegmented route tables]
      vpce2[VPC Endpoints\nPrivateLink]
    end
    subgraph foundation[Foundational Accounts]
      log[Log Archive]
      sec[Security / Audit]
      net[Network]
      id[Identity]
      svc[Shared Services]
      aft[AFT Management]
    end
  end

  user --> dns
  dns --> cf
  dns --> ga
  dns --> auth
  ga --> alb1 --> app1
  ga --> alb2 --> app2
  auth --> cog1
  cog1 -. managed replication .-> cog2
  app1 <--> ddb1
  app2 <--> ddb2
  ddb1 <-->|bi-directional async| ddb2
  app1 --> cache1
  app2 --> cache2
  app1 --> vpce1
  app2 --> vpce2
  tgw1 <-->|inter-Region peering| tgw2
  sec --> log
```

---

## 2.2 AWS account and OU topology

```mermaid
flowchart TB
  mgmt[Management Account\nOrganizations · Control Tower]

  mgmt --> secOU[Security OU]
  mgmt --> platOU[Platform OU]
  mgmt --> wkldOU[Workloads OU]
  mgmt --> sbxOU[Sandbox OU]
  mgmt --> suspOU[Suspended OU]

  secOU --> audit[Security / Audit\nGuardDuty · Security Hub delegated admin]
  secOU --> archive[Log Archive\nOrg CloudTrail · Config · VPC Flow Logs]

  platOU --> identity[Identity\nIAM Identity Center delegated admin]
  platOU --> network[Network\nTGW · IPAM · Route 53 Resolver]
  platOU --> shared[Shared Services\nState backends · CI support]
  platOU --> aftmgmt[AFT Management\nAccount Factory for Terraform]

  wkldOU --> prod[Workload prod account]
  wkldOU --> staging[Workload staging account]
  wkldOU --> dev[Workload dev account]

  sbxOU --> ephemeral[Ephemeral test accounts]
```

**Key rules:**
- Management account has no workload resources and is never a CI deployment target
- Management root user has no access keys, is MFA-protected, and alerts on any use
- SCPs apply to all member accounts; Management account root is separately hardened
- AFT Management is isolated in Platform OU; its bootstrap is a one-time, separately approved action

---

## 2.3 Network topology

```mermaid
flowchart LR
  onprem[On-Premises\n2 customer gateways\nper Region]

  subgraph netacct[Network Account — Primary Region]
    vpn1[VPN Connection A\nIPsec · IKEv2 · eBGP]
    vpn2[VPN Connection B\nIPsec · IKEv2 · eBGP]
    tgw[Transit Gateway\nEncryption support ON]
    rt_onprem[on-prem\nroute table]
    rt_prod[prod\nroute table]
    rt_nonprod[non-prod\nroute table]
    rt_shared[shared-svc\nroute table]
    rt_inspect[inspection\nroute table]
    resolver[Route 53 Resolver\nInbound + Outbound endpoints]
    egress[Inspection / Egress VPC\nNetwork Firewall · NAT\nConditional — approved egress only]
  end

  prod_vpc[Production\nWorkload VPC]
  nonprod_vpc[Non-Production\nWorkload VPC]
  shared_vpc[Shared Services\nVPC]

  onprem --> vpn1 --> tgw
  onprem --> vpn2 --> tgw
  tgw --- rt_onprem
  tgw --- rt_prod
  tgw --- rt_nonprod
  tgw --- rt_shared
  tgw --- rt_inspect
  tgw --> prod_vpc
  tgw --> nonprod_vpc
  tgw --> shared_vpc
  tgw --> egress
  onprem <--> resolver
```

---

## 2.4 CI/CD delivery pipeline

```mermaid
flowchart LR
  dev[Developer\nlocal branch]
  pr[Pull Request\ngithub.com]

  subgraph quality[Quality Gate — no AWS credentials]
    fmt[terraform fmt]
    validate[terraform validate]
    lint[TFLint]
    test[terraform test\nprovider mocks]
    checkov[Checkov\nIaC policy]
    trivy[Trivy\nHIGH/CRITICAL]
    docs[terraform-docs\ndrift check]
  end

  subgraph plan[Plan Gate — OIDC plan role]
    tfplan[terraform plan]
    cost[Infracost\nbase/head diff]
  end

  subgraph gate[Human Gate — GitHub Environment]
    review[2 approvals\nCODEOWNER review\nstale dismissal]
  end

  subgraph apply[Apply Gate — OIDC apply role]
    replan[terraform plan\nre-run]
    tfapply[terraform apply\nstate lock]
  end

  dev --> pr --> quality --> plan --> gate --> apply
```

---

## 2.5 Data flow — authenticated API request

```mermaid
sequenceDiagram
  participant U as User
  participant GA as Global Accelerator
  participant ALB as Regional ALB + WAF
  participant ECS as ECS Fargate Task
  participant COG as Cognito (JWT validation)
  participant AVP as Verified Permissions (Cedar)
  participant DDB as DynamoDB Global Table

  U->>GA: HTTPS request + JWT
  GA->>ALB: Anycast routing to healthy Region
  ALB->>ECS: TLS-terminated, WAF-inspected
  ECS->>COG: Validate JWT signature + claims (local)
  ECS->>ECS: Coarse authz from JWT scopes/groups
  alt High-value resource decision
    ECS->>AVP: Cedar policy evaluation
    AVP-->>ECS: Allow / Deny
  end
  ECS->>DDB: Read/write via VPC endpoint
  DDB-->>ECS: Response
  ECS-->>U: API response
```

---

## 2.6 Regional failover sequence

```mermaid
sequenceDiagram
  participant MON as CloudWatch Alarm
  participant GA as Global Accelerator
  participant IC as Incident Commander
  participant COG as Cognito Custom Domain
  participant DDB as DynamoDB Global Table
  participant RB as Runbook

  MON->>IC: Regional ALB health check failure alert
  IC->>RB: Open regional-failover runbook
  GA->>GA: Health check stops routing to unhealthy Region
  IC->>IC: Verify survivor Region capacity (N+1 pre-scaled)
  IC->>COG: Confirm MRR secondary pool active for auth
  Note over COG: Signup/password-reset suspended in secondary
  IC->>DDB: Confirm global table healthy in survivor Region
  IC->>RB: Record incident timeline + evidence
  Note over IC,RB: Failback only after primary confirmed healthy\nand controlled change window approved
```

---

## 2.7 Design assumptions summary

| ID | Assumption | Must be validated by |
|---|---|---|
| A-01 | 5M registered users, 1M MAU, 250K peak concurrent sessions | Product analytics |
| A-02 | 300 UserAuthentication RPS per Region | Load test + Cognito quota purchase |
| A-03 | 10,000 API RPS globally; either Region carries full load | API benchmark + load test |
| A-04 | Auth p50 ≤250 ms, p99 ≤600 ms; API p50 ≤100 ms, p99 ≤250 ms | Synthetic tests from user geographies |
| A-05 | API availability SLO 99.99%; auth journey SLO 99.9% | Contract/SLA review |
| A-06 | RTO ≤60 min regional failover; RPO ≤5 min DynamoDB; RPO ≤24 h audit logs | Business continuity approval |
| A-07 | `us-east-2` / `us-west-2` are pricing benchmarks only, not chosen Regions | User geography + data residency review |
| A-13 | `10.128.0.0/9` is available for IPAM — placeholder only | Enterprise IPAM + on-premises conflict review |

Full assumption register: [docs/ASSUMPTIONS.md](../ASSUMPTIONS.md)
