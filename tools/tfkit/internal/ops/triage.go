package ops

import (
	"bufio"
	"context"
	"fmt"
	"io"
	"net/http"
	"strings"

	"github.com/hatan4ik/tfkit/internal/fleet"
)

// WorkflowRunSummary holds top-level metadata for an integration run.
type WorkflowRunSummary struct {
	ID         int64  `json:"id"`
	Name       string `json:"name"`
	Status     string `json:"status"`
	Conclusion string `json:"conclusion"`
	CreatedAt  string `json:"created_at"`
	HTMLURL    string `json:"html_url"`
}

// StepFailure captures a single failed step and its isolated error message.
type StepFailure struct {
	JobName    string   `json:"job_name"`
	StepName   string   `json:"step_name"`
	StepNumber int      `json:"step_number"`
	Conclusion string   `json:"conclusion"`
	KeyErrors  []string `json:"key_errors,omitempty"`
}

// TriageReport summarizes the root cause analysis of a workflow run.
type TriageReport struct {
	RunID      int64         `json:"run_id"`
	Repo       string        `json:"repo"`
	Status     string        `json:"status"`
	Conclusion string        `json:"conclusion"`
	Failures   []StepFailure `json:"failures,omitempty"`
	Summary    string        `json:"summary"`
}

// ListRecentRuns queries the GitHub Actions API for the latest workflow runs.
func ListRecentRuns(ctx context.Context, api fleet.GitHubAPI, owner, repo string, limit int) ([]WorkflowRunSummary, error) {
	var resp struct {
		WorkflowRuns []struct {
			ID         int64  `json:"id"`
			Name       string `json:"name"`
			Status     string `json:"status"`
			Conclusion string `json:"conclusion"`
			CreatedAt  string `json:"created_at"`
			HTMLURL    string `json:"html_url"`
		} `json:"workflow_runs"`
	}
	endpoint := fmt.Sprintf("/repos/%s/%s/actions/runs?per_page=%d", owner, repo, limit)
	if err := api.GetJSON(ctx, endpoint, &resp); err != nil {
		return nil, err
	}

	runs := make([]WorkflowRunSummary, len(resp.WorkflowRuns))
	for i, r := range resp.WorkflowRuns {
		runs[i] = WorkflowRunSummary{
			ID:         r.ID,
			Name:       r.Name,
			Status:     r.Status,
			Conclusion: r.Conclusion,
			CreatedAt:  r.CreatedAt,
			HTMLURL:    r.HTMLURL,
		}
	}
	return runs, nil
}

// TriageRun fetches job details, isolates failed steps, and extracts root-cause logs.
func TriageRun(ctx context.Context, api fleet.GitHubAPI, httpRaw *fleet.HTTPGitHubClient, owner, repo string, runID int64) (*TriageReport, error) {
	var runObj struct {
		ID         int64  `json:"id"`
		Status     string `json:"status"`
		Conclusion string `json:"conclusion"`
	}
	if err := api.GetJSON(ctx, fmt.Sprintf("/repos/%s/%s/actions/runs/%d", owner, repo, runID), &runObj); err != nil {
		return nil, fmt.Errorf("getting run %d: %w", runID, err)
	}

	report := &TriageReport{
		RunID:      runObj.ID,
		Repo:       fmt.Sprintf("%s/%s", owner, repo),
		Status:     runObj.Status,
		Conclusion: runObj.Conclusion,
	}

	var jobsObj struct {
		Jobs []struct {
			ID         int64  `json:"id"`
			Name       string `json:"name"`
			Status     string `json:"status"`
			Conclusion string `json:"conclusion"`
			Steps      []struct {
				Name       string `json:"name"`
				Number     int    `json:"number"`
				Status     string `json:"status"`
				Conclusion string `json:"conclusion"`
			} `json:"steps"`
		} `json:"jobs"`
	}
	if err := api.GetJSON(ctx, fmt.Sprintf("/repos/%s/%s/actions/runs/%d/jobs", owner, repo, runID), &jobsObj); err != nil {
		return nil, fmt.Errorf("getting jobs for run %d: %w", runID, err)
	}

	for _, job := range jobsObj.Jobs {
		if job.Conclusion != "failure" {
			continue
		}
		for _, step := range job.Steps {
			if step.Conclusion == "failure" {
				sf := StepFailure{
					JobName:    job.Name,
					StepName:   step.Name,
					StepNumber: step.Number,
					Conclusion: step.Conclusion,
				}
				if httpRaw != nil {
					sf.KeyErrors = extractJobErrorLogs(ctx, httpRaw, owner, repo, job.ID)
				}
				report.Failures = append(report.Failures, sf)
			}
		}
	}

	if len(report.Failures) == 0 {
		report.Summary = fmt.Sprintf("Run %d conclusion is %s with no failing steps identified", runID, runObj.Conclusion)
	} else {
		report.Summary = fmt.Sprintf("Run %d failed at step %q in job %q", runID, report.Failures[0].StepName, report.Failures[0].JobName)
	}

	return report, nil
}

func extractJobErrorLogs(ctx context.Context, client *fleet.HTTPGitHubClient, owner, repo string, jobID int64) []string {
	endpoint := fmt.Sprintf("/repos/%s/%s/actions/jobs/%d/logs", owner, repo, jobID)
	url := strings.TrimRight(client.BaseURL, "/") + endpoint
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
	if err != nil {
		return nil
	}
	req.Header.Set("Authorization", "Bearer "+client.Token)

	resp, err := client.HTTPClient.Do(req)
	if err != nil || resp.StatusCode != http.StatusOK {
		return nil
	}
	defer resp.Body.Close()

	var errorsFound []string
	scanner := bufio.NewScanner(io.LimitReader(resp.Body, 5*1024*1024))
	for scanner.Scan() {
		line := scanner.Text()
		trimmed := strings.TrimSpace(line)
		if strings.Contains(trimmed, "Error: ") ||
			strings.Contains(trimmed, "InvalidParameterValue") ||
			strings.Contains(trimmed, "CannotPullContainer") ||
			strings.Contains(trimmed, "ResourceInitializationError") ||
			strings.Contains(trimmed, "AccessDenied") {
			errorsFound = append(errorsFound, trimmed)
			if len(errorsFound) >= 8 {
				break
			}
		}
	}
	return errorsFound
}
