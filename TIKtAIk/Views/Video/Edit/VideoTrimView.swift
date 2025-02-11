import SwiftUI
import Foundation

struct VideoTrimView: View {
    @Binding var timeRange: ClosedRange<TimeInterval>
    let duration: TimeInterval
    let thumbnails: [UIImage]
    let onPreview: (TimeInterval) -> Void
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    // Observe the view model's progress
    @ObservedObject var viewModel: VideoEditViewModel
    
    init(timeRange: Binding<ClosedRange<TimeInterval>>,
         duration: TimeInterval,
         thumbnails: [UIImage],
         onPreview: @escaping (TimeInterval) -> Void,
         onSave: @escaping () -> Void,
         viewModel: VideoEditViewModel) {
        self._timeRange = timeRange
        self.duration = duration
        self.thumbnails = thumbnails
        self.onPreview = onPreview
        self.onSave = onSave
        self.viewModel = viewModel
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // Preview thumbnail
                if let currentThumb = thumbnailForTime(timeRange.lowerBound) {
                    Image(uiImage: currentThumb)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 300)
                }
                
                TrimSlider(
                    value: $timeRange,
                    bounds: 0...duration,
                    thumbnails: thumbnails,
                    onScrub: onPreview
                )
                .padding()
                
                // Add progress view when processing
                if viewModel.progress > 0 {
                    ProgressView("Trimming video...", value: viewModel.progress, total: 1.0)
                        .padding()
                }
            }
            .padding()
            .navigationTitle("Trim Video")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .disabled(viewModel.progress > 0)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave() // VideoEditViewModel will handle validation
                        // Don't dismiss until complete
                    }
                    .disabled(viewModel.progress > 0)
                }
            }
        }
    }
    
    private func thumbnailForTime(_ time: TimeInterval) -> UIImage? {
        let index = Int((time / duration) * Double(thumbnails.count - 1))
        return thumbnails.indices.contains(index) ? thumbnails[index] : nil
    }
}
