package ops

import (
	"context"
	"fmt"
	"regexp"
	"strings"
	"sync"
)

var validSGDescRegex = regexp.MustCompile(`^[a-zA-Z0-9. _\-:/()#,@\[\]+=&;{}!$*]+$`)

// DiagnosticReport contains the complete live stack health and compliance state.
type DiagnosticReport struct {
	AccountID       string            `json:"account_id"`
	Region          string            `json:"region"`
	CallerARN       string            `json:"caller_arn"`
	Cluster         string            `json:"cluster"`
	ActiveTasks     int               `json:"active_tasks"`
	StoppedTasks    int               `json:"stopped_tasks"`
	TaskErrors      []string          `json:"task_errors,omitempty"`
	Endpoints       map[string]string `json:"endpoints"`
	ZeroEgressOK    bool              `json:"zero_egress_ok"`
	SGsValidated    int               `json:"security_groups_validated"`
	SGDescriptionOK bool              `json:"sg_description_ok"`
	Status          string            `json:"status"` // PASS, WARN, or FAIL
	Violations      []string          `json:"violations,omitempty"`
}

// DiagnoseStack runs read-only inspections against active AWS infrastructure.
func DiagnoseStack(ctx context.Context, aws AWSCaller, prefix, cluster string) (*DiagnosticReport, error) {
	rep := &DiagnosticReport{
		Endpoints: make(map[string]string),
		Status:    "PASS",
	}

	// 1. Caller Identity
	var identity struct {
		Account string `json:"Account"`
		Arn     string `json:"Arn"`
	}
	if err := aws.CallJSON(ctx, "sts", &identity, "get-caller-identity"); err != nil {
		return nil, fmt.Errorf("getting caller identity: %w", err)
	}
	rep.AccountID = identity.Account
	rep.CallerARN = identity.Arn

	// 2. Cluster Discovery
	if cluster == "" {
		var clusterList struct {
			ClusterArns []string `json:"clusterArns"`
		}
		if err := aws.CallJSON(ctx, "ecs", &clusterList, "list-clusters"); err == nil {
			for _, arn := range clusterList.ClusterArns {
				if strings.Contains(arn, prefix) {
					parts := strings.Split(arn, "/")
					rep.Cluster = parts[len(parts)-1]
					break
				}
			}
		}
	} else {
		rep.Cluster = cluster
	}

	var wg sync.WaitGroup
	var mu sync.Mutex

	// 3. ECS Tasks Diagnostics (if cluster found)
	if rep.Cluster != "" {
		wg.Add(1)
		go func() {
			defer wg.Done()
			var running struct {
				TaskArns []string `json:"taskArns"`
			}
			_ = aws.CallJSON(ctx, "ecs", &running, "list-tasks", "--cluster", rep.Cluster, "--desired-status", "RUNNING")

			var stopped struct {
				TaskArns []string `json:"taskArns"`
			}
			_ = aws.CallJSON(ctx, "ecs", &stopped, "list-tasks", "--cluster", rep.Cluster, "--desired-status", "STOPPED")

			mu.Lock()
			rep.ActiveTasks = len(running.TaskArns)
			rep.StoppedTasks = len(stopped.TaskArns)
			mu.Unlock()

			if len(stopped.TaskArns) > 0 {
				args := []string{"describe-tasks", "--cluster", rep.Cluster, "--tasks"}
				args = append(args, stopped.TaskArns...)
				var desc struct {
					Tasks []struct {
						TaskArn       string `json:"taskArn"`
						StoppedReason string `json:"stoppedReason"`
						Containers    []struct {
							Name     string `json:"name"`
							ExitCode *int   `json:"exitCode"`
							Reason   string `json:"reason"`
						} `json:"containers"`
					} `json:"tasks"`
				}
				if err := aws.CallJSON(ctx, "ecs", &desc, args...); err == nil {
					mu.Lock()
					for _, t := range desc.Tasks {
						short := t.TaskArn
						if parts := strings.Split(t.TaskArn, "/"); len(parts) > 2 {
							short = parts[len(parts)-1]
						}
						for _, c := range t.Containers {
							if c.Reason != "" {
								msg := fmt.Sprintf("task %s: %s (%s)", short, c.Reason, c.Name)
								rep.TaskErrors = append(rep.TaskErrors, msg)
								if strings.Contains(c.Reason, "CannotPullContainer") || strings.Contains(c.Reason, "ResourceInitializationError") {
									rep.Violations = append(rep.Violations, msg)
								}
							}
						}
					}
					mu.Unlock()
				}
			}
		}()
	}

	// 4. VPC Endpoints Inspection
	wg.Add(1)
	go func() {
		defer wg.Done()
		var endpoints struct {
			VpcEndpoints []struct {
				ServiceName string `json:"ServiceName"`
				State       string `json:"State"`
			} `json:"VpcEndpoints"`
		}
		if err := aws.CallJSON(ctx, "ec2", &endpoints, "describe-vpc-endpoints"); err == nil {
			mu.Lock()
			for _, ep := range endpoints.VpcEndpoints {
				parts := strings.Split(ep.ServiceName, ".")
				svc := parts[len(parts)-1]
				rep.Endpoints[svc] = ep.State
				if ep.State != "available" {
					rep.Violations = append(rep.Violations, fmt.Sprintf("endpoint %s is %s", svc, ep.State))
				}
			}
			mu.Unlock()
		}
	}()

	// 5. Route Tables Zero-Egress Inspection
	wg.Add(1)
	go func() {
		defer wg.Done()
		var routes struct {
			RouteTables []struct {
				Routes []struct {
					DestinationCidrBlock     string `json:"DestinationCidrBlock"`
					DestinationIpv6CidrBlock string `json:"DestinationIpv6CidrBlock"`
				} `json:"Routes"`
			} `json:"RouteTables"`
		}
		zeroEgress := true
		if err := aws.CallJSON(ctx, "ec2", &routes, "describe-route-tables"); err == nil {
			for _, rt := range routes.RouteTables {
				for _, r := range rt.Routes {
					if r.DestinationCidrBlock == "0.0.0.0/0" || r.DestinationIpv6CidrBlock == "::/0" {
						zeroEgress = false
					}
				}
			}
		}
		mu.Lock()
		rep.ZeroEgressOK = zeroEgress
		mu.Unlock()
	}()

	// 6. Security Group Character Set Validation
	wg.Add(1)
	go func() {
		defer wg.Done()
		var sgs struct {
			SecurityGroups []struct {
				GroupId     string `json:"GroupId"`
				Description string `json:"Description"`
			} `json:"SecurityGroups"`
		}
		allValid := true
		count := 0
		if err := aws.CallJSON(ctx, "ec2", &sgs, "describe-security-groups"); err == nil {
			for _, sg := range sgs.SecurityGroups {
				count++
				if !validSGDescRegex.MatchString(sg.Description) {
					allValid = false
					mu.Lock()
					rep.Violations = append(rep.Violations, fmt.Sprintf("SG %s description violates EC2 regex: %q", sg.GroupId, sg.Description))
					mu.Unlock()
				}
			}
		}
		mu.Lock()
		rep.SGsValidated = count
		rep.SGDescriptionOK = allValid
		mu.Unlock()
	}()

	wg.Wait()

	if len(rep.Violations) > 0 {
		rep.Status = "FAIL"
	} else if len(rep.TaskErrors) > 0 {
		rep.Status = "WARN"
	}
	return rep, nil
}
