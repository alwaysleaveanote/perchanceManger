import SwiftUI

/// Sheet view for adding a scratch prompt to multiple characters
struct AddScratchToCharacterSheet: View {
    let characters: [CharacterProfile]
    @Binding var title: String
    let onAddToMultiple: ([CharacterProfile.ID], String) -> Void
    let onCreateNewCharacter: (CharacterProfile, String) -> Void
    
    // Legacy single-character callback (for backwards compatibility)
    var onAdd: ((CharacterProfile.ID, String) -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var showingNewCharacterForm = false
    @State private var newCharacterName = ""
    @State private var showNameRequiredToast = false
    @State private var toastMessage = ""
    @State private var selectedCharacterIds: Set<UUID> = []
    @State private var searchText = ""
    
    private var filteredCharacters: [CharacterProfile] {
        if searchText.isEmpty {
            return characters
        }
        let lowercasedSearch = searchText.lowercased()
        return characters.filter { $0.name.lowercased().contains(lowercasedSearch) }
    }

    var body: some View {
        let theme = themeManager.resolved
        
        NavigationView {
            VStack(spacing: 0) {
                // Title input section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Prompt Title")
                        .font(.subheadline.weight(.semibold))
                        .fontDesign(theme.fontDesign)
                        .foregroundColor(theme.textPrimary)
                    
                    ThemedTextField(placeholder: "Enter a name for this prompt", text: $title)
                    
                    if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("A title is required before adding to characters")
                            .font(.caption)
                            .foregroundColor(theme.textSecondary)
                    }
                }
                .padding(16)
                .background(theme.backgroundSecondary)
                
                if showingNewCharacterForm {
                    // New character creation form
                    newCharacterFormSection
                        .padding(16)
                } else {
                    // Create new character button
                    Button {
                        showingNewCharacterForm = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(theme.primary)
                            Text("Create New Character")
                                .fontDesign(theme.fontDesign)
                                .foregroundColor(theme.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(theme.textSecondary)
                        }
                        .padding(12)
                        .background(theme.primary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    
                    if !characters.isEmpty {
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
                        .padding(10)
                        .background(theme.backgroundTertiary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        
                        // Selection controls
                        HStack {
                            Text("\(selectedCharacterIds.count) selected")
                                .font(.caption)
                                .foregroundColor(theme.textSecondary)
                            
                            Spacer()
                            
                            Button("Select All") {
                                selectedCharacterIds = Set(filteredCharacters.map { $0.id })
                            }
                            .font(.caption.weight(.medium))
                            .foregroundColor(theme.primary)
                            
                            Text("•")
                                .foregroundColor(theme.textSecondary)
                            
                            Button("Clear") {
                                selectedCharacterIds.removeAll()
                            }
                            .font(.caption.weight(.medium))
                            .foregroundColor(theme.primary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        
                        // Character list
                        List {
                            ForEach(filteredCharacters) { character in
                                characterRow(character: character, theme: theme)
                                    .listRowBackground(theme.backgroundSecondary)
                            }
                        }
                        .themedList()
                        .listStyle(.plain)
                    }
                    
                    // Add button
                    addButton(theme: theme)
                }
            }
            .themedBackground()
            .navigationTitle("Add to Characters")
            .navigationBarTitleDisplayMode(.inline)
            .themedNavigationBar()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if showingNewCharacterForm {
                        Button("Back") {
                            showingNewCharacterForm = false
                        }
                        .foregroundColor(theme.primary)
                    } else {
                        Button("Cancel") {
                            dismiss()
                        }
                        .foregroundColor(theme.primary)
                    }
                }
            }
            .overlay(alignment: .top) {
                if showNameRequiredToast {
                    nameRequiredToastView
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
    }
    
    // MARK: - Character Row
    
    private func characterRow(character: CharacterProfile, theme: ResolvedTheme) -> some View {
        let isSelected = selectedCharacterIds.contains(character.id)
        let titleEmpty = title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        
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
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                } else {
                    ZStack {
                        Circle()
                            .fill(theme.primary.opacity(0.15))
                            .frame(width: 40, height: 40)
                        
                        Text(character.name.prefix(1).uppercased())
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(theme.primary)
                    }
                }
                
                // Character info
                VStack(alignment: .leading, spacing: 2) {
                    Text(character.name.isEmpty ? "Untitled Character" : character.name)
                        .font(.subheadline.weight(.medium))
                        .fontDesign(theme.fontDesign)
                        .foregroundColor(titleEmpty ? theme.textSecondary : theme.textPrimary)
                    
                    Text("\(character.prompts.count) prompt\(character.prompts.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                }
                
                Spacer()
                
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
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
                let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty {
                    showNameRequiredFeedback()
                    return
                }
                
                if selectedCharacterIds.isEmpty {
                    toastMessage = "Please select at least one character"
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showNameRequiredToast = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showNameRequiredToast = false
                        }
                    }
                    return
                }
                
                // Pass IDs in the order they appear in the characters list (first selected = first in list)
                let orderedIds = characters
                    .filter { selectedCharacterIds.contains($0.id) }
                    .map { $0.id }
                onAddToMultiple(orderedIds, trimmed)
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
            .disabled(selectedCharacterIds.isEmpty || title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(selectedCharacterIds.isEmpty || title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
            .padding(16)
            .background(theme.backgroundSecondary)
        }
    }
    
    private var nameRequiredToastView: some View {
        let theme = themeManager.resolved
        return HStack(spacing: 8) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(theme.textOnPrimary)
            Text(toastMessage)
                .font(.subheadline.weight(.medium))
                .fontDesign(theme.fontDesign)
                .foregroundColor(theme.textOnPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(theme.warning)
        )
        .padding(.top, 8)
    }
    
    private func showNameRequiredFeedback() {
        toastMessage = "Please enter a prompt name first"
        withAnimation(.easeInOut(duration: 0.2)) {
            showNameRequiredToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.2)) {
                showNameRequiredToast = false
            }
        }
    }
    
    private func showMissingFieldsFeedback(promptName: Bool, characterName: Bool) {
        if !promptName && !characterName {
            toastMessage = "Please enter prompt name and character name"
        } else if !promptName {
            toastMessage = "Please enter a prompt name"
        } else {
            toastMessage = "Please enter a character name"
        }
        withAnimation(.easeInOut(duration: 0.2)) {
            showNameRequiredToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.2)) {
                showNameRequiredToast = false
            }
        }
    }
    
    private var newCharacterFormSection: some View {
        let theme = themeManager.resolved
        let titleTrimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let nameTrimmed = newCharacterName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return VStack(alignment: .leading, spacing: 12) {
            Text("New Character")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(theme.textPrimary)
            
            ThemedTextField(placeholder: "Character name (required)", text: $newCharacterName)
            
            Button {
                // Validate both fields
                if titleTrimmed.isEmpty || nameTrimmed.isEmpty {
                    showMissingFieldsFeedback(promptName: !titleTrimmed.isEmpty, characterName: !nameTrimmed.isEmpty)
                    return
                }
                let newCharacter = CharacterProfile(
                    name: nameTrimmed,
                    bio: ""
                )
                onCreateNewCharacter(newCharacter, titleTrimmed)
                dismiss()
            } label: {
                HStack {
                    Spacer()
                    Text("Create & Add Prompt")
                        .font(.headline)
                    Spacer()
                }
                .foregroundColor(theme.textOnPrimary)
                .padding(14)
                .background(theme.primary)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            
            Spacer()
        }
    }
}
