import Foundation

struct UserVideoMetadata: Codable, Equatable {
    let id: String
    var title: String              // Required
    var description: String        // Required
    var creatorType: CreatorType   // Required
    var group: String              // Required (genre/subject/cuisine/etc)
    var customFieldsJSON: String   // JSON string for Firestore
    let createdAt: Date
    let updatedAt: Date
    
    enum CreatorType: String, Codable, CaseIterable {
        case other = "Other"
        case food = "Chef/Food"
        case fitness = "Fitness"
        case educational = "Educational"
        case comedy = "Comedy"
        case beauty = "Beauty/Makeup"
        case music = "Music"
    }
    
    // Computed property for working with customFields
    var customFields: [String: String] {
        get {
            guard let data = customFieldsJSON.data(using: .utf8),
                  let dict = try? JSONDecoder().decode([String: String].self, from: data)
            else { return [:] }
            return dict
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
               let json = String(data: data, encoding: .utf8) {
                customFieldsJSON = json
            }
        }
    }
} 