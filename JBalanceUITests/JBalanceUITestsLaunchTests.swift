//
//  JBalanceUITestsLaunchTests.swift
//  JBalanceUITests
//
//  Created by JJ Romero Alvarez on 10/05/2026.
//

import XCTest

final class JBalanceUITestsLaunchTests: XCTestCase {
    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunchScreenIsAvailable() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
        XCTAssertGreaterThan(app.screenshot().image.size.width, 0)
    }
}
