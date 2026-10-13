package module

import (
	"context"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
)

// Executor runs an external system command with context.
type Executor interface {
	Run(ctx context.Context, dir, name string, args ...string) error
}

// OSExecutor is the default real os/exec command executor.
type OSExecutor struct{}

func (e *OSExecutor) Run(ctx context.Context, dir, name string, args ...string) error {
	cmd := exec.CommandContext(ctx, name, args...)
	cmd.Dir = dir
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}

// CheckReport summarizes the results of running module quality checks.
type CheckReport struct {
	ModuleRoot  string   `json:"module_root"`
	Directories int      `json:"directories_checked"`
	StepsPassed []string `json:"steps_passed"`
	Status      string   `json:"status"` // PASS or FAIL
	Error       string   `json:"error,omitempty"`
}

// RunFmt checks or fixes formatting recursively using terraform fmt.
func RunFmt(ctx context.Context, exec Executor, rootDir string, fix bool) error {
	args := []string{"fmt", "-recursive"}
	if !fix {
		args = []string{"fmt", "-check", "-recursive", "-diff"}
	}
	return exec.Run(ctx, rootDir, "terraform", args...)
}

// RunValidate inits each directory with -backend=false and validates HCL.
func RunValidate(ctx context.Context, exec Executor, rootDir string, dirs *Dirs) error {
	for _, relDir := range dirs.All {
		targetDir := filepath.Join(rootDir, relDir)
		if err := exec.Run(ctx, targetDir, "terraform", "init", "-backend=false", "-input=false"); err != nil {
			return fmt.Errorf("terraform init %s: %w", relDir, err)
		}
		if err := exec.Run(ctx, targetDir, "terraform", "validate"); err != nil {
			return fmt.Errorf("terraform validate %s: %w", relDir, err)
		}
	}
	return nil
}

// RunLint runs tflint across all discovered directories.
func RunLint(ctx context.Context, exec Executor, rootDir string, dirs *Dirs) error {
	configPath := filepath.Join(rootDir, ".tflint.hcl")
	var initArgs []string
	if _, err := os.Stat(configPath); err == nil {
		initArgs = append(initArgs, "--config="+configPath)
	}

	_ = exec.Run(ctx, rootDir, "tflint", append([]string{"--init"}, initArgs...)...)

	for _, relDir := range dirs.All {
		targetDir := filepath.Join(rootDir, relDir)
		lintArgs := []string{"--format", "compact"}
		if len(initArgs) > 0 {
			lintArgs = append(lintArgs, initArgs...)
		}
		if err := exec.Run(ctx, targetDir, "tflint", lintArgs...); err != nil {
			return fmt.Errorf("tflint %s: %w", relDir, err)
		}
	}
	return nil
}

// RunTest inits and executes terraform test for each root and submodule.
func RunTest(ctx context.Context, exec Executor, rootDir string, dirs *Dirs) error {
	for _, relDir := range dirs.Roots {
		targetDir := filepath.Join(rootDir, relDir)
		// Only run if tests exist
		testDir := filepath.Join(targetDir, "tests")
		if _, err := os.Stat(testDir); err != nil {
			continue
		}
		if err := exec.Run(ctx, targetDir, "terraform", "init", "-backend=false", "-input=false"); err != nil {
			return fmt.Errorf("terraform init %s: %w", relDir, err)
		}
		if err := exec.Run(ctx, targetDir, "terraform", "test"); err != nil {
			return fmt.Errorf("terraform test %s: %w", relDir, err)
		}
	}
	return nil
}

// RunDocs generates or checks terraform-docs across all module directories.
func RunDocs(ctx context.Context, exec Executor, rootDir string, dirs *Dirs, checkOnly bool) error {
	configFile := filepath.Join(rootDir, ".terraform-docs.yml")
	for _, relDir := range dirs.All {
		targetDir := filepath.Join(rootDir, relDir)
		args := []string{}
		if _, err := os.Stat(configFile); err == nil {
			args = append(args, "-c", configFile)
		}
		if checkOnly {
			args = append(args, "--output-check")
		}
		args = append(args, targetDir)
		if err := exec.Run(ctx, rootDir, "terraform-docs", args...); err != nil {
			return fmt.Errorf("terraform-docs %s: %w", relDir, err)
		}
	}
	return nil
}

// RunLock locks provider hashes for all 4 standard contributor and CI platforms.
func RunLock(ctx context.Context, exec Executor, rootDir string, platforms []string) error {
	if len(platforms) == 0 {
		platforms = []string{"linux_amd64", "linux_arm64", "darwin_amd64", "darwin_arm64"}
	}
	args := []string{"providers", "lock"}
	for _, p := range platforms {
		args = append(args, "-platform="+p)
	}
	return exec.Run(ctx, rootDir, "terraform", args...)
}

// RunSecurity runs checkov and trivy (if installed) against the module root.
func RunSecurity(ctx context.Context, exec Executor, rootDir string) error {
	if err := exec.Run(ctx, rootDir, "checkov", "-d", ".", "--framework", "terraform", "--quiet", "--compact"); err != nil {
		return fmt.Errorf("checkov security scan: %w", err)
	}
	if _, err := execLookPath("trivy"); err == nil {
		if err := exec.Run(ctx, rootDir, "trivy", "config", "--severity", "HIGH,CRITICAL", "--exit-code", "1", "."); err != nil {
			return fmt.Errorf("trivy security scan: %w", err)
		}
	}
	return nil
}

// RunCheck orchestrates the full module quality gate pipeline:
// fmt -> validate -> lint -> test -> docs-check -> security
func RunCheck(ctx context.Context, exec Executor, rootDir string, skipSecurity bool) (*CheckReport, error) {
	dirs, err := DiscoverDirs(rootDir)
	if err != nil {
		return nil, err
	}

	report := &CheckReport{
		ModuleRoot:  dirs.Root,
		Directories: len(dirs.All),
		Status:      "PASS",
	}

	steps := []struct {
		name string
		fn   func() error
	}{
		{"fmt", func() error { return RunFmt(ctx, exec, rootDir, false) }},
		{"validate", func() error { return RunValidate(ctx, exec, rootDir, dirs) }},
		{"lint", func() error { return RunLint(ctx, exec, rootDir, dirs) }},
		{"test", func() error { return RunTest(ctx, exec, rootDir, dirs) }},
		{"docs-check", func() error { return RunDocs(ctx, exec, rootDir, dirs, true) }},
	}

	if !skipSecurity {
		steps = append(steps, struct {
			name string
			fn   func() error
		}{"security", func() error { return RunSecurity(ctx, exec, rootDir) }})
	}

	for _, step := range steps {
		if err := step.fn(); err != nil {
			report.Status = "FAIL"
			report.Error = fmt.Sprintf("step %s failed: %v", step.name, err)
			return report, fmt.Errorf("%s: %w", step.name, err)
		}
		report.StepsPassed = append(report.StepsPassed, step.name)
	}

	return report, nil
}

func execLookPath(file string) (string, error) {
	return exec.LookPath(file)
}
