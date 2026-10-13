package cli

import (
	"context"
	"flag"
	"fmt"
	"os"
	"strconv"
	"strings"

	"github.com/hatan4ik/tfkit/internal/fleet"
	"github.com/hatan4ik/tfkit/internal/ops"
	"github.com/hatan4ik/tfkit/internal/output"
)

func (a *App) runOps(ctx context.Context, args []string) error {
	if len(args) == 0 || args[0] == "-h" || args[0] == "--help" {
		fmt.Fprintf(a.Err, `Usage:
  tfkit ops diagnose [--prefix bp-e2e-] [--cluster <name>] [--region us-east-2] [--profile <name>] [--output table|json]
  tfkit ops triage [--run-id <id>] [--repo <owner/repo>] [--limit 5] [--output table|json]
  tfkit ops janitor [--prefix bp-e2e-] [--tag-key IntegrationTest] [--tag-value <val>] [--dry-run=false] [--force]
`)
		if len(args) == 0 {
			return &UsageError{Msg: "ops subcommand required (diagnose, triage, janitor)"}
		}
		return nil
	}

	switch args[0] {
	case "diagnose":
		return a.runOpsDiagnose(ctx, args[1:])
	case "triage":
		return a.runOpsTriage(ctx, args[1:])
	case "janitor":
		return a.runOpsJanitor(ctx, args[1:])
	default:
		return &UsageError{Msg: fmt.Sprintf("unknown ops subcommand %q", args[0])}
	}
}

func (a *App) runOpsDiagnose(ctx context.Context, args []string) error {
	fs := flag.NewFlagSet("ops diagnose", flag.ContinueOnError)
	fs.SetOutput(a.Err)
	prefix := fs.String("prefix", "bp-e2e-", "Name prefix filter for resources")
	cluster := fs.String("cluster", "", "Specific ECS cluster name to inspect")
	region := fs.String("region", os.Getenv("AWS_REGION"), "AWS Region (default: AWS_REGION or us-east-2)")
	profile := fs.String("profile", os.Getenv("AWS_PROFILE"), "AWS CLI profile (default: AWS_PROFILE)")
	outFmt := fs.String("output", "table", "Output format: table or json")
	noColor := fs.Bool("no-color", false, "Disable ANSI color output")
	if err := fs.Parse(args); err != nil {
		return &UsageError{Msg: err.Error()}
	}

	if *region == "" {
		*region = "us-east-2"
	}

	p, err := a.newPrinter(*outFmt, *noColor)
	if err != nil {
		return &UsageError{Msg: err.Error()}
	}

	awsClient := a.AWS
	if awsClient == nil {
		awsClient = ops.NewCLIClient(*profile, *region)
	}

	rep, err := ops.DiagnoseStack(ctx, awsClient, *prefix, *cluster)
	if err != nil {
		return err
	}

	if p.Format == output.FormatJSON {
		if err := p.PrintJSON(rep); err != nil {
			return err
		}
	} else {
		fmt.Fprintf(a.Out, "Account: %s | Region: %s | Caller: %s\n", rep.AccountID, *region, rep.CallerARN)
		clusterDesc := rep.Cluster
		if clusterDesc == "" {
			clusterDesc = "(none found)"
		}
		fmt.Fprintf(a.Out, "Cluster: %s | Active Tasks: %d | Stopped Tasks: %d\n", clusterDesc, rep.ActiveTasks, rep.StoppedTasks)

		epList := make([]string, 0, len(rep.Endpoints))
		for k, v := range rep.Endpoints {
			epList = append(epList, fmt.Sprintf("%s=%s", k, v))
		}
		epDesc := strings.Join(epList, ", ")
		if epDesc == "" {
			epDesc = "(none)"
		}
		fmt.Fprintf(a.Out, "Endpoints: %s\n", epDesc)
		fmt.Fprintf(a.Out, "Zero-Egress Private Routes: %s | SG Description Regex: %s\n",
			p.Badge(boolStatus(rep.ZeroEgressOK)), p.Badge(boolStatus(rep.SGDescriptionOK)))

		if len(rep.Violations) > 0 {
			fmt.Fprintf(a.Err, "\nViolations:\n")
			for _, v := range rep.Violations {
				fmt.Fprintf(a.Err, "  - %s\n", v)
			}
		}
		if len(rep.TaskErrors) > 0 {
			fmt.Fprintf(a.Err, "\nTask Error Details:\n")
			for _, te := range rep.TaskErrors {
				fmt.Fprintf(a.Err, "  - %s\n", te)
			}
		}
	}

	if rep.Status == "FAIL" {
		return &ViolationError{
			Count:   len(rep.Violations),
			Summary: fmt.Sprintf("diagnose failed: %d violation(s) detected", len(rep.Violations)),
		}
	}
	return nil
}

func (a *App) runOpsTriage(ctx context.Context, args []string) error {
	fs := flag.NewFlagSet("ops triage", flag.ContinueOnError)
	fs.SetOutput(a.Err)
	repo := fs.String("repo", "hatan4ik/aws.modules.blueprint-microservice-private", "GitHub repository (owner/repo)")
	runID := fs.Int64("run-id", 0, "Specific workflow run ID to triage")
	limit := fs.Int("limit", 5, "Number of recent runs to list if run-id is not provided")
	outFmt := fs.String("output", "table", "Output format: table or json")
	noColor := fs.Bool("no-color", false, "Disable ANSI color output")
	if err := fs.Parse(args); err != nil {
		return &UsageError{Msg: err.Error()}
	}

	p, err := a.newPrinter(*outFmt, *noColor)
	if err != nil {
		return &UsageError{Msg: err.Error()}
	}

	parts := strings.Split(*repo, "/")
	if len(parts) != 2 {
		return &UsageError{Msg: fmt.Sprintf("invalid repo format %q (expected owner/repo)", *repo)}
	}
	owner, repoName := parts[0], parts[1]

	api := a.GitHubAPI
	var rawClient *fleet.HTTPGitHubClient
	if api == nil {
		rawClient = fleet.NewHTTPGitHubClient(ctx)
		api = rawClient
	}

	if *runID == 0 {
		runs, err := ops.ListRecentRuns(ctx, api, owner, repoName, *limit)
		if err != nil {
			return err
		}
		if p.Format == output.FormatJSON {
			return p.PrintJSON(runs)
		}
		rows := make([][]string, len(runs))
		for i, r := range runs {
			rows[i] = []string{
				strconv.FormatInt(r.ID, 10),
				p.Badge(strings.ToUpper(r.Conclusion)),
				r.CreatedAt,
				r.Name,
			}
		}
		return p.PrintTable([]string{"RUN_ID", "CONCLUSION", "CREATED_AT", "WORKFLOW"}, rows)
	}

	report, err := ops.TriageRun(ctx, api, rawClient, owner, repoName, *runID)
	if err != nil {
		return err
	}

	if p.Format == output.FormatJSON {
		return p.PrintJSON(report)
	}

	fmt.Fprintf(a.Out, "Run: %d (%s) | Status: %s | Conclusion: %s\n", report.RunID, report.Repo, report.Status, p.Badge(strings.ToUpper(report.Conclusion)))
	fmt.Fprintf(a.Out, "Summary: %s\n", report.Summary)
	if len(report.Failures) > 0 {
		fmt.Fprintf(a.Err, "\nFailed Steps:\n")
		for _, f := range report.Failures {
			fmt.Fprintf(a.Err, "  - [%s] Step #%d: %s (%s)\n", f.JobName, f.StepNumber, f.StepName, p.Badge("FAILED"))
			for _, line := range f.KeyErrors {
				fmt.Fprintf(a.Err, "      > %s\n", line)
			}
		}
	}

	if report.Conclusion == "failure" {
		return &ViolationError{
			Count:   len(report.Failures),
			Summary: report.Summary,
		}
	}
	return nil
}

func (a *App) runOpsJanitor(ctx context.Context, args []string) error {
	fs := flag.NewFlagSet("ops janitor", flag.ContinueOnError)
	fs.SetOutput(a.Err)
	prefix := fs.String("prefix", "bp-e2e-", "Name prefix filter for orphan resources")
	tagKey := fs.String("tag-key", "IntegrationTest", "Resource tag key filter")
	tagValue := fs.String("tag-value", "aws.modules.blueprint-microservice-private", "Resource tag value filter")
	region := fs.String("region", os.Getenv("AWS_REGION"), "AWS Region")
	profile := fs.String("profile", os.Getenv("AWS_PROFILE"), "AWS Profile")
	dryRun := fs.Bool("dry-run", true, "Preview resources without executing deletions")
	force := fs.Bool("force", false, "Execute deletions without prompting (sets dry-run=false)")
	outFmt := fs.String("output", "table", "Output format: table or json")
	noColor := fs.Bool("no-color", false, "Disable ANSI color output")
	if err := fs.Parse(args); err != nil {
		return &UsageError{Msg: err.Error()}
	}

	if *force {
		*dryRun = false
	}
	if *region == "" {
		*region = "us-east-2"
	}

	p, err := a.newPrinter(*outFmt, *noColor)
	if err != nil {
		return &UsageError{Msg: err.Error()}
	}

	awsClient := a.AWS
	if awsClient == nil {
		awsClient = ops.NewCLIClient(*profile, *region)
	}

	plan, err := ops.ScanAndCleanup(ctx, awsClient, *prefix, *tagKey, *tagValue, *dryRun)
	if err != nil {
		return err
	}

	if p.Format == output.FormatJSON {
		return p.PrintJSON(plan)
	}

	rows := make([][]string, len(plan.Resources))
	for i, r := range plan.Resources {
		name := r.Name
		if name == "" {
			name = "-"
		}
		rows[i] = []string{r.Type, r.ID, name}
	}

	if err := p.PrintTable([]string{"TYPE", "IDENTIFIER", "NAME"}, rows); err != nil {
		return err
	}
	fmt.Fprintf(a.Out, "\n%s\n", plan.Summary)
	return nil
}

func boolStatus(b bool) string {
	if b {
		return "PASS"
	}
	return "FAIL"
}
