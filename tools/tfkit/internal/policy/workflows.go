// Package policy implements credential-free static policy checks for GitHub Actions workflows
// and repository documentation.
package policy

import (
	"bufio"
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
)

var (
	usesLineRegex = regexp.MustCompile(`^\s*(?:-\s*)?uses:\s*([^\s#]+)`)
	shaPinRegex   = regexp.MustCompile(`^[^\s@]+@[0-9a-f]{40}$`)
	topKeyRegex   = regexp.MustCompile(`^([a-zA-Z0-9_-]+|"on"|'on'):\s*(.*)$`)
)

// WorkflowCheckReport summarizes workflow structure and SHA-pin verification across a directory.
type WorkflowCheckReport struct {
	Directory       string   `json:"directory"`
	FilesChecked    int      `json:"files_checked"`
	ActionsVerified int      `json:"actions_verified"`
	Status          string   `json:"status"` // PASS or FAIL
	Violations      []string `json:"violations,omitempty"`
}

// CheckWorkflows validates top-level workflow structure (name, on, permissions, jobs)
// and enforces immutable 40-character commit SHA pins on all third-party action uses.
func CheckWorkflows(workflowDir string) (WorkflowCheckReport, error) {
	report := WorkflowCheckReport{
		Directory: workflowDir,
		Status:    "PASS",
	}

	info, err := os.Stat(workflowDir)
	if err != nil || !info.IsDir() {
		return report, fmt.Errorf("workflow directory does not exist: %s", workflowDir)
	}

	entries, err := os.ReadDir(workflowDir)
	if err != nil {
		return report, err
	}

	var files []string
	for _, entry := range entries {
		if entry.IsDir() {
			continue
		}
		ext := strings.ToLower(filepath.Ext(entry.Name()))
		if ext == ".yml" || ext == ".yaml" {
			files = append(files, filepath.Join(workflowDir, entry.Name()))
		}
	}
	sort.Strings(files)

	if len(files) == 0 {
		return report, fmt.Errorf("no workflow files found in %s", workflowDir)
	}

	for _, file := range files {
		report.FilesChecked++
		actionsCount, fileViolations, err := inspectWorkflowFile(file)
		if err != nil {
			return report, err
		}
		report.ActionsVerified += actionsCount
		report.Violations = append(report.Violations, fileViolations...)
	}

	if report.ActionsVerified == 0 {
		report.Violations = append(report.Violations, fmt.Sprintf("no third-party action references found in %s", workflowDir))
	}

	if len(report.Violations) > 0 {
		report.Status = "FAIL"
	}
	return report, nil
}

func inspectWorkflowFile(path string) (int, []string, error) {
	f, err := os.Open(path)
	if err != nil {
		return 0, nil, err
	}
	defer f.Close()

	topKeys := make(map[string]bool)
	var violations []string
	actionsCount := 0
	lineNum := 0

	scanner := bufio.NewScanner(f)
	for scanner.Scan() {
		lineNum++
		line := scanner.Text()
		trimmed := strings.TrimSpace(line)
		if trimmed == "" || strings.HasPrefix(trimmed, "#") {
			continue
		}

		// Top-level key (zero leading indentation)
		if len(line) > 0 && line[0] != ' ' && line[0] != '\t' {
			if m := topKeyRegex.FindStringSubmatch(line); m != nil {
				key := strings.Trim(m[1], `"'`)
				topKeys[key] = true
			}
		}

		if m := usesLineRegex.FindStringSubmatch(line); m != nil {
			ref := strings.Trim(m[1], `"'`)
			if strings.HasPrefix(ref, "./") {
				continue
			}
			actionsCount++
			if !shaPinRegex.MatchString(ref) {
				violations = append(violations, fmt.Sprintf("%s:%d: mutable or malformed action reference: %s", path, lineNum, ref))
			}
		}
	}
	if err := scanner.Err(); err != nil {
		return actionsCount, violations, err
	}

	for _, reqKey := range []string{"name", "on", "permissions", "jobs"} {
		if !topKeys[reqKey] {
			violations = append(violations, fmt.Sprintf("%s: missing required top-level key '%s'", path, reqKey))
		}
	}

	return actionsCount, violations, nil
}
