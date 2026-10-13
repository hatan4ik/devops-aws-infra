package fleet

import (
	"context"
	"os"
	"path/filepath"
	"testing"
)

func TestDiscoverAndAuditRepos(t *testing.T) {
	t.Setenv("GIT_CONFIG_GLOBAL", "/dev/null")
	t.Setenv("GIT_CONFIG_NOSYSTEM", "1")

	baseDir := t.TempDir()
	ctx := context.Background()

	// 1. Create a clean repo on main
	cleanRepo := filepath.Join(baseDir, "aws.modules.clean")
	if err := os.MkdirAll(cleanRepo, 0o755); err != nil {
		t.Fatal(err)
	}
	mustGit(t, ctx, cleanRepo, "init", "-b", "main")
	mustGit(t, ctx, cleanRepo, "config", "user.email", "test@example.com")
	mustGit(t, ctx, cleanRepo, "config", "user.name", "Test")
	if err := os.WriteFile(filepath.Join(cleanRepo, "main.tf"), []byte("# clean\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	mustGit(t, ctx, cleanRepo, "add", "main.tf")
	mustGit(t, ctx, cleanRepo, "commit", "-m", "initial")

	// 2. Create a dirty repo on main
	dirtyRepo := filepath.Join(baseDir, "aws.modules.dirty")
	if err := os.MkdirAll(dirtyRepo, 0o755); err != nil {
		t.Fatal(err)
	}
	mustGit(t, ctx, dirtyRepo, "init", "-b", "main")
	mustGit(t, ctx, dirtyRepo, "config", "user.email", "test@example.com")
	mustGit(t, ctx, dirtyRepo, "config", "user.name", "Test")
	if err := os.WriteFile(filepath.Join(dirtyRepo, "untracked.tf"), []byte("# dirty\n"), 0o644); err != nil {
		t.Fatal(err)
	}

	// 3. Create a repo on a stale feature branch
	staleRepo := filepath.Join(baseDir, "aws.modules.stale")
	if err := os.MkdirAll(staleRepo, 0o755); err != nil {
		t.Fatal(err)
	}
	mustGit(t, ctx, staleRepo, "init", "-b", "main")
	mustGit(t, ctx, staleRepo, "config", "user.email", "test@example.com")
	mustGit(t, ctx, staleRepo, "config", "user.name", "Test")
	if err := os.WriteFile(filepath.Join(staleRepo, "main.tf"), []byte("# stale\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	mustGit(t, ctx, staleRepo, "add", "main.tf")
	mustGit(t, ctx, staleRepo, "commit", "-m", "initial")
	mustGit(t, ctx, staleRepo, "checkout", "-b", "feat/old-feature")

	repos, err := DiscoverRepos(baseDir, "aws.modules.")
	if err != nil {
		t.Fatalf("DiscoverRepos failed: %v", err)
	}
	if len(repos) != 3 {
		t.Fatalf("expected 3 repos, got %d", len(repos))
	}

	results := AuditRepos(ctx, repos, false)
	if len(results) != 3 {
		t.Fatalf("expected 3 results, got %d", len(results))
	}

	if results[0].Name != "aws.modules.clean" || results[0].State != "CLEAN" {
		t.Errorf("expected aws.modules.clean to be CLEAN, got %+v", results[0])
	}
	if results[1].Name != "aws.modules.dirty" || results[1].State != "DIRTY" {
		t.Errorf("expected aws.modules.dirty to be DIRTY, got %+v", results[1])
	}
	if results[2].Name != "aws.modules.stale" || results[2].State != "STALE" {
		t.Errorf("expected aws.modules.stale to be STALE, got %+v", results[2])
	}
}

func mustGit(t *testing.T, ctx context.Context, dir string, args ...string) {
	t.Helper()
	if _, err := runGit(ctx, dir, args...); err != nil {
		t.Fatalf("git %v failed: %v", args, err)
	}
}
