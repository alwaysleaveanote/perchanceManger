import SwiftUI
import UIKit

/// List view showing all characters with navigation to detail
struct CharactersView: View {
    @Binding var characters: [CharacterProfile]
    let openGenerator: (String) -> Void

    @EnvironmentObject var themeManager: ThemeManager
    @State private var showingNewCharacterSheet = false
    @State private var characterToDelete: CharacterProfile? = nil
    @State private var showingDeleteConfirmation = false
    
    /// Always use global theme for the list view to prevent flash when returning from character detail
    private var globalTheme: ResolvedTheme {
        if let globalTheme = themeManager.availableThemes.first(where: { $0.id == themeManager.globalThemeId }) {
            return ResolvedTheme(source: globalTheme)
        }
        return themeManager.resolved
    }

    var body: some View {
        let theme = globalTheme
        let _ = print("[CharactersView] body - using globalTheme id: \(theme.source.id), themeManager.resolved id: \(themeManager.resolved.source.id)")
        
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
                            ForEach(characters) { character in
                                ZStack {
                                    // Hidden NavigationLink for navigation
                                    NavigationLink {
                                        CharacterDetailView(
                                            character: binding(for: character),
                                            openGenerator: openGenerator
                                        )
                                    } label: {
                                        EmptyView()
                                    }
                                    .opacity(0)
                                    
                                    // Visible row with custom theming
                                    CharacterRowView(character: character)
                                }
                                .listRowBackground(theme.backgroundSecondary)
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

    private func binding(for character: CharacterProfile) -> Binding<CharacterProfile> {
        guard let index = characters.firstIndex(where: { $0.id == character.id }) else {
            return .constant(character)
        }
        return $characters[index]
    }
}

// MARK: - Character Row View

/// A single row in the characters list
struct CharacterRowView: View {
    let character: CharacterProfile
    @EnvironmentObject var themeManager: ThemeManager
    
    /// Get the character's resolved theme (custom or global)
    private var resolvedTheme: ResolvedTheme {
        if let themeId = character.characterThemeId,
           let charTheme = themeManager.availableThemes.first(where: { $0.id == themeId }) {
            return ResolvedTheme(source: charTheme)
        }
        return themeManager.resolved
    }
    
    /// Check if character has a custom theme
    private var hasCustomTheme: Bool {
        character.characterThemeId != nil
    }
    
    var body: some View {
        let theme = resolvedTheme
        let globalTheme = themeManager.resolved
        
        HStack(spacing: 12) {
            // Thumbnail (if profileImageData exists)
            if let data = character.profileImageData,
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadiusSmall))
                    .overlay(
                        RoundedRectangle(cornerRadius: theme.cornerRadiusSmall)
                            .stroke(theme.border.opacity(0.3), lineWidth: 1)
                    )
            } else {
                // Placeholder for characters without profile image
                RoundedRectangle(cornerRadius: theme.cornerRadiusSmall)
                    .fill(theme.backgroundTertiary)
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(theme.textSecondary)
                    )
            }

            // Character name and bio preview
            VStack(alignment: .leading, spacing: 4) {
                Text(character.name)
                    .font(.headline)
                    .fontDesign(theme.fontDesign)
                    .foregroundColor(theme.textPrimary)
                
                if !character.bio.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(character.bio)
                        .font(.caption)
                        .fontDesign(theme.fontDesign)
                        .foregroundColor(theme.textSecondary)
                        .lineLimit(2)
                }
            }

            Spacer()
            
            // Themed chevron indicator
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(theme.textSecondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: globalTheme.cornerRadiusMedium)
                .fill(hasCustomTheme ? theme.background : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: globalTheme.cornerRadiusMedium)
                .stroke(hasCustomTheme ? theme.primary.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
}
