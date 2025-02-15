import SwiftUI

struct VideoMetadataForm: View {
    @Binding var usermetadata: UserVideoMetadata
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    @State private var showMetadataSelection = false
    @State private var showAddField = false
    @State private var newFieldKey = ""
    @State private var newFieldValue = ""
    
    var body: some View {
        Form {
            Section("Video Type") {
                if let profile = profileViewModel.userProfile {
                    Text("Your creator type: \(profile.creatorType?.rawValue ?? "Other")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Picker("Video Type", selection: $usermetadata.creatorType) {
                    ForEach(UserVideoMetadata.CreatorType.allCases, id: \.self) { type in
                        Text(type.rawValue)
                            .tag(type)
                    }
                }
            }
            
            Section("Video Group") {
                TextField("Group", text: $usermetadata.group)
            }

            Section("Custom Fields") {
                ForEach(Array(usermetadata.customFields.keys), id: \.self) { key in
                    HStack {
                        TextField(key, text: Binding(
                            get: { key },
                            set: { newKey in
                                if newKey != key {
                                    // Save the old value
                                    let value = usermetadata.customFields[key] ?? ""
                                    // Remove old key
                                    usermetadata.customFields.removeValue(forKey: key)
                                    // Add new key with old value
                                    usermetadata.customFields[newKey] = value
                                }
                            }
                        ))
                        TextField("Value", text: Binding(
                            get: { usermetadata.customFields[key] ?? "" },
                            set: { usermetadata.customFields[key] = $0 }
                        ))
                        
                        Button(role: .destructive) {
                            usermetadata.customFields.removeValue(forKey: key)
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
            print("UserVideoMetadataForm appeared with metadata:", usermetadata)
            print("Custom fields:", usermetadata.customFields)
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
                                usermetadata.customFields[newFieldKey] = newFieldValue
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