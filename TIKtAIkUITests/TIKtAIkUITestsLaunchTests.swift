//
// TIKtAIkUITestsLaunchTests.swift
// TIKtAIk
//
// Created: 2024-02-14
// Last modified: 2024-02-14
//
// Purpose: Launch screen UI tests and screenshot capture
// Author: Assistant
// Copyright © 2024 TIKtAIk. All rights reserved.
//

// Framework: XCTest - UI Testing framework
import XCTest

/// Tests for app launch and initial screen appearance
///
/// Tests:
/// - App launch success
/// - Launch screen appearance
/// - Screenshot capture
///
/// Example:
/// ```swift
/// let tests = TIKtAIkUITestsLaunchTests()
/// tests.testLaunch() // Captures launch screen
/// ```
final class TIKtAIkUITestsLaunchTests: TIKtAIkUITestBase {
    /// Indicates if tests should run for each UI configuration
    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false
    }
    
    /// Tests app launch and captures screenshot
    /// - Throws: XCTest assertion errors if launch fails
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Insert steps here to perform after app launch but before taking a screenshot,
        // such as logging into a test account or navigating somewhere in the app
        
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
