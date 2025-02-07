//
// TIKtAIkUITestBase.swift
// TIKtAIk
//
// Created: 2024-02-14
// Last modified: 2024-02-14
//
// Purpose: Base test class providing common UI test functionality
// Author: Assistant
// Copyright © 2024 TIKtAIk. All rights reserved.
//

// Framework: XCTest - UI Testing framework
import XCTest

/// Base class for UI tests providing common functionality
///
/// Provides:
/// - Common setup for UI tests
/// - Helper methods for element waiting
/// - Environment configuration
/// - Screenshot handling
///
/// Example:
/// ```swift
/// class MyTests: TIKtAIkUITestBase {
///     func testSomething() {
///         XCTAssertTrue(waitForElement(app.buttons["myButton"]))
///     }
/// }
/// ```
class TIKtAIkUITestBase: XCTestCase {
    /// Main application instance for testing
    let app = XCUIApplication()
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchArguments = ["UI-Testing"]
        app.launchEnvironment = ["ENV": "TEST"]
    }
    
    /// Waits for an element to exist with timeout
    /// - Parameters:
    ///   - element: Element to wait for
    ///   - timeout: Maximum time to wait in seconds
    /// - Returns: True if element exists within timeout
    func waitForElement(_ element: XCUIElement, timeout: TimeInterval = 10) -> Bool {
        let predicate = NSPredicate(format: "exists == true")
        let expectation = expectation(for: predicate, evaluatedWith: element)
        
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        return result == .completed
    }
    
    /// Waits for authentication state change
    /// - Parameter timeout: Maximum time to wait in seconds
    /// - Returns: True if authentication changed within timeout
    func waitForAuthStateChange(timeout: TimeInterval = 5) -> Bool {
        let welcomeText = app.staticTexts["welcomeText"]
        return waitForElement(welcomeText, timeout: timeout)
    }
} 