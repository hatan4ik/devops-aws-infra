# Architecture Diagrams

## Target Architecture (Active-Active Multi-Region)

```mermaid
flowchart TD
    User([End Users]) --> Route53[Route 53 Latency Routing]
    
    subgraph Edge Layer
        Route53 --> CF[CloudFront + WAF]
    end
    
    subgraph Region 1 [Primary Region - us-east-1]
        CF --> ALB1[Application Load Balancer]
        
        subgraph Workload VPC
            ALB1 --> ECS1[ECS Fargate APIs]
            ECS1 --> VPCE1[VPC Endpoints]
        end
        
        subgraph Data Layer 1
            ECS1 --> DDB1[(DynamoDB Global Table)]
            ECS1 --> ElastiCache1[(ElastiCache)]
        end
        
        subgraph Network & Security Hub 1
            TGW1[Transit Gateway]
            VPN1[Site-to-Site VPN]
            TGW1 --- VPN1
        end
        
        Workload VPC --> TGW1
    end

    subgraph Region 2 [Secondary Region - eu-west-1]
        CF --> ALB2[Application Load Balancer]
        
        subgraph Workload VPC 2
            ALB2 --> ECS2[ECS Fargate APIs]
            ECS2 --> VPCE2[VPC Endpoints]
        end
        
        subgraph Data Layer 2
            ECS2 --> DDB2[(DynamoDB Global Table)]
            ECS2 --> ElastiCache2[(ElastiCache)]
        end
        
        subgraph Network & Security Hub 2
            TGW2[Transit Gateway]
            VPN2[Site-to-Site VPN]
            TGW2 --- VPN2
        end
        
        Workload VPC 2 --> TGW2
    end
    
    DDB1 <-->|Bi-directional Sync| DDB2
    TGW1 <-->|Inter-Region Peering| TGW2
    VPN1 --- OnPrem[On-Premise DC]
    VPN2 --- OnPrem
    
    subgraph Identity & Governance [Global / Shared]
        Cognito[Amazon Cognito User Pools]
        IdentityCenter[AWS IAM Identity Center]
        CloudWatch[Centralized CloudWatch]
    end
    
    ECS1 -.-> Cognito
    ECS2 -.-> Cognito
    ECS1 -.-> CloudWatch
    ECS2 -.-> CloudWatch
```

