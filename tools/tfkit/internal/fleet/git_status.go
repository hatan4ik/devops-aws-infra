// Package fleet provides concurrent multi-repository Git auditing, synchronization,
// and GitHub release verification across the aws.modules.* catalog.
package fleet

import (
	"context"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
	"sync"
)

// RepoStatus captures the Git health and synchronization state of a single module repository.
type RepoStatus struct {
	Name          string   `json:"name"`
	Path          string   `json:"path"`
	Branch        string   `json:"branch"`
	Clean         bool     `json:"clean"`
	DirtyFiles    int      `json:"dirty_files"`
	Ahead         int      `json:"ahead"`
	Behind        int      `json:"behind"`
	StaleBranches []string `json:"stale_branches,omitempty"`
	State         string   `json:"state"` // CLEAN, BEHIND, STALE, DIRTY, ERROR
	Error         string   `json:"error,omitempty"`
}

// DiscoverRepos finds all Git repositories matching prefix (e.g. "aws.modules.") inside baseDir.
func DiscoverRepos(baseDir, prefix string) ([]string, error) {
	entries, err := os.ReadDir(baseDir)
	if err != nil {
		return nil, fmt.Errorf("reading base directory %s: %w", baseDir, err)
	}

	var paths []string
	for _, entry := range entries {
		if !entry.IsDir() || !strings.HasPrefix(entry.Name(), prefix) {
			continue
		}
		repoPath := filepath.Join(baseDir, entry.Name())
		if info, err := os.Stat(filepath.Join(repoPath, ".git")); err == nil && (info.IsDir() || info.Mode().IsRegular()) {
			paths = append(paths, repoPath)
		}
	}
	sort.Strings(paths)
	return paths, nil
}

// AuditRepos inspects a list of repository paths concurrently.
func AuditRepos(ctx context.Context, repoPaths []string, fetch bool) []RepoStatus {
	results := make([]RepoStatus, len(repoPaths))
	const maxWorkers = 8
	sem := make(chan struct{}, maxWorkers)
	var wg sync.WaitGroup

	for i, path := range repoPaths {
		wg.Add(1)
		go func(idx int, p string) {
			defer wg.Done()
			sem <- struct{}{}
			defer func() { <-sem }()
			results[idx] = inspectRepo(ctx, p, fetch)
		}(i, path)
	}
	wg.Wait()
	return results
}

// SyncRepos fetches remotes, switches clean feature checkouts to main, fast-forwards main,
// and prunes local branches whose upstream tracking branch is gone.
func SyncRepos(ctx context.Context, repoPaths []string) []RepoStatus {
	results := make([]RepoStatus, len(repoPaths))
	const maxWorkers = 8
	sem := make(chan struct{}, maxWorkers)
	var wg sync.WaitGroup

	for i, path := range repoPaths {
		wg.Add(1)
		go func(idx int, p string) {
			defer wg.Done()
			sem <- struct{}{}
			defer func() { <-sem }()
			results[idx] = syncSingleRepo(ctx, p)
		}(i, path)
	}
	wg.Wait()
	return results
}

func inspectRepo(ctx context.Context, repoPath string, fetch bool) RepoStatus {
	st := RepoStatus{
		Name: filepath.Base(repoPath),
		Path: repoPath,
	}

	if fetch {
		_, _ = runGit(ctx, repoPath, "fetch", "--all", "--prune")
	}

	branch, err := runGit(ctx, repoPath, "branch", "--show-current")
	if err != nil {
		st.State = "ERROR"
		st.Error = err.Error()
		return st
	}
	if branch == "" {
		branch = "DETACHED"
	}
	st.Branch = branch

	porcelain, err := runGit(ctx, repoPath, "status", "--porcelain")
	if err != nil {
		st.State = "ERROR"
		st.Error = err.Error()
		return st
	}
	if porcelain == "" {
		st.Clean = true
	} else {
		st.DirtyFiles = len(strings.Split(porcelain, "\n"))
	}

	// Compare local main with origin/main if origin/main exists.
	if revOut, err := runGit(ctx, repoPath, "rev-list", "--left-right", "--count", "main...origin/main"); err == nil {
		fields := strings.Fields(revOut)
		if len(fields) == 2 {
			st.Ahead, _ = strconv.Atoi(fields[0])
			st.Behind, _ = strconv.Atoi(fields[1])
		}
	}

	// Detect extra/stale local branches.
	if branchOut, err := runGit(ctx, repoPath, "branch", "-vv"); err == nil {
		for _, line := range strings.Split(branchOut, "\n") {
			trimmed := strings.TrimSpace(strings.TrimPrefix(strings.TrimPrefix(line, "*"), "+"))
			if trimmed == "" {
				continue
			}
			bName := strings.Fields(trimmed)[0]
			if bName == "main" || strings.HasPrefix(bName, "release/") {
				continue
			}
			st.StaleBranches = append(st.StaleBranches, bName)
		}
	}

	switch {
	case !st.Clean || st.Ahead > 0:
		st.State = "DIRTY"
	case st.Branch != "main":
		st.State = "STALE"
	case st.Behind > 0:
		st.State = "BEHIND"
	case len(st.StaleBranches) > 0:
		st.State = "STALE"
	default:
		st.State = "CLEAN"
	}

	return st
}

func syncSingleRepo(ctx context.Context, repoPath string) RepoStatus {
	_, _ = runGit(ctx, repoPath, "fetch", "--all", "--prune")
	_, _ = runGit(ctx, repoPath, "worktree", "prune")

	st := inspectRepo(ctx, repoPath, false)
	if !st.Clean {
		// Never mutate a dirty working tree.
		return st
	}

	if st.Branch != "main" {
		if _, err := runGit(ctx, repoPath, "checkout", "main"); err != nil {
			st.State = "ERROR"
			st.Error = fmt.Sprintf("checkout main: %v", err)
			return st
		}
	}

	if st.Behind > 0 {
		if _, err := runGit(ctx, repoPath, "merge", "--ff-only", "origin/main"); err != nil {
			st.State = "ERROR"
			st.Error = fmt.Sprintf("ff-only merge: %v", err)
			return st
		}
	}

	// Remove branches whose upstream is gone.
	if branchOut, err := runGit(ctx, repoPath, "branch", "-vv"); err == nil {
		for _, line := range strings.Split(branchOut, "\n") {
			if !strings.Contains(line, ": gone]") {
				continue
			}
			trimmed := strings.TrimSpace(strings.TrimPrefix(strings.TrimPrefix(line, "*"), "+"))
			if trimmed == "" {
				continue
			}
			bName := strings.Fields(trimmed)[0]
			if bName != "main" && !strings.HasPrefix(bName, "release/") {
				_, _ = runGit(ctx, repoPath, "branch", "-D", bName)
			}
		}
	}

	return inspectRepo(ctx, repoPath, false)
}

func runGit(ctx context.Context, repoPath string, args ...string) (string, error) {
	cmdArgs := append([]string{"-C", repoPath}, args...)
	cmd := exec.CommandContext(ctx, "git", cmdArgs...)
	cmd.Env = append(os.Environ(), "GIT_TERMINAL_PROMPT=0")
	out, err := cmd.CombinedOutput()
	if err != nil && strings.Contains(string(out), "Operation not permitted") {
		retryCmd := exec.CommandContext(ctx, "git", cmdArgs...)
		retryCmd.Env = append(os.Environ(), "GIT_TERMINAL_PROMPT=0", "GIT_CONFIG_GLOBAL=/dev/null", "GIT_CONFIG_NOSYSTEM=1")
		out, err = retryCmd.CombinedOutput()
	}
	if err != nil {
		return "", fmt.Errorf("git %s: %w (%s)", strings.Join(args, " "), err, strings.TrimSpace(string(out)))
	}
	return strings.TrimSpace(string(out)), nil
}
