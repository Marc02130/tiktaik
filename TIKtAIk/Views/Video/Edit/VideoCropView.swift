import SwiftUI

struct VideoCropView: View {
    @Binding var cropRect: CGRect
    let thumbnail: UIImage
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var errorMessage: String?
    @State private var showError = false
    @ObservedObject var viewModel: VideoEditViewModel
    
    // Constants for crop constraints
    private let aspectRatio: CGFloat = CropConfig.aspectRatio // 9/16 for portrait
    private let minWidth: CGFloat = CropConfig.minWidth
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let imageSize = thumbnail.size
                let scale = min(geometry.size.width / imageSize.width,
                              geometry.size.height / imageSize.height)
                let scaledSize = CGSize(
                    width: imageSize.width * scale,
                    height: imageSize.height * scale
                )
                let imageFrame = CGRect(
                    x: (geometry.size.width - scaledSize.width) / 2,
                    y: (geometry.size.height - scaledSize.height) / 2,
                    width: scaledSize.width,
                    height: scaledSize.height
                )
                
                ZStack {
                    Color.black
                    
                    // Background image
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: scaledSize.width, height: scaledSize.height)
                    
                    // Crop overlay
                    CropOverlay(
                        cropRect: $cropRect,
                        imageFrame: imageFrame,
                        aspectRatio: aspectRatio,
                        minWidth: minWidth * scaledSize.width
                    )
                }
            }
            .navigationTitle("Crop Video")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if validateCrop() {
                            Task {
                                await viewModel.cropVideo()
                                if viewModel.error == nil {
                                    onSave()
                                    dismiss()
                                }
                            }
                        }
                    }
                }
                ToolbarItem(placement: .bottomBar) {
                    Button("Reset") {
                        withAnimation {
                            cropRect = CGRect(x: 0, y: 0, width: 1, height: aspectRatio)
                        }
                    }
                }
            }
            .overlay {
                if viewModel.progress > 0 && viewModel.progress < 1 {
                    ProgressView("Processing...", value: viewModel.progress)
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)
                }
            }
            .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") { viewModel.clearError() }
            } message: {
                Text(viewModel.error ?? "")
            }
        }
    }
    
    private func validateCrop() -> Bool {
        // Check minimum size
        if cropRect.width < minWidth {
            errorMessage = "Crop area is too small. Minimum width is 30% of image width."
            showError = true
            return false
        }
        
        // Check bounds
        if cropRect.minX < 0 || cropRect.maxX > 1 ||
           cropRect.minY < 0 || cropRect.maxY > 1 {
            errorMessage = "Crop area must be within image bounds."
            showError = true
            return false
        }
        
        return true
    }
}

private struct CropOverlay: View {
    @Binding var cropRect: CGRect
    let imageFrame: CGRect
    let aspectRatio: CGFloat
    let minWidth: CGFloat
    
    // Track initial states
    @State private var dragStartRect: CGRect?
    @State private var dragStartLocation: CGPoint?
    
    var body: some View {
        ZStack {
            // Debug overlay
            Rectangle()
                .stroke(Color.red, lineWidth: 1)
                .frame(width: imageFrame.width, height: imageFrame.height)
                .position(x: imageFrame.midX, y: imageFrame.midY)
            
            // Dimmed overlay
            Path { path in
                path.addRect(imageFrame)
                path.addRect(currentCropFrame)
            }
            .fill(style: FillStyle(eoFill: true))
            .foregroundColor(.black.opacity(0.5))
            
            // Crop rectangle
            Rectangle()
                .strokeBorder(.white, lineWidth: 1)
                .frame(
                    width: currentCropFrame.width,
                    height: currentCropFrame.height
                )
                .position(
                    x: currentCropFrame.midX,
                    y: currentCropFrame.midY
                )
            
            // Corner handles
            ForEach(Corner.allCases, id: \.self) { corner in
                cornerHandle(for: corner)
            }
            
            // Debug text
            VStack {
                Text("Crop: \(String(format: "%.2f,%.2f", cropRect.origin.x, cropRect.origin.y))")
                Text("Size: \(String(format: "%.2f,%.2f", cropRect.width, cropRect.height))")
            }
            .font(.caption)
            .foregroundColor(.white)
            .padding()
            .background(Color.black.opacity(0.5))
            .position(x: imageFrame.midX, y: imageFrame.minY + 40)
        }
    }
    
    private var currentCropFrame: CGRect {
        let normalizedRect = CGRect(
            x: imageFrame.minX + (cropRect.minX * imageFrame.width),
            y: imageFrame.minY + (cropRect.minY * imageFrame.height),
            width: cropRect.width * imageFrame.width,
            height: cropRect.height * imageFrame.height
        )
        return normalizedRect
    }
    
    private func updateCrop(for corner: Corner, with gesture: DragGesture.Value) {
        // Get the absolute position in normalized coordinates
        let currentLocation = CGPoint(
            x: (gesture.location.x - imageFrame.minX) / imageFrame.width,
            y: (gesture.location.y - imageFrame.minY) / imageFrame.height
        )
        
        // If this is the start of the drag, store initial positions
        if dragStartLocation == nil {
            dragStartLocation = currentLocation
            dragStartRect = cropRect
            return
        }
        
        guard let startRect = dragStartRect else { return }
        var newRect = startRect
        
        switch corner {
        case .topLeft:
            // Move entire rectangle by the drag offset
            let deltaX = currentLocation.x - dragStartLocation!.x
            let deltaY = currentLocation.y - dragStartLocation!.y
            
            newRect.origin = CGPoint(
                x: startRect.minX + deltaX,
                y: startRect.minY + deltaY
            )
            
        case .bottomRight:
            // Calculate new size based on absolute position
            let newWidth = currentLocation.x - startRect.minX
            let newHeight = currentLocation.y - startRect.minY
            
            newRect.size = CGSize(
                width: newWidth,
                height: newHeight
            )
            
        default:
            return
        }
        
        // Only check if rect is within bounds during dragging
        if newRect.minX >= 0 && newRect.maxX <= 1 &&
           newRect.minY >= 0 && newRect.maxY <= 1 {
            cropRect = newRect
        }
    }
    
    private func cornerHandle(for corner: Corner) -> some View {
        let position = cornerPosition(for: corner)
        return Circle()
            .fill(.white)
            .frame(width: 20, height: 20)
            .position(position)
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        updateCrop(for: corner, with: gesture)
                    }
                    .onEnded { _ in
                        // Clear drag state
                        dragStartLocation = nil
                        dragStartRect = nil
                    }
            )
    }
    
    private func cornerPosition(for corner: Corner) -> CGPoint {
        switch corner {
        case .topLeft:
            return CGPoint(x: currentCropFrame.minX, y: currentCropFrame.minY)
        case .topRight:
            return CGPoint(x: currentCropFrame.maxX, y: currentCropFrame.minY)
        case .bottomLeft:
            return CGPoint(x: currentCropFrame.minX, y: currentCropFrame.maxY)
        case .bottomRight:
            return CGPoint(x: currentCropFrame.maxX, y: currentCropFrame.maxY)
        }
    }
}

private enum Corner: CaseIterable {
    case topLeft, topRight, bottomLeft, bottomRight
} 