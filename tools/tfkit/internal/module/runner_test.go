package module

import (
	"context"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

type mockExecutor struct {
	commands []string
}

func (m *mockExecutor) Run(_ context.Context, dir, name string, args ...string) error {
	cmd := name + " " + strings.Join(args, " ")
	m.commands = append(m.commands, cmd)
	return nil
}

func TestRunFmtAndLock(t *testing.T) {
	mock := &mockExecutor{}
	ctx := context.Background()

	if err := RunFmt(ctx, mock, ".", false); err != nil {
		t.Fatal(err)
	}
	if len(mock.commands) != 1 || mock.commands[0] != "terraform fmt -check -recursive -diff" {
		t.Errorf("unexpected fmt check command: %s", mock.commands[0])
	}

	mock.commands = nil
	if err := RunFmt(ctx, mock, ".", true); err != nil {
		t.Fatal(err)
	}
	if len(mock.commands) != 1 || mock.commands[0] != "terraform fmt -recursive" {
		t.Errorf("unexpected fmt fix command: %s", mock.commands[0])
	}

	mock.commands = nil
	if err := RunLock(ctx, mock, ".", nil); err != nil {
		t.Fatal(err)
	}
	expectedLock := "terraform providers lock -platform=linux_amd64 -platform=linux_arm64 -platform=darwin_amd64 -platform=darwin_arm64"
	if len(mock.commands) != 1 || mock.commands[0] != expectedLock {
		t.Errorf("unexpected lock command: %s", mock.commands[0])
	}
}

func TestRunCheckOrchestration(t *testing.T) {
	mock := &mockExecutor{}
	ctx := context.Background()
	tmp := t.TempDir()

	if err := os.WriteFile(filepath.Join(tmp, "main.tf"), []byte("# test"), 0o644); err != nil {
		t.Fatal(err)
	}

	rep, err := RunCheck(ctx, mock, tmp, true)
	if err != nil {
		t.Fatalf("RunCheck failed: %v", err)
	}
	if rep.Status != "PASS" {
		t.Errorf("expected status PASS, got %s", rep.Status)
	}
	if len(rep.StepsPassed) != 5 {
		t.Errorf("expected 5 steps passed (fmt, validate, lint, test, docs-check), got %d (%+v)", len(rep.StepsPassed), rep.StepsPassed)
	}
}
