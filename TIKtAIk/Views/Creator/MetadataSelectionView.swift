import SwiftUI

struct MetadataSelectionView: View {
    @StateObject private var viewModel: VideoMetadataViewModel
    @Environment(\.dismiss) private var dismiss
    let creatorType: VideoMetadata.CreatorType
    
    init(customFields: Binding<[String: String]>, creatorType: VideoMetadata.CreatorType) {
        self._viewModel = StateObject(wrappedValue: VideoMetadataViewModel(customFields: customFields))
        self.creatorType = creatorType
    }
    
    // Get field keys based on creator type
    var fieldKeys: [String] {
        switch creatorType {
        case .food:
            return ["ingredients", "cookingTime", "cuisineType"]
        case .fitness:
            return ["muscleGroups", "equipment", "duration"]
        case .educational:
            return ["subject", "level", "keyPoints"]
        case .comedy:
            return ["genre", "contentRating", "tags"]
        case .beauty:
            return ["skillLevel", "products", "techniques"]
        case .music:
            return ["genre", "instruments", "isOriginal"]
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                ForEach(fieldKeys, id: \.self) { key in
                    Section(key.capitalized) {
                        TextField("Enter \(key)", text: Binding(
                            get: { viewModel.customFields[key] ?? "" },
                            set: { viewModel.updateField(key: key, value: $0) }
                        ))
                    }
                }
            }
            .navigationTitle("Additional Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
} 