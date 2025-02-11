import SwiftUI
import UIKit

struct TrimSlider: View {
    @Binding var value: ClosedRange<TimeInterval>
    let bounds: ClosedRange<TimeInterval>
    let thumbnails: [UIImage]
    let onScrub: (TimeInterval) -> Void
    
    // Simple state for UI feedback
    @State private var isDragging = false
    
    var body: some View {
        VStack(spacing: 8) {
            // Show current time values
            HStack {
                Text(String(format: "%.1fs", value.lowerBound))
                Spacer()
                Text(String(format: "%.1fs", value.upperBound))
            }
            .font(.caption)
            
            // Thumbnail strip
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Thumbnails
                    HStack(spacing: 0) {
                        ForEach(thumbnails.indices, id: \.self) { index in
                            Image(uiImage: thumbnails[index])
                                .resizable()
                                .scaledToFill()
                        }
                    }
                    .frame(height: 44)
                    
                    // Selection overlay
                    Rectangle()
                        .fill(.blue.opacity(0.3))
                        .frame(width: selectionWidth(in: geometry))
                        .offset(x: selectionOffset(in: geometry))
                }
            }
            .frame(height: 44)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // Start time slider
            Slider(
                value: Binding(
                    get: { value.lowerBound },
                    set: { newValue in
                        if newValue < value.upperBound {
                            value = newValue...value.upperBound
                            onScrub(newValue)
                        }
                    }
                ),
                in: bounds
            )
            
            // End time slider
            Slider(
                value: Binding(
                    get: { value.upperBound },
                    set: { newValue in
                        if newValue > value.lowerBound {
                            value = value.lowerBound...newValue
                            onScrub(newValue)
                        }
                    }
                ),
                in: bounds
            )
        }
    }
    
    private func selectionOffset(in geometry: GeometryProxy) -> CGFloat {
        let boundsRange = bounds.upperBound - bounds.lowerBound
        let percentage = (value.lowerBound - bounds.lowerBound) / boundsRange
        return geometry.size.width * CGFloat(percentage)
    }
    
    private func selectionWidth(in geometry: GeometryProxy) -> CGFloat {
        let boundsRange = bounds.upperBound - bounds.lowerBound
        let percentage = (value.upperBound - value.lowerBound) / boundsRange
        return geometry.size.width * CGFloat(percentage)
    }
}

enum Edge {
    case leading, trailing
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
} 