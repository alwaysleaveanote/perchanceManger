//
//  CharactersView.swift
//  PerchanceImageGenerator
//
//  Displays a list of all character profiles with navigation to detail views.
//

import SwiftUI
import UIKit

// MARK: - CharactersView

/// A list view displaying all character profiles with navigation to detail views.
///
/// Features:
/// - List of all characters with profile images and bio previews
/// - Navigation to character detail views
/// - Add new character button
/// - Swipe-to-delete with confirmation
/// - Per-character theme preview in list rows
///
/// ## Theme Handling
/// This view always uses the global theme to prevent visual flashing when
/// returning from a character detail view that uses a custom theme.
struct CharactersView: View {
    
    // MARK: - Properties
    
    /// Binding to the array of character profiles
    @Binding var characters: [CharacterProfile]
    
    /// Callback to open the Perchance generator with a prompt
    let openGenerator: (String) -> Void
    
    // MARK: - Environment & State
    
    @EnvironmentObject var themeManager: ThemeManager
    
    /// Whether the new character sheet is showing
    @State private var showingNewCharacterSheet = false
    
    /// Character pending deletion (for confirmation)
    @State private var characterToDelete: CharacterProfile? = nil
    
    /// Whether the delete confirmation alert is showing
    @State private var showingDeleteConfirmation = false
    
    // MARK: - Computed Properties
    
    /// The global theme (ignores character theme override to prevent flash)
    private var globalTheme: ResolvedTheme {
        if let theme = themeManager.availableThemes.first(where: { $0.id == themeManager.globalThemeId }) {
            return ResolvedTheme(source: theme)
        }
        return themeManager.resolved
    }
    
    // MARK: - Body
    
    var body: some View {
        let theme = globalTheme
        let _ = Logger.debug("Rendering CharactersView with theme: \(theme.source.id)", category: .ui)
        
        NavigationView {
            ZStack {
                theme.background
                    .ignoresSafeArea()
                
                List {
                    Section(header: Text("Your Characters")
                        .foregroundColor(theme.textSecondary)
                        .fontDesign(theme.fontDesign)
                    ) {
                        if characters.isEmpty {
                            Text("No characters yet. Tap + to create one.")
                                .foregroundColor(theme.textSecondary)
                                .fontDesign(theme.fontDesign)
                                .listRowBackground(theme.backgroundSecondary)
                        } else {
                            ForEach(Array(characters.enumerated()), id: \.element.id) { index, character in
                                // NavigationLink with custom row content
                                // Use .buttonStyle(.plain) to prevent default styling
                                // CharacterRowView includes its own themed chevron
                                NavigationLink {
                                    CharacterDetailView(
                                        character: $characters[index],
                                        openGenerator: openGenerator
                                    )
                                } label: {
                                    CharacterRowView(character: character)
                                }
                                .buttonStyle(.plain)
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                .listRowSeparator(.hidden)
                            }
                            .onDelete { indices in
                                if let first = indices.first {
                                    characterToDelete = characters[first]
                                    showingDeleteConfirmation = true
                                }
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Characters")
            .navigationBarTitleDisplayMode(.inline)
            .globalThemedNavigationBar()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingNewCharacterSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(theme.primary)
                    }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button {
                        KeyboardHelper.dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .sheet(isPresented: $showingNewCharacterSheet) {
                NewCharacterView { newCharacter in
                    characters.insert(newCharacter, at: 0)
                }
            }
            .alert("Delete Character?", isPresented: $showingDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    if let character = characterToDelete,
                       let index = characters.firstIndex(where: { $0.id == character.id }) {
                        characters.remove(at: index)
                    }
                    characterToDelete = nil
                }
                Button("Cancel", role: .cancel) {
                    characterToDelete = nil
                }
            } message: {
                if let character = characterToDelete {
                    Text("Are you sure you want to delete \"\(character.name)\"? This cannot be undone.")
                } else {
                    Text("Are you sure you want to delete this character?")
                }
            }
        }
    }

    // MARK: - Actions
    
    /// Handles character deletion with confirmation
    private func confirmDelete(at indices: IndexSet) {
        guard let first = indices.first else { return }
        characterToDelete = characters[first]
        showingDeleteConfirmation = true
        Logger.debug("Delete requested for character: \(characters[first].name)", category: .character)
    }
    
    /// Performs the actual deletion after confirmation
    private func deleteCharacter() {
        guard let character = characterToDelete,
              let index = characters.firstIndex(where: { $0.id == character.id }) else {
            return
        }
        
        Logger.info("Deleting character: \(character.name)", category: .character)
        characters.remove(at: index)
        characterToDelete = nil
    }
}

// MARK: - CharacterRowView

/// A single row in the characters list displaying character info with theme support.
///
/// Features:
/// - Profile image thumbnail (or placeholder)
/// - Character name and bio preview
/// - Custom theme styling when character has a theme override
/// - Navigation chevron
///
/// ## Theme Behavior
/// If the character has a custom theme set, the row displays with that theme's
/// colors and styling, providing a visual preview of the character's theme.
struct CharacterRowView: View {
    
    // MARK: - Properties
    
    /// The character to display
    let character: CharacterProfile
    
    // MARK: - Environment
    
    @EnvironmentObject var themeManager: ThemeManager
    
    // MARK: - Configuration
    
    private enum Layout {
        static let thumbnailSize: CGFloat = 50
        static let spacing: CGFloat = 12
        static let verticalPadding: CGFloat = 8
        static let horizontalPadding: CGFloat = 12
    }
    
    // MARK: - Computed Properties
    
    /// The character's resolved theme (custom or global)
    /// Uses the new simplified ThemeManager helper
    private var resolvedTheme: ResolvedTheme {
        themeManager.resolvedTheme(forCharacterThemeId: character.characterThemeId)
    }
    
    /// Whether this character has a custom theme
    private var hasCustomTheme: Bool {
        character.hasCustomTheme
    }
    
    // MARK: - Body
    
    var body: some View {
        let theme = resolvedTheme
        
        HStack(spacing: Layout.spacing) {
            thumbnailView(theme: theme)
            characterInfoView(theme: theme)
            Spacer()
            // Custom themed chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(theme.textSecondary)
        }
        .padding(.vertical, Layout.verticalPadding)
        .padding(.horizontal, Layout.horizontalPadding)
        .background(rowBackground(theme: theme))
        .overlay(rowBorder(theme: theme))
    }
    
    // MARK: - Subviews
    
    /// Profile image thumbnail or placeholder
    @ViewBuilder
    private func thumbnailView(theme: ResolvedTheme) -> some View {
        if let data = character.profileImageData,
           let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: Layout.thumbnailSize, height: Layout.thumbnailSize)
                .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadiusSmall))
                .overlay(
                    RoundedRectangle(cornerRadius: theme.cornerRadiusSmall)
                        .stroke(theme.border.opacity(0.3), lineWidth: 1)
                )
        } else {
            // Placeholder
            RoundedRectangle(cornerRadius: theme.cornerRadiusSmall)
                .fill(theme.backgroundTertiary)
                .frame(width: Layout.thumbnailSize, height: Layout.thumbnailSize)
                .overlay(
                    Image(systemName: "person.fill")
                        .foregroundColor(theme.textSecondary)
                )
        }
    }
    
    /// Character name and bio preview
    private func characterInfoView(theme: ResolvedTheme) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(character.name)
                .font(.headline)
                .fontDesign(theme.fontDesign)
                .foregroundColor(theme.textPrimary)
            
            if let bio = character.bio.nonEmpty {
                Text(bio)
                    .font(.caption)
                    .fontDesign(theme.fontDesign)
                    .foregroundColor(theme.textSecondary)
                    .lineLimit(2)
            }
        }
    }
    
    /// Row background (highlighted for custom theme)
    private func rowBackground(theme: ResolvedTheme) -> some View {
        RoundedRectangle(cornerRadius: theme.cornerRadiusMedium)
            .fill(hasCustomTheme ? theme.background : Color.clear)
    }
    
    /// Row border (visible for custom theme)
    private func rowBorder(theme: ResolvedTheme) -> some View {
        RoundedRectangle(cornerRadius: theme.cornerRadiusMedium)
            .stroke(hasCustomTheme ? theme.primary.opacity(0.3) : Color.clear, lineWidth: 1)
    }
}
