# `tfkit` — Unified DevUX, Fleet Governance & SRE ConOps CLI

`tfkit` is a zero-dependency, single-binary Go CLI that consolidates fleet synchronization, GitHub release invariant verification, and static workflow/documentation policy gates across the `aws.modules.*` catalog and [`devops-aws-infra`](../../README.md).

See [`UNIFIED_DEVUX_TOOL_RFC.md`](../../UNIFIED_DEVUX_TOOL_RFC.md) for the full architectural design and roadmap.

---

## Build & Verify

```bash
make -C tools/tfkit check     # Runs gofmt, go vet, go test -race -cover, and builds bin/tfkit
```

---

## Commands (Phase 0, Phase 1 & Phase 3)

### 1. Fleet Git Audit & Synchronization
Concurrently audits or synchronizes all local `aws.modules.*` repositories in `< 200ms`:

```bash
# Audit local module repositories (table or JSON)
./tools/tfkit/bin/tfkit fleet status --dir ~
./tools/tfkit/bin/tfkit fleet status --dir ~ --output json

# Fetch remotes, switch clean feature checkouts to main, fast-forward main, and prune gone branches
./tools/tfkit/bin/tfkit fleet sync --dir ~
```

### 2. Fleet Release & Signed-Tag Invariant Verification
Concurrently verifies all 6 release invariants (default branch SHA parity, annotated tag, GitHub-verified SSH/GPG signature, and published latest Release match) across all `aws.modules.*` repositories on GitHub:

```bash
./tools/tfkit/bin/tfkit fleet verify-releases --owner hatan4ik
```

### 3. Static Workflow & Documentation Policy Gates
Replaces `check-action-pins.sh`, `validate-workflows.rb`, and `check-markdown-links.rb` with native Go checks:

```bash
# Validate workflow top-level schema and 40-character commit SHA pins
./tools/tfkit/bin/tfkit policy workflows --dir .github/workflows

# Verify all repository-relative Markdown links resolve on disk
./tools/tfkit/bin/tfkit policy markdown --dir docs
```

---

## Deterministic Exit Code Contract

| Exit Code | Meaning |
| :--- | :--- |
| `0` | Success / All checks and invariants passed |
| `1` | Unexpected runtime, I/O, or upstream API error |
| `2` | CLI usage or flag validation error |
| `3` | Policy, drift, or release invariant violation detected |

