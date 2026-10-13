package cli

import (
	"context"
	"flag"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"runtime"
	"strconv"
	"strings"

	"github.com/hatan4ik/tfkit/internal/fleet"
	"github.com/hatan4ik/tfkit/internal/ops"
	"github.com/hatan4ik/tfkit/internal/output"
	"github.com/hatan4ik/tfkit/internal/policy"
)

// Version is set at build time via -ldflags.
var Version = "0.1.0-dev"

// App encapsulates the CLI runtime streams and dependencies.
type App struct {
	Out       io.Writer
	Err       io.Writer
	GitHubAPI fleet.GitHubAPI
	AWS       ops.AWSCaller
}

// NewApp constructs a default App writing to stdout and stderr.
func NewApp(out, errOut io.Writer) *App {
	return &App{
		Out: out,
		Err: errOut,
	}
}

// Run parses args and dispatches the requested subcommand.
func (a *App) Run(ctx context.Context, args []string) error {
	if len(args) == 0 {
		a.printRootUsage()
		return &UsageError{Msg: "subcommand required"}
	}

	switch args[0] {
	case "-h", "--help", "help":
		a.printRootUsage()
		return nil
	case "version", "--version", "-v":
		return a.runVersion(args[1:])
	case "fleet":
		return a.runFleet(ctx, args[1:])
	case "ops":
		return a.runOps(ctx, args[1:])
	case "policy":
		return a.runPolicy(ctx, args[1:])
	default:
		a.printRootUsage()
		return &UsageError{Msg: fmt.Sprintf("unknown command %q", args[0])}
	}
}

func (a *App) printRootUsage() {
	fmt.Fprintf(a.Err, `tfkit - Unified DevUX, Fleet Governance & SRE ConOps CLI (%s)

Usage:
  tfkit <command> <subcommand> [flags]

Commands:
  fleet status            Audit local aws.modules.* repositories (branch, dirty tree, ahead/behind)
  fleet sync              Fetch remotes, switch clean feature checkouts to main, and fast-forward
  fleet verify-releases   Verify signed tags and GitHub Release parity across all module repos
  ops diagnose            Live AWS stack inspector (ECS tasks, VPC endpoints, zero-egress routes)
  ops triage              GitHub Actions integration run failure analyzer and root cause extractor
  ops janitor             Safe dependency-ordered cleanup of orphan integration test resources
  policy workflows        Validate GitHub Actions workflow structure and 40-char commit SHA pins
  policy markdown         Verify all repository-relative Markdown links resolve on disk
  version                 Print tfkit version and runtime metadata

Global Flags (available on all subcommands):
  --output string         Output format: table or json (default "table")
  --no-color              Disable ANSI color output
`, Version)
}

func (a *App) runVersion(args []string) error {
	fs := flag.NewFlagSet("version", flag.ContinueOnError)
	fs.SetOutput(a.Err)
	outFmt := fs.String("output", "table", "Output format: table or json")
	noColor := fs.Bool("no-color", false, "Disable ANSI color output")
	if err := fs.Parse(args); err != nil {
		return &UsageError{Msg: err.Error()}
	}

	p, err := a.newPrinter(*outFmt, *noColor)
	if err != nil {
		return &UsageError{Msg: err.Error()}
	}

	info := map[string]string{
		"version":    Version,
		"go_version": runtime.Version(),
		"platform":   runtime.GOOS + "/" + runtime.GOARCH,
	}
	if p.Format == output.FormatJSON {
		return p.PrintJSON(info)
	}
	return p.PrintTable(
		[]string{"VERSION", "GO", "PLATFORM"},
		[][]string{{info["version"], info["go_version"], info["platform"]}},
	)
}

func (a *App) runFleet(ctx context.Context, args []string) error {
	if len(args) == 0 || args[0] == "-h" || args[0] == "--help" {
		fmt.Fprintf(a.Err, `Usage:
  tfkit fleet status [--dir <base-dir>] [--prefix aws.modules.] [--fetch] [--output table|json]
  tfkit fleet sync [--dir <base-dir>] [--prefix aws.modules.] [--output table|json]
  tfkit fleet verify-releases [--owner hatan4ik] [--prefix aws.modules.] [--output table|json]
`)
		if len(args) == 0 {
			return &UsageError{Msg: "fleet subcommand required (status, sync, verify-releases)"}
		}
		return nil
	}

	switch args[0] {
	case "status":
		return a.runFleetStatus(ctx, args[1:], false)
	case "sync":
		return a.runFleetStatus(ctx, args[1:], true)
	case "verify-releases":
		return a.runFleetVerifyReleases(ctx, args[1:])
	default:
		return &UsageError{Msg: fmt.Sprintf("unknown fleet subcommand %q", args[0])}
	}
}

func (a *App) runFleetStatus(ctx context.Context, args []string, doSync bool) error {
	defaultDir := defaultFleetBaseDir()
	cmdName := "fleet status"
	if doSync {
		cmdName = "fleet sync"
	}

	fs := flag.NewFlagSet(cmdName, flag.ContinueOnError)
	fs.SetOutput(a.Err)
	baseDir := fs.String("dir", defaultDir, "Parent directory containing module repositories")
	prefix := fs.String("prefix", "aws.modules.", "Repository directory name prefix")
	fetch := fs.Bool("fetch", false, "Fetch remotes before auditing status")
	outFmt := fs.String("output", "table", "Output format: table or json")
	noColor := fs.Bool("no-color", false, "Disable ANSI color output")
	if err := fs.Parse(args); err != nil {
		return &UsageError{Msg: err.Error()}
	}

	p, err := a.newPrinter(*outFmt, *noColor)
	if err != nil {
		return &UsageError{Msg: err.Error()}
	}

	repos, err := fleet.DiscoverRepos(*baseDir, *prefix)
	if err != nil {
		return err
	}
	if len(repos) == 0 {
		return fmt.Errorf("no %s* repositories found in %s", *prefix, *baseDir)
	}

	var results []fleet.RepoStatus
	if doSync {
		results = fleet.SyncRepos(ctx, repos)
	} else {
		results = fleet.AuditRepos(ctx, repos, *fetch)
	}

	if p.Format == output.FormatJSON {
		if err := p.PrintJSON(results); err != nil {
			return err
		}
	} else {
		rows := make([][]string, 0, len(results))
		for _, r := range results {
			syncDesc := fmt.Sprintf("+%d/-%d", r.Ahead, r.Behind)
			stale := "-"
			if len(r.StaleBranches) > 0 {
				stale = strings.Join(r.StaleBranches, ",")
			}
			rows = append(rows, []string{
				r.Name,
				r.Branch,
				p.Badge(r.State),
				syncDesc,
				strconv.Itoa(r.DirtyFiles),
				stale,
			})
		}
		if err := p.PrintTable([]string{"MODULE", "BRANCH", "STATE", "AHEAD/BEHIND", "DIRTY", "EXTRA_BRANCHES"}, rows); err != nil {
			return err
		}
	}

	violations := 0
	for _, r := range results {
		if r.State != "CLEAN" {
			violations++
		}
	}
	if violations > 0 {
		return &ViolationError{
			Count:   violations,
			Summary: fmt.Sprintf("%d of %d repositories are not in CLEAN state", violations, len(results)),
		}
	}
	return nil
}

func (a *App) runFleetVerifyReleases(ctx context.Context, args []string) error {
	defaultOwner := os.Getenv("MODULE_OWNER")
	if defaultOwner == "" {
		defaultOwner = "hatan4ik"
	}

	fs := flag.NewFlagSet("fleet verify-releases", flag.ContinueOnError)
	fs.SetOutput(a.Err)
	owner := fs.String("owner", defaultOwner, "GitHub repository owner")
	prefix := fs.String("prefix", "aws.modules.", "Repository name prefix")
	outFmt := fs.String("output", "table", "Output format: table or json")
	noColor := fs.Bool("no-color", false, "Disable ANSI color output")
	if err := fs.Parse(args); err != nil {
		return &UsageError{Msg: err.Error()}
	}

	p, err := a.newPrinter(*outFmt, *noColor)
	if err != nil {
		return &UsageError{Msg: err.Error()}
	}

	api := a.GitHubAPI
	if api == nil {
		api = fleet.NewHTTPGitHubClient(ctx)
	}

	results, err := fleet.VerifyReleaseFleet(ctx, api, *owner, *prefix)
	if err != nil {
		return err
	}

	if p.Format == output.FormatJSON {
		if err := p.PrintJSON(results); err != nil {
			return err
		}
	} else {
		rows := make([][]string, 0, len(results))
		for _, r := range results {
			shaShort := r.MainSHA
			if len(shaShort) > 7 {
				shaShort = shaShort[:7]
			}
			notes := "verified"
			if len(r.Violations) > 0 {
				notes = strings.Join(r.Violations, "; ")
			}
			rows = append(rows, []string{
				r.Repository,
				r.LatestTag,
				shaShort,
				p.Badge(r.Status),
				notes,
			})
		}
		if err := p.PrintTable([]string{"REPOSITORY", "TAG", "MAIN_SHA", "STATUS", "DETAILS"}, rows); err != nil {
			return err
		}
	}

	failures := 0
	for _, r := range results {
		if r.Status != "PASS" {
			failures++
		}
	}
	if failures > 0 {
		return &ViolationError{
			Count:   failures,
			Summary: fmt.Sprintf("FAIL: %d release invariant violation(s) across %d repositories", failures, len(results)),
		}
	}
	return nil
}

func (a *App) runPolicy(_ context.Context, args []string) error {
	if len(args) == 0 || args[0] == "-h" || args[0] == "--help" {
		fmt.Fprintf(a.Err, `Usage:
  tfkit policy workflows [--dir .github/workflows] [--output table|json]
  tfkit policy markdown [--dir docs] [--output table|json]
`)
		if len(args) == 0 {
			return &UsageError{Msg: "policy subcommand required (workflows, markdown)"}
		}
		return nil
	}

	switch args[0] {
	case "workflows":
		return a.runPolicyWorkflows(args[1:])
	case "markdown":
		return a.runPolicyMarkdown(args[1:])
	default:
		return &UsageError{Msg: fmt.Sprintf("unknown policy subcommand %q", args[0])}
	}
}

func (a *App) runPolicyWorkflows(args []string) error {
	fs := flag.NewFlagSet("policy workflows", flag.ContinueOnError)
	fs.SetOutput(a.Err)
	dir := fs.String("dir", ".github/workflows", "Workflows directory to validate")
	outFmt := fs.String("output", "table", "Output format: table or json")
	noColor := fs.Bool("no-color", false, "Disable ANSI color output")
	if err := fs.Parse(args); err != nil {
		return &UsageError{Msg: err.Error()}
	}

	p, err := a.newPrinter(*outFmt, *noColor)
	if err != nil {
		return &UsageError{Msg: err.Error()}
	}

	report, err := policy.CheckWorkflows(*dir)
	if err != nil {
		return err
	}

	if p.Format == output.FormatJSON {
		if err := p.PrintJSON(report); err != nil {
			return err
		}
	} else {
		if err := p.PrintTable(
			[]string{"DIRECTORY", "FILES", "ACTIONS_PINNED", "STATUS"},
			[][]string{{
				report.Directory,
				strconv.Itoa(report.FilesChecked),
				strconv.Itoa(report.ActionsVerified),
				p.Badge(report.Status),
			}},
		); err != nil {
			return err
		}
		for _, v := range report.Violations {
			fmt.Fprintf(a.Err, "  - %s\n", v)
		}
	}

	if report.Status != "PASS" {
		return &ViolationError{
			Count:   len(report.Violations),
			Summary: fmt.Sprintf("%d workflow policy violation(s)", len(report.Violations)),
		}
	}
	return nil
}

func (a *App) runPolicyMarkdown(args []string) error {
	fs := flag.NewFlagSet("policy markdown", flag.ContinueOnError)
	fs.SetOutput(a.Err)
	dir := fs.String("dir", "docs", "Documentation directory to scan for relative links")
	outFmt := fs.String("output", "table", "Output format: table or json")
	noColor := fs.Bool("no-color", false, "Disable ANSI color output")
	if err := fs.Parse(args); err != nil {
		return &UsageError{Msg: err.Error()}
	}

	p, err := a.newPrinter(*outFmt, *noColor)
	if err != nil {
		return &UsageError{Msg: err.Error()}
	}

	report, err := policy.CheckMarkdownLinks(*dir)
	if err != nil {
		return err
	}

	if p.Format == output.FormatJSON {
		if err := p.PrintJSON(report); err != nil {
			return err
		}
	} else {
		if err := p.PrintTable(
			[]string{"ROOT_DIR", "FILES", "LINKS_CHECKED", "STATUS"},
			[][]string{{
				report.RootDir,
				strconv.Itoa(report.FilesChecked),
				strconv.Itoa(report.LinksChecked),
				p.Badge(report.Status),
			}},
		); err != nil {
			return err
		}
		for _, b := range report.BrokenLinks {
			fmt.Fprintf(a.Err, "  - %s\n", b)
		}
	}

	if report.Status != "PASS" {
		return &ViolationError{
			Count:   len(report.BrokenLinks),
			Summary: fmt.Sprintf("%d broken markdown link(s)", len(report.BrokenLinks)),
		}
	}
	return nil
}

func (a *App) newPrinter(rawFmt string, noColor bool) (*output.Printer, error) {
	f, err := output.ParseFormat(rawFmt)
	if err != nil {
		return nil, err
	}
	return output.NewPrinter(a.Out, a.Err, f, output.ShouldUseColor(noColor)), nil
}

func defaultFleetBaseDir() string {
	if home, err := os.UserHomeDir(); err == nil && home != "" {
		return home
	}
	return filepath.Clean("..")
}
