//
// SignUpUITests.swift
// TIKtAIk
//
// Created: 2024-02-14
// Last modified: 2024-02-14
//
// Purpose: UI tests specifically for the sign up flow and form validation
// Author: Assistant
// Copyright © 2024 TIKtAIk. All rights reserved.
//

import XCTest

/// Tests for the sign up view and registration flow
///
/// Tests:
/// - Initial view state and form elements
/// - Form validation
/// - Profile type selection
/// - Terms acceptance
/// - Successful registration flow
///
/// Example:
/// ```swift
/// let tests = SignUpUITests()
/// tests.testSignUpViewInitialState() // Tests UI elements
/// tests.testSuccessfulSignUp() // Tests full registration flow
/// ```
final class SignUpUITests: TIKtAIkAuthTestBase {
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Debug view hierarchy if needed
        if !waitForElement(app.buttons["createAccountButton"]) {
            print("\nCurrent View State:")
            print("Available Buttons:", app.buttons.allElementsBoundByIndex.map { $0.identifier })
            print("Available Navigation Bars:", app.navigationBars.allElementsBoundByIndex.map { $0.identifier })
            print("Available Views:", app.otherElements.allElementsBoundByIndex.map { $0.identifier })
        }
    }
    
    /// Tests the initial state of the sign up view
    /// 
    /// Verifies:
    /// - All form fields are present
    /// - Profile type picker exists
    /// - Terms toggle exists
    /// - Sign up button is initially disabled
    /// 
    /// Example:
    /// ```swift
    /// let tests = SignUpUITests()
    /// tests.testSignUpViewInitialState()
    /// // Should verify all UI elements exist
    /// ```
    func testSignUpViewInitialState() {
        // Debug current state
        print("\nInitial View State:")
        print("- Navigation Bars:", app.navigationBars.allElementsBoundByIndex.map { $0.identifier })
        print("- Buttons:", app.buttons.allElementsBoundByIndex.map { $0.identifier })
        print("- Text Fields:", app.textFields.allElementsBoundByIndex.map { $0.identifier })
        
        // Wait for and tap create account button
        let createAccountButton = app.buttons["createAccountButton"]
        XCTAssertTrue(waitForElement(createAccountButton), "Create account button should be visible")
        createAccountButton.tap()
        
        // Debug post-tap state
        print("\nPost-tap State:")
        print("- Navigation title:", app.navigationBars.element.identifier)
        print("- Form container exists:", app.otherElements["signUpFormContainer"].exists)
        
        // Wait for navigation and form to appear
        let formContainer = app.otherElements["signUpFormContainer"]
        XCTAssertTrue(waitForElement(formContainer), "Sign up form should be visible")
        
        // Verify form fields directly (not through container)
        XCTAssertTrue(waitForElement(app.textFields["emailTextField"]), "Email field should be visible")
        XCTAssertTrue(waitForElement(app.textFields["usernameTextField"]), "Username field should be visible")
        XCTAssertTrue(waitForElement(app.secureTextFields["passwordTextField"]), "Password field should be visible")
        XCTAssertTrue(waitForElement(app.secureTextFields["confirmPasswordTextField"]), "Confirm password field should be visible")
        
        // Debug picker state
        print("\nPicker State:")
        print("- Picker containers:", app.otherElements.matching(identifier: "profileTypeContainer").allElementsBoundByIndex.map { $0.identifier })
        print("- Segmented controls:", app.segmentedControls.allElementsBoundByIndex.map { $0.identifier })
        print("- Picker options:", app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'profileType'")).allElementsBoundByIndex.map { $0.identifier })
        
        // Verify profile type picker (try different queries)
        let picker = app.segmentedControls["profileTypePicker"]
        XCTAssertTrue(waitForElement(picker), "Profile type picker should be visible")
        
        // Verify picker options exist
        let creatorOption = app.buttons["profileTypeCreator"]
        let consumerOption = app.buttons["profileTypeConsumer"]
        XCTAssertTrue(creatorOption.exists, "Creator option should be visible")
        XCTAssertTrue(consumerOption.exists, "Consumer option should be visible")
        
        // Verify terms toggle
        XCTAssertTrue(waitForElement(app.switches["termsToggle"]), "Terms toggle should be visible")
        
        // Verify signup button
        let signUpButton = app.buttons["signUpButton"]
        XCTAssertTrue(waitForElement(signUpButton), "Sign up button should be visible")
        XCTAssertFalse(signUpButton.isEnabled, "Sign up button should be disabled initially")
        
        // Debug final state if needed
        if signUpButton.exists && !signUpButton.isEnabled {
            print("\nFinal State:")
            print("- All fields present")
            print("- Sign up button disabled as expected")
        }
    }
    
    /// Tests successful user registration flow
    /// 
    /// Steps:
    /// 1. Navigate to sign up
    /// 2. Fill all form fields
    /// 3. Select Creator profile
    /// 4. Accept terms
    /// 5. Submit form
    /// 6. Verify success
    /// 
    /// Example:
    /// ```swift
    /// let tests = SignUpUITests()
    /// tests.testSuccessfulSignUp()
    /// // Should complete registration and show welcome
    /// ```
    func testSuccessfulSignUp() {
        // Debug initial state
        print("\nInitial State:")
        print("- App launched")
        print("- Environment:", app.launchEnvironment)
        
        // Navigate to signup
        app.buttons["createAccountButton"].tap()
        
        // Fill form with test credentials
        app.textFields["emailTextField"].tap()
        app.textFields["emailTextField"].typeText("test@tiktaik.com")
        
        app.textFields["usernameTextField"].tap()
        app.textFields["usernameTextField"].typeText("testuser")
        
        // Use a longer password that meets requirements
        let testPassword = "TestPassword123!"
        print("\nPassword State Before:")
        print("- Test password:", testPassword)
        print("- Password length:", testPassword.count)
        
        let passwordField = app.secureTextFields["passwordTextField"]
        XCTAssertTrue(waitForElement(passwordField))
        passwordField.tap()
        passwordField.typeText(testPassword)
        
        let confirmPasswordField = app.secureTextFields["confirmPasswordTextField"]
        XCTAssertTrue(waitForElement(confirmPasswordField))
        confirmPasswordField.tap()
        confirmPasswordField.typeText(testPassword)
        
        // Select Creator profile
        app.buttons["Creator"].tap()
        
        // Accept terms
        let termsToggle = app.switches["termsToggle"]
        XCTAssertTrue(termsToggle.exists, "Terms toggle should exist")
        
        print("\nTerms State Before:")
        print("- Toggle exists:", termsToggle.exists)
        print("- Toggle value:", termsToggle.value as? String ?? "nil")
        
        // According to HIG, we need to check if it's already on
        if termsToggle.value as? String == "0" {
            // Try tapping the toggle area
            let toggleCoordinate = termsToggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5))
            toggleCoordinate.tap()
            
            // Wait for animation
            Thread.sleep(forTimeInterval: 0.5)
            
            print("\nTerms State After:")
            print("- Toggle value:", termsToggle.value as? String ?? "nil")
            print("- Sign up button enabled:", app.buttons["signUpButton"].isEnabled)
            
            // Verify toggle changed
            XCTAssertEqual(termsToggle.value as? String, "1", "Toggle should be on")
        }
        
        // Verify button is enabled
        let signUpButton = app.buttons["signUpButton"]
        XCTAssertTrue(signUpButton.isEnabled, "Sign up button should be enabled after accepting terms")
        
        // Submit and wait for auth state change
        signUpButton.tap()
        
        // Debug post-submit state
        print("\nPost-Submit State:")
        print("- Current elements:", app.descendants(matching: .any).allElementsBoundByIndex.map { "\($0.elementType) - \($0.identifier)" })
        
        // Check for error alert
        let errorAlert = app.alerts["Error"]
        if errorAlert.exists {
            print("Error Alert Found:")
            print("- Title:", errorAlert.label)
            print("- Message:", errorAlert.staticTexts.allElementsBoundByIndex.map { $0.label })
            XCTFail("Sign up failed with error alert")
        }
        
        print("- Welcome text exists:", app.staticTexts["welcomeText"].exists)
        
        // Use base class method to wait for auth state with longer timeout
        XCTAssertTrue(waitForAuthStateChange(timeout: 10), "Should show welcome screen after successful signup")
    }
} 