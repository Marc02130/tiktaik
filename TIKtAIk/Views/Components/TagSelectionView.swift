//
// TagSelectionView.swift
// TIKtAIk
//
// Created: 2024-02-14
// Last modified: 2024-02-14
//
// Purpose: Reusable component for tag/interest selection
// Author: Assistant
// Copyright © 2024 TIKtAIk. All rights reserved.
//

import SwiftUI

/// Reusable view for selecting multiple tags
///
/// Used for:
/// - User interests in profile
/// - Video tags in upload/edit
/// - Content categorization
///
/// Features:
/// - Tag input with search
/// - Tag suggestions
/// - Selected tags display
/// - Batch updates
struct TagSelectionView: View {
    @Binding var selectedTags: Set<String>
    @State private var viewModel: TagSelectionViewModel
    
    init(selectedTags: Binding<Set<String>>) {
        self._selectedTags = selectedTags
        self._viewModel = State(initialValue: TagSelectionViewModel(selectedTags: selectedTags.wrappedValue))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            selectedTagsSection
            tagInputSection
            suggestedTagsSection
        }
        .onChange(of: selectedTags) { _, newTags in
            viewModel.batchUpdateTags(newTags)
        }
    }
    
    // MARK: - View Sections
    
    private var selectedTagsSection: some View {
        Group {
            if viewModel.selectedTags.isEmpty {
                Text("No tags selected")
                    .foregroundStyle(.secondary)
            } else {
                TagFlowLayout(tags: Array(viewModel.selectedTags)) { tag in
                    viewModel.removeTag(tag)
                    selectedTags = viewModel.selectedTags
                }
            }
        }
    }
    
    private var tagInputSection: some View {
        HStack {
            TextField("Add interests (type to search)", text: $viewModel.newTag)
                .textFieldStyle(.roundedBorder)
                .onChange(of: viewModel.newTag) { _, query in
                    viewModel.updateSuggestions(for: query)
                }
            
            if !viewModel.newTag.isEmpty {
                Button("Add") {
                    viewModel.addTag()
                    selectedTags = viewModel.selectedTags
                }
                .disabled(viewModel.newTag.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }
    
    private var suggestedTagsSection: some View {
        Group {
            if !viewModel.suggestedTags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.suggestedTags, id: \.self) { tag in
                            SuggestionButton(tag: tag) {
                                viewModel.addSuggestedTag(tag)
                                selectedTags = viewModel.selectedTags
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct TagFlowLayout: View {
    let tags: [String]
    let onRemove: (String) -> Void
    
    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(tags, id: \.self) { tag in
                TagView(tag: tag) {
                    onRemove(tag)
                }
            }
        }
    }
}

struct TagView: View {
    let tag: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(tag)
                .font(.subheadline)
            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.systemGray6))
        .clipShape(Capsule())
    }
}

struct SuggestionButton: View {
    let tag: String
    let action: () -> Void
    
    var body: some View {
        Button(tag, action: action)
            .buttonStyle(.bordered)
            .tint(.blue)
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    // Cache the row computation results
    struct CacheData {
        var rows: [[LayoutSubviews.Element]]
    }
    
    func makeCache(subviews: Subviews) -> CacheData {
        CacheData(rows: [])
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout CacheData) -> CGSize {
        cache.rows = computeRows(proposal: proposal, subviews: subviews)
        
        var height: CGFloat = 0
        var maxWidth: CGFloat = 0
        
        for row in cache.rows {
            let rowSize = computeRowSize(row)
            height += rowSize.height
            maxWidth = max(maxWidth, rowSize.width)
        }
        
        return CGSize(width: maxWidth, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout CacheData) {
        var y = bounds.minY
        
        for row in cache.rows {
            let rowSize = computeRowSize(row)
            var x = bounds.minX
            
            for view in row {
                let viewSize = view.sizeThatFits(.unspecified)
                view.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
                x += viewSize.width + spacing
            }
            
            y += rowSize.height + spacing
        }
    }
    
    private func computeRowSize(_ row: [LayoutSubviews.Element]) -> CGSize {
        let width = row.reduce(0) { $0 + $1.sizeThatFits(.unspecified).width } + CGFloat(max(0, row.count - 1)) * spacing
        let height = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
        return CGSize(width: width, height: height)
    }
    
    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[LayoutSubviews.Element]] {
        guard !subviews.isEmpty else { return [] }
        
        var result: [[LayoutSubviews.Element]] = [[]]
        var currentX: CGFloat = 0
        var currentRow = 0
        let maxWidth = proposal.width ?? .infinity
        
        for view in subviews {
            let viewSize = view.sizeThatFits(.unspecified)
            
            if currentX + viewSize.width > maxWidth && !result[currentRow].isEmpty {
                // Start new row
                currentRow += 1
                result.append([])
                currentX = viewSize.width
            } else {
                currentX += viewSize.width + spacing
            }
            
            result[currentRow].append(view)
        }
        
        return result
    }
} 

