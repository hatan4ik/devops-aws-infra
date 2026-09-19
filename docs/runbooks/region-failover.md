# Runbook: Active-Active Region Failover / Evacuation

## Purpose
Procedure to gracefully shift all traffic away from a failing AWS region to the remaining healthy region.

## Context
Per ADR 0002, the architecture is Active-Active. Both regions serve traffic simultaneously. A failover means we are actively draining one region (making it Active-Passive temporarily).

## Procedure
1. **Identify Failure**: Verify via CloudWatch Alarms that a regional failure has occurred (e.g., Auth latency spikes > 500ms consistently in `eu-west-1`).
2. **Shift DNS Routing**:
   - Navigate to the `platform-aws-platform-roots/network/route53.tf` (or equivalent CloudFront configuration).
   - If using Route 53 Latency records, disable the record for the failing region, OR change the weight of the failing region to `0`.
   - If using CloudFront Origin Groups (ADR 0006), ensure the primary origin is marked unhealthy. CloudFront will automatically failover to the secondary origin within milliseconds.
3. **Verify Data Replication**:
   - DynamoDB Global Tables handles async replication automatically. Check the `ReplicationLatency` metric in the healthy region to ensure it is not spiking.
   - *Warning*: Data written to the failed region seconds before the outage may be lost or delayed.
4. **Scale Compute**:
   - The healthy region will receive 2x traffic.
   - ECS Fargate Target Tracking scaling policies will automatically spin up more tasks.
   - Monitor the 5XX errors on the healthy region ALB while scaling catches up.

## Revert Procedure
1. Verify the failing region is completely healthy via synthetic tests.
2. Re-enable the DNS Latency record or restore CloudFront Origin weights.
3. Traffic will naturally balance back based on DNS TTL (usually 60 seconds).

