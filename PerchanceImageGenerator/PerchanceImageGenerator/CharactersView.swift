import SwiftUI

struct CharactersView: View {
    @Binding var characters: [CharacterProfile]
    let openGenerator: (String) -> Void

    @State private var showingNewCharacterSheet = false

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Characters")) {
                    if characters.isEmpty {
                        Text("No characters yet. Tap + to create one.")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(characters) { character in
                            NavigationLink {
                                CharacterDetailView(
                                    character: binding(for: character),
                                    openGenerator: openGenerator
                                )
                            } label: {
                                HStack(spacing: 12) {

                                    // Thumbnail (if profileImageData exists)
                                    if let data = character.profileImageData,
                                       let uiImage = UIImage(data: data) {

                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 44, height: 44)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                                            )
                                    }

                                    // Character name
                                    Text(character.name)
                                        .font(.headline)
                                        .foregroundColor(.primary)

                                    Spacer()
                                }
                            }

                        }
                        .onDelete { indices in
                            characters.remove(atOffsets: indices)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Characters")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingNewCharacterSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        KeyboardHelper.dismiss()
                    }
                }
            }

            .sheet(isPresented: $showingNewCharacterSheet) {
                NewCharacterView { newCharacter in
                    characters.insert(newCharacter, at: 0)
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
