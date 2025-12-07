import SwiftUI

/// Sheet view for displaying and selecting saved scratch prompts
struct SavedScratchSheetView: View {
    @Binding var scratchpadSaved: [SavedPrompt]
    let onSelect: (SavedPrompt) -> Void

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var promptToDelete: SavedPrompt? = nil
    @State private var showingDeleteConfirmation = false
    @State private var searchText = ""
    
    private var filteredPrompts: [SavedPrompt] {
        if searchText.isEmpty {
            return scratchpadSaved
        }
        let lowercasedSearch = searchText.lowercased()
        return scratchpadSaved.filter { prompt in
            prompt.title.lowercased().contains(lowercasedSearch) ||
            prompt.text.lowercased().contains(lowercasedSearch)
        }
    }

    var body: some View {
        let theme = themeManager.resolved
        
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(theme.textSecondary)
                    TextField("Search saved prompts...", text: $searchText)
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
                
                List {
                    if scratchpadSaved.isEmpty {
                        Text("No saved scratch prompts yet.")
                            .foregroundColor(theme.textSecondary)
                            .fontDesign(theme.fontDesign)
                    } else if filteredPrompts.isEmpty {
                        Text("No results for \"\(searchText)\"")
                            .foregroundColor(theme.textSecondary)
                            .fontDesign(theme.fontDesign)
                    } else {
                        ForEach(filteredPrompts) { prompt in
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
                            // Map filtered index back to original array
                            if let first = indices.first {
                                let prompt = filteredPrompts[first]
                                promptToDelete = prompt
                                showingDeleteConfirmation = true
                            }
                        }
                    }
                }
                .themedList()
            }
            .themedBackground()
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
