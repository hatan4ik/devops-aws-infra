// Package output provides 12-Factor CLI rendering for human-readable tables and machine-parseable JSON.
package output

import (
	"encoding/json"
	"fmt"
	"io"
	"os"
	"strings"
	"text/tabwriter"
)

// Format specifies the CLI output serialization format.
type Format string

const (
	FormatTable Format = "table"
	FormatJSON  Format = "json"
)

// ParseFormat validates and normalizes a user-supplied output format flag.
func ParseFormat(raw string) (Format, error) {
	switch strings.ToLower(strings.TrimSpace(raw)) {
	case "", "table", "text":
		return FormatTable, nil
	case "json":
		return FormatJSON, nil
	default:
		return "", fmt.Errorf("unsupported output format %q (expected 'table' or 'json')", raw)
	}
}

// ShouldUseColor adheres to the https://no-color.org standard.
func ShouldUseColor(explicitNoColor bool) bool {
	if explicitNoColor {
		return false
	}
	if _, ok := os.LookupEnv("NO_COLOR"); ok {
		return false
	}
	if strings.EqualFold(os.Getenv("TERM"), "dumb") {
		return false
	}
	return true
}

// Printer renders structured results to stdout/stderr.
type Printer struct {
	Out    io.Writer
	Err    io.Writer
	Format Format
	Color  bool
}

// NewPrinter constructs a configured Printer.
func NewPrinter(out, errOut io.Writer, format Format, useColor bool) *Printer {
	return &Printer{
		Out:    out,
		Err:    errOut,
		Format: format,
		Color:  useColor,
	}
}

// Badge formats a status string (e.g. PASS, FAIL, WARN) with optional ANSI color.
func (p *Printer) Badge(status string) string {
	if !p.Color {
		return status
	}
	switch status {
	case "PASS", "CLEAN", "OK", "SYNCED":
		return "\033[0;32m" + status + "\033[0m"
	case "WARN", "BEHIND", "STALE":
		return "\033[1;33m" + status + "\033[0m"
	case "FAIL", "DIRTY", "ERROR":
		return "\033[0;31m" + status + "\033[0m"
	default:
		return status
	}
}

// PrintJSON serializes v as indented JSON to p.Out.
func (p *Printer) PrintJSON(v any) error {
	enc := json.NewEncoder(p.Out)
	enc.SetIndent("", "  ")
	return enc.Encode(v)
}

// PrintTable writes aligned tabular rows to p.Out.
func (p *Printer) PrintTable(headers []string, rows [][]string) error {
	tw := tabwriter.NewWriter(p.Out, 0, 4, 2, ' ', 0)
	if len(headers) > 0 {
		if _, err := fmt.Fprintln(tw, strings.Join(headers, "\t")); err != nil {
			return err
		}
	}
	for _, row := range rows {
		if _, err := fmt.Fprintln(tw, strings.Join(row, "\t")); err != nil {
			return err
		}
	}
	return tw.Flush()
}
