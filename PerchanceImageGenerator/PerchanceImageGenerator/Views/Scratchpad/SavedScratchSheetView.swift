import SwiftUI

/// Sheet view for displaying and selecting saved scratch prompts
struct SavedScratchSheetView: View {
    @Binding var scratchpadSaved: [SavedPrompt]
    let onSelect: (SavedPrompt) -> Void

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var promptToDelete: SavedPrompt? = nil
    @State private var showingDeleteConfirmation = false

    var body: some View {
        let theme = themeManager.resolved
        
        NavigationView {
            List {
                if scratchpadSaved.isEmpty {
                    Text("No saved scratch prompts yet.")
                        .foregroundColor(theme.textSecondary)
                        .fontDesign(theme.fontDesign)
                } else {
                    ForEach(scratchpadSaved) { prompt in
                        VStack(alignment: .leading) {
                            Text(prompt.title)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .fontDesign(theme.fontDesign)
                                .foregroundColor(theme.textPrimary)
                            Text(prompt.text)
                                .font(.caption)
                                .fontDesign(theme.fontDesign)
                                .lineLimit(3)
                                .foregroundColor(theme.textSecondary)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onSelect(prompt)
                            dismiss()
                        }
                        .listRowBackground(theme.backgroundSecondary)
                    }
                    .onDelete { indices in
                        if let first = indices.first {
                            promptToDelete = scratchpadSaved[first]
                            showingDeleteConfirmation = true
                        }
                    }
                }
            }
            .themedList()
            .navigationTitle("Saved Scratches")
            .navigationBarTitleDisplayMode(.inline)
            .themedNavigationBar()
            .alert("Delete Saved Scratch?", isPresented: $showingDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    if let prompt = promptToDelete,
                       let index = scratchpadSaved.firstIndex(where: { $0.id == prompt.id }) {
                        scratchpadSaved.remove(at: index)
                    }
                    promptToDelete = nil
                }
                Button("Cancel", role: .cancel) {
                    promptToDelete = nil
                }
            } message: {
                if let prompt = promptToDelete {
                    Text("Are you sure you want to delete \"\(prompt.title)\"?")
                } else {
                    Text("Are you sure you want to delete this saved scratch?")
                }
            }
        }
    }
}
