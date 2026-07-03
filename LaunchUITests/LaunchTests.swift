import XCTest

/// The template's launch guarantee: the app starts, shows its window, and responds.
///
/// XCTest by necessity — Apple has not ported UI automation to Swift Testing.
/// All other tests use Swift Testing in Packages/MyAppKit.
final class LaunchTests: XCTestCase {
    private enum Timeout {
        static let windowAppears: TimeInterval = 10
        static let elementAppears: TimeInterval = 5
    }

    @MainActor
    func testAppLaunchesAndShowsCounter() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.windows.firstMatch.waitForExistence(timeout: Timeout.windowAppears))
        XCTAssertTrue(app.staticTexts["counterValue"]
            .waitForExistence(timeout: Timeout.elementAppears))
        app.buttons["incrementButton"].click()
        XCTAssertEqual(app.staticTexts["counterValue"].label, "1")
    }
}
