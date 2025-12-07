//
//  CharactersView.swift
//  Chancery
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
    
    /// Character ID to navigate to (for deep linking)
    @Binding var navigateToCharacterId: UUID?
    
    /// Prompt ID to navigate to (for deep linking to specific prompt)
    @Binding var navigateToPromptId: UUID?
    
    // MARK: - Environment & State
    
    @EnvironmentObject var themeManager: ThemeManager
    
    /// Whether the new character sheet is showing
    @State private var showingNewCharacterSheet = false
    
    /// Character pending deletion (for confirmation)
    @State private var characterToDelete: CharacterProfile? = nil
    
    /// Whether the delete confirmation alert is showing
    @State private var showingDeleteConfirmation = false
    
    /// Search text for filtering characters
    @State private var searchText = ""
    
    // MARK: - Computed Properties
    
    /// Filtered characters based on search text
    private var filteredCharacters: [CharacterProfile] {
        if searchText.isEmpty {
            return characters
        }
        let lowercasedSearch = searchText.lowercased()
        return characters.filter { character in
            character.name.lowercased().contains(lowercasedSearch)
        }
    }
    
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
                
                VStack(spacing: 0) {
                    // Search bar
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(theme.textSecondary)
                        TextField("Search characters...", text: $searchText)
                            .font(.body)
                            .foregroundColor(theme.textPrimary)
                        
                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(theme.textSecondary)
                            }
                        }
                    }
                    .padding(12)
                    .background(theme.backgroundTertiary)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(theme.background)
                    
                    List {
                        Section(header: Text("Your Characters")
                            .foregroundColor(theme.textSecondary)
                            .fontDesign(theme.fontDesign)
                        ) {
                            if characters.isEmpty {
                                VStack(spacing: 16) {
                                    Text("No characters yet")
                                        .font(.headline)
                                        .foregroundColor(theme.textPrimary)
                                        .fontDesign(theme.fontDesign)
                                    
                                    Text("Create your first character or generate a test character to get started.")
                                        .font(.subheadline)
                                        .foregroundColor(theme.textSecondary)
                                        .fontDesign(theme.fontDesign)
                                        .multilineTextAlignment(.center)
                                    
                                    HStack(spacing: 12) {
                                        Button {
                                            showingNewCharacterSheet = true
                                        } label: {
                                            HStack {
                                                Image(systemName: "plus")
                                                Text("New Character")
                                            }
                                            .font(.subheadline.weight(.medium))
                                            .foregroundColor(theme.textOnPrimary)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 10)
                                            .background(theme.primary)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                            .contentShape(Rectangle())
                                        }
                                        .buttonStyle(.plain)
                                        
                                        Button {
                                            generateTestCharacter()
                                        } label: {
                                            HStack {
                                                Image(systemName: "dice")
                                                Text("Generate")
                                            }
                                            .font(.subheadline.weight(.medium))
                                            .foregroundColor(theme.primary)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 10)
                                            .background(theme.primary.opacity(0.15))
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                            .contentShape(Rectangle())
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                                .listRowBackground(theme.backgroundSecondary)
                            } else if filteredCharacters.isEmpty {
                                Text("No characters match \"\(searchText)\"")
                                    .foregroundColor(theme.textSecondary)
                                    .fontDesign(theme.fontDesign)
                                    .listRowBackground(theme.backgroundSecondary)
                            } else {
                                ForEach(filteredCharacters) { character in
                                    // Find the actual index in the original array for binding
                                    if let index = characters.firstIndex(where: { $0.id == character.id }) {
                                        // Use NavigationLink with EmptyView label to hide default chevron
                                        // CharacterRowView provides the visible content with custom themed chevron
                                        ZStack {
                                            NavigationLink {
                                                CharacterDetailView(
                                                    character: $characters[index],
                                                    openGenerator: openGenerator
                                                )
                                            } label: {
                                                EmptyView()
                                            }
                                            .opacity(0)
                                            
                                            CharacterRowView(character: character)
                                        }
                                        .listRowBackground(Color.clear)
                                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                        .listRowSeparator(.hidden)
                                    }
                                }
                                .onDelete { indices in
                                    // Map filtered indices back to original array
                                    let charactersToDelete = indices.compactMap { filteredCharacters.indices.contains($0) ? filteredCharacters[$0] : nil }
                                    if let first = charactersToDelete.first {
                                        characterToDelete = first
                                        showingDeleteConfirmation = true
                                    }
                                }
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .listStyle(.insetGrouped)
                    
                    // Generate Test Character button at bottom
                    if !characters.isEmpty {
                        Button {
                            generateTestCharacter()
                        } label: {
                            HStack {
                                Image(systemName: "dice")
                                Text("Generate Random Character")
                            }
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(theme.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(theme.primary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    }
                }
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
            .background(
                // Hidden NavigationLink for programmatic navigation from Home
                Group {
                    if let id = navigateToCharacterId,
                       let index = characters.firstIndex(where: { $0.id == id }) {
                        NavigationLink(
                            destination: CharacterDetailView(
                                character: $characters[index],
                                openGenerator: openGenerator,
                                initialPromptId: navigateToPromptId
                            )
                            // Force view recreation when character or prompt changes
                            .id("\(id.uuidString)-\(navigateToPromptId?.uuidString ?? "none")"),
                            isActive: Binding(
                                get: { navigateToCharacterId != nil },
                                set: { if !$0 { 
                                    navigateToCharacterId = nil
                                    navigateToPromptId = nil
                                } }
                            )
                        ) {
                            EmptyView()
                        }
                        .hidden()
                    }
                }
            )
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
    
    /// Generates a random test character for demo/testing purposes
    private func generateTestCharacter() {
        let testCharacter = CharacterProfile.generateTestCharacter(availableThemes: themeManager.availableThemes)
        characters.insert(testCharacter, at: 0)
        Logger.info("Generated test character: \(testCharacter.name)", category: .character)
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
    /// If no custom theme, falls back to global theme
    private var resolvedTheme: ResolvedTheme {
        themeManager.resolvedTheme(forCharacterThemeId: character.characterThemeId)
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
    
    /// Row background - always shows the character's theme background
    private func rowBackground(theme: ResolvedTheme) -> some View {
        RoundedRectangle(cornerRadius: theme.cornerRadiusMedium)
            .fill(theme.backgroundSecondary)
    }
    
    /// Row border - subtle border using the character's theme
    private func rowBorder(theme: ResolvedTheme) -> some View {
        RoundedRectangle(cornerRadius: theme.cornerRadiusMedium)
            .stroke(theme.border.opacity(0.3), lineWidth: 1)
    }
}
