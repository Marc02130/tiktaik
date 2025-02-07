import SwiftUI

struct InteractionButton: View {
    let icon: String
    let count: Int
    var isActive: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(isActive ? .red : .white)
                
                Text("\(count)")
                    .font(.caption)
                    .bold()
                    .foregroundStyle(.white)
            }
        }
        .shadow(radius: 2)
    }
} 