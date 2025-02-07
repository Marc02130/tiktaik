//
// TIKtAIkUITests.swift
// TIKtAIk
//
// Created: 2024-02-14
// Last modified: 2024-02-14
//
// Purpose: Basic UI test cases for app functionality
// Author: Assistant
// Copyright © 2024 TIKtAIk. All rights reserved.
//

import XCTest

/// Specific UI test cases for basic app functionality
final class TIKtAIkUITests: TIKtAIkUITestBase {
    override func setUpWithError() throws {
        try super.setUpWithError()
        app.launch()
    }

    /// Tests basic app launch and UI elements
    /// - Throws: XCTest assertion errors if elements are not found
    func testAppLaunchAndBasicUI() throws {
        // Wait for and verify navigation bar
        let navigationBar = app.navigationBars["TIKtAIk"]
        XCTAssertTrue(waitForElement(navigationBar), "Navigation bar should appear")
        
        // Verify welcome text
        let welcomeText = app.staticTexts["Welcome to TIKtAIk"]
        XCTAssertTrue(waitForElement(welcomeText), "Welcome text should appear")
    }
    
    /// Tests app launch performance
    /// - Throws: XCTest assertion errors if performance thresholds are not met
    func testAppPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            app.launch()
            
            // Wait for app to become stable
            let navigationBar = app.navigationBars["TIKtAIk"]
            XCTAssertTrue(waitForElement(navigationBar), "App should load within performance threshold")
        }
    }

    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()
    }

    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
