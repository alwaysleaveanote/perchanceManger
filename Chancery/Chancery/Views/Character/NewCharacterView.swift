import SwiftUI
import UIKit

/// Sheet view for creating a new character
struct NewCharacterView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager

    @State private var name: String = ""

    let onCreate: (CharacterProfile) -> Void

    var body: some View {
        let theme = themeManager.resolved
        
        NavigationView {
            Form {
                Section(header: Text("Character Name")
                    .foregroundColor(theme.textSecondary)
                    .fontDesign(theme.fontDesign)
                ) {
                    ThemedTextField(
                        placeholder: "Enter character name",
                        text: $name
                    )
                }
                .listRowBackground(theme.backgroundSecondary)
            }
            .themedList()
            .dismissKeyboardOnDrag()
            .navigationTitle("New Character")
            .navigationBarTitleDisplayMode(.inline)
            .themedNavigationBar()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        KeyboardHelper.dismiss()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmedName.isEmpty else { return }
                        let character = CharacterProfile(
                            name: trimmedName,
                            bio: "",
                            prompts: []
                        )
                        onCreate(character)
                        KeyboardHelper.dismiss()
                        dismiss()
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
        }
    }
}
