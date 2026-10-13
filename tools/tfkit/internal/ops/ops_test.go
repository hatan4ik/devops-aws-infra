package ops

import (
	"context"
	"encoding/json"
	"strings"
	"testing"
)

type mockAWS struct {
	responses map[string]any
}

func (m *mockAWS) CallJSON(_ context.Context, service string, target any, args ...string) error {
	key := service + " " + strings.Join(args, " ")
	for k, resp := range m.responses {
		if strings.HasPrefix(key, k) {
			b, err := json.Marshal(resp)
			if err != nil {
				return err
			}
			return json.Unmarshal(b, target)
		}
	}
	return nil
}

func (m *mockAWS) CallRaw(_ context.Context, _ string, _ ...string) ([]byte, error) {
	return []byte("{}"), nil
}

func TestDiagnoseStack(t *testing.T) {
	mock := &mockAWS{
		responses: map[string]any{
			"sts get-caller-identity": map[string]string{
				"Account": "448871779014",
				"Arn":     "arn:aws:iam::448871779014:role/admin",
			},
			"ecs list-clusters": map[string]any{
				"clusterArns": []string{"arn:aws:ecs:us-east-2:448871779014:cluster/bp-e2e-123456"},
			},
			"ecs list-tasks": map[string]any{
				"taskArns": []string{"arn:aws:ecs:us-east-2:448871779014:task/bp-e2e-123456/task-1"},
			},
			"ecs describe-tasks": map[string]any{
				"tasks": []map[string]any{
					{
						"taskArn": "arn:aws:ecs:us-east-2:448871779014:task/bp-e2e-123456/task-1",
						"containers": []map[string]any{
							{
								"name":   "app",
								"reason": "CannotPullContainerError: ref failed",
							},
						},
					},
				},
			},
			"ec2 describe-vpc-endpoints": map[string]any{
				"VpcEndpoints": []map[string]string{
					{"ServiceName": "com.amazonaws.us-east-2.ecr.api", "State": "available"},
					{"ServiceName": "com.amazonaws.us-east-2.s3", "State": "available"},
				},
			},
			"ec2 describe-security-groups": map[string]any{
				"SecurityGroups": []map[string]string{
					{"GroupId": "sg-123", "Description": "Valid security group description"},
				},
			},
			"ec2 describe-route-tables": map[string]any{
				"RouteTables": []map[string]any{
					{
						"Routes": []map[string]string{
							{"DestinationCidrBlock": "10.0.0.0/16"},
						},
					},
				},
			},
		},
	}

	rep, err := DiagnoseStack(context.Background(), mock, "bp-e2e-", "")
	if err != nil {
		t.Fatalf("DiagnoseStack failed: %v", err)
	}

	if rep.AccountID != "448871779014" {
		t.Errorf("expected account 448871779014, got %s", rep.AccountID)
	}
	if rep.Cluster != "bp-e2e-123456" {
		t.Errorf("expected cluster bp-e2e-123456, got %s", rep.Cluster)
	}
	if len(rep.TaskErrors) != 1 || !strings.Contains(rep.TaskErrors[0], "CannotPullContainerError") {
		t.Errorf("expected CannotPullContainerError, got %+v", rep.TaskErrors)
	}
	if !rep.ZeroEgressOK {
		t.Errorf("expected ZeroEgressOK to be true")
	}
	if rep.Status != "FAIL" { // CannotPullContainerError is a violation
		t.Errorf("expected status FAIL due to container pull error, got %s", rep.Status)
	}
}

func TestScanAndCleanupDryRun(t *testing.T) {
	mock := &mockAWS{
		responses: map[string]any{
			"ecs list-clusters": map[string]any{
				"clusterArns": []string{"arn:aws:ecs:us-east-2:448871779014:cluster/bp-e2e-cleanup"},
			},
			"elbv2 describe-load-balancers": map[string]any{
				"LoadBalancers": []map[string]string{
					{"LoadBalancerArn": "arn:alb:1", "LoadBalancerName": "bp-e2e-alb"},
				},
			},
			"ecr describe-repositories": map[string]any{
				"repositories": []map[string]string{
					{"repositoryName": "bp-e2e-repo"},
				},
			},
		},
	}

	plan, err := ScanAndCleanup(context.Background(), mock, "bp-e2e-", "IntegrationTest", "aws.modules", true)
	if err != nil {
		t.Fatalf("ScanAndCleanup failed: %v", err)
	}
	if !plan.DryRun {
		t.Errorf("expected DryRun to be true")
	}
	if len(plan.Resources) != 3 {
		t.Errorf("expected 3 orphan resources discovered, got %d", len(plan.Resources))
	}
}
