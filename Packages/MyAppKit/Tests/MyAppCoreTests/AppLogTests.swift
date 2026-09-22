import Foundation
import MyAppCore
import Testing

/// ``AppLog/subsystem`` is the only place this app's unified-log subsystem is spelled,
/// and it has to stay the bundle identifier `project.yml` declares: `just logs` streams
/// `subsystem == "$(scripts/bundle-id.sh)"`, which reads that manifest. Both spellings
/// are placeholder literals `scripts/bootstrap.sh` rewrites together, so they can only
/// drift when someone edits one by hand — this suite is what makes that a failing test
/// instead of a log stream that silently shows nothing.
@Suite("AppLog")
struct AppLogTests {
    /// The checkout root, resolved from this file's path:
    /// `Packages/MyAppKit/Tests/MyAppCoreTests/<this file>`, five levels up.
    static let repositoryRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()

    @Test
    func `the log subsystem is the bundle identifier project yml declares`() throws {
        let manifest = Self.repositoryRoot.appendingPathComponent("project.yml")
        let declaration = "PRODUCT_BUNDLE_IDENTIFIER: \(AppLog.subsystem)"
        let text = try String(contentsOf: manifest, encoding: .utf8)
        #expect(
            text.contains(declaration),
            """
            \(manifest.path) declares no `\(declaration)`.
            AppLog.subsystem and project.yml must name the same bundle identifier, or
            `just logs` filters on a subsystem nothing in the app logs to.
            """,
        )
    }

    @Test
    func `the log subsystem is a well formed bundle identifier`() {
        // The same shape scripts/bundle-id.sh accepts: alphanumerics, hyphens, and
        // periods, dot-separated, with no leading or trailing period.
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-."))
        #expect(AppLog.subsystem.unicodeScalars.allSatisfy(allowed.contains))
        #expect(!AppLog.subsystem.hasPrefix("."))
        #expect(!AppLog.subsystem.hasSuffix("."))
        #expect(AppLog.subsystem.split(separator: ".").count >= 2)
    }
}
