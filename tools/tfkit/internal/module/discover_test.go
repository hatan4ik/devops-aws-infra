package module

import (
	"os"
	"path/filepath"
	"testing"
)

func TestDiscoverDirs(t *testing.T) {
	root := t.TempDir()

	// 1. Root .tf file
	if err := os.WriteFile(filepath.Join(root, "main.tf"), []byte("# root"), 0o644); err != nil {
		t.Fatal(err)
	}

	// 2. Submodule modules/bucket
	subDir := filepath.Join(root, "modules", "bucket")
	if err := os.MkdirAll(subDir, 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(subDir, "main.tf"), []byte("# sub"), 0o644); err != nil {
		t.Fatal(err)
	}

	// 3. Example examples/complete
	exDir := filepath.Join(root, "examples", "complete")
	if err := os.MkdirAll(exDir, 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(exDir, "main.tf"), []byte("# example"), 0o644); err != nil {
		t.Fatal(err)
	}

	// 4. Test fixture tests/integration/setup
	fixDir := filepath.Join(root, "tests", "integration", "setup")
	if err := os.MkdirAll(fixDir, 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(fixDir, "main.tf"), []byte("# fixture"), 0o644); err != nil {
		t.Fatal(err)
	}

	// 5. Ignored non-terraform dir
	docsDir := filepath.Join(root, "docs")
	if err := os.MkdirAll(docsDir, 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(docsDir, "README.md"), []byte("# docs"), 0o644); err != nil {
		t.Fatal(err)
	}

	dirs, err := DiscoverDirs(root)
	if err != nil {
		t.Fatalf("DiscoverDirs failed: %v", err)
	}

	if len(dirs.Roots) != 2 || dirs.Roots[0] != "." || dirs.Roots[1] != "modules/bucket" {
		t.Errorf("unexpected Roots: %+v", dirs.Roots)
	}
	if len(dirs.Examples) != 1 || dirs.Examples[0] != "examples/complete" {
		t.Errorf("unexpected Examples: %+v", dirs.Examples)
	}
	if len(dirs.Fixtures) != 1 || dirs.Fixtures[0] != "tests/integration/setup" {
		t.Errorf("unexpected Fixtures: %+v", dirs.Fixtures)
	}
	if len(dirs.All) != 4 {
		t.Errorf("expected 4 total directories, got %d (%+v)", len(dirs.All), dirs.All)
	}
}
