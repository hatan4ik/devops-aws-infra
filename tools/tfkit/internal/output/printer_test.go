package output

import (
	"bytes"
	"strings"
	"testing"
)

func TestParseFormat(t *testing.T) {
	tests := []struct {
		input   string
		want    Format
		wantErr bool
	}{
		{"", FormatTable, false},
		{"table", FormatTable, false},
		{"TABLE", FormatTable, false},
		{"json", FormatJSON, false},
		{"JSON", FormatJSON, false},
		{"xml", "", true},
	}

	for _, tc := range tests {
		got, err := ParseFormat(tc.input)
		if (err != nil) != tc.wantErr {
			t.Fatalf("ParseFormat(%q) err = %v, wantErr = %v", tc.input, err, tc.wantErr)
		}
		if got != tc.want {
			t.Errorf("ParseFormat(%q) = %q, want %q", tc.input, got, tc.want)
		}
	}
}

func TestPrinterTableAndJSON(t *testing.T) {
	var out, errOut bytes.Buffer
	p := NewPrinter(&out, &errOut, FormatTable, false)

	if badge := p.Badge("PASS"); badge != "PASS" {
		t.Errorf("expected uncolored badge PASS, got %q", badge)
	}

	err := p.PrintTable(
		[]string{"MODULE", "STATUS"},
		[][]string{
			{"aws.modules.vpc", "CLEAN"},
			{"aws.modules.s3", "CLEAN"},
		},
	)
	if err != nil {
		t.Fatalf("PrintTable failed: %v", err)
	}
	if !strings.Contains(out.String(), "aws.modules.vpc") {
		t.Errorf("expected table output to contain module name, got:\n%s", out.String())
	}

	out.Reset()
	payload := map[string]string{"status": "PASS"}
	if err := p.PrintJSON(payload); err != nil {
		t.Fatalf("PrintJSON failed: %v", err)
	}
	if !strings.Contains(out.String(), `"status": "PASS"`) {
		t.Errorf("unexpected JSON output:\n%s", out.String())
	}
}
