//
//  CollapsibleSection.swift
//  Chancery
//
//  A reusable collapsible section component with themed styling.
//  Used for settings pages and other expandable content areas.
//

import SwiftUI

// MARK: - CollapsibleSection

/// A themed collapsible section with a header, optional description, and expandable content.
///
/// This component provides a consistent UI pattern for expandable sections throughout the app.
/// It includes:
/// - A tappable header with title and chevron indicator
/// - Optional description text shown when expanded
/// - Customizable content wrapped in a themed card
///
/// ## Usage
/// ```swift
/// @State private var isExpanded = false
///
/// CollapsibleSection(
///     title: "Settings",
///     description: "Configure your preferences",
///     isExpanded: $isExpanded
/// ) {
///     // Your content here
///     Text("Content")
/// }
/// ```
struct CollapsibleSection<Content: View>: View {
    
    // MARK: - Properties
    
    /// The title displayed in the header
    let title: String
    
    /// Optional description shown below the header when expanded
    let description: String?
    
    /// Binding to control the expanded state
    @Binding var isExpanded: Bool
    
    /// Whether to wrap content in a card with background
    let showCard: Bool
    
    /// The content to display when expanded
    @ViewBuilder let content: () -> Content
    
    // MARK: - Environment
    
    @EnvironmentObject var themeManager: ThemeManager
    
    // MARK: - Initialization
    
    /// Creates a new collapsible section
    /// - Parameters:
    ///   - title: The header title
    ///   - description: Optional description text
    ///   - isExpanded: Binding to control expansion state
    ///   - showCard: Whether to wrap content in a card (default: true)
    ///   - content: The content to show when expanded
    init(
        title: String,
        description: String? = nil,
        isExpanded: Binding<Bool>,
        showCard: Bool = true,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.description = description
        self._isExpanded = isExpanded
        self.showCard = showCard
        self.content = content
    }
    
    // MARK: - Body
    
    var body: some View {
        let theme = themeManager.resolved
        
        VStack(alignment: .leading, spacing: 8) {
            // Header button
            headerButton(theme: theme)
            
            // Expanded content
            if isExpanded {
                // Description text (if provided)
                if let description = description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                        .padding(.bottom, 8)
                }
                
                // Content (optionally wrapped in card)
                if showCard {
                    contentCard(theme: theme)
                } else {
                    content()
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private func headerButton(theme: ResolvedTheme) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                isExpanded.toggle()
            }
        }) {
            HStack {
                Text(title)
                    .font(.title3)
                    .bold()
                    .fontDesign(theme.fontDesign)
                    .foregroundColor(theme.textPrimary)
                
                Spacer()
                
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.subheadline)
                    .foregroundColor(theme.textSecondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    private func contentCard(theme: ResolvedTheme) -> some View {
        content()
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: theme.cornerRadiusMedium)
                    .fill(theme.backgroundSecondary)
            )
    }
}

// MARK: - Character-Themed Variant

/// A collapsible section that uses character-specific theming.
///
/// Use this variant when displaying sections within a character's detail view
/// to ensure the section matches the character's custom theme.
struct CharacterThemedCollapsibleSection<Content: View>: View {
    
    // MARK: - Properties
    
    let title: String
    let description: String?
    @Binding var isExpanded: Bool
    let showCard: Bool
    let characterThemeId: String?
    @ViewBuilder let content: () -> Content
    
    @EnvironmentObject var themeManager: ThemeManager
    
    // MARK: - Initialization
    
    init(
        title: String,
        description: String? = nil,
        isExpanded: Binding<Bool>,
        showCard: Bool = true,
        characterThemeId: String?,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.description = description
        self._isExpanded = isExpanded
        self.showCard = showCard
        self.characterThemeId = characterThemeId
        self.content = content
    }
    
    // MARK: - Body
    
    var body: some View {
        let theme = themeManager.resolvedTheme(forCharacterThemeId: characterThemeId)
        
        VStack(alignment: .leading, spacing: 8) {
            // Header button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(title)
                        .font(.title3)
                        .bold()
                        .fontDesign(theme.fontDesign)
                        .foregroundColor(theme.textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.subheadline)
                        .foregroundColor(theme.textSecondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                if let description = description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                        .padding(.bottom, 8)
                }
                
                if showCard {
                    content()
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: theme.cornerRadiusMedium)
                                .fill(theme.backgroundSecondary)
                        )
                } else {
                    content()
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            CollapsibleSection(
                title: "App Theme",
                description: "Choose a visual theme for the entire app.",
                isExpanded: .constant(true)
            ) {
                Text("Theme picker content here")
                    .padding()
            }
            
            CollapsibleSection(
                title: "Collapsed Section",
                description: "This section is collapsed.",
                isExpanded: .constant(false)
            ) {
                Text("Hidden content")
            }
        }
        .padding()
    }
    .environmentObject(ThemeManager())
}
