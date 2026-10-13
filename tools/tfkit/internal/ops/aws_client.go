// Package ops provides SRE ConOps live stack diagnostics, GitHub Actions incident triage,
// and dependency-ordered orphan resource cleanup.
package ops

import (
	"context"
	"encoding/json"
	"fmt"
	"os/exec"
	"strings"
)

// AWSCaller abstracts AWS CLI/SDK invocations for testability and isolation.
type AWSCaller interface {
	CallJSON(ctx context.Context, service string, target any, args ...string) error
	CallRaw(ctx context.Context, service string, args ...string) ([]byte, error)
}

// CLIClient invokes the official AWS CLI with profile and region flags.
type CLIClient struct {
	Profile string
	Region  string
}

// NewCLIClient constructs an AWS CLI client.
func NewCLIClient(profile, region string) *CLIClient {
	return &CLIClient{
		Profile: profile,
		Region:  region,
	}
}

// CallRaw executes an AWS CLI command and returns the raw output bytes.
func (c *CLIClient) CallRaw(ctx context.Context, service string, args ...string) ([]byte, error) {
	cmdArgs := []string{service}
	if c.Profile != "" {
		cmdArgs = append(cmdArgs, "--profile", c.Profile)
	}
	if c.Region != "" {
		cmdArgs = append(cmdArgs, "--region", c.Region)
	}
	cmdArgs = append(cmdArgs, args...)
	cmdArgs = append(cmdArgs, "--output", "json")

	cmd := exec.CommandContext(ctx, "aws", cmdArgs...)
	out, err := cmd.CombinedOutput()
	if err != nil {
		return nil, fmt.Errorf("aws %s: %w (%s)", strings.Join(cmdArgs, " "), err, strings.TrimSpace(string(out)))
	}
	return out, nil
}

// CallJSON executes an AWS CLI command and unmarshals JSON into target.
func (c *CLIClient) CallJSON(ctx context.Context, service string, target any, args ...string) error {
	out, err := c.CallRaw(ctx, service, args...)
	if err != nil {
		return err
	}
	if target == nil {
		return nil
	}
	return json.Unmarshal(out, target)
}
