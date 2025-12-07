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
    @State private var showNameRequiredToast = false
    @State private var toastMessage = ""

    var body: some View {
        let theme = themeManager.resolved
        
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Add to Character")
                    .font(.headline)
                    .fontDesign(theme.fontDesign)
                    .foregroundColor(theme.textPrimary)

                VStack(alignment: .leading, spacing: 4) {
                    ThemedTextField(placeholder: "Prompt title (required)", text: $title)
                    
                    if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("Enter a name for this prompt before adding to a character")
                            .font(.caption)
                            .foregroundColor(theme.textSecondary)
                    }
                }
                
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
                    
                    if !characters.isEmpty {
                        Text("Or select an existing character:")
                            .font(.caption)
                            .fontDesign(theme.fontDesign)
                            .foregroundColor(theme.textSecondary)
                        
                        List {
                            ForEach(characters) { character in
                                let titleEmpty = title
                                    .trimmingCharacters(in: .whitespacesAndNewlines)
                                    .isEmpty
                                Button {
                                    let trimmed = title
                                        .trimmingCharacters(in: .whitespacesAndNewlines)
                                    if trimmed.isEmpty {
                                        showNameRequiredFeedback()
                                        return
                                    }
                                    onAdd(character.id, trimmed)
                                    dismiss()
                                } label: {
                                    HStack {
                                        Text(character.name.isEmpty ? "Untitled Character" : character.name)
                                            .fontDesign(theme.fontDesign)
                                            .foregroundColor(titleEmpty ? theme.textSecondary : theme.textPrimary)
                                        Spacer()
                                    }
                                }
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
            .overlay(alignment: .top) {
                if showNameRequiredToast {
                    nameRequiredToastView
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
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
        }
    }
}
