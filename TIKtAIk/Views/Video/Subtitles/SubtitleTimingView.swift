import SwiftUI

struct SubtitleTimingView: View {
    let subtitle: VideoSubtitle
    let onUpdate: (TimeInterval, TimeInterval) -> Void
    
    @State private var startTime: TimeInterval
    @State private var endTime: TimeInterval
    @Environment(\.dismiss) private var dismiss
    
    init(subtitle: VideoSubtitle, onUpdate: @escaping (TimeInterval, TimeInterval) -> Void) {
        self.subtitle = subtitle
        self.onUpdate = onUpdate
        _startTime = State(initialValue: subtitle.startTime)
        _endTime = State(initialValue: subtitle.endTime)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Start Time") {
                    TimeSlider(time: $startTime)
                }
                
                Section("End Time") {
                    TimeSlider(time: $endTime)
                }
            }
            .navigationTitle("Edit Timing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onUpdate(startTime, endTime)
                        dismiss()
                    }
                    .disabled(startTime >= endTime)
                }
            }
        }
    }
}

private struct TimeSlider: View {
    @Binding var time: TimeInterval
    
    var body: some View {
        VStack {
            Text(timeString)
                .monospacedDigit()
            
            Slider(
                value: $time,
                in: 0...3600, // Max 1 hour
                step: 0.1
            )
        }
    }
    
    private var timeString: String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%02d:%02d.%d", minutes, seconds, milliseconds)
    }
} 