// swift-tools-version: 6.2
import PackageDescription

/// Strictness from day one: Swift 6 language mode (data-race safety as errors)
/// and every warning treated as an error. There is never a "legacy" codebase.
let strictSettings: [SwiftSetting] = [
    .swiftLanguageMode(.v6),
    .treatAllWarnings(as: .error),
]

let package = Package(
    name: "MyAppKit",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "MyAppCore", targets: ["MyAppCore"]),
        .library(name: "MyAppUI", targets: ["MyAppUI"]),
    ],
    targets: [
        .target(name: "MyAppCore", swiftSettings: strictSettings),
        .target(name: "MyAppUI", dependencies: ["MyAppCore"], swiftSettings: strictSettings),
        .testTarget(
            name: "MyAppCoreTests",
            dependencies: ["MyAppCore"],
            swiftSettings: strictSettings,
        ),
    ],
)
