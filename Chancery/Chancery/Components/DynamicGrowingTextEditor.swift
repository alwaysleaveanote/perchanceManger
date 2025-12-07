//
//  ThemedTextEditor.swift
//  Chancery
//
//  A simple, themed text editor with placeholder support.
//

import SwiftUI

// MARK: - ThemedTextEditor

/// A simple text editor that supports theming and placeholders.
///
/// ## Features
/// - Placeholder text when empty
/// - Automatic theme support (global or character-specific via optional override)
/// - Configurable min/max height
/// - Smaller font size for better fit in forms
///
/// ## Important
/// Keyboard dismiss button should be added at the VIEW level using `.toolbar`,
/// not in individual text editors. This prevents duplicate toolbar items.
///
/// ## Usage
/// ```swift
/// // Basic usage (uses global theme)
/// ThemedTextEditor(text: $description, placeholder: "Enter description...")
///
/// // With character theme override
/// ThemedTextEditor(
///     text: $description,
///     placeholder: "Enter description...",
///     characterThemeId: character.characterThemeId
/// )
/// ```
struct ThemedTextEditor: View {
    
    // MARK: - Properties
    
    @Binding var text: String
    let placeholder: String
    var characterThemeId: String? = nil
    var minHeight: CGFloat = 44
    var maxHeight: CGFloat = 200
    var showClearButton: Bool = true
    
    @EnvironmentObject var themeManager: ThemeManager
    
    // MARK: - Theme Resolution
    
    /// Resolves the theme - uses character theme if provided, otherwise global
    private var theme: ResolvedTheme {
        themeManager.resolvedTheme(forCharacterThemeId: characterThemeId)
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Text Editor - use subheadline for smaller text
            TextEditor(text: $text)
                .font(.subheadline)
                .fontDesign(theme.fontDesign)
                .foregroundColor(theme.textPrimary)
                .scrollContentBackground(.hidden)
                .frame(minHeight: minHeight, maxHeight: maxHeight)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .padding(.trailing, showClearButton && !text.isEmpty ? 24 : 0)
            
            // Placeholder - matches text editor font
            if text.isEmpty {
                Text(placeholder)
                    .font(.subheadline)
                    .fontDesign(theme.fontDesign)
                    .foregroundColor(theme.textSecondary.opacity(0.5))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 14)
                    .allowsHitTesting(false)
            }
            
            // Clear button
            if showClearButton && !text.isEmpty {
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            text = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(theme.textSecondary.opacity(0.6))
                                .font(.system(size: 16))
                        }
                        .buttonStyle(.plain)
                        .padding(8)
                    }
                    Spacer()
                }
            }
        }
        .background(theme.backgroundTertiary)
        .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadiusSmall))
        .overlay(
            RoundedRectangle(cornerRadius: theme.cornerRadiusSmall)
                .stroke(theme.border.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - DynamicGrowingTextEditor

/// A text editor that dynamically grows to fit its content up to a maximum number of lines.
/// When content exceeds maxLines, the editor becomes scrollable.
struct DynamicGrowingTextEditor: View {
    
    @Binding var text: String
    let placeholder: String
    var minLines: Int = 1
    var maxLines: Int = 5
    var fontSize: CGFloat = 14
    var characterThemeId: String? = nil
    var showClearButton: Bool = true
    
    @EnvironmentObject var themeManager: ThemeManager
    @State private var textHeight: CGFloat = 0
    
    /// Resolves the theme - uses character theme if provided, otherwise global
    private var theme: ResolvedTheme {
        themeManager.resolvedTheme(forCharacterThemeId: characterThemeId)
    }
    
    /// Approximate line height for calculating min/max heights
    private var lineHeight: CGFloat {
        UIFont.systemFont(ofSize: fontSize).lineHeight
    }
    
    private var minHeight: CGFloat {
        max(CGFloat(minLines) * lineHeight + 16, 36)
    }
    
    private var maxHeight: CGFloat {
        max(CGFloat(maxLines) * lineHeight + 16, 80)
    }
    
    /// Calculate the height needed for the current text
    private func calculateTextHeight(for text: String, width: CGFloat) -> CGFloat {
        guard width > 0 else { return minHeight }
        
        let font = UIFont.systemFont(ofSize: fontSize)
        let constraintRect = CGSize(width: width - 24, height: .greatestFiniteMagnitude) // Account for padding
        let boundingBox = text.isEmpty ? "" : text
        let rect = (boundingBox as NSString).boundingRect(
            with: constraintRect,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        )
        return rect.height + 20 // Add padding
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                // Text Editor
                TextEditor(text: $text)
                    .font(.system(size: fontSize))
                    .fontDesign(theme.fontDesign)
                    .foregroundColor(theme.textPrimary)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .padding(.trailing, showClearButton && !text.isEmpty ? 24 : 0)
                
                // Placeholder
                if text.isEmpty {
                    Text(placeholder)
                        .font(.system(size: fontSize))
                        .fontDesign(theme.fontDesign)
                        .foregroundColor(theme.textSecondary.opacity(0.5))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 14)
                        .allowsHitTesting(false)
                }
                
                // Clear button
                if showClearButton && !text.isEmpty {
                    VStack {
                        HStack {
                            Spacer()
                            Button {
                                text = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(theme.textSecondary.opacity(0.6))
                                    .font(.system(size: 16))
                            }
                            .buttonStyle(.plain)
                            .padding(8)
                        }
                        Spacer()
                    }
                }
            }
            .background(theme.backgroundTertiary)
            .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadiusSmall))
            .overlay(
                RoundedRectangle(cornerRadius: theme.cornerRadiusSmall)
                    .stroke(theme.border.opacity(0.3), lineWidth: 1)
            )
            .onAppear {
                textHeight = calculateTextHeight(for: text, width: geometry.size.width)
            }
            .onChange(of: text) { _, newValue in
                textHeight = calculateTextHeight(for: newValue, width: geometry.size.width)
            }
        }
        .frame(height: min(max(textHeight, minHeight), maxHeight))
    }
}
