// Package cli wires the command-line surface, global flags, and exit-code contract for tfkit.
package cli

import (
	"errors"
	"fmt"
)

// Exit codes following POSIX and 12-Factor CLI standards.
const (
	ExitOK        = 0 // All checks or operations succeeded.
	ExitError     = 1 // Unexpected runtime, I/O, or upstream API error.
	ExitUsage     = 2 // Invalid CLI flags, arguments, or command syntax.
	ExitViolation = 3 // Audit, policy, or invariant violation detected.
)

// UsageError indicates invalid command arguments or flags (maps to ExitUsage = 2).
type UsageError struct {
	Msg string
}

func (e *UsageError) Error() string {
	return e.Msg
}

// ViolationError indicates one or more policy, drift, or release invariants failed (maps to ExitViolation = 3).
type ViolationError struct {
	Count   int
	Summary string
}

func (e *ViolationError) Error() string {
	if e.Summary != "" {
		return e.Summary
	}
	return fmt.Sprintf("%d violation(s) detected", e.Count)
}

// ResolveExitCode maps any returned error to its deterministic POSIX exit code.
func ResolveExitCode(err error) int {
	if err == nil {
		return ExitOK
	}
	var usageErr *UsageError
	if errors.As(err, &usageErr) {
		return ExitUsage
	}
	var violationErr *ViolationError
	if errors.As(err, &violationErr) {
		return ExitViolation
	}
	return ExitError
}
