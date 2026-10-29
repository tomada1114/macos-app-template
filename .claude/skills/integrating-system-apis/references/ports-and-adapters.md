# Ports and adapters

The full description behind `integrating-system-apis`' five-piece table: what each piece
is, why `App/` is the only place that picks an implementation, why `MyAppPlatform` sits
outside the coverage floor, and why logging is the one OS facility that is not a port.
The layer rules themselves are `AGENTS.md`'s Architecture section.

## The five pieces

Code that talks to the OS — `NSWorkspace`, accessibility, a Carbon hotkey, an event tap,
an `NSPanel` overlay, a login item — lives in `MyAppPlatform`, never in Core, a view, or
the shell. It is always the same five pieces, and the template ships one worked example
of them to copy:

1. **The port**, in Core — a `Sendable` protocol taking and returning value types Core
   owns: `FrontmostAppProviding` in
   `Packages/MyAppKit/Sources/MyAppCore/FrontmostAppProviding.swift`.
2. **The adapter**, in Platform — the OS framework import, translating the OS type into
   the Core value and doing nothing else: `WorkspaceFrontmostAppProvider` in
   `Packages/MyAppKit/Sources/MyAppPlatform/WorkspaceFrontmostAppProvider.swift`.
3. **The fake**, in `MyAppTestSupport` — a real implementation answering from data the
   test hands it, used by the Core tests of whatever consumes the port
   (`.claude/rules/testing.md` › Fakes, not mocks): `FakeFrontmostAppProvider` in
   `Packages/MyAppKit/Tests/MyAppTestSupport/FakeFrontmostAppProvider.swift`.
4. **The local-machine test**, in `Packages/MyAppKit/Tests/MyAppPlatformTests` — the
   adapter against the *real* OS, which the fake by construction cannot check:
   `WorkspaceFrontmostAppProviderTests` asks the live `NSWorkspace`. Every suite there
   carries the `.requiresLocalMachine` trait, so it runs only with
   `RUN_LOCAL_MACHINE_TESTS=1` — what `just test-local` sets — and is reported as
   *skipped* under `just test` and in CI. It has to be: a runner has no logged-in GUI
   session and cannot be granted Accessibility, Input Monitoring, or Screen Recording,
   so such a test could only ever fail there. A skip is the honest outcome, and a human
   runs `just test-local` when an adapter changes and puts the output in the pull
   request (`.claude/rules/testing.md` › Where a Test Goes).
5. **The contract suite**, in `MyAppTestSupport` — one function over the protocol that
   checks every promise the port's `///` states, so the fake cannot quietly promise
   something the adapter does not: `FrontmostAppProvidingContract` in
   `Packages/MyAppKit/Tests/MyAppTestSupport/FrontmostAppProvidingContract.swift`.
   `FrontmostAppProvidingContractTests` in `MyAppCoreTests` runs it against the fake on
   every `just test` and in CI, and `WorkspaceFrontmostAppProviderTests` runs the same
   function against the adapter under `.requiresLocalMachine` (`just test-local`)
   (`.claude/rules/testing.md` › One Contract Suite per Port).

`MyAppTestSupport` is a library target rather than a test target only because SwiftPM
lets no target depend on a test target, and both test targets need its fakes and
contracts. It depends on `MyAppCore` alone, no product exports it, and its sources sit
under `Tests/`, outside `scripts/coverage.sh`'s `Sources/MyAppCore` filter.

## The composition root

`App/` is the composition root: the only place that constructs an adapter and hands it
to a Core view model, so nothing below it knows which implementation answered. A test
substitutes the fake at that same seam.

## Why Platform sits outside the coverage floor

`MyAppPlatform` is deliberately **outside the coverage floor** — `scripts/coverage.sh`
measures `Sources/MyAppCore` only. That is a constraint on adapters rather than a
licence: an adapter carries translation, so it has no branch worth a test. The moment
one needs a decision, the decision moves into Core behind the port, where the floor
sees it. What the floor cannot hold is the translation itself — whether the OS really
answers what the adapter assumes — and that is what the fourth and fifth pieces are for.

A port exists only where an OS or I/O boundary does. A pure rule in Core is tested
directly; wrapping it in a protocol "for testability" adds a seam with nothing behind it.

## Logging is not a port

**`MyAppCore` imports `os` directly, and that does not break the boundary.** The ban
list (`.swiftlint.yml`'s `no_ui_import_in_core` and `ArchitectureBoundaryTests`) holds
UI frameworks and the OS-integration frameworks an adapter reaches for; `os` is neither.
It pulls in no AppKit, it is available on every Apple platform Core is meant to serve
(`docs/adding-ios.md`), and it writes to the unified log rather than touching the screen
or the OS on Core's behalf. So logging is *not* modelled as a port: a `LoggingPort`
would buy no testability — a log line is not an outcome a test asserts — and would cost
every Core type an injected dependency it does not otherwise need. `os` and `OSLog` are
therefore absent from both halves of the ban list, and a test case pins their absence
so narrowing that list later fails loudly.

Every logger lives in `AppLog` (`Packages/MyAppKit/Sources/MyAppCore/AppLog.swift`), and
`MyAppUI`, `MyAppPlatform`, and `App/` log through the same loggers, which they already
see by importing `MyAppCore` — so one `just logs` stream shows the whole app. The
subsystem literal, categories, privacy annotations, and the `print` ban are
`.claude/rules/swift.md` › Logging; `FrontmostAppViewModel.refresh()` is the worked
example.
