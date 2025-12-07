import SwiftUI

/// Sheet view for displaying and selecting saved scratch prompts
struct SavedScratchSheetView: View {
    @Binding var scratchpadSaved: [SavedPrompt]
    let onSelect: (SavedPrompt) -> Void

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var presetStore: PromptPresetStore
    
    @State private var promptToDelete: SavedPrompt? = nil
    @State private var showingDeleteConfirmation = false
    @State private var showingClearAllConfirmation = false
    @State private var searchText = ""
    @State private var expandedPromptIds: Set<UUID> = []
    
    /// Composes a prompt using PromptComposer to include global defaults
    private func composedPromptWithDefaults(_ prompt: SavedPrompt) -> String {
        let scratchCharacter = CharacterProfile(
            name: "",
            bio: "",
            notes: "",
            prompts: []
        )
        return PromptComposer.composePrompt(
            character: scratchCharacter,
            prompt: prompt,
            stylePreset: nil,
            globalDefaults: presetStore.globalDefaults
        )
    }
    
    private var filteredPrompts: [SavedPrompt] {
        if searchText.isEmpty {
            return scratchpadSaved
        }
        let lowercasedSearch = searchText.lowercased()
        return scratchpadSaved.filter { prompt in
            prompt.autoSummary.lowercased().contains(lowercasedSearch) ||
            prompt.composedPrompt.lowercased().contains(lowercasedSearch)
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
                        Text("No bookmarked scratches yet.")
                            .foregroundColor(theme.textSecondary)
                            .fontDesign(theme.fontDesign)
                    } else if filteredPrompts.isEmpty {
                        Text("No results for \"\(searchText)\"")
                            .foregroundColor(theme.textSecondary)
                            .fontDesign(theme.fontDesign)
                    } else {
                        ForEach(filteredPrompts) { prompt in
                            promptRow(prompt: prompt, theme: theme)
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
                        
                        // Clear All section at bottom of list
                        Section {
                            Button {
                                showingClearAllConfirmation = true
                            } label: {
                                HStack {
                                    Spacer()
                                    Text("Clear All Bookmarks")
                                        .font(.subheadline)
                                        .foregroundColor(theme.error)
                                    Spacer()
                                }
                            }
                            .listRowBackground(Color.clear)
                        }
                    }
                }
                .themedList()
            }
            .themedBackground()
            .navigationTitle("Bookmarked Scratches")
            .navigationBarTitleDisplayMode(.inline)
            .themedNavigationBar()
            .toolbar {
            }
            .alert("Delete Bookmark?", isPresented: $showingDeleteConfirmation) {
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
                    Text("Are you sure you want to delete \"\(prompt.autoSummary)\"?")
                } else {
                    Text("Are you sure you want to delete this bookmark?")
                }
            }
            .alert("Clear All Bookmarks?", isPresented: $showingClearAllConfirmation) {
                Button("Clear All", role: .destructive) {
                    scratchpadSaved.removeAll()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to delete all \(scratchpadSaved.count) bookmarked scratches? This cannot be undone.")
            }
        }
    }
    
    // MARK: - Prompt Row
    
    private func promptRow(prompt: SavedPrompt, theme: ResolvedTheme) -> some View {
        let isExpanded = expandedPromptIds.contains(prompt.id)
        let fullPrompt = composedPromptWithDefaults(prompt)
        
        return VStack(alignment: .leading, spacing: 8) {
            // Header row with title and expand button
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    // Auto-generated summary as title (max 2 lines) - tappable to load prompt
                    Button {
                        onSelect(prompt)
                        dismiss()
                    } label: {
                        Text(prompt.autoSummary)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .fontDesign(theme.fontDesign)
                            .foregroundColor(theme.primary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                    .buttonStyle(.plain)
                    
                    // Preview of prompt (collapsed state) - uses composed prompt with defaults
                    if !isExpanded {
                        Text(fullPrompt)
                            .font(.caption)
                            .fontDesign(theme.fontDesign)
                            .lineLimit(2)
                            .foregroundColor(theme.textSecondary)
                    }
                }
                
                Spacer()
                
                // Expand/collapse button
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if isExpanded {
                            expandedPromptIds.remove(prompt.id)
                        } else {
                            expandedPromptIds.insert(prompt.id)
                        }
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle")
                        .font(.system(size: 20))
                        .foregroundColor(theme.primary)
                }
                .buttonStyle(.plain)
            }
            
            // Expanded content - full prompt (matches PromptPreviewSection styling exactly)
            if isExpanded {
                // Prompt preview container - same styling as PromptPreviewSection
                ZStack {
                    RoundedRectangle(cornerRadius: theme.cornerRadiusSmall)
                        .fill(theme.backgroundTertiary)
                    
                    RoundedRectangle(cornerRadius: theme.cornerRadiusSmall)
                        .stroke(theme.border.opacity(0.3), lineWidth: 1)
                    
                    ScrollView {
                        Text(fullPrompt)
                            .font(.footnote)
                            .fontDesign(theme.fontDesign)
                            .foregroundColor(theme.textSecondary)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .textSelection(.enabled)
                    }
                }
                .frame(maxHeight: 300) // Taller expanded view
            }
        }
    }
}
