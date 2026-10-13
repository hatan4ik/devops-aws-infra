// Package module implements standardized quality gates, formatting, docs generation,
// testing, and provider locking across Terraform module repositories.
package module

import (
	"os"
	"path/filepath"
	"sort"
	"strings"
)

// Dirs groups all discovered Terraform directories in a module repository.
type Dirs struct {
	Root     string   `json:"root"`
	Roots    []string `json:"roots"`    // Root module (.) and submodules (modules/*)
	Examples []string `json:"examples"` // Example directories (examples/*)
	Fixtures []string `json:"fixtures"` // Test fixtures (tests/setup/*, tests/integration/*)
	All      []string `json:"all"`      // All unique directories containing .tf files
}

// DiscoverDirs scans a repository root and discovers all directories containing .tf files,
// categorized by their architectural role.
func DiscoverDirs(repoRoot string) (*Dirs, error) {
	absRoot, err := filepath.Abs(repoRoot)
	if err != nil {
		return nil, err
	}

	d := &Dirs{
		Root: absRoot,
	}

	// 1. Check if repo root contains .tf files
	if hasTFFiles(absRoot) {
		d.Roots = append(d.Roots, ".")
	}

	// 2. Scan submodules (modules/*)
	submodulesDir := filepath.Join(absRoot, "modules")
	if entries, err := os.ReadDir(submodulesDir); err == nil {
		for _, e := range entries {
			if e.IsDir() && !strings.HasPrefix(e.Name(), ".") {
				subPath := filepath.Join(submodulesDir, e.Name())
				if hasTFFiles(subPath) {
					rel, _ := filepath.Rel(absRoot, subPath)
					d.Roots = append(d.Roots, rel)
				}
			}
		}
	}

	// 3. Scan examples (examples/* and examples/*/*)
	examplesDir := filepath.Join(absRoot, "examples")
	if entries, err := os.ReadDir(examplesDir); err == nil {
		for _, e := range entries {
			if e.IsDir() && !strings.HasPrefix(e.Name(), ".") {
				exPath := filepath.Join(examplesDir, e.Name())
				if hasTFFiles(exPath) {
					rel, _ := filepath.Rel(absRoot, exPath)
					d.Examples = append(d.Examples, rel)
				} else {
					// Check nested example directories (e.g. examples/vpc/complete)
					if subEntries, err := os.ReadDir(exPath); err == nil {
						for _, se := range subEntries {
							if se.IsDir() && !strings.HasPrefix(se.Name(), ".") {
								nestedPath := filepath.Join(exPath, se.Name())
								if hasTFFiles(nestedPath) {
									rel, _ := filepath.Rel(absRoot, nestedPath)
									d.Examples = append(d.Examples, rel)
								}
							}
						}
					}
				}
			}
		}
	}

	// 4. Scan test fixtures (tests/setup/*, tests/integration/*)
	testsDir := filepath.Join(absRoot, "tests")
	for _, sub := range []string{"setup", "integration"} {
		targetSub := filepath.Join(testsDir, sub)
		if entries, err := os.ReadDir(targetSub); err == nil {
			for _, e := range entries {
				if e.IsDir() && !strings.HasPrefix(e.Name(), ".") {
					fixPath := filepath.Join(targetSub, e.Name())
					if hasTFFiles(fixPath) {
						rel, _ := filepath.Rel(absRoot, fixPath)
						d.Fixtures = append(d.Fixtures, rel)
					}
				}
			}
		}
	}

	// 5. Aggregate and sort All directories
	seen := make(map[string]bool)
	for _, list := range [][]string{d.Roots, d.Examples, d.Fixtures} {
		for _, dir := range list {
			if !seen[dir] {
				seen[dir] = true
				d.All = append(d.All, dir)
			}
		}
	}
	sort.Strings(d.Roots)
	sort.Strings(d.Examples)
	sort.Strings(d.Fixtures)
	sort.Strings(d.All)

	return d, nil
}

func hasTFFiles(dir string) bool {
	entries, err := os.ReadDir(dir)
	if err != nil {
		return false
	}
	for _, e := range entries {
		if !e.IsDir() && strings.EqualFold(filepath.Ext(e.Name()), ".tf") {
			return true
		}
	}
	return false
}
