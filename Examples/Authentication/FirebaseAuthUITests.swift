//
// FirebaseAuthUITests.swift
// TIKtAIk
//
// Purpose: Examples of UI Tests for Firebase Authentication flows
// Created: 2024-02-05
//

import XCTest

class AuthenticationUITests: XCTestCase {
    let app = XCUIApplication()
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }
    
    /// Example 1: Test Login View Initial State
    func testLoginViewInitialState() throws {
        // Verify all elements exist and are enabled
        XCTAssertTrue(app.textFields["emailTextField"].exists)
        XCTAssertTrue(app.secureTextFields["passwordTextField"].exists)
        XCTAssertTrue(app.buttons["loginButton"].exists)
        XCTAssertTrue(app.buttons["signUpButton"].exists)
        
        // Verify initial button states
        XCTAssertFalse(app.buttons["loginButton"].isEnabled, "Login button should be disabled initially")
        XCTAssertTrue(app.buttons["signUpButton"].isEnabled, "Sign up button should be enabled")
        
        /// Usage Example:
        /// ```swift
        /// struct LoginView: View {
        ///     var body: some View {
        ///         TextField("Email", text: $email)
        ///             .accessibilityIdentifier("emailTextField")
        ///         SecureField("Password", text: $password)
        ///             .accessibilityIdentifier("passwordTextField")
        ///         Button("Login", action: login)
        ///             .accessibilityIdentifier("loginButton")
        ///         Button("Sign Up", action: showSignUp)
        ///             .accessibilityIdentifier("signUpButton")
        ///     }
        /// }
        /// ```
    }
    
    /// Example 2: Test Login Flow
    func testLoginFlow() throws {
        // Enter credentials
        let emailTextField = app.textFields["emailTextField"]
        let passwordTextField = app.secureTextFields["passwordTextField"]
        let loginButton = app.buttons["loginButton"]
        
        emailTextField.tap()
        emailTextField.typeText("test@example.com")
        
        passwordTextField.tap()
        passwordTextField.typeText("password123")
        
        // Verify login button is enabled
        XCTAssertTrue(loginButton.isEnabled)
        
        // Perform login
        loginButton.tap()
        
        // Verify successful login
        let homeView = app.otherElements["homeView"]
        XCTAssertTrue(homeView.waitForExistence(timeout: 5))
    }
    
    /// Example 3: Test Error States
    func testLoginErrorStates() throws {
        let emailTextField = app.textFields["emailTextField"]
        let passwordTextField = app.secureTextFields["passwordTextField"]
        let loginButton = app.buttons["loginButton"]
        
        // Test invalid email
        emailTextField.tap()
        emailTextField.typeText("invalid-email")
        
        let emailErrorText = app.staticTexts["emailErrorText"]
        XCTAssertTrue(emailErrorText.exists)
        
        // Test short password
        passwordTextField.tap()
        passwordTextField.typeText("short")
        
        let passwordErrorText = app.staticTexts["passwordErrorText"]
        XCTAssertTrue(passwordErrorText.exists)
    }
    
    /// Example 4: Test Navigation
    func testAuthenticationNavigation() throws {
        // Test Sign Up navigation
        app.buttons["signUpButton"].tap()
        XCTAssertTrue(app.otherElements["signUpView"].exists)
        
        // Test Forgot Password navigation
        app.buttons["forgotPasswordButton"].tap()
        XCTAssertTrue(app.otherElements["resetPasswordView"].exists)
    }
    
    /// Example 5: Test Loading States
    func testLoadingStates() throws {
        let emailTextField = app.textFields["emailTextField"]
        let passwordTextField = app.secureTextFields["passwordTextField"]
        let loginButton = app.buttons["loginButton"]
        
        // Enter credentials
        emailTextField.typeText("test@example.com")
        passwordTextField.typeText("password123")
        
        // Tap login and verify loading state
        loginButton.tap()
        
        let loadingIndicator = app.activityIndicators["loadingIndicator"]
        XCTAssertTrue(loadingIndicator.exists)
        
        // Verify loading indicator disappears
        XCTAssertTrue(loadingIndicator.waitForNonExistence(timeout: 5))
    }
} 