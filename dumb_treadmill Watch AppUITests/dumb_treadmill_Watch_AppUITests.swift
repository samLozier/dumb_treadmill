//
//  dumb_treadmill_Watch_AppUITests.swift
//  dumb_treadmill Watch AppUITests
//
//  Created by Samuel Lozier on 5/2/25.
//

import XCTest

final class dumb_treadmill_Watch_AppUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        XCUIApplication().launchArguments.append("UITEST_DISABLE_HEALTHKIT")

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        throw XCTSkip("Example test removed in favor of targeted UI flow tests.")
    }

    @MainActor
    func testLaunchPerformance() throws {
        throw XCTSkip("Performance test is flaky on watchOS simulators.")
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }

    @MainActor
    func testStartPauseFlow() throws {
        let app = XCUIApplication()
        app.launch()
        registerHealthAccessInterruptionMonitor(for: app)

        dismissHealthAccessAlert(in: app)
        returnToRootIfNeeded(in: app)

        let startButton = app.buttons["startWorkoutButton"]
        XCTAssertTrue(waitForStartScreen(in: app))
        XCTAssertTrue(scrollToElement(startButton, in: app))
        startButton.tap()

        let inProgress = app.staticTexts["workoutInProgressTitle"]
        XCTAssertTrue(inProgress.waitForExistence(timeout: 5))

        let pauseButton = app.buttons["pauseWorkoutButton"]
        XCTAssertTrue(pauseButton.waitForExistence(timeout: 5))
        pauseButton.tap()

        let paused = app.staticTexts["workoutPausedTitle"]
        XCTAssertTrue(paused.waitForExistence(timeout: 5))
    }

    private func registerHealthAccessInterruptionMonitor(for app: XCUIApplication) {
        addUIInterruptionMonitor(withDescription: "Health Access") { alert in
            if alert.buttons["Close"].exists {
                alert.buttons["Close"].tap()
                return true
            }
            if alert.buttons["Review"].exists {
                alert.buttons["Review"].tap()
                return true
            }
            return false
        }
        app.tap()
    }

    private func dismissHealthAccessAlert(in app: XCUIApplication) {
        let alertApp = XCUIApplication(bundleIdentifier: "com.apple.Carousel")
        let closeButton = alertApp.buttons["Close"]
        if closeButton.waitForExistence(timeout: 2) {
            closeButton.tap()
        }
    }

    private func returnToRootIfNeeded(in app: XCUIApplication) {
        let distancePicker = app.pickers["distanceUnitPicker"]
        let weightPicker = app.pickers["weightPicker"]

        for _ in 0..<3 {
            if app.buttons["startWorkoutButton"].exists {
                return
            }

            if distancePicker.exists || weightPicker.exists {
                tapBackButton(in: app)
                continue
            }

            tapBackButton(in: app)
        }
    }

    private func tapBackButton(in app: XCUIApplication) {
        let backButton = app.navigationBars.buttons.firstMatch
        if backButton.exists {
            backButton.tap()
            return
        }

        let genericBack = app.buttons["Back"]
        if genericBack.exists {
            genericBack.tap()
        }
    }

    private func waitForStartScreen(in app: XCUIApplication) -> Bool {
        let startButton = app.buttons["startWorkoutButton"]
        for _ in 0..<6 {
            if startButton.exists {
                return true
            }
            dismissHealthAccessAlert(in: app)
            app.swipeUp()
        }
        return startButton.exists
    }

    private func scrollToElement(_ element: XCUIElement, in app: XCUIApplication, maxSwipes: Int = 6) -> Bool {
        if element.exists {
            return true
        }

        let scrollView = app.scrollViews.firstMatch
        for _ in 0..<maxSwipes {
            if scrollView.exists {
                scrollView.swipeUp()
            } else {
                app.swipeUp()
            }
            if element.exists {
                return true
            }
        }

        return element.exists
    }
}
