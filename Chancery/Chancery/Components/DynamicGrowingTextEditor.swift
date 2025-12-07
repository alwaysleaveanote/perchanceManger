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
        }
        .background(theme.backgroundTertiary)
        .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadiusSmall))
        .overlay(
            RoundedRectangle(cornerRadius: theme.cornerRadiusSmall)
                .stroke(theme.border.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - DynamicGrowingTextEditor (Legacy Compatibility)

/// Legacy wrapper for ThemedTextEditor - maintains backward compatibility
/// while using the new simplified implementation.
struct DynamicGrowingTextEditor: View {
    
    @Binding var text: String
    let placeholder: String
    var minLines: Int = 1
    var maxLines: Int = 10
    var fontSize: CGFloat = 14  // Default to smaller font
    var characterThemeId: String? = nil
    
    /// Approximate line height for calculating min/max heights
    private var lineHeight: CGFloat {
        UIFont.systemFont(ofSize: fontSize).lineHeight
    }
    
    var body: some View {
        ThemedTextEditor(
            text: $text,
            placeholder: placeholder,
            characterThemeId: characterThemeId,
            minHeight: max(CGFloat(minLines) * lineHeight + 12, 36),
            maxHeight: max(CGFloat(maxLines) * lineHeight + 12, 80)
        )
    }
}
