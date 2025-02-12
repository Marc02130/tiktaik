// Framework: Foundation - Basic functionality
import Foundation
// Framework: FirebaseFirestore - Cloud Database
import FirebaseFirestore
// Framework: FirebaseAuth - Authentication
import FirebaseAuth
// Framework: CoreGraphics - Graphics Types
import CoreGraphics
import SwiftUI

/// Service for managing user preferences
@Observable
final class UserPreferencesService {
    private let db = Firestore.firestore()
    private let auth = Auth.auth()
    
    var subtitlePreferences: SubtitlePreferences = .default
    
    func loadSubtitlePreferences() async {
        guard let userId = auth.currentUser?.uid else { return }
        
        do {
            let doc = try await db.collection("userPreferences")
                .document(userId)
                .getDocument()
            
            if let data = doc.data() {
                let fontSize = SubtitlePreferences.FontSize(
                    rawValue: data["subtitleFontSize"] as? String ?? ""
                ) ?? .medium
                
                let textColor = SubtitlePreferences.TextColor(
                    rawValue: data["subtitleTextColor"] as? String ?? ""
                ) ?? .white
                
                let position = SubtitlePreferences.Position(
                    rawValue: data["subtitlePosition"] as? String ?? ""
                ) ?? .bottom
                
                let shadowRadius = data["subtitleShadowRadius"] as? CGFloat ?? 2
                
                subtitlePreferences = SubtitlePreferences(
                    fontSize: fontSize,
                    textColor: textColor,
                    position: position,
                    shadowRadius: shadowRadius
                )
            }
        } catch {
            print("Failed to load preferences:", error)
        }
    }
    
    func updateSubtitlePreferences(_ preferences: SubtitlePreferences) async {
        guard let userId = auth.currentUser?.uid else { return }
        
        do {
            try await db.collection("userPreferences")
                .document(userId)
                .setData([
                    "subtitleFontSize": preferences.fontSize.rawValue,
                    "subtitleTextColor": preferences.textColor.rawValue,
                    "subtitlePosition": preferences.position.rawValue,
                    "subtitleShadowRadius": preferences.shadowRadius
                ], merge: true)
            
            self.subtitlePreferences = preferences
        } catch {
            print("Failed to update preferences:", error)
        }
    }
} 