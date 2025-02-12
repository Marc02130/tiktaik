//
// SubtitleOverlayView.swift
// TIKtAIk
//
// Created: 2024-02-14
// Last modified: 2024-02-14
//
// Purpose: Overlay view for displaying video subtitles
// Author: Assistant
// Copyright © 2024 TIKtAIk. All rights reserved.

import SwiftUI
import AVKit
import TIKtAIk

/// View that displays subtitles over a video player
struct SubtitleOverlayView: View {
    let subtitles: [VideoSubtitle]
    let currentTime: TimeInterval
    let preferences: SubtitlePreferences
    
    var body: some View {
        VStack {
            HStack(alignment: .top) {
                if let subtitle = currentSubtitle {
                    Text(subtitle.text)
                        .font(preferences.fontSize.font)
                        .foregroundColor(preferences.textColor.color)
                        .shadow(radius: preferences.shadowRadius)
                        .transition(.opacity)
                        .multilineTextAlignment(.center)
                        .padding(.top, 50)
                }
            }
            .padding()
            .padding(.top, 40)
            Spacer()
        }
        .animation(.easeInOut, value: currentTime)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var currentSubtitle: VideoSubtitle? {
        subtitles.first { subtitle in
            subtitle.startTime <= currentTime && currentTime <= subtitle.endTime
        }
    }
}

#Preview {
    SubtitleOverlayView(
        subtitles: [
            VideoSubtitle(
                id: "1",
                videoId: "test",
                startTime: 0,
                endTime: 5,
                text: "This is a test subtitle\nWith multiple lines",
                isEdited: false,
                createdAt: Date()
            )
        ],
        currentTime: 2.5,
        preferences: SubtitlePreferences()
    )
    .background(Color.gray)
} 