# SES Projects Digest

## Overview
This document summarizes the cloud architecture, best practices, and conventions extracted from the local `~/ses-projects/` repository collection.

### Repository Inventory Analysis
The local repositories are overwhelmingly Azure-focused rather than AWS-focused. Key findings include:
- **Azure Landing Zone / CCoE**: Extensive documentation on Azure Cloud Center of Excellence (CCoE), Microsoft Security Management (MSM) Control Framework, Azure Policy (OPA/Gatekeeper in AKS), and Azure Resource Manager / Terraform deployments.
- **Azure Workloads**: `azure-mx1-dc-migration`, `azure-o3b-dc-migration`, `azure-pde-lab`.
- **Containers**: Kubernetes (`aks`) configuration examples including Cilium CNI, NGINX Ingress, and GitOps deployments.
- **AWS Legacy**: A single AWS-related project (`aws-terraforming-import-ovp`) which consists of a legacy `terraforming` flat file dump (bare resources, no modules).
- **Application Code**: `UCP-Authentication` (Node.js/TypeScript backend).

## What to Reuse Verbatim
Given the strict AWS target architecture, there is little *infrastructure code* to reuse verbatim. However, several *process and governance* concepts from the SES CCoE are highly applicable and should be adopted:
1. **MSM Control Framework**:
   - **Playground Controls**: Environments are automatically deployed on request with delegated authorization and deleted automatically at the end of their agreed lifetime.
   - **Incident Response**: Major Incident Response Plan (MIRP) and Health alerts correlation.
   - **Financial Controls**: Spending limits are defined and alerts are automatically generated.
2. **Security Control Framework (SCF)**:
   - `SCF-IAM-04` Least-Privilege Access to resources.
   - `SCF-INFRA-07` Micro-Segmentation.
   - `SCF-DATA-03` Encrypt data in transit using private & public connectivity.
   - `SCF-INFRA-01` Application Whitelisting.

## What to Adapt
- **Landing Zone Concepts**: Azure CCoE principles (Management, Identity, Connectivity subscriptions) map directly to AWS Organizations (Control Tower, Identity Center, Network/Shared Services accounts).
- **Naming Conventions**: Azure naming conventions in `names.tf` should be adapted to the AWS naming standard requested in Phase 4 (lowercase, hyphenated, `org-aws-platform-layer`).
- **AKS GitOps / Policy**: Adapt Azure OPA/Gatekeeper policies to AWS EKS/ECS context if Kubernetes is chosen, or to AWS Config/SCP for the platform layer.

## What Conflicts with AWS Best Practice (and Which Wins)
1. **Flat File Architecture vs. Modular Design**
   - **Conflict**: `aws-terraforming-import-ovp` dumps all resources into root-level flat files (e.g., `ec2.tf`, `iamr.tf`) with zero modularity or abstraction.
   - **Winner**: The new AWS Best Practice (Engineering Pillars: SOLID). We will discard the flat structure and enforce strict module boundaries, using root invocations for composition only.
2. **Bare Resources in Roots**
   - **Conflict**: Existing Terraform examples use bare resources rather than typed module calls.
   - **Winner**: Phase 5 requirements explicitly forbid bare resources in roots. All resources will be wrapped in reusable, version-tagged modules.
3. **IAM and Credential Management**
   - **Conflict**: Some existing projects reference local `credentials.tf` and static app passwords.
   - **Winner**: AWS Identity Center + OIDC for CI/CD. No static credentials or long-lived IAM users.
