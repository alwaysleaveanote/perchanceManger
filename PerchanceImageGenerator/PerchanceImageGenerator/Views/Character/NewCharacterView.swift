import SwiftUI
import UIKit

/// Sheet view for creating a new character
struct NewCharacterView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager

    @State private var name: String = ""
    @State private var bio: String = ""
    @State private var notes: String = ""

    let onCreate: (CharacterProfile) -> Void

    var body: some View {
        let theme = themeManager.resolved
        
        NavigationView {
            Form {
                Section(header: Text("New Character")
                    .foregroundColor(theme.textSecondary)
                    .fontDesign(theme.fontDesign)
                ) {
                    DynamicGrowingTextEditor(
                        text: $name,
                        placeholder: "Name",
                        minLines: 0,
                        maxLines: 10
                    )

                    DynamicGrowingTextEditor(
                        text: $bio,
                        placeholder: "Bio / description",
                        minLines: 0,
                        maxLines: 10
                    )

                    DynamicGrowingTextEditor(
                        text: $notes,
                        placeholder: "Notes (optional)",
                        minLines: 0,
                        maxLines: 10
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
                            bio: bio,
                            notes: notes,
                            prompts: []
                        )
                        onCreate(character)
                        KeyboardHelper.dismiss()
                        dismiss()
                    }
                }
            }
        }
    }
}
