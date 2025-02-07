//
// AuthenticationUITests.swift
// TIKtAIk
//
// Created: 2024-02-14
// Last modified: 2024-02-14
//
// Purpose: UI tests for authentication flows
// Author: Assistant
// Copyright © 2024 TIKtAIk. All rights reserved.
//

// Framework: XCTest - UI Testing framework
import XCTest

/// UI tests for authentication flows
/// 
/// Tests user authentication scenarios including:
/// - Initial login view state
/// - Successful login flow
/// - Invalid credentials handling
/// - Password reset flow
final class AuthenticationUITests: TIKtAIkUITestBase {
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Ensure we start in a signed-out state
        app.launchEnvironment["UI_TEST_FORCE_SIGNOUT"] = "true"
        app.launch()
        
        // Debug view hierarchy - update to check for actual interactive elements
        if !waitForElement(app.textFields["emailField"]) {
            print("\nCurrent View State:")
            print("- Has emailField: \(app.textFields["emailField"].exists)")
            print("- Has passwordField: \(app.secureTextFields["passwordField"].exists)")
            print("- Has signInButton: \(app.buttons["signInButton"].exists)")
        }
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
    
    /// Tests the initial state of the login view
    /// 
    /// Verifies that all required UI elements are present and properly configured
    /// 
    /// Example:
    /// ```swift
    /// let tests = AuthenticationUITests()
    /// tests.testLoginViewInitialState()
    /// // Should verify loginFormContainer exists
    /// ```
    func testLoginViewInitialState() throws {
        // First check if we're logged in by looking for Feed tab
        if app.tabBars.buttons["Feed"].exists {
            ensureSignedOut()

            // We're logged in, so sign out
            app.tabBars.buttons["Profile"].tap()
            
            // Wait for profile view to load
            let signOutButton = app.buttons["signOutButton"]
            XCTAssertTrue(waitForElement(signOutButton), "Sign out button should appear")
            signOutButton.tap()
            
            // Wait for login view to appear
            let emailField = app.textFields["emailField"]
            XCTAssertTrue(waitForElement(emailField), "Should return to login view")
        }
        
        // Now verify login view elements
        XCTAssertTrue(app.textFields["emailField"].exists, "Email field should exist")
        XCTAssertTrue(app.secureTextFields["passwordField"].exists, "Password field should exist")
        XCTAssertTrue(app.buttons["signInButton"].exists, "Sign in button should exist")
        XCTAssertTrue(app.buttons["forgotPasswordButton"].exists, "Forgot password button should exist")
    }
    
    /// Tests successful login flow with valid credentials
    func testLoginFlow() {
        ensureSignedOut()

        let emailField = app.textFields["emailField"]
        XCTAssertTrue(waitForElement(emailField))
        emailField.tap()
        emailField.typeText("test@tiktaik.com")
        
        let passwordField = app.secureTextFields["passwordField"]
        XCTAssertTrue(waitForElement(passwordField))
        passwordField.tap()
        passwordField.typeText("testpassword123")
        
        let signInButton = app.buttons["signInButton"]
        XCTAssertTrue(waitForElement(signInButton))
        signInButton.tap()
        
        // Check for error alert
        if app.alerts["Error"].waitForExistence(timeout: 2) {
            let errorMessage = app.alerts["Error"].staticTexts.element(boundBy: 1).label
            XCTFail("Login failed with error: \(errorMessage)")
            return
        }
        
        // Verify successful login by checking for tab bar
        XCTAssertTrue(app.tabBars.buttons["Feed"].waitForExistence(timeout: 5), "Feed tab should appear after login")
    }
    
    func testInvalidLoginFlow() {
        ensureSignedOut()

        // Get and wait for elements
        let emailField = app.textFields["emailField"]
        XCTAssertTrue(waitForElement(emailField))
        emailField.tap()
        emailField.typeText("invalid@email.com")
        
        let passwordField = app.secureTextFields["passwordField"]
        XCTAssertTrue(waitForElement(passwordField))
        passwordField.tap()
        passwordField.typeText("wrongpassword")
        
        let signInButton = app.buttons["signInButton"]
        XCTAssertTrue(waitForElement(signInButton))
        signInButton.tap()
        
        // Verify error alert appears
        let alert = app.alerts.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        
        // Debug alert info
        print("Alert title:", alert.label)
        print("Alert message:", alert.staticTexts.allElementsBoundByIndex.map { $0.label })
    }
    
    func testForgotPasswordFlow() {
        ensureSignedOut()

        let emailField = app.textFields["emailField"]
        XCTAssertTrue(waitForElement(emailField))
        
        let forgotPasswordButton = app.buttons["forgotPasswordButton"]
        XCTAssertTrue(waitForElement(forgotPasswordButton))
        
        // Tap forgot password to open reset view
        forgotPasswordButton.tap()
        
        // Wait for reset view email field and send button
        let resetEmailField = app.textFields["resetEmailTextField"]  // Make sure this matches PasswordResetView
        XCTAssertTrue(resetEmailField.waitForExistence(timeout: 5), "Reset email field should appear")
        
        // Enter email and send
        resetEmailField.tap()
        resetEmailField.typeText("test@tiktaik.com")
        
        let sendButton = app.buttons["sendResetButton"]  // Make sure this matches PasswordResetView
        XCTAssertTrue(sendButton.waitForExistence(timeout: 5), "Send button should appear")
        sendButton.tap()
        
        // Verify alert appears with correct title and message
        let errorAlert = app.alerts["Error"]  // Alert title is "Error" even for success
        XCTAssertTrue(errorAlert.waitForExistence(timeout: 5), "Alert should appear")
        XCTAssertEqual(errorAlert.staticTexts.element(boundBy: 1).label, "Password reset email sent", "Should show success message")
    }
}

// Helper extension for debugging
extension XCUIElementQuery {
    var allIdentifiers: [String] {
        self.allElementsBoundByIndex.map { $0.identifier }
    }
} 