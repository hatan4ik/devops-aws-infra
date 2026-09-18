# AWS primary-source references

All cost figures are planning benchmarks captured on 2026-09-18. Revalidate them in the AWS Pricing Calculator and Service Quotas console for the selected Regions before approval.

- [Amazon Cognito quotas](https://docs.aws.amazon.com/cognito/latest/developerguide/quotas.html): quotas apply per account and Region; default UserAuthentication quota is 120 RPS; pool user limit is 40 million.
- [Amazon Cognito multi-Region replication](https://docs.aws.amazon.com/cognito/latest/developerguide/user-pool-multi-region.html): MRR uses a primary plus one secondary, requires Essentials/Plus and a multi-Region CMK, has eventual replication, and restricts secondary operations.
- [Amazon Cognito regional data considerations](https://docs.aws.amazon.com/cognito/latest/developerguide/security-cognito-regional-data-considerations.html): a normal user pool stores profiles in one Region.
- [Amazon Cognito pricing](https://aws.amazon.com/cognito/pricing/): Essentials MAU pricing, MRR add-on, and purchasable quota capacity.
- [AWS Transit Gateway documentation](https://docs.aws.amazon.com/vpc/latest/tgw/what-is-transit-gateway.html): encryption control, attachment association, route propagation, BGP, and inter-Region peering.
- [VPC encryption controls](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-encryption-controls.html): TGW encryption support and encrypted lanes.
- [AWS Transit Gateway pricing](https://aws.amazon.com/transit-gateway/pricing/): attachment-hour, data processing, and inter-Region charge examples.
- [AWS Site-to-Site VPN pricing](https://aws.amazon.com/vpn/pricing/): VPN + TGW attachment pricing and accelerated-VPN Global Accelerator costs.
- [AWS Direct Connect pricing](https://aws.amazon.com/directconnect/pricing/): dedicated/hosted port-hour and data transfer pricing.
- [Amazon DynamoDB global tables](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/GlobalTables.html): MREC/MRSC consistency modes and multi-account model.
- [Amazon DynamoDB disaster-recovery strategies](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/DynamodbDisasterRecoveryStrategy.html): global-table recovery characteristics and pricing benchmark.
- [Amazon Verified Permissions](https://docs.aws.amazon.com/verifiedpermissions/latest/userguide/what-is-avp.html) and its [2025 price reduction](https://aws.amazon.com/about-aws/whats-new/2025/06/amazon-verified-permissions-reduces-price/): Cedar authorization and the `$5/million` single-decision benchmark.
- [AWS Fargate pricing](https://aws.amazon.com/fargate/pricing/): per-second vCPU/memory pricing used in the task calculation.
- [AWS Network Firewall pricing](https://aws.amazon.com/network-firewall/pricing/): endpoint-hour/data processing and NAT service-chain discount.
- [AWS PrivateLink pricing](https://aws.amazon.com/privatelink/pricing/): interface-endpoint ENI-hour and data processing pricing.
- [AWS WAF pricing](https://aws.amazon.com/waf/pricing/): Web ACL/rule/request and bot/fraud-control pricing examples.
- [AWS Shield Advanced pricing](https://aws.amazon.com/shield/pricing/): organization subscription and WAF usage interaction.
- [AWS Control Tower Account Factory](https://docs.aws.amazon.com/controltower/latest/userguide/account-factory.html) and [AFT deployment](https://docs.aws.amazon.com/controltower/latest/userguide/aft-getting-started.html): governed account-vending and dedicated AFT account prerequisites.
- [AWS Organizations SCPs](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scps.html) and [management-account guidance](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_best-practices_mgmt-acct.html): SCP scope, staged testing, organization-escape protection, and management-account limits.
- [AWS VPC pricing](https://aws.amazon.com/vpc/pricing/): NAT gateway and gateway-endpoint benchmark used by the cost model.
