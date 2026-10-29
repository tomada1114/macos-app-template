# Why the gates are shaped this way

The reasoning behind three choices `changing-gates` relies on. A change that replaces
one of them rewrites its paragraph here, in place (`AGENTS.md`'s "Before changing the
architecture").

## One `just check`, run through Just

`just check` runs locally the same gate CI runs, so a green local run predicts a green
pull request. Just has cleaner syntax than Make and is a task runner rather than a build
system, which is what an Xcode project needs: Xcode and SwiftPM already build, and the
recipes only sequence them. Every recipe also works without Just — `CONTRIBUTING.md`
lists the underlying commands.

## The coverage floor measures Core only, by lines and functions

`MyAppCore` holds all logic and imports no UI or OS-integration framework, so a numeric
floor on it is honest for a GUI app: it measures the code that can regress silently.
Putting the floor on `MyAppUI` or `MyAppPlatform` would instead invite meaningless view
tests and gate on whether a human ran `just test-local` (`changing-gates` ›
`scripts/coverage.sh`). Swift's llvm-cov has no dependable branch metric, so the gate
uses line coverage, plus function coverage so a Core function no test calls cannot hide
under the line floor.

## `release.yml` signs and notarizes only when its secrets exist

The release workflow always produces a DMG. With the Developer ID secrets configured it
signs, notarizes, and staples; without them it ad-hoc signs and says so loudly. The
template therefore works on day one without an Apple Developer Program membership, and
upgrades to fully trusted distribution by adding secrets — no workflow edit.
`docs/distribution.md` lists the secrets and the release flow.
