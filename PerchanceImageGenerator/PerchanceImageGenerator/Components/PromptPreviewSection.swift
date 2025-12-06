//
//  PromptPreviewSection.swift
//  PerchanceImageGenerator
//
//  A reusable component for displaying a composed prompt with copy functionality.
//

import SwiftUI
import UIKit

// MARK: - PromptPreviewSection

/// A themed section displaying a composed prompt with copy-to-clipboard functionality.
///
/// Shows the full composed prompt text in a scrollable container with a header
/// and copy button. Useful for previewing the final prompt before generation.
///
/// ## Features
/// - Scrollable text area for long prompts
/// - One-tap copy to clipboard
/// - Themed appearance matching the current app theme
/// - Configurable maximum height
///
/// ## Usage
/// ```swift
/// PromptPreviewSection(
///     composedPrompt: prompt.composedPrompt,
///     height: 200
/// )
/// ```
struct PromptPreviewSection: View {
    
    // MARK: - Properties
    
    /// The composed prompt text to display
    let composedPrompt: String
    
    /// Maximum height for the preview area (defaults to 250)
    var maxHeight: CGFloat = 250
    
    /// Optional character theme ID for character-specific theming
    var characterThemeId: String? = nil
    
    // MARK: - Environment
    
    @EnvironmentObject var themeManager: ThemeManager
    
    // MARK: - Theme Resolution
    
    private var theme: ResolvedTheme {
        themeManager.resolvedTheme(forCharacterThemeId: characterThemeId)
    }
    
    // MARK: - Body
    
    var body: some View {
        let theme = self.theme
        
        VStack(alignment: .leading, spacing: 8) {
            headerView(theme: theme)
            previewContainer(theme: theme)
        }
    }
    
    // MARK: - Subviews
    
    /// Header with title and copy button
    private func headerView(theme: ResolvedTheme) -> some View {
        HStack {
            Text("Prompt Preview")
                .font(.subheadline)
                .fontWeight(.semibold)
                .fontDesign(theme.fontDesign)
                .foregroundColor(theme.textPrimary)
            
            Spacer()
            
            copyButton(theme: theme)
        }
    }
    
    /// Copy to clipboard button
    private func copyButton(theme: ResolvedTheme) -> some View {
        Button {
            copyToClipboard()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "doc.on.doc")
                Text("Copy")
            }
            .font(.caption)
            .foregroundColor(theme.primary)
        }
    }
    
    /// Scrollable prompt text container
    private func previewContainer(theme: ResolvedTheme) -> some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: theme.cornerRadiusSmall)
                .fill(theme.backgroundTertiary)
            
            // Border
            RoundedRectangle(cornerRadius: theme.cornerRadiusSmall)
                .stroke(theme.border.opacity(0.3), lineWidth: 1)
            
            // Content
            ScrollView {
                Text(composedPrompt)
                    .font(.footnote)
                    .fontDesign(theme.fontDesign)
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
            }
        }
        .frame(maxHeight: maxHeight)
    }
    
    // MARK: - Actions
    
    /// Copies the composed prompt to the system clipboard
    private func copyToClipboard() {
        Logger.debug("Copying prompt to clipboard (\(composedPrompt.count) characters)", category: .prompt)
        UIPasteboard.general.string = composedPrompt
    }
}
