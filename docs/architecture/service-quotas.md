# Service quota and capacity register

Quotas must be checked in the target account and selected Region before any
deployment. Values below are planning obligations, not asserted limits or
approved quota increases.

| Service / capability | Planning driver | Validation required | Owner | Evidence |
|---|---|---|---|---|
| Cognito authentication | Assumption A-02 and login flow | Current per-pool/account quota, MFA/challenge load test, paid quota decision | Identity + product owner | Service Quotas response and benchmark |
| ECS Fargate | Assumption A-03/A-10 | vCPU/task limits, subnet IP capacity, task startup/load benchmark | Service + platform owner | Quota export and load-test result |
| ALB / Global Accelerator | Regional active-active API | Target/LCU/endpoint capacity and failover behaviour | Edge + SRE owner | Quota export and game day |
| DynamoDB global tables | RPO and workload data model | Read/write/storage/backup/replication capacity and restore test | Data owner | Load/restore evidence |
| VPC, TGW, RAM, VPN, BGP | Multi-account/hybrid topology | CIDR/IPAM, attachment, route, tunnel and prefix limits | Network owner | IPAM/route design and device test |
| PrivateLink endpoints | Assumption A-09 | Endpoint/service support, ENI/IP capacity, endpoint policy | Network + platform owner | Dependency inventory and quota check |
| KMS, CloudTrail, Config, logs | Encryption and evidence retention | Key, request, trail/config/log delivery quotas and retention cost | Security owner | Service Quotas and retention approval |
| S3 state and Object Lock | State recovery | Bucket/Object Lock support, version volume, KMS requests, retention policy | Platform + Security + FinOps | Restore drill and Cost Explorer/CUR baseline |

The change record must attach quota evidence and a capacity result for every row
used by the deployed workload. A quota request is not completion evidence until
the account/Region reports the approved value.
