//
// CustomStyles.swift
// TIKtAIk
//
// Created: 2024-02-14
// Last modified: 2024-02-14
//
// Purpose: Custom view styles for consistent UI appearance
// Author: Assistant
// Copyright © 2024 TIKtAIk. All rights reserved.
//

import SwiftUI

/// Custom rounded text field style
struct CustomRoundedTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
    }
}

/// Custom primary button style
struct CustomPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor)
            .foregroundStyle(.white)
            .cornerRadius(10)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

// Style extensions
extension TextFieldStyle where Self == CustomRoundedTextFieldStyle {
    /// Custom rounded style for text fields
    static var customRounded: CustomRoundedTextFieldStyle {
        CustomRoundedTextFieldStyle()
    }
}

extension ButtonStyle where Self == CustomPrimaryButtonStyle {
    /// Custom primary style for buttons
    static var customPrimary: CustomPrimaryButtonStyle {
        CustomPrimaryButtonStyle()
    }
} 