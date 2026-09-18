# ADR 0003: Compute Platform for Workloads

## Status
Accepted

## Context
We need a compute platform for low-latency APIs serving 25,000 RPS.

## Options Considered
1. **AWS Lambda (Serverless)**: Event-driven, pay-per-use, scale-to-zero.
2. **Amazon ECS on Fargate**: Serverless containers, standard Docker workflow, predictable latency.
3. **Amazon EKS (Kubernetes)**: Industry standard container orchestration, high flexibility.

## Decision
**Amazon ECS on Fargate**

ECS on Fargate provides the lowest operational burden while maintaining predictable latency and standard container workflows.

## Consequences
* **Positive**: No control plane to manage (unlike EKS); no cold starts (unlike Lambda); fully serverless compute; integrates natively with ALB/NLB.
* **Negative**: Slightly slower deployment times compared to Lambda; less ecosystem tooling compared to Kubernetes (Helm, operators).

## Dissenting Opinions
* *DevOps Lead*: Advocated for EKS given the existing local CCoE Azure Kubernetes patterns and rich ecosystem.
* *Resolution*: The Security Engineer and Cloud Architect rejected EKS due to the heavy operational burden of managing add-ons, upgrades, and IAM integration. ECS Fargate aligns with the "financially conservative / lowest operational burden" constraint.
