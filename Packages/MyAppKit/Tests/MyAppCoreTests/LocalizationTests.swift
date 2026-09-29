import Foundation
import MyAppCore
import Testing

/// The subset of the String Catalog format these tests read: its source language and,
/// per key, each language's single string. A plural or device-varied entry has
/// `variations` instead of a `stringUnit`.
private struct StringCatalog: Decodable {
    let sourceLanguage: String
    let strings: [String: CatalogEntry]
}

/// One key's entry. An entry keyed by its own English text may carry no `localizations`
/// at all, which decodes as none rather than failing the whole catalog.
private struct CatalogEntry: Decodable {
    private enum CodingKeys: String, CodingKey {
        case localizations
    }

    let localizations: [String: CatalogLocalization]

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        localizations = try container.decodeIfPresent(
            [String: CatalogLocalization].self,
            forKey: .localizations,
        ) ?? [:]
    }
}

private struct CatalogLocalization: Decodable {
    struct StringUnit: Decodable {
        let value: String
    }

    let stringUnit: StringUnit?
}

/// The String Catalog plumbing (`Sources/MyAppCore/Resources/Localizable.xcstrings`).
///
/// `swift test` builds with SwiftPM's native build system, which copies the catalog into
/// Core's resource bundle uncompiled, so every English string here comes from a
/// resource's `defaultValue`; only `xcodebuild` compiles the catalog into the app. These
/// tests therefore read the catalog's source and hold the two together: every key Core
/// uses is in the catalog, the catalog holds no other key, and its English is exactly
/// what Core renders. Without them, a key missing from the catalog still reads correctly
/// in English and simply never translates.
@MainActor
@Suite("Localization")
struct LocalizationTests {
    /// A resource Core returns, and the arguments its English format takes.
    struct Case {
        let resource: LocalizedStringResource
        let arguments: [String]
    }

    /// Every resource Core returns, once per state that picks a different key. Adding a
    /// key to Core means adding it here; `the catalog holds exactly the keys Core uses`
    /// fails until both sides agree.
    static func everyCase() -> [Case] {
        let answered = FrontmostAppViewModel(
            provider: FakeFrontmostAppProvider(answering: [FrontmostApp(name: "Finder")]),
        )
        answered.refresh()
        let unanswered = FrontmostAppViewModel(provider: FakeFrontmostAppProvider(answering: [nil]))
        return [
            Case(resource: answered.label, arguments: ["Finder"]),
            Case(resource: unanswered.label, arguments: []),
            Case(resource: CounterViewModel.resetTitle, arguments: []),
        ]
    }

    /// `Sources/MyAppCore/Resources/Localizable.xcstrings`, resolved from this file's path.
    private static func catalog() throws -> StringCatalog {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(path: "Sources/MyAppCore/Resources/Localizable.xcstrings")
        return try JSONDecoder().decode(StringCatalog.self, from: Data(contentsOf: url))
    }

    @Test
    func `every resource is looked up in Core's resource bundle, not the main bundle`() {
        for testCase in Self.everyCase() {
            let resource = testCase.resource
            guard case let .atURL(url) = resource.bundle else {
                Issue.record("\(resource.key) is not looked up in Core's bundle")
                continue
            }
            #expect(url.pathExtension == "bundle", "\(resource.key)")
            #expect(url != Bundle.main.bundleURL, "\(resource.key)")
        }
    }

    @Test
    func `the catalog holds exactly the keys Core uses`() throws {
        let used = Set(Self.everyCase().map(\.resource.key))
        let catalogued = try Set(Self.catalog().strings.keys)
        #expect(used.subtracting(catalogued).isEmpty, "missing from Localizable.xcstrings")
        #expect(catalogued.subtracting(used).isEmpty, "in Localizable.xcstrings but unused")
    }

    @Test
    func `the catalog's English is exactly what Core renders in English`() throws {
        let catalog = try Self.catalog()
        for testCase in Self.everyCase() {
            let key = testCase.resource.key
            let english = try #require(
                catalog.strings[key]?.localizations[catalog.sourceLanguage]?.stringUnit?.value,
                "\(key) has no English value",
            )
            let formatted = String(format: english, arguments: testCase.arguments)
            #expect(formatted == testCase.resource.resolved(in: .english), "\(key)")
        }
    }

    @Test
    func `the catalog and Core's bundle both declare English as the development language`() throws {
        #expect(try Self.catalog().sourceLanguage == "en")
        guard case let .atURL(url) = CounterViewModel.resetTitle.bundle else {
            Issue.record("resetTitle is not looked up in Core's bundle")
            return
        }
        #expect(Bundle(url: url)?.developmentLocalization == "en")
    }

    /// `zxx` is ISO 639's "no linguistic content": a language no catalog will ever ship,
    /// so this stays true however many locales an app adds.
    @Test
    func `a language the catalog lacks falls back to English`() {
        #expect(CounterViewModel.resetTitle.resolved(in: Locale(identifier: "zxx")) == "Reset")
        let model = FrontmostAppViewModel(provider: FakeFrontmostAppProvider(answering: [nil]))
        #expect(model.label.resolved(in: Locale(identifier: "zxx")) == "Frontmost: —")
    }
}

extension Locale {
    /// The catalog's source language. Expectations resolve in it explicitly, so a test's
    /// expected string does not depend on the language of the Mac running it.
    static let english = Locale(identifier: "en")
}

extension LocalizedStringResource {
    /// The string this resource renders as in `locale` — what a view would show a
    /// reader whose language is `locale`.
    func resolved(in locale: Locale) -> String {
        var resource = self
        resource.locale = locale
        return String(localized: resource)
    }
}
