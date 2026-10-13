package policy

import (
	"os"
	"path/filepath"
	"testing"
)

func TestCheckWorkflows(t *testing.T) {
	dir := t.TempDir()

	validWorkflow := `name: CI
on:
  pull_request:
permissions:
  contents: read
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@fbc6f3992d24b796d5a048ff273f7fcc4a7b6c09
      - uses: ./.github/workflows/local.yml
`
	if err := os.WriteFile(filepath.Join(dir, "valid.yml"), []byte(validWorkflow), 0o644); err != nil {
		t.Fatal(err)
	}

	report, err := CheckWorkflows(dir)
	if err != nil {
		t.Fatalf("CheckWorkflows failed: %v", err)
	}
	if report.Status != "PASS" || report.FilesChecked != 1 || report.ActionsVerified != 1 {
		t.Errorf("unexpected report for valid workflow: %+v", report)
	}

	// Add a mutable action tag and missing permissions key
	invalidWorkflow := `name: Bad
on: push
jobs:
  build:
    steps:
      - uses: actions/checkout@v4
`
	if err := os.WriteFile(filepath.Join(dir, "invalid.yml"), []byte(invalidWorkflow), 0o644); err != nil {
		t.Fatal(err)
	}

	report2, err := CheckWorkflows(dir)
	if err != nil {
		t.Fatalf("CheckWorkflows failed: %v", err)
	}
	if report2.Status != "FAIL" || len(report2.Violations) != 2 {
		t.Errorf("expected FAIL with 2 violations, got %+v", report2)
	}
}

func TestCheckMarkdownLinks(t *testing.T) {
	dir := t.TempDir()
	if err := os.WriteFile(filepath.Join(dir, "target.md"), []byte("# Target\n"), 0o644); err != nil {
		t.Fatal(err)
	}

	mdContent := "# Index\nValid link: [Target](target.md#heading)\nExternal link: [GitHub](https://github.com)\n```markdown\nBroken inside code block ignored: [Missing](missing_ignored.md)\n```\n"

	if err := os.WriteFile(filepath.Join(dir, "README.md"), []byte(mdContent), 0o644); err != nil {
		t.Fatal(err)
	}

	rep, err := CheckMarkdownLinks(dir)
	if err != nil {
		t.Fatalf("CheckMarkdownLinks failed: %v", err)
	}
	if rep.Status != "PASS" || rep.LinksChecked != 1 {
		t.Errorf("expected PASS with 1 link checked, got %+v", rep)
	}

	// Add broken link outside code fence
	brokenMD := mdContent + "\nBroken: [Missing](does_not_exist.md)\n"
	if err := os.WriteFile(filepath.Join(dir, "README.md"), []byte(brokenMD), 0o644); err != nil {
		t.Fatal(err)
	}

	rep2, err := CheckMarkdownLinks(dir)
	if err != nil {
		t.Fatalf("CheckMarkdownLinks failed: %v", err)
	}
	if rep2.Status != "FAIL" || len(rep2.BrokenLinks) != 1 {
		t.Errorf("expected FAIL with 1 broken link, got %+v", rep2)
	}
}
