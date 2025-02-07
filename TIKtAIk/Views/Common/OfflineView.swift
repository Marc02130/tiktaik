//
// OfflineView.swift
// TIKtAIk
//

import SwiftUI

struct OfflineView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 60))
            
            Text("No Internet Connection")
                .font(.title2)
            
            Text("Please check your connection and try again")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}