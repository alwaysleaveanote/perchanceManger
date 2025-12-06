import SwiftUI
import UIKit

struct NewCharacterView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var bio: String = ""
    @State private var notes: String = ""

    let onCreate: (CharacterProfile) -> Void

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("New Character")) {
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
            }
            .dismissKeyboardOnDrag()
            .navigationTitle("New Character")
            .toolbar {
                // Cancel button – this is the one that should close the sheet
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
