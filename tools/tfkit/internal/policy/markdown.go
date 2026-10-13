package policy

import (
	"bufio"
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
	"regexp"
	"strings"
)

var (
	mdLinkRegex = regexp.MustCompile(`!?\[[^\]]*\]\((?:<)?([^\s)>]+)(?:>)?(?:\s+[^)]*)?\)`)
	schemeRegex = regexp.MustCompile(`^(?:[a-zA-Z][a-zA-Z0-9+.-]*:|//)`)
)

// MarkdownCheckReport summarizes repository-relative Markdown link verification.
type MarkdownCheckReport struct {
	RootDir      string   `json:"root_dir"`
	FilesChecked int      `json:"files_checked"`
	LinksChecked int      `json:"links_checked"`
	Status       string   `json:"status"` // PASS or FAIL
	BrokenLinks  []string `json:"broken_links,omitempty"`
}

// CheckMarkdownLinks recursively scans rootDir for .md files and verifies that all
// repository-relative links resolve on disk.
func CheckMarkdownLinks(rootDir string) (MarkdownCheckReport, error) {
	report := MarkdownCheckReport{
		RootDir: rootDir,
		Status:  "PASS",
	}

	absRoot, err := filepath.Abs(rootDir)
	if err != nil {
		return report, err
	}

	err = filepath.WalkDir(absRoot, func(path string, d fs.DirEntry, walkErr error) error {
		if walkErr != nil {
			return walkErr
		}
		if d.IsDir() {
			if strings.HasPrefix(d.Name(), ".") && path != absRoot {
				return filepath.SkipDir
			}
			return nil
		}
		if !strings.EqualFold(filepath.Ext(d.Name()), ".md") {
			return nil
		}

		report.FilesChecked++
		links, broken, err := checkSingleMarkdownFile(path)
		if err != nil {
			return err
		}
		report.LinksChecked += links
		report.BrokenLinks = append(report.BrokenLinks, broken...)
		return nil
	})
	if err != nil {
		return report, err
	}

	if len(report.BrokenLinks) > 0 {
		report.Status = "FAIL"
	}
	return report, nil
}

func checkSingleMarkdownFile(filePath string) (int, []string, error) {
	f, err := os.Open(filePath)
	if err != nil {
		return 0, nil, err
	}
	defer f.Close()

	inFence := false
	lineNum := 0
	linksChecked := 0
	var broken []string
	baseDir := filepath.Dir(filePath)

	scanner := bufio.NewScanner(f)
	for scanner.Scan() {
		lineNum++
		line := scanner.Text()
		if strings.HasPrefix(strings.TrimLeft(line, " \t"), "```") {
			inFence = !inFence
		}
		if inFence {
			continue
		}

		matches := mdLinkRegex.FindAllStringSubmatch(line, -1)
		for _, m := range matches {
			target := m[1]
			if target == "" || strings.HasPrefix(target, "#") || strings.HasPrefix(target, "/") {
				continue
			}
			if schemeRegex.MatchString(target) {
				continue
			}
			relPath := strings.SplitN(target, "#", 2)[0]
			if relPath == "" {
				continue
			}
			linksChecked++
			resolved := filepath.Join(baseDir, relPath)
			if _, err := os.Stat(resolved); err != nil {
				broken = append(broken, fmt.Sprintf("%s:%d: missing local link %s", filePath, lineNum, target))
			}
		}
	}
	return linksChecked, broken, scanner.Err()
}
