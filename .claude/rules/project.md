---
paths:
  - "project.yml"
  - "Packages/**/Package.swift"
  - "mise.toml"
  - ".swiftlint.yml"
  - ".swiftformat"
  - "scripts/coverage.sh"
---

## Dependency Policy

- The template ships with ZERO package dependencies — keep it that way unless the app truly needs one
- Before adding a dependency: verify active maintenance, compatible license (MIT/BSD/Apache),
  and minimal transitive dependencies
- `Package.resolved` MUST be committed alongside any dependency change
- NEVER lower the coverage floor (currently 80% on MyAppCore)
- NEVER remove SwiftLint rules without explicit user approval

## Project Generation

- `project.yml` is the source of truth; `MyApp.xcodeproj` is generated and gitignored —
  never hand-edit or commit it
- After changing `project.yml`, run `just generate` and build to verify

## Toolchain Pinning

- CI pins Xcode via `DEVELOPER_DIR: /Applications/Xcode_26.5.app`; CLI tools are pinned in `mise.toml`
- Bump pins deliberately (roughly monthly), one commit per bump, after `just check` passes locally
- Dependabot's `cooldown.default-days: 7` delays update PRs for SwiftPM and Actions; note that
  SwiftPM itself has no resolver-level cooldown (unlike uv's `exclude-newer`), so fresh installs
  are only protected by the committed `Package.resolved`
