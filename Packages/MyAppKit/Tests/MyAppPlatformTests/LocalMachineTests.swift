import Foundation
import Testing

/// The opt-in every test in this target carries, and the helpers those tests share.
///
/// `MyAppPlatformTests` exercises adapters against the *real* OS. A CI runner has no
/// logged-in GUI session and cannot be granted Accessibility, Input Monitoring, or
/// Screen Recording, so these tests can only be believed on a developer's machine.
/// They are therefore opt-in rather than absent: with the opt-in unset they are
/// reported as **skipped** on every run — `just test`, a bare `swift test`, and CI —
/// so a green run is never mistaken for evidence that an adapter works.
///
/// The variable name carries no app-specific prefix on purpose. `scripts/bootstrap.sh`
/// rewrites the literal `MyApp`, not an upper-cased spelling of it, so a prefixed name
/// would survive the template rename as a stale one. It matches the repository's other
/// environment opt-in, `ALLOW_MISSING_GIT_HOOKS`.
enum LocalMachineTests {
    /// The environment variable that opts a run in. `just test-local` sets it to `1`.
    static let optInVariable = "RUN_LOCAL_MACHINE_TESTS"

    /// Whether this process was started with the opt-in.
    static var isOptedIn: Bool {
        ProcessInfo.processInfo.environment[optInVariable] == "1"
    }

    /// Unwraps an answer the OS gives only a process that holds `requirement`, failing
    /// with that requirement's name when the answer is `nil`.
    ///
    /// The convention for every test here, and the reason this helper exists: the OS
    /// does not report a missing permission, it simply answers nothing. A bare `nil`
    /// would therefore read as "the adapter is broken"; naming what is missing turns
    /// the failure into an instruction. A test that needs Accessibility, Input
    /// Monitoring, or Screen Recording says so here.
    static func require<Value>(
        _ value: Value?,
        requires requirement: String,
        // The default is the point of the parameter: `#_sourceLocation` is evaluated at
        // the call site, so the failure points at the test rather than at this helper.
        // swiftlint:disable:next discouraged_default_parameter
        sourceLocation: SourceLocation = #_sourceLocation,
    ) throws -> Value {
        try #require(
            value,
            """
            The OS answered nothing. This test needs \(requirement). \
            A permission is held by the application that launched the run — your \
            terminal, or Xcode — so grant it to that application in \
            System Settings › Privacy & Security and rerun `just test-local`.
            """,
            sourceLocation: sourceLocation,
        )
    }
}

extension Trait where Self == ConditionTrait {
    /// Runs the test only on a machine that opted in, and reports it as skipped
    /// everywhere else.
    ///
    /// Every suite in `MyAppPlatformTests` carries this, so the whole target is one
    /// switch: `RUN_LOCAL_MACHINE_TESTS=1` (what `just test-local` sets) runs it, and
    /// nothing else does. It is built on `.enabled(if:)` rather than on a `withKnownIssue`
    /// or a commented-out test so the skip is a reported outcome, not an absence.
    static var requiresLocalMachine: Self {
        .enabled(
            if: LocalMachineTests.isOptedIn,
            "local-machine only: run `just test-local` (sets \(LocalMachineTests.optInVariable)=1)",
        )
    }
}
