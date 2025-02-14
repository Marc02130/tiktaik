import SwiftUI

struct VideoMetadataForm: View {
    @Binding var metadata: VideoMetadata
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    @State private var showMetadataSelection = false
    @State private var showAddField = false
    @State private var newFieldKey = ""
    @State private var newFieldValue = ""
    
    var body: some View {
        Form {
            Section("Group/Category") {
                if let profile = profileViewModel.userProfile {
                    Text("Your creator type: \(profile.creatorType?.rawValue ?? "Not set")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Picker("Video Type", selection: $metadata.creatorType) {
                    ForEach(VideoMetadata.CreatorType.allCases, id: \.self) { type in
                        Text(type.rawValue)
                            .tag(type)
                    }
                }
            }
            
            Section("Custom Fields") {
                ForEach(Array(metadata.customFields.keys), id: \.self) { key in
                    HStack {
                        TextField(key, text: Binding(
                            get: { metadata.customFields[key] ?? "" },
                            set: { metadata.customFields[key] = $0 }
                        ))
                        
                        Button(role: .destructive) {
                            metadata.customFields.removeValue(forKey: key)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                        }
                    }
                }
                
                Button("Add Field") {
                    showAddField = true
                }
            }
        }
        .onAppear {
            // Debug print to verify metadata is loaded
            #if DEBUG
            print("VideoMetadataForm appeared with metadata:", metadata)
            print("Custom fields:", metadata.customFields)
            #endif
        }
        .sheet(isPresented: $showAddField) {
            NavigationStack {
                Form {
                    TextField("Field Name", text: $newFieldKey)
                    TextField("Value", text: $newFieldValue)
                }
                .navigationTitle("Add Metadata Field")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showAddField = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") {
                            if !newFieldKey.isEmpty {
                                metadata.customFields[newFieldKey] = newFieldValue
                                newFieldKey = ""
                                newFieldValue = ""
                                showAddField = false
                            }
                        }
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }
}

// Helper view for custom fields
struct CustomFieldList: View {
    @Binding var fields: [String: String]
    let keys: [String]
    
    var body: some View {
        ForEach(keys, id: \.self) { key in
            TextField(key.capitalized, text: Binding(
                get: { fields[key] ?? "" },
                set: { fields[key] = $0 }
            ))
        }
    }
} 