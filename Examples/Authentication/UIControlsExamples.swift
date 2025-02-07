//
// UIControlsExamples.swift
// TIKtAIk Examples
//
// Created: 2024-02-14
// Last modified: 2024-02-14
//
// Author: Assistant
// Copyright © 2024 TIKtAIk. All rights reserved.
//

import SwiftUI

/// Examples of proper accessibility identifier usage in SwiftUI
struct UIControlsExamples: View {
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        // MARK: - Example 1: Container Pattern
        /// Important: SwiftUI propagates accessibility identifiers to child views
        /// To prevent this, use .accessibilityElement(children: .contain)
        VStack {
            TextField("Email", text: $email)
                .accessibilityIdentifier("emailTextField")
            
            SecureField("Password", text: $password)
                .accessibilityIdentifier("passwordTextField")
            
            Button("Sign In") {}
                .accessibilityIdentifier("signInButton")
        }
        .background(Color.clear) // Forces container view creation
        .accessibilityElement(children: .contain) // Prevents identifier propagation
        .accessibilityIdentifier("loginFormContainer")
        
        // MARK: - Example 2: What Not To Do
        /// ❌ Don't do this - identifier will propagate to all children
        VStack {
            TextField("Email", text: $email)
            SecureField("Password", text: $password)
            Button("Sign In") {}
        }
        .accessibilityIdentifier("loginFormContainer") // Will affect all children
        
        // MARK: - Example 3: Reusable Container
        /// ✅ Best practice: Create a reusable container view
        FormContainer {
            TextField("Email", text: $email)
                .accessibilityIdentifier("emailTextField")
            
            SecureField("Password", text: $password)
                .accessibilityIdentifier("passwordTextField")
        }
    }
}

/// Reusable container that properly handles accessibility
struct FormContainer<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack {
            content
        }
        .background(Color.clear)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("loginFormContainer")
    }
}

// MARK: - UI Testing Examples
extension UIControlsExamples {
    /// Example of finding elements in the correct container
    func testFindingInContainer() throws {
        let app = XCUIApplication()
        
        // First find the container
        let loginForm = app.otherElements["loginFormContainer"]
        XCTAssertTrue(loginForm.exists, "Login form container not found")
        
        // Then find elements within the container
        let emailField = loginForm.textFields["emailTextField"]
        XCTAssertTrue(emailField.exists, "Email field not found in form")
    }
}

#Preview {
    UIControlsExamples()
} 