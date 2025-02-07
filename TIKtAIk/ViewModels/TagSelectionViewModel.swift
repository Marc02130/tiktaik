import SwiftUI

final class TagSelectionViewModel: ObservableObject {
    @Published private(set) var selectedTags: Set<String>
    @Published var newTag: String = ""
    @Published private(set) var suggestedTags: [String] = []
    private var updateParent: (Set<String>) -> Void
    
    private let commonTags = [
        "comedy", "dance", "music", "food", "travel", 
        "fitness", "gaming", "education", "tech", "fashion",
        "sports", "lifestyle", "art", "beauty", "pets",
        "cooking", "diy", "nature", "science", "business"
    ]
    
    init(selectedTags: Binding<Set<String>>) {
        self.selectedTags = selectedTags.wrappedValue
        self.updateParent = { selectedTags.wrappedValue = $0 }
    }
    
    func updateSuggestions(for query: String) {
        let query = query.lowercased().trimmingCharacters(in: .whitespaces)
        // Only show suggestions for 3+ characters
        if query.count < 3 {
            suggestedTags = []
            return
        }
        
        suggestedTags = commonTags
            .filter { $0.contains(query) && !selectedTags.contains($0) }
            .prefix(5)
            .sorted()
    }
    
    func addTag() {
        let tag = newTag.lowercased().trimmingCharacters(in: .whitespaces)
        if !tag.isEmpty {
            selectedTags.insert(tag)
            updateParent(selectedTags)
            newTag = ""
            suggestedTags = []
        }
    }
    
    func addSuggestedTag(_ tag: String) {
        selectedTags.insert(tag)
        updateParent(selectedTags)
        newTag = ""
        suggestedTags = []
    }
    
    func removeTag(_ tag: String) {
        selectedTags.remove(tag)
        updateParent(selectedTags)
    }
    
    func batchUpdateTags(_ tags: Set<String>) {
        selectedTags = tags
        updateParent(tags)
    }
} 