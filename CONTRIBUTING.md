# Contributing

Thank you for considering a contribution! This document explains how to set up
your development environment and submit changes.

## Prerequisites

Install these tools:

- [Xcode 26.5+](https://developer.apple.com/xcode/)
- [mise](https://mise.jdx.dev/) — provides the pinned CLI tools from `mise.toml`
- [Just](https://just.systems/man/en/installation.html) (optional — you can run
  the underlying commands directly)

Then:

```bash
mise trust     # approve mise.toml (asked once per fresh clone)
just install
```

## Development Workflow

```bash
# Format
just fmt

# Lint (swiftformat --lint + swiftlint --strict + actionlint)
just lint

# Run tests with the coverage floor
just test

# Build the app
just build

# Launch guarantee (Release build + alive check)
just smoke

# Run everything (format → lint → test → build)
just check
```

**Without Just**, run the equivalent commands:

```bash
mise install
git config core.hooksPath .githooks   # pre-commit lint gate (just install does this)
mise exec -- swiftformat .
mise exec -- swiftformat --lint .
mise exec -- swiftlint lint --strict --quiet
mise exec -- actionlint
scripts/coverage.sh
mise exec -- xcodegen generate
xcodebuild -project MyApp.xcodeproj -scheme MyApp -configuration Debug build
xcodebuild test -project MyApp.xcodeproj -scheme MyApp -destination 'platform=macOS'
scripts/smoke_launch.sh
```

## Pull Request Process

1. Fork the repository and create a branch from `main`
2. Make your changes
3. Ensure `just check` passes
4. Write or update tests for your changes
5. Open a pull request using the PR template

### Code Standards

- New logic lives in `MyAppCore` with Swift Testing coverage (happy + error path)
- SwiftLint strict and SwiftFormat must pass with no warnings
- Maintain or improve the 80% line-coverage floor on `MyAppCore`
- Public API carries `///` doc comments that explain *why*

### Commit Messages

Use Conventional Commits for both commits and PR titles:

```
<type>(<optional-scope>): <short summary>
```

Examples:

- `feat: add JSON export support`
- `fix(ui): handle window restoration`
- `docs: update installation guide`

Recommended types: `feat`, `fix`, `docs`, `refactor`, `test`, `ci`, `chore`,
`perf`, `build`, `deps` (dependency bumps).

### Changelog Policy

`CHANGELOG.md` (in [Keep a Changelog](https://keepachangelog.com/) format) is
the canonical, human-curated record of user-facing changes. Add an entry
under `[Unreleased]` for any user-facing change in the same PR that makes it.

GitHub's auto-generated release notes (via `.github/release.yml` categories)
are supplementary — useful for a quick PR-by-PR diff, but `CHANGELOG.md` is
what users should read to understand what changed in a release.

## Getting Help

If something is unclear, open an issue or start a discussion. We're happy to
help you get started.
