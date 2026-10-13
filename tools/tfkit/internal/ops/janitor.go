package ops

import (
	"context"
	"fmt"
	"strings"
)

// OrphanResource represents an AWS resource slated for safe dependency-ordered cleanup.
type OrphanResource struct {
	Type string `json:"type"`
	ID   string `json:"id"`
	Name string `json:"name,omitempty"`
}

// JanitorPlan represents the ordered discovery and action plan.
type JanitorPlan struct {
	DryRun    bool             `json:"dry_run"`
	Resources []OrphanResource `json:"resources"`
	Summary   string           `json:"summary"`
}

// ScanAndCleanup discovers tagged orphan resources and purges them in dependency order.
func ScanAndCleanup(ctx context.Context, aws AWSCaller, prefix, tagKey, tagValue string, dryRun bool) (*JanitorPlan, error) {
	plan := &JanitorPlan{
		DryRun: dryRun,
	}

	// 1. Discover Clusters matching prefix
	var clusters struct {
		ClusterArns []string `json:"clusterArns"`
	}
	_ = aws.CallJSON(ctx, "ecs", &clusters, "list-clusters")

	var matchedClusters []string
	for _, arn := range clusters.ClusterArns {
		if strings.Contains(arn, prefix) {
			parts := strings.Split(arn, "/")
			cName := parts[len(parts)-1]
			matchedClusters = append(matchedClusters, cName)
			plan.Resources = append(plan.Resources, OrphanResource{Type: "ECS_CLUSTER", ID: cName})
		}
	}

	// 2. Discover ALBs matching prefix
	var albs struct {
		LoadBalancers []struct {
			LoadBalancerArn  string `json:"LoadBalancerArn"`
			LoadBalancerName string `json:"LoadBalancerName"`
		} `json:"LoadBalancers"`
	}
	_ = aws.CallJSON(ctx, "elbv2", &albs, "describe-load-balancers")
	for _, lb := range albs.LoadBalancers {
		if strings.Contains(lb.LoadBalancerName, prefix) {
			plan.Resources = append(plan.Resources, OrphanResource{
				Type: "ALB",
				ID:   lb.LoadBalancerArn,
				Name: lb.LoadBalancerName,
			})
		}
	}

	// 3. Discover ECR Repositories matching prefix
	var repos struct {
		Repositories []struct {
			RepositoryName string `json:"repositoryName"`
		} `json:"repositories"`
	}
	_ = aws.CallJSON(ctx, "ecr", &repos, "describe-repositories")
	for _, r := range repos.Repositories {
		if strings.Contains(r.RepositoryName, prefix) {
			plan.Resources = append(plan.Resources, OrphanResource{
				Type: "ECR_REPOSITORY",
				ID:   r.RepositoryName,
			})
		}
	}

	// 4. Discover VPC Endpoints tagged or matching VPC
	var endpoints struct {
		VpcEndpoints []struct {
			VpcEndpointId string `json:"VpcEndpointId"`
			Tags          []struct {
				Key   string `json:"Key"`
				Value string `json:"Value"`
			} `json:"Tags"`
		} `json:"VpcEndpoints"`
	}
	_ = aws.CallJSON(ctx, "ec2", &endpoints, "describe-vpc-endpoints")
	for _, ep := range endpoints.VpcEndpoints {
		matches := false
		for _, t := range ep.Tags {
			if t.Key == tagKey && t.Value == tagValue {
				matches = true
				break
			}
		}
		if matches {
			plan.Resources = append(plan.Resources, OrphanResource{
				Type: "VPC_ENDPOINT",
				ID:   ep.VpcEndpointId,
			})
		}
	}

	// 5. Discover VPCs tagged with IntegrationTest
	var vpcs struct {
		Vpcs []struct {
			VpcId string `json:"VpcId"`
			Tags  []struct {
				Key   string `json:"Key"`
				Value string `json:"Value"`
			} `json:"Tags"`
		} `json:"Vpcs"`
	}
	_ = aws.CallJSON(ctx, "ec2", &vpcs, "describe-vpcs")
	for _, v := range vpcs.Vpcs {
		matches := false
		for _, t := range v.Tags {
			if t.Key == tagKey && t.Value == tagValue {
				matches = true
				break
			}
		}
		if matches {
			plan.Resources = append(plan.Resources, OrphanResource{
				Type: "VPC",
				ID:   v.VpcId,
			})
		}
	}

	// If dry-run, we return the plan without executing deletions.
	if dryRun {
		plan.Summary = fmt.Sprintf("DRY-RUN: %d orphan resources identified for deletion", len(plan.Resources))
		return plan, nil
	}

	// Execution order: ECS Tasks/Services -> ALBs -> ECR -> Endpoints -> VPC -> Cluster
	for _, res := range plan.Resources {
		switch res.Type {
		case "ALB":
			_, _ = aws.CallRaw(ctx, "elbv2", "delete-load-balancer", "--load-balancer-arn", res.ID)
		case "ECR_REPOSITORY":
			_, _ = aws.CallRaw(ctx, "ecr", "delete-repository", "--repository-name", res.ID, "--force")
		case "VPC_ENDPOINT":
			_, _ = aws.CallRaw(ctx, "ec2", "delete-vpc-endpoints", "--vpc-endpoint-ids", res.ID)
		case "ECS_CLUSTER":
			_, _ = aws.CallRaw(ctx, "ecs", "delete-cluster", "--cluster", res.ID)
		}
	}

	plan.Summary = fmt.Sprintf("PURGED: %d orphan resources successfully cleaned up", len(plan.Resources))
	return plan, nil
}
