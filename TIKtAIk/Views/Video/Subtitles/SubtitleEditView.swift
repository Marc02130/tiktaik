//
// SubtitleEditView.swift
// TIKtAIk
//
// Created: 2024-02-14
// Last modified: 2024-02-14
//
// Purpose: View for editing video subtitles
// Author: Assistant
// Copyright © 2024 TIKtAIk. All rights reserved.

import SwiftUI
import AVKit

struct SubtitleEditView: View {
    @ObservedObject var viewModel: VideoSubtitleViewModel
    @State private var selectedSubtitle: VideoSubtitle?
    @State private var showGenerationOptions = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom toolbar
            HStack {
                Button("Done") {
                    dismiss()
                }
                .padding()
                
                Spacer()
                
                Text("Subtitles")
                    .font(.headline)
                
                Spacer()
                
                if !viewModel.subtitles.isEmpty {
                    Button("Save") {
                        Task {
                            do {
                                try await viewModel.saveChanges()
                                dismiss()
                            } catch {
                                print("Failed to save subtitles:", error)
                            }
                        }
                    }
                    .padding()
                }
            }
            .background(Color(.systemBackground))
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.gray.opacity(0.3)),
                alignment: .bottom
            )
            
            // Main content
            List {
                if viewModel.isGenerating {
                    Section {
                        HStack {
                            ProgressView()
                            Text("Generating subtitles...")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Section {
                    Button("Generate Subtitles") {
                        print("DEBUG: Generate subtitles tapped")
                        showGenerationOptions = true
                    }
                    .disabled(viewModel.isGenerating)
                }
                
                if !viewModel.subtitles.isEmpty {
                    Section("Subtitles") {
                        ForEach(viewModel.subtitles) { subtitle in
                            SubtitleRow(
                                subtitle: subtitle,
                                isSelected: selectedSubtitle?.id == subtitle.id,
                                onSelect: {
                                    selectedSubtitle = subtitle
                                }
                            )
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showGenerationOptions) {
            GenerationOptionsView(
                videoURL: viewModel.currentVideoURL,
                onGenerate: { preferences in
                    Task {
                        do {
                            try await viewModel.generateSubtitles(with: preferences)
                            showGenerationOptions = false
                        } catch {
                            print("Failed to generate subtitles:", error)
                        }
                    }
                }
            )
        }
        .sheet(item: $selectedSubtitle) { subtitle in
            SubtitleTimingView(
                subtitle: subtitle,
                onUpdate: { startTime, endTime in
                    Task {
                        try await viewModel.updateTiming(
                            for: subtitle,
                            startTime: startTime,
                            endTime: endTime
                        )
                    }
                }
            )
        }
    }
    
    private func deleteSubtitle(for subtitle: VideoSubtitle) {
        Task {
            do {
                try await viewModel.deleteSubtitle(for: subtitle.id)
            } catch {
                print("Error deleting subtitle:", error)
            }
        }
    }
}

// Break out list content to separate view
private struct SubtitleListContent: View {
    let viewModel: VideoSubtitleViewModel
    let videoURL: URL
    @Binding var selectedSubtitle: VideoSubtitle?
    @State private var editedText = ""
    @State private var showGenerationOptions = false
    @State private var showSubtitles = true
    
    var body: some View {
        List {
            if viewModel.isGenerating {
                GeneratingSection(progress: viewModel.progress)
            } else if viewModel.subtitles.isEmpty {
                EmptySection(showOptions: $showGenerationOptions)
            } else if showSubtitles {
                SubtitlesSection(
                    subtitles: viewModel.subtitles,
                    viewModel: viewModel,
                    selectedSubtitle: $selectedSubtitle,
                    editedText: $editedText,
                    onSave: { newText in
                        Task {
                            do {
                                if let subtitle = selectedSubtitle {
                                    // Update the subtitle in Firestore
                                    let updatedSubtitle = VideoSubtitle(
                                        id: subtitle.id,
                                        videoId: subtitle.videoId,
                                        startTime: subtitle.startTime,
                                        endTime: subtitle.endTime,
                                        text: newText,
                                        isEdited: true,
                                        createdAt: subtitle.createdAt
                                    )
                                    
                                    try await viewModel.updateSubtitles([updatedSubtitle])
                                    selectedSubtitle = nil
                                    editedText = ""
                                }
                            } catch {
                                print("Failed to update subtitle:", error)
                            }
                        }
                    }
                )
            }
        }
        .sheet(isPresented: $showGenerationOptions) {
            GenerationOptionsView(
                videoURL: videoURL,
                onGenerate: { preferences in
                    showGenerationOptions = false
                    Task {
                        do {
                            try await viewModel.generateSubtitles(with: preferences)
                        } catch {
                            // Handle the error appropriately
                            print("Failed to generate subtitles:", error)
                            // You might want to show an alert or error message to the user
                        }
                    }
                }
            )
        }
    }
}

// Dedicated section for generating state
private struct GeneratingSection: View {
    let progress: Double
    
    var body: some View {
        Section {
            VStack(spacing: 12) {
                Text("Generating subtitles...")
                    .font(.headline)
                
                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                
                Text(progressDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text("\(Int(progress * 100))%")
                    .monospacedDigit()
            }
            .padding()
            .frame(maxWidth: .infinity)
        }
    }
    
    private var progressDescription: String {
        if progress < 0.3 {
            return "Extracting audio..."
        } else if progress < 0.7 {
            return "Processing with Whisper AI..."
        } else if progress < 0.9 {
            return "Parsing subtitles..."
        } else {
            return "Almost done..."
        }
    }
}

// Dedicated section for empty state
private struct EmptySection: View {
    @Binding var showOptions: Bool
    
    var body: some View {
        Section {
            VStack(spacing: 16) {
                ContentUnavailableView(
                    "No Subtitles",
                    systemImage: "captions.bubble",
                    description: Text("Generate subtitles to get started")
                )
                Button("Generate Subtitles") {
                    showOptions = true
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }
}

// Dedicated section for subtitle list
private struct SubtitlesSection: View {
    let subtitles: [VideoSubtitle]
    let viewModel: VideoSubtitleViewModel
    @Binding var selectedSubtitle: VideoSubtitle?
    @Binding var editedText: String
    let onSave: (String) -> Void
    
    var body: some View {
        ForEach(subtitles) { subtitle in
            SubtitleRow(
                subtitle: subtitle,
                isSelected: selectedSubtitle?.id == subtitle.id,
                onSelect: {
                    selectedSubtitle = subtitle
                    editedText = subtitle.text
                }
            )
        }
        
        if let subtitle = selectedSubtitle {
            SubtitleEditPanel(
                subtitle: subtitle,
                viewModel: viewModel,
                editedText: $editedText,
                onSave: onSave
            )
        }
    }
}

private struct SubtitleRow: View {
    let subtitle: VideoSubtitle
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(subtitle.text)
                    .lineLimit(2)
                Text("\(formatDuration(subtitle.endTime - subtitle.startTime))s")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if subtitle.isEdited {
                Image(systemName: "pencil.circle.fill")
                    .foregroundStyle(.blue)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
        .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        String(format: "%.1f", duration)
    }
}

// Just extract the edit panel to its own view
private struct SubtitleEditPanel: View {
    let subtitle: VideoSubtitle
    let viewModel: VideoSubtitleViewModel
    @Binding var editedText: String
    let onSave: (String) -> Void
    @State private var showVTTPreview = false
    @State private var startTime: TimeInterval
    @State private var endTime: TimeInterval
    
    init(subtitle: VideoSubtitle, 
         viewModel: VideoSubtitleViewModel,
         editedText: Binding<String>, 
         onSave: @escaping (String) -> Void) {
        self.subtitle = subtitle
        self.viewModel = viewModel
        self._editedText = editedText
        self.onSave = onSave
        self._startTime = State(initialValue: subtitle.startTime)
        self._endTime = State(initialValue: subtitle.endTime)
    }
    
    var body: some View {
        Section {
            VStack(spacing: 12) {
                // Timing controls
                HStack {
                    VStack {
                        Text("Start")
                            .font(.caption)
                        TimeAdjustButton(time: startTime) { newTime in
                            startTime = newTime
                            Task {
                                try? await viewModel.updateTiming(
                                    for: subtitle,
                                    startTime: startTime,
                                    endTime: endTime
                                )
                            }
                        }
                    }
                    
                    Text("→")
                    
                    VStack {
                        Text("End")
                            .font(.caption)
                        TimeAdjustButton(time: endTime) { newTime in
                            endTime = newTime
                            Task {
                                try? await viewModel.updateTiming(
                                    for: subtitle,
                                    startTime: startTime,
                                    endTime: newTime
                                )
                            }
                        }
                    }
                }
                .foregroundStyle(.secondary)
                
                // Text editor with character limit
                TextField("Subtitle text", text: $editedText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(SubtitleConstants.maxLines)
                    .onChange(of: editedText) { _, newValue in
                        if newValue.count > SubtitleConstants.maxCharsPerLine * SubtitleConstants.maxLines {
                            editedText = String(newValue.prefix(SubtitleConstants.maxCharsPerLine * SubtitleConstants.maxLines))
                        }
                    }
                
                // Character count
                Text("\(editedText.count)/\(SubtitleConstants.maxCharsPerLine * SubtitleConstants.maxLines)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                // VTT Preview
                Button("Preview VTT Format") {
                    showVTTPreview = true
                }
                .sheet(isPresented: $showVTTPreview) {
                    VTTPreviewView(subtitle: subtitle)
                }
                
                // Save button
                Button("Save Changes") {
                    onSave(editedText)
                }
                .buttonStyle(.borderedProminent)
                .disabled(editedText.isEmpty || editedText == subtitle.text)
            }
            .padding()
            .background(.ultraThinMaterial)
        }
    }
}

private struct TimeAdjustButton: View {
    let time: TimeInterval
    let onUpdate: (TimeInterval) -> Void
    @State private var isFineTuning = false  // Add fine-tuning mode
    
    var body: some View {
        VStack {
            HStack {
                Button {
                    onUpdate(max(0, time - (isFineTuning ? 0.01 : 0.1)))
                } label: {
                    Image(systemName: "minus.circle")
                }
                
                Text(formatTime(time))
                    .monospacedDigit()
                
                Button {
                    onUpdate(time + (isFineTuning ? 0.01 : 0.1))
                } label: {
                    Image(systemName: "plus.circle")
                }
            }
            
            // Add fine-tuning toggle
            Toggle("Fine Adjust", isOn: $isFineTuning)
                .toggleStyle(.button)
                .font(.caption)
                .controlSize(.mini)
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 1000)
        return String(format: "%02d:%02d.%03d", minutes, seconds, milliseconds)
    }
}

// Add the missing constants
private enum SubtitleConstants {
    static let maxLines = 2
    static let maxCharsPerLine = 40
}

// Generation options sheet
private struct GenerationOptionsView: View {
    let videoURL: URL
    let onGenerate: (SubtitlePreferences) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var preferences = SubtitlePreferences.default
    @State private var isGenerating = false
    @State private var error: Error?
    
    var body: some View {
        NavigationStack {
            Form {
                if isGenerating {
                    Section {
                        HStack {
                            ProgressView()
                                .controlSize(.regular)
                            Text("Starting subtitle generation...")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Section("Preferences") {
                    Picker("Font Size", selection: $preferences.fontSize) {
                        ForEach(SubtitlePreferences.FontSize.allCases, id: \.self) { size in
                            Text(size.rawValue).tag(size)
                        }
                    }
                    
                    Picker("Color", selection: $preferences.textColor) {
                        ForEach(SubtitlePreferences.TextColor.allCases, id: \.self) { color in
                            Text(color.rawValue.capitalized).tag(color)
                        }
                    }
                    
                    Picker("Position", selection: $preferences.position) {
                        ForEach(SubtitlePreferences.Position.allCases, id: \.self) { position in
                            Text(position.rawValue.capitalized).tag(position)
                        }
                    }
                }
                
                if let error {
                    Section {
                        Text(error.localizedDescription)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Generation Options")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Generate") {
                        isGenerating = true
                        error = nil
                        
                        Task {
                            onGenerate(preferences)
                        }
                    }
                    .disabled(isGenerating)
                }
            }
            .interactiveDismissDisabled(isGenerating)
        }
    }
}

// VTT Preview View
private struct VTTPreviewView: View {
    let subtitle: VideoSubtitle
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                Text(vttFormat)
                    .font(.system(.body, design: .monospaced))
                    .padding()
            }
            .navigationTitle("VTT Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private var vttFormat: String {
        """
        WEBVTT
        
        \(formatTimestamp(subtitle.startTime)) --> \(formatTimestamp(subtitle.endTime))
        \(subtitle.text)
        """
    }
    
    private func formatTimestamp(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 1000)
        return String(format: "%02d:%02d.%03d", minutes, seconds, milliseconds)
    }
} 