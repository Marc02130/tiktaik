import SwiftUI

final class VideoMetadataViewModel: ObservableObject {
    @Published private(set) var customFields: [String: String]
    private var updateParent: ([String: String]) -> Void
    
    init(customFields: Binding<[String: String]>) {
        self.customFields = customFields.wrappedValue
        self.updateParent = { customFields.wrappedValue = $0 }
    }
    
    func updateField(key: String, value: String) {
        customFields[key] = value
        updateParent(customFields)
    }
} 