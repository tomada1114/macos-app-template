/// The frontmost application, as a value Core can reason about.
///
/// A port answers in types Core owns, never in the OS type the adapter used
/// (`NSRunningApplication` here): that is what keeps Core testable with a fake and
/// free of AppKit.
public struct FrontmostApp: Equatable, Sendable {
    /// The application's display name.
    public let name: String
    /// Its bundle identifier, when it has one — some processes do not.
    public let bundleIdentifier: String?

    public init(name: String, bundleIdentifier: String? = nil) {
        self.name = name
        self.bundleIdentifier = bundleIdentifier
    }
}

/// A port: "which application is frontmost right now?", asked in Core's own vocabulary.
///
/// This is the template's worked example of the ports-and-adapters boundary
/// (`docs/architecture.md`). Core declares the protocol, `MyAppPlatform` holds the
/// adapter that answers it with `NSWorkspace`, tests substitute a fake, and `App/` —
/// the composition root — decides which one a view model gets. Nothing below `App/`
/// knows which implementation it is talking to.
///
/// Ports are `Sendable` and take and return value types, so an adapter can be handed
/// across actors and a Core caller never has to reason about the OS object behind it.
public protocol FrontmostAppProviding: Sendable {
    /// The application currently frontmost, or `nil` when there is none or the OS
    /// declines to say (a sandboxed or background process may get no answer).
    func currentFrontmostApp() -> FrontmostApp?
}
