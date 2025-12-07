//
//  MultiCharacterPickerSheet.swift
//  Chancery
//
//  A sheet for selecting multiple characters to add a prompt to.
//

import SwiftUI

/// Sheet for selecting multiple characters to add a prompt to
struct MultiCharacterPickerSheet: View {
    let characters: [CharacterProfile]
    let prompt: SavedPrompt
    let onComplete: ([CharacterProfile]) -> Void
    
    /// Optional: Exclude a specific character (e.g., the current character when duplicating)
    var excludeCharacterId: UUID? = nil
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var selectedCharacterIds: Set<UUID> = []
    @State private var searchText = ""
    
    private var availableCharacters: [CharacterProfile] {
        characters.filter { character in
            if let excludeId = excludeCharacterId, character.id == excludeId {
                return false
            }
            return true
        }
    }
    
    private var filteredCharacters: [CharacterProfile] {
        if searchText.isEmpty {
            return availableCharacters
        }
        let lowercasedSearch = searchText.lowercased()
        return availableCharacters.filter { character in
            character.name.lowercased().contains(lowercasedSearch)
        }
    }
    
    private var selectedCharacters: [CharacterProfile] {
        availableCharacters.filter { selectedCharacterIds.contains($0.id) }
    }
    
    var body: some View {
        let theme = themeManager.resolved
        
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                searchBar(theme: theme)
                
                // Selection controls
                selectionControls(theme: theme)
                
                // Character list
                characterList(theme: theme)
                
                // Add button
                addButton(theme: theme)
            }
            .themedBackground()
            .navigationTitle("Add to Characters")
            .navigationBarTitleDisplayMode(.inline)
            .themedNavigationBar()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(theme.primary)
                }
            }
        }
    }
    
    // MARK: - Search Bar
    
    private func searchBar(theme: ResolvedTheme) -> some View {
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
        .background(theme.backgroundSecondary)
    }
    
    // MARK: - Selection Controls
    
    private func selectionControls(theme: ResolvedTheme) -> some View {
        HStack {
            Text("\(selectedCharacterIds.count) selected")
                .font(.subheadline)
                .foregroundColor(theme.textSecondary)
            
            Spacer()
            
            Button("Select All") {
                selectedCharacterIds = Set(filteredCharacters.map { $0.id })
            }
            .font(.subheadline.weight(.medium))
            .foregroundColor(theme.primary)
            .disabled(filteredCharacters.isEmpty)
            
            Text("•")
                .foregroundColor(theme.textSecondary)
            
            Button("Clear") {
                selectedCharacterIds.removeAll()
            }
            .font(.subheadline.weight(.medium))
            .foregroundColor(theme.primary)
            .disabled(selectedCharacterIds.isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(theme.backgroundSecondary)
    }
    
    // MARK: - Character List
    
    private func characterList(theme: ResolvedTheme) -> some View {
        List {
            if availableCharacters.isEmpty {
                Text("No other characters available")
                    .foregroundColor(theme.textSecondary)
                    .fontDesign(theme.fontDesign)
            } else if filteredCharacters.isEmpty {
                Text("No results for \"\(searchText)\"")
                    .foregroundColor(theme.textSecondary)
                    .fontDesign(theme.fontDesign)
            } else {
                ForEach(filteredCharacters) { character in
                    characterRow(character: character, theme: theme)
                        .listRowBackground(theme.backgroundSecondary)
                }
            }
        }
        .themedList()
    }
    
    private func characterRow(character: CharacterProfile, theme: ResolvedTheme) -> some View {
        let isSelected = selectedCharacterIds.contains(character.id)
        
        return Button {
            if isSelected {
                selectedCharacterIds.remove(character.id)
            } else {
                selectedCharacterIds.insert(character.id)
            }
        } label: {
            HStack(spacing: 12) {
                // Profile image
                if let imageData = character.profileImageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())
                } else {
                    ZStack {
                        Circle()
                            .fill(theme.primary.opacity(0.15))
                            .frame(width: 44, height: 44)
                        
                        Text(character.name.prefix(1).uppercased())
                            .font(.headline)
                            .foregroundColor(theme.primary)
                    }
                }
                
                // Character info
                VStack(alignment: .leading, spacing: 2) {
                    Text(character.name.isEmpty ? "Unnamed Character" : character.name)
                        .font(.subheadline.weight(.medium))
                        .fontDesign(theme.fontDesign)
                        .foregroundColor(theme.textPrimary)
                    
                    Text("\(character.prompts.count) prompt\(character.prompts.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                }
                
                Spacer()
                
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? theme.primary : theme.textSecondary.opacity(0.5))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Add Button
    
    private func addButton(theme: ResolvedTheme) -> some View {
        VStack(spacing: 0) {
            Divider()
                .background(theme.divider)
            
            Button {
                onComplete(selectedCharacters)
                dismiss()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.headline)
                    Text(selectedCharacterIds.count == 1 
                         ? "Add to 1 Character" 
                         : "Add to \(selectedCharacterIds.count) Characters")
                        .font(.headline.weight(.semibold))
                }
                .foregroundColor(theme.textOnPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [theme.primary, theme.primary.opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadiusMedium))
            }
            .disabled(selectedCharacterIds.isEmpty)
            .opacity(selectedCharacterIds.isEmpty ? 0.5 : 1)
            .padding(16)
            .background(theme.backgroundSecondary)
        }
    }
}
