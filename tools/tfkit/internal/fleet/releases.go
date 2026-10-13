package fleet

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"os/exec"
	"sort"
	"strings"
	"sync"
	"time"
)

// ReleaseAuditResult holds the release invariant verification result for one repository.
type ReleaseAuditResult struct {
	Repository    string   `json:"repository"`
	DefaultBranch string   `json:"default_branch"`
	MainSHA       string   `json:"main_sha"`
	LatestTag     string   `json:"latest_tag"`
	ReleaseTag    string   `json:"release_tag"`
	VerifiedSig   bool     `json:"verified_signature"`
	Status        string   `json:"status"` // PASS or FAIL
	Violations    []string `json:"violations,omitempty"`
}

// GitHubAPI abstracts GitHub REST API queries for testability.
type GitHubAPI interface {
	GetJSON(ctx context.Context, endpoint string, target any) error
}

// HTTPGitHubClient queries the GitHub REST API over HTTPS.
type HTTPGitHubClient struct {
	BaseURL    string
	Token      string
	HTTPClient *http.Client
}

// NewHTTPGitHubClient constructs a GitHub REST client, resolving credentials from env or gh CLI.
func NewHTTPGitHubClient(ctx context.Context) *HTTPGitHubClient {
	token := strings.TrimSpace(os.Getenv("GITHUB_TOKEN"))
	if token == "" {
		token = strings.TrimSpace(os.Getenv("GH_TOKEN"))
	}
	if token == "" {
		if out, err := exec.CommandContext(ctx, "gh", "auth", "token").Output(); err == nil {
			token = strings.TrimSpace(string(out))
		}
	}
	return &HTTPGitHubClient{
		BaseURL: "https://api.github.com",
		Token:   token,
		HTTPClient: &http.Client{
			Timeout: 15 * time.Second,
		},
	}
}

// GetJSON performs a GET request against a GitHub API path and decodes JSON into target.
func (c *HTTPGitHubClient) GetJSON(ctx context.Context, endpoint string, target any) error {
	url := strings.TrimRight(c.BaseURL, "/") + "/" + strings.TrimLeft(endpoint, "/")
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
	if err != nil {
		return err
	}
	req.Header.Set("Accept", "application/vnd.github+json")
	req.Header.Set("X-GitHub-Api-Version", "2022-11-28")
	if c.Token != "" {
		req.Header.Set("Authorization", "Bearer "+c.Token)
	}

	resp, err := c.HTTPClient.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		body, _ := io.ReadAll(io.LimitReader(resp.Body, 512))
		return fmt.Errorf("HTTP %d for %s: %s", resp.StatusCode, endpoint, strings.TrimSpace(string(body)))
	}
	return json.NewDecoder(resp.Body).Decode(target)
}

// VerifyReleaseFleet discovers all repos matching prefix owned by owner and concurrently verifies
// their signed-tag and release parity invariants.
func VerifyReleaseFleet(ctx context.Context, api GitHubAPI, owner, prefix string) ([]ReleaseAuditResult, error) {
	repos, err := listOwnerRepos(ctx, api, owner, prefix)
	if err != nil {
		return nil, err
	}
	if len(repos) == 0 {
		return nil, fmt.Errorf("no %s* repositories were discovered for %s", prefix, owner)
	}

	results := make([]ReleaseAuditResult, len(repos))
	const maxWorkers = 8
	sem := make(chan struct{}, maxWorkers)
	var wg sync.WaitGroup

	for i, repo := range repos {
		wg.Add(1)
		go func(idx int, repoName string) {
			defer wg.Done()
			sem <- struct{}{}
			defer func() { <-sem }()
			results[idx] = verifySingleRepoRelease(ctx, api, owner, repoName)
		}(i, repo)
	}
	wg.Wait()
	return results, nil
}

func listOwnerRepos(ctx context.Context, api GitHubAPI, owner, prefix string) ([]string, error) {
	var names []string
	for page := 1; page <= 5; page++ {
		var pageRepos []struct {
			Name string `json:"name"`
		}
		endpoint := fmt.Sprintf("/users/%s/repos?per_page=100&type=owner&page=%d", owner, page)
		if err := api.GetJSON(ctx, endpoint, &pageRepos); err != nil {
			return nil, fmt.Errorf("listing repositories for %s: %w", owner, err)
		}
		if len(pageRepos) == 0 {
			break
		}
		for _, r := range pageRepos {
			if strings.HasPrefix(r.Name, prefix) {
				names = append(names, r.Name)
			}
		}
		if len(pageRepos) < 100 {
			break
		}
	}
	sort.Strings(names)
	return names, nil
}

func verifySingleRepoRelease(ctx context.Context, api GitHubAPI, owner, repo string) ReleaseAuditResult {
	res := ReleaseAuditResult{
		Repository: repo,
		Status:     "PASS",
	}
	fail := func(reason string) {
		res.Status = "FAIL"
		res.Violations = append(res.Violations, reason)
	}

	var repoMeta struct {
		DefaultBranch string `json:"default_branch"`
	}
	if err := api.GetJSON(ctx, fmt.Sprintf("/repos/%s/%s", owner, repo), &repoMeta); err != nil {
		fail("repository metadata is unavailable")
		return res
	}
	if repoMeta.DefaultBranch == "" {
		fail("default branch is absent")
		return res
	}
	res.DefaultBranch = repoMeta.DefaultBranch

	var commitMeta struct {
		SHA string `json:"sha"`
	}
	if err := api.GetJSON(ctx, fmt.Sprintf("/repos/%s/%s/commits/%s", owner, repo, res.DefaultBranch), &commitMeta); err != nil || commitMeta.SHA == "" {
		fail(fmt.Sprintf("cannot resolve %s", res.DefaultBranch))
		return res
	}
	res.MainSHA = commitMeta.SHA

	var tags []struct {
		Name string `json:"name"`
	}
	if err := api.GetJSON(ctx, fmt.Sprintf("/repos/%s/%s/tags?per_page=1", owner, repo), &tags); err != nil || len(tags) == 0 || tags[0].Name == "" {
		fail("no tag exists")
		return res
	}
	res.LatestTag = tags[0].Name

	var tagRef struct {
		Object struct {
			Type string `json:"type"`
			SHA  string `json:"sha"`
		} `json:"object"`
	}
	if err := api.GetJSON(ctx, fmt.Sprintf("/repos/%s/%s/git/ref/tags/%s", owner, repo, res.LatestTag), &tagRef); err != nil {
		fail(fmt.Sprintf("cannot resolve tag %s", res.LatestTag))
		return res
	}
	if tagRef.Object.Type != "tag" {
		fail(fmt.Sprintf("%s is not an annotated tag", res.LatestTag))
		return res
	}

	var tagObj struct {
		Object struct {
			SHA string `json:"sha"`
		} `json:"object"`
		Verification struct {
			Verified bool `json:"verified"`
		} `json:"verification"`
	}
	if err := api.GetJSON(ctx, fmt.Sprintf("/repos/%s/%s/git/tags/%s", owner, repo, tagRef.Object.SHA), &tagObj); err != nil {
		fail(fmt.Sprintf("annotated tag object %s is unavailable", res.LatestTag))
		return res
	}
	res.VerifiedSig = tagObj.Verification.Verified
	if !tagObj.Verification.Verified {
		fail(fmt.Sprintf("%s does not have a GitHub-verified signature", res.LatestTag))
	}
	if tagObj.Object.SHA != res.MainSHA {
		fail(fmt.Sprintf("%s does not point at current %s", res.LatestTag, res.DefaultBranch))
	}

	var releaseObj struct {
		TagName string `json:"tag_name"`
	}
	if err := api.GetJSON(ctx, fmt.Sprintf("/repos/%s/%s/releases/latest", owner, repo), &releaseObj); err != nil {
		fail("no published non-prerelease GitHub Release exists")
	} else {
		res.ReleaseTag = releaseObj.TagName
		if releaseObj.TagName != res.LatestTag {
			fail(fmt.Sprintf("latest Release %s does not match tag %s", releaseObj.TagName, res.LatestTag))
		}
	}

	return res
}
