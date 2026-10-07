import XCTest

/// Scripted UI tour used by CI to produce the screen recording the
/// maintainer reviews: Home, Liquid Glass (scroll), Tweaks (scroll),
/// Settings (incl. the 3-UI picker), back Home. It only navigates and
/// stages nothing — it never applies anything.
final class TourUITests: XCTestCase {
    func testTour() throws {
        let app = XCUIApplication()
        // Demonstrate the supported (open) iOS 26 state in the tour.
        app.launchArguments = ["-DemoIOS26"]
        app.launch()
        XCTAssertEqual(app.state, .runningForeground,
                       "app must be in the foreground after launch")
        XCTAssertTrue(app.tabBars.buttons["Liquid Glass"]
            .waitForExistence(timeout: 15),
            "tab bar never appeared — app UI not shown")
        sleep(2)

        app.tabBars.buttons["Liquid Glass"].tap()
        sleep(1)
        app.swipeUp()
        sleep(1)
        app.swipeUp()
        sleep(1)
        app.swipeDown()

        app.tabBars.buttons["Tweaks"].tap()
        sleep(1)
        app.swipeUp()
        sleep(1)
        app.swipeUp()
        sleep(1)

        app.tabBars.buttons["Settings"].tap()
        sleep(1)
        // The 3-UI picker really re-themes the app; pick "Nugget" so the
        // change of tint is visible in the recording.
        let picker = app.buttons["ui-style-picker"]
        if picker.waitForExistence(timeout: 3) {
            picker.tap()
            sleep(1)
            let nugget = app.buttons["Nugget"]
            if nugget.waitForExistence(timeout: 3) {
                nugget.tap()
                sleep(1)
            }
        }

        app.tabBars.buttons["Home"].tap()
        sleep(1)
        app.buttons["home-lg-latest"].tap()
        sleep(2)
    }
}
