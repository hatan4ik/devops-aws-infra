package fleet

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestVerifyReleaseFleet(t *testing.T) {
	mux := http.NewServeMux()

	mux.HandleFunc("/users/hatan4ik/repos", func(w http.ResponseWriter, r *http.Request) {
		_ = json.NewEncoder(w).Encode([]map[string]string{
			{"name": "aws.modules.s3"},
			{"name": "aws.modules.drifted"},
			{"name": "unrelated-repo"},
		})
	})

	// 1. aws.modules.s3 (healthy signed release)
	mux.HandleFunc("/repos/hatan4ik/aws.modules.s3", func(w http.ResponseWriter, r *http.Request) {
		_ = json.NewEncoder(w).Encode(map[string]string{"default_branch": "main"})
	})
	mux.HandleFunc("/repos/hatan4ik/aws.modules.s3/commits/main", func(w http.ResponseWriter, r *http.Request) {
		_ = json.NewEncoder(w).Encode(map[string]string{"sha": "1111111"})
	})
	mux.HandleFunc("/repos/hatan4ik/aws.modules.s3/tags", func(w http.ResponseWriter, r *http.Request) {
		_ = json.NewEncoder(w).Encode([]map[string]string{{"name": "v1.0.2"}})
	})
	mux.HandleFunc("/repos/hatan4ik/aws.modules.s3/git/ref/tags/v1.0.2", func(w http.ResponseWriter, r *http.Request) {
		_ = json.NewEncoder(w).Encode(map[string]any{
			"object": map[string]string{"type": "tag", "sha": "tagobj1"},
		})
	})
	mux.HandleFunc("/repos/hatan4ik/aws.modules.s3/git/tags/tagobj1", func(w http.ResponseWriter, r *http.Request) {
		_ = json.NewEncoder(w).Encode(map[string]any{
			"object":       map[string]string{"sha": "1111111"},
			"verification": map[string]bool{"verified": true},
		})
	})
	mux.HandleFunc("/repos/hatan4ik/aws.modules.s3/releases/latest", func(w http.ResponseWriter, r *http.Request) {
		_ = json.NewEncoder(w).Encode(map[string]string{"tag_name": "v1.0.2"})
	})

	// 2. aws.modules.drifted (unsigned and behind main)
	mux.HandleFunc("/repos/hatan4ik/aws.modules.drifted", func(w http.ResponseWriter, r *http.Request) {
		_ = json.NewEncoder(w).Encode(map[string]string{"default_branch": "main"})
	})
	mux.HandleFunc("/repos/hatan4ik/aws.modules.drifted/commits/main", func(w http.ResponseWriter, r *http.Request) {
		_ = json.NewEncoder(w).Encode(map[string]string{"sha": "9999999"})
	})
	mux.HandleFunc("/repos/hatan4ik/aws.modules.drifted/tags", func(w http.ResponseWriter, r *http.Request) {
		_ = json.NewEncoder(w).Encode([]map[string]string{{"name": "v1.0.0"}})
	})
	mux.HandleFunc("/repos/hatan4ik/aws.modules.drifted/git/ref/tags/v1.0.0", func(w http.ResponseWriter, r *http.Request) {
		_ = json.NewEncoder(w).Encode(map[string]any{
			"object": map[string]string{"type": "tag", "sha": "tagobj2"},
		})
	})
	mux.HandleFunc("/repos/hatan4ik/aws.modules.drifted/git/tags/tagobj2", func(w http.ResponseWriter, r *http.Request) {
		_ = json.NewEncoder(w).Encode(map[string]any{
			"object":       map[string]string{"sha": "0000000"},
			"verification": map[string]bool{"verified": false},
		})
	})
	mux.HandleFunc("/repos/hatan4ik/aws.modules.drifted/releases/latest", func(w http.ResponseWriter, r *http.Request) {
		_ = json.NewEncoder(w).Encode(map[string]string{"tag_name": "v1.0.0"})
	})

	client := &HTTPGitHubClient{
		BaseURL: "https://api.github.test",
		Token:   "test-token",
		HTTPClient: &http.Client{
			Transport: roundTripFunc(func(req *http.Request) (*http.Response, error) {
				rec := httptest.NewRecorder()
				mux.ServeHTTP(rec, req)
				return rec.Result(), nil
			}),
		},
	}

	results, err := VerifyReleaseFleet(context.Background(), client, "hatan4ik", "aws.modules.")
	if err != nil {
		t.Fatalf("VerifyReleaseFleet failed: %v", err)
	}
	if len(results) != 2 {
		t.Fatalf("expected 2 results, got %d", len(results))
	}

	// Sorted alphabetically: aws.modules.drifted, aws.modules.s3
	if results[0].Repository != "aws.modules.drifted" || results[0].Status != "FAIL" || len(results[0].Violations) != 2 {
		t.Errorf("expected aws.modules.drifted to FAIL with 2 violations, got %+v", results[0])
	}
	if results[1].Repository != "aws.modules.s3" || results[1].Status != "PASS" {
		t.Errorf("expected aws.modules.s3 to PASS, got %+v", results[1])
	}
}

type roundTripFunc func(*http.Request) (*http.Response, error)

func (f roundTripFunc) RoundTrip(req *http.Request) (*http.Response, error) {
	return f(req)
}
