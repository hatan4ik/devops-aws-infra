package cli

import (
	"bytes"
	"context"
	"strings"
	"testing"
)

func TestAppVersionAndExitCodes(t *testing.T) {
	var out, errOut bytes.Buffer
	app := NewApp(&out, &errOut)

	// 1. No args -> ExitUsage (2)
	err := app.Run(context.Background(), nil)
	if code := ResolveExitCode(err); code != ExitUsage {
		t.Errorf("expected ExitUsage (%d) for empty args, got %d", ExitUsage, code)
	}

	// 2. Unknown command -> ExitUsage (2)
	out.Reset()
	errOut.Reset()
	err = app.Run(context.Background(), []string{"nonexistent"})
	if code := ResolveExitCode(err); code != ExitUsage {
		t.Errorf("expected ExitUsage (%d) for unknown command, got %d", ExitUsage, code)
	}

	// 3. version --output json -> ExitOK (0)
	out.Reset()
	errOut.Reset()
	err = app.Run(context.Background(), []string{"version", "--output", "json"})
	if code := ResolveExitCode(err); code != ExitOK {
		t.Fatalf("expected ExitOK for version, got %d (%v)", code, err)
	}
	if !strings.Contains(out.String(), `"version"`) {
		t.Errorf("expected JSON version output, got:\n%s", out.String())
	}
}
