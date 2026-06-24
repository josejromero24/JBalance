//
//  JBalanceUITests.swift
//  JBalanceUITests
//
//  Created by JJ Romero Alvarez on 10/05/2026.
//

import XCTest

final class JBalanceUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testAppLaunches() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
    }
}
