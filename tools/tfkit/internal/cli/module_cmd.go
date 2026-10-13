package cli

import (
	"context"
	"flag"
	"fmt"
	"strconv"
	"strings"

	"github.com/hatan4ik/tfkit/internal/module"
	"github.com/hatan4ik/tfkit/internal/output"
)

func (a *App) runModule(ctx context.Context, args []string) error {
	if len(args) == 0 || args[0] == "-h" || args[0] == "--help" {
		fmt.Fprintf(a.Err, `Usage:
  tfkit module check [--dir .] [--skip-security] [--output table|json]
  tfkit module fmt [--dir .] [--fix]
  tfkit module validate [--dir .]
  tfkit module lint [--dir .]
  tfkit module test [--dir .]
  tfkit module docs [--dir .] [--check]
  tfkit module lock [--dir .] [--platforms all]
  tfkit module dirs [--dir .] [--output table|json]
`)
		if len(args) == 0 {
			return &UsageError{Msg: "module subcommand required (check, fmt, validate, lint, test, docs, lock, dirs)"}
		}
		return nil
	}

	switch args[0] {
	case "check":
		return a.runModuleCheck(ctx, args[1:])
	case "fmt":
		return a.runModuleFmt(ctx, args[1:])
	case "validate":
		return a.runModuleValidate(ctx, args[1:])
	case "lint":
		return a.runModuleLint(ctx, args[1:])
	case "test":
		return a.runModuleTest(ctx, args[1:])
	case "docs":
		return a.runModuleDocs(ctx, args[1:])
	case "lock":
		return a.runModuleLock(ctx, args[1:])
	case "dirs":
		return a.runModuleDirs(args[1:])
	default:
		return &UsageError{Msg: fmt.Sprintf("unknown module subcommand %q", args[0])}
	}
}

func (a *App) getModuleExecutor() module.Executor {
	if a.ModuleExec != nil {
		return a.ModuleExec
	}
	return &module.OSExecutor{}
}

func (a *App) runModuleCheck(ctx context.Context, args []string) error {
	fs := flag.NewFlagSet("module check", flag.ContinueOnError)
	fs.SetOutput(a.Err)
	dir := fs.String("dir", ".", "Module repository directory")
	skipSec := fs.Bool("skip-security", false, "Skip checkov and trivy security scans")
	outFmt := fs.String("output", "table", "Output format: table or json")
	noColor := fs.Bool("no-color", false, "Disable ANSI color output")
	if err := fs.Parse(args); err != nil {
		return &UsageError{Msg: err.Error()}
	}

	p, err := a.newPrinter(*outFmt, *noColor)
	if err != nil {
		return &UsageError{Msg: err.Error()}
	}

	exec := a.getModuleExecutor()
	report, err := module.RunCheck(ctx, exec, *dir, *skipSec)
	if err != nil {
		if report != nil && p.Format == output.FormatJSON {
			_ = p.PrintJSON(report)
		}
		return err
	}

	if p.Format == output.FormatJSON {
		return p.PrintJSON(report)
	}

	rows := [][]string{{
		report.ModuleRoot,
		strconv.Itoa(report.Directories),
		strings.Join(report.StepsPassed, ", "),
		p.Badge(report.Status),
	}}
	return p.PrintTable([]string{"MODULE_ROOT", "DIRS", "STEPS_PASSED", "STATUS"}, rows)
}

func (a *App) runModuleFmt(ctx context.Context, args []string) error {
	fs := flag.NewFlagSet("module fmt", flag.ContinueOnError)
	fs.SetOutput(a.Err)
	dir := fs.String("dir", ".", "Module repository directory")
	fix := fs.Bool("fix", false, "Rewrite files in-place instead of checking")
	if err := fs.Parse(args); err != nil {
		return &UsageError{Msg: err.Error()}
	}
	return module.RunFmt(ctx, a.getModuleExecutor(), *dir, *fix)
}

func (a *App) runModuleValidate(ctx context.Context, args []string) error {
	fs := flag.NewFlagSet("module validate", flag.ContinueOnError)
	fs.SetOutput(a.Err)
	dir := fs.String("dir", ".", "Module repository directory")
	if err := fs.Parse(args); err != nil {
		return &UsageError{Msg: err.Error()}
	}
	dirs, err := module.DiscoverDirs(*dir)
	if err != nil {
		return err
	}
	return module.RunValidate(ctx, a.getModuleExecutor(), *dir, dirs)
}

func (a *App) runModuleLint(ctx context.Context, args []string) error {
	fs := flag.NewFlagSet("module lint", flag.ContinueOnError)
	fs.SetOutput(a.Err)
	dir := fs.String("dir", ".", "Module repository directory")
	if err := fs.Parse(args); err != nil {
		return &UsageError{Msg: err.Error()}
	}
	dirs, err := module.DiscoverDirs(*dir)
	if err != nil {
		return err
	}
	return module.RunLint(ctx, a.getModuleExecutor(), *dir, dirs)
}

func (a *App) runModuleTest(ctx context.Context, args []string) error {
	fs := flag.NewFlagSet("module test", flag.ContinueOnError)
	fs.SetOutput(a.Err)
	dir := fs.String("dir", ".", "Module repository directory")
	if err := fs.Parse(args); err != nil {
		return &UsageError{Msg: err.Error()}
	}
	dirs, err := module.DiscoverDirs(*dir)
	if err != nil {
		return err
	}
	return module.RunTest(ctx, a.getModuleExecutor(), *dir, dirs)
}

func (a *App) runModuleDocs(ctx context.Context, args []string) error {
	fs := flag.NewFlagSet("module docs", flag.ContinueOnError)
	fs.SetOutput(a.Err)
	dir := fs.String("dir", ".", "Module repository directory")
	checkOnly := fs.Bool("check", false, "Verify documentation is up to date without writing")
	if err := fs.Parse(args); err != nil {
		return &UsageError{Msg: err.Error()}
	}
	dirs, err := module.DiscoverDirs(*dir)
	if err != nil {
		return err
	}
	return module.RunDocs(ctx, a.getModuleExecutor(), *dir, dirs, *checkOnly)
}

func (a *App) runModuleLock(ctx context.Context, args []string) error {
	fs := flag.NewFlagSet("module lock", flag.ContinueOnError)
	fs.SetOutput(a.Err)
	dir := fs.String("dir", ".", "Module repository directory")
	if err := fs.Parse(args); err != nil {
		return &UsageError{Msg: err.Error()}
	}
	return module.RunLock(ctx, a.getModuleExecutor(), *dir, nil)
}

func (a *App) runModuleDirs(args []string) error {
	fs := flag.NewFlagSet("module dirs", flag.ContinueOnError)
	fs.SetOutput(a.Err)
	dir := fs.String("dir", ".", "Module repository directory")
	outFmt := fs.String("output", "table", "Output format: table or json")
	noColor := fs.Bool("no-color", false, "Disable ANSI color output")
	if err := fs.Parse(args); err != nil {
		return &UsageError{Msg: err.Error()}
	}

	dirs, err := module.DiscoverDirs(*dir)
	if err != nil {
		return err
	}

	p, err := a.newPrinter(*outFmt, *noColor)
	if err != nil {
		return &UsageError{Msg: err.Error()}
	}

	if p.Format == output.FormatJSON {
		return p.PrintJSON(dirs)
	}

	rows := [][]string{
		{"ROOTS", strings.Join(dirs.Roots, ", ")},
		{"EXAMPLES", strings.Join(dirs.Examples, ", ")},
		{"FIXTURES", strings.Join(dirs.Fixtures, ", ")},
		{"ALL (" + strconv.Itoa(len(dirs.All)) + ")", strings.Join(dirs.All, ", ")},
	}
	return p.PrintTable([]string{"CATEGORY", "DIRECTORIES"}, rows)
}
