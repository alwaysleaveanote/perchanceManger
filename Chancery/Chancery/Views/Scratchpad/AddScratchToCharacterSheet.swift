import SwiftUI

/// Sheet view for adding a scratch prompt to a character
struct AddScratchToCharacterSheet: View {
    let characters: [CharacterProfile]
    @Binding var title: String
    let onAdd: (CharacterProfile.ID, String) -> Void
    let onCreateNewCharacter: (CharacterProfile, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var showingNewCharacterForm = false
    @State private var newCharacterName = ""
    @State private var newCharacterBio = ""
    @State private var newCharacterNotes = ""

    var body: some View {
        let theme = themeManager.resolved
        
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Add to Character")
                    .font(.headline)
                    .fontDesign(theme.fontDesign)
                    .foregroundColor(theme.textPrimary)

                ThemedTextField(placeholder: "Prompt title (required)", text: $title)
                
                if showingNewCharacterForm {
                    // New character creation form
                    newCharacterFormSection
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
                    
                    if characters.isEmpty {
                        Text("Or select an existing character below.")
                            .font(.caption)
                            .fontDesign(theme.fontDesign)
                            .foregroundColor(theme.textSecondary)
                    } else {
                        Text("Or select an existing character:")
                            .font(.caption)
                            .fontDesign(theme.fontDesign)
                            .foregroundColor(theme.textSecondary)
                        
                        List {
                            ForEach(characters) { character in
                                let disabled = title
                                    .trimmingCharacters(in: .whitespacesAndNewlines)
                                    .isEmpty
                                Button {
                                    let trimmed = title
                                        .trimmingCharacters(in: .whitespacesAndNewlines)
                                    guard !trimmed.isEmpty else { return }
                                    onAdd(character.id, trimmed)
                                    dismiss()
                                } label: {
                                    HStack {
                                        Text(character.name.isEmpty ? "Untitled Character" : character.name)
                                            .fontDesign(theme.fontDesign)
                                            .foregroundColor(theme.textPrimary)
                                        Spacer()
                                    }
                                }
                                .disabled(disabled)
                                .listRowBackground(theme.backgroundSecondary)
                            }
                        }
                        .themedList()
                        .listStyle(.plain)
                    }
                }

                Spacer()
            }
            .padding()
            .themedBackground()
            .navigationTitle("Add to Character")
            .navigationBarTitleDisplayMode(.inline)
            .themedNavigationBar()
            .toolbar {
                if showingNewCharacterForm {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Back") {
                            showingNewCharacterForm = false
                        }
                    }
                }
            }
        }
    }
    
    private var newCharacterFormSection: some View {
        let theme = themeManager.resolved
        let titleTrimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let nameTrimmed = newCharacterName.trimmingCharacters(in: .whitespacesAndNewlines)
        let canCreate = !titleTrimmed.isEmpty && !nameTrimmed.isEmpty
        
        return VStack(alignment: .leading, spacing: 12) {
            Text("New Character")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(theme.textPrimary)
            
            ThemedTextField(placeholder: "Character name (required)", text: $newCharacterName)
            
            ThemedTextField(placeholder: "Bio (optional)", text: $newCharacterBio)
            
            ThemedTextField(placeholder: "Notes (optional)", text: $newCharacterNotes)
            
            Button {
                let newCharacter = CharacterProfile(
                    name: nameTrimmed,
                    bio: newCharacterBio.trimmingCharacters(in: .whitespacesAndNewlines),
                    notes: newCharacterNotes.trimmingCharacters(in: .whitespacesAndNewlines)
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
                .foregroundColor(canCreate ? theme.textOnPrimary : theme.textSecondary)
                .padding(14)
                .background(canCreate ? theme.primary : theme.backgroundTertiary)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .disabled(!canCreate)
        }
    }
}
