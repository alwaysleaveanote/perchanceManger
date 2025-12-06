import SwiftUI
import UIKit

/// A reusable prompt preview section with copy button
struct PromptPreviewSection: View {
    let composedPrompt: String
    var height: CGFloat = 250
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        let theme = themeManager.resolved
        
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Prompt Preview")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .fontDesign(theme.fontDesign)
                    .foregroundColor(theme.textPrimary)

                Spacer()

                Button {
                    UIPasteboard.general.string = composedPrompt
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.on.doc")
                        Text("Copy")
                    }
                    .font(.caption)
                    .foregroundColor(theme.primary)
                }
            }

            ZStack {
                RoundedRectangle(cornerRadius: theme.cornerRadiusSmall)
                    .fill(theme.backgroundTertiary)
                RoundedRectangle(cornerRadius: theme.cornerRadiusSmall)
                    .stroke(theme.border.opacity(0.3), lineWidth: 1)

                ScrollView {
                    Text(composedPrompt)
                        .font(.footnote)
                        .fontDesign(theme.fontDesign)
                        .foregroundColor(theme.textSecondary)
                        .multilineTextAlignment(.leading)
                        .padding(12)
                }
            }
            .frame(maxHeight: min(height, 250))
        }
    }
}
