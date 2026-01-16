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

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }

    @MainActor
    func testStartPauseFlow() throws {
        let app = XCUIApplication()
        app.launchArguments.append("UITEST_DISABLE_HEALTHKIT")
        app.launch()

        let startButton = app.buttons["Start"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 5))
        startButton.tap()

        let inProgress = app.staticTexts["Workout in Progress"]
        XCTAssertTrue(inProgress.waitForExistence(timeout: 5))

        let pauseButton = app.buttons["Pause"]
        XCTAssertTrue(pauseButton.waitForExistence(timeout: 5))
        pauseButton.tap()

        let paused = app.staticTexts["Workout Paused"]
        XCTAssertTrue(paused.waitForExistence(timeout: 5))
    }
}
