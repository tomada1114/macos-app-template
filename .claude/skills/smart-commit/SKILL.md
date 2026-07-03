---
name: smart-commit
description: >
  Analyze working tree changes, group them into logical atomic commits with
  Conventional Commits messages, and push. Handles staging, sensitive file
  exclusion, and Package.resolved bundling automatically. Use PROACTIVELY when:
  commit, git commit, save changes, commit and push, stage changes,
  push my changes, commit this work, ship it.
---

# Smart Commit Workflow

All commit messages must be written in English.

## Dynamic Context

Current branch:
!git rev-parse --abbrev-ref HEAD

Working tree status:
!git status --short

Recent commit style:
!git log --oneline -5

## Branch Guard

**Never commit directly to `main`.** If the current branch is `main`, abort
immediately and tell the user to create a feature branch first. There is no
enforcing hook — this skill is the guard, so check before any staging work.

## Step 1: Analyze Changes

Review staged and unstaged changes to understand what was modified.

```bash
git status
git diff          # unstaged changes
git diff --cached # staged changes
```

If changes are already staged, prioritize those — the user has expressed intent
about what to commit. If nothing is staged, treat all modified/untracked files
as candidates.

## Step 2: Sensitive File Check

Never commit files that could contain secrets:

- `.env`, `.env.*` (environment variables)
- `**/credentials.json`, `**/secrets.json`, `**/private-key.*`
- Files matching `*password*`, `*secret*`, `*key*.pem`, `*.p12`

Also never commit generated artifacts: `MyApp.xcodeproj/`, `.build/`, `build/`
(all gitignored — if one shows up as untracked, something is wrong; investigate
instead of committing it).

If any are detected among the candidates, **exclude them** and warn the user.
Everything else — config files, source code, docs, test files — should be
committed. Prefer committing work-in-progress over leaving it uncommitted.

## Step 3: Group Changes

Analyze the changes and group them into logical, atomic commits. Each commit
should be independently meaningful. The goal is to tell a clear story of what
happened through the commit history.

**Grouping rules:**

- **Tests** (`Packages/**/Tests/`, `LaunchUITests/`): prefix `test:`
  - New tests → `test: add ...`
  - Fixed tests → `test: fix ...`

- **Documentation** (`.md`, `docs/`): prefix `docs:`

- **Configuration** (`.swiftlint.yml`, `.swiftformat`, `.claude/`, `mise.toml`,
  `typos.toml`, `.editorconfig`): prefix `chore:`

- **Dependencies** (`Package.swift` dependency changes): prefix `deps:`
  - Always include `Package.resolved` in the same commit

- **Build system** (`project.yml`, `justfile`, `scripts/`): prefix `build:`

- **Source code** (`Packages/**/Sources/`, `App/`):
  - New feature → `feat:`
  - Bug fix → `fix:`
  - Refactor → `refactor:`
  - Performance → `perf:`

- **CI/CD** (`.github/`): prefix `ci:`

**Special cases:**
- `Package.resolved` changes must be in the same commit as the `Package.swift`
  dependency change that caused them
- A source file and its corresponding test file MUST go in the same commit —
  this project is TDD-first, and red tests are never committed alone
  (use `feat:` or `fix:` prefix)

If all changes are closely related, a single commit is fine. Don't split
artificially — three related one-line changes are better as one commit than
three separate commits.

## Step 4: Create Commits

For each group, stage the relevant files and commit:

```bash
git add <file1> <file2> ...
git commit -m "$(cat <<'EOF'
<type>(<optional-scope>): <short summary>
EOF
)"
```

**Commit message format:**
- Conventional Commits: `<type>(<optional-scope>): <short summary>`
- Types: `feat`, `fix`, `docs`, `refactor`, `test`, `ci`, `chore`, `perf`,
  `build`, `deps`
- Summary: imperative mood, lowercase start, no period at end
- Under 72 characters
- Focus on *what* changed, not *how*

**Examples:**

```
feat(core): add persistence for counter state
fix: clamp counter at range bounds instead of overflowing
test: add parameterized tests for boundary values
docs: update architecture guide for new module
chore: enable additional SwiftLint analyzer rules
```

Stage specific files by name — avoid `git add .` or `git add -A` which can
accidentally include sensitive files or unrelated changes.

## Step 5: Push (if requested)

Only push if the user explicitly asked to push (e.g., "commit and push",
"ship it"). If the user only said "commit", skip this step — they may want
to make more commits before pushing, or use the `create-pr` skill which
handles push on its own.

```bash
git push
# or if no upstream:
git push -u origin <current-branch>
```

## Step 6: Verify

Show the final state to confirm everything is clean:

```bash
git status
git log --oneline -<number-of-new-commits>
```

Report any remaining uncommitted files and explain why they were excluded
(should only be sensitive files).

## Pre-commit Hook Interaction

This project's pre-commit hook (`.githooks/pre-commit`) runs
`swiftformat --lint` and `swiftlint lint --strict` on the staged Swift files.
It checks but never modifies files. The skill does NOT duplicate these checks —
the hook handles code quality, while the skill handles commit workflow.

**When the hook fails:**

1. The commit did NOT happen — staged files remain staged but uncommitted
2. Run `just fmt` to fix formatting, or fix the reported SwiftLint violation
   in the source
3. Re-stage the fixed files: `git add <fixed-files>`
4. Retry the commit (same message is fine) — never `--amend` someone else's commit
5. Never use `--no-verify` to skip hooks — fix the underlying issue instead

**Common hook failures and fixes:**
- `swiftformat`: run `just fmt` and re-stage
- `swiftlint`: fix the violation; only subjective style rules may be disabled
  in `.swiftlint.yml`, each with a reason comment — NEVER safety rules

## Notes

- When in doubt about grouping, fewer larger commits are better than many tiny ones
