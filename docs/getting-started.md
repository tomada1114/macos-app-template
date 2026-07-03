# Getting Started

## Prerequisites

- [Xcode 26.5+](https://developer.apple.com/xcode/) (`xcode-select --install` alone is not enough — the app target needs the full IDE toolchain)
- [mise](https://mise.jdx.dev/) — installs the pinned CLI tools from `mise.toml`
- [Just](https://just.systems/man/en/installation.html) (optional — every recipe's underlying commands are plain shell; see CONTRIBUTING.md)

## Setup

```bash
just install
```

This runs `mise install` (SwiftLint, SwiftFormat, XcodeGen, xcbeautify,
actionlint — all pinned), points `core.hooksPath` at `.githooks/` for the
fast pre-commit lint, and generates `MyApp.xcodeproj`.

## Everyday Commands

```bash
just check     # the full local gate: fmt → lint → test → build
just test      # Swift Testing suite + 80% coverage floor on MyAppCore
just uitest    # XCUITest launch test (first local run may prompt for Accessibility)
just smoke     # Release build + "does it actually launch" assertion
```

## Open in Xcode

```bash
just generate
open MyApp.xcodeproj
```

Remember: `MyApp.xcodeproj` is generated from `project.yml` and gitignored.
Change targets/settings in `project.yml`, then `just generate`.
