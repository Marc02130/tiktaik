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
    @StateObject private var viewModel: TagSelectionViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(selectedTags: Binding<Set<String>>) {
        self._selectedTags = selectedTags
        self._viewModel = StateObject(wrappedValue: TagSelectionViewModel(selectedTags: selectedTags))
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Selected tags
            FlowLayout(spacing: 8) {
                ForEach(Array(viewModel.selectedTags), id: \.self) { tag in
                    TagChip(tag: tag) {
                        viewModel.removeTag(tag)
                    }
                }
            }
            .padding(.horizontal)
            
            // Tag input
            HStack {
                TextField("Add tag", text: $viewModel.newTag)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        viewModel.addTag()
                    }
                
                Button("Add") {
                    viewModel.addTag()
                }
                .disabled(viewModel.newTag.isEmpty)
            }
            .padding(.horizontal)
            
            // Suggestions
            if !viewModel.suggestedTags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.suggestedTags, id: \.self) { tag in
                            TagChip(tag: tag) {
                                viewModel.addSuggestedTag(tag)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            // Done button
            Button("Done") {
                dismiss()
            }
            .buttonStyle(.customPrimary)
            .padding()
        }
    }
}

struct TagChip: View {
    let tag: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(tag)
                .foregroundStyle(.white)
            
            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.white.opacity(0.8))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.accentColor)
        .clipShape(Capsule())
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
