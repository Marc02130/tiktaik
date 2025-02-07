//
// UITestExamples.swift
// TIKtAIk
//
// Purpose: Examples of UI Testing with accessibility identifiers
// Created: 2024-02-05
//

// MARK: - View Implementation
struct LoginView: View {
    @State private var email = ""
    
    var body: some View {
        TextField("Email", text: $email)
            // Important: Set accessibility identifier
            .accessibilityIdentifier("emailTextField")
    }
}

// MARK: - UI Test Implementation
class AuthenticationUITests: XCTestCase {
    let app = XCUIApplication()
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }
    
    /// Example 1: Basic Element Existence Test
    func testLoginViewInitialState() throws {
        // Get email field using accessibility identifier
        let emailField = app.textFields["emailTextField"]
        
        // Verify existence with helpful error message
        XCTAssertTrue(emailField.exists, "Email field should exist")
        
        // Optional: Print view hierarchy if test fails
        if !emailField.exists {
            print("View Hierarchy: \(app.debugDescription)")
        }
    }
    
    /// Example 2: Wait for Element
    func testLoginViewWithWait() throws {
        let emailField = app.textFields["emailTextField"]
        
        // Wait for element to appear
        let exists = emailField.waitForExistence(timeout: 5)
        XCTAssertTrue(exists, "Email field should appear within 5 seconds")
    }
    
    /// Example 3: Debug View Hierarchy
    func testWithHierarchyDebug() throws {
        let emailField = app.textFields["emailTextField"]
        
        // If test fails, print detailed information
        if !emailField.exists {
            // Print entire view hierarchy
            print("Full View Hierarchy:")
            print(app.debugDescription)
            
            // Print all accessibility identifiers
            print("Available Identifiers:")
            for element in app.descendants(matching: .any) {
                if let identifier = element.identifier {
                    print("- \(identifier)")
                }
            }
        }
        
        XCTAssertTrue(emailField.exists, "Email field should exist")
    }
} 