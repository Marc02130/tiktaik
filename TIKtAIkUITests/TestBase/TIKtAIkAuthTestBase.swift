//
// TIKtAIkUITestBase.swift
// TIKtAIk
//
// Created: 2024-02-14
// Last modified: 2024-02-14
//
// Purpose: Base test class providing common UI test functionality for authentication flows
// Author: Assistant
// Copyright © 2024 TIKtAIk. All rights reserved.
//

import XCTest

/// Base class for authentication UI tests providing common functionality
///
/// Provides:
/// - Common setup for auth UI tests
/// - Helper methods for element waiting
/// - Authentication state management
/// - Environment configuration for auth testing
///
/// Example:
/// ```swift
/// class MyAuthTests: TIKtAIkAuthTestBase {
///     func testAuthFlow() {
///         XCTAssertTrue(waitForAuthStateChange())
///     }
/// }
/// ```
class TIKtAIkAuthTestBase: XCTestCase {
    /// Main application instance for testing
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        app = XCUIApplication()
        
        // Set up test environment for auth testing
        app.launchEnvironment["UI_TEST_MODE"] = "true"
        
        continueAfterFailure = false
        app.launch()
        
        // Ensure we're signed out before each test
        ensureSignedOut()
    }
    
    /// Ensures the user is signed out before running tests
    private func ensureSignedOut() {
        // Check if we're logged in by looking for Feed tab
        if app.tabBars.buttons["Feed"].exists {
            // Navigate to profile and sign out
            app.tabBars.buttons["Profile"].tap()
            
            // Wait for and tap sign out button
            let signOutButton = app.buttons["signOutButton"]
            guard waitForElement(signOutButton) else {
                XCTFail("Failed to find sign out button")
                return
            }
            signOutButton.tap()
            
            // Verify we're back at login view
            let emailField = app.textFields["emailField"]
            guard waitForElement(emailField) else {
                XCTFail("Failed to return to login view after sign out")
                return
            }
        }
    }
    
    /// Waits for an element to exist with timeout
    /// - Parameters:
    ///   - element: Element to wait for
    ///   - timeout: Maximum time to wait
    /// - Returns: True if element exists within timeout
    func waitForElement(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        let predicate = NSPredicate(format: "exists == true")
        let expectation = expectation(for: predicate, evaluatedWith: element, handler: nil)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        return result == .completed
    }
    
    /// Waits for authentication state change
    /// - Parameter timeout: Maximum time to wait
    /// - Returns: True if authentication changed within timeout
    func waitForAuthStateChange(timeout: TimeInterval = 5) -> Bool {
        let welcomeText = app.staticTexts["welcomeText"]
        return waitForElement(welcomeText, timeout: timeout)
    }
} 