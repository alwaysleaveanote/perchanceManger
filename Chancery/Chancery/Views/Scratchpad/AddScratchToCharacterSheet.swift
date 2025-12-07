import SwiftUI

/// Sheet view for adding a scratch prompt to a character
struct AddScratchToCharacterSheet: View {
    let characters: [CharacterProfile]
    @Binding var title: String
    let onAdd: (CharacterProfile.ID, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        let theme = themeManager.resolved
        
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Add to Character")
                    .font(.headline)
                    .fontDesign(theme.fontDesign)
                    .foregroundColor(theme.textPrimary)

                ThemedTextField(placeholder: "Prompt title (required)", text: $title)

                if characters.isEmpty {
                    Text("You don't have any characters yet.")
                        .font(.caption)
                        .fontDesign(theme.fontDesign)
                        .foregroundColor(theme.textSecondary)
                    Spacer()
                } else {
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

                Spacer()
            }
            .padding()
            .themedBackground()
            .navigationTitle("Add to Character")
            .navigationBarTitleDisplayMode(.inline)
            .themedNavigationBar()
        }
    }
}
