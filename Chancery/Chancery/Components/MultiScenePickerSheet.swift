//
//  MultiScenePickerSheet.swift
//  Chancery
//
//  A sheet for selecting multiple scenes to add a prompt to.
//  Mirrors MultiCharacterPickerSheet for feature parity.
//

import SwiftUI

/// Sheet for selecting multiple scenes to add a prompt to
struct MultiScenePickerSheet: View {
    let scenes: [CharacterScene]
    let prompt: ScenePrompt
    let onComplete: ([CharacterScene]) -> Void
    
    /// Optional: Exclude a specific scene (e.g., the current scene when duplicating)
    var excludeSceneId: UUID? = nil
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var selectedSceneIds: Set<UUID> = []
    @State private var searchText = ""
    
    private var availableScenes: [CharacterScene] {
        scenes.filter { scene in
            if let excludeId = excludeSceneId, scene.id == excludeId {
                return false
            }
            return true
        }
    }
    
    private var filteredScenes: [CharacterScene] {
        if searchText.isEmpty {
            return availableScenes
        }
        let lowercasedSearch = searchText.lowercased()
        return availableScenes.filter { scene in
            scene.name.lowercased().contains(lowercasedSearch)
        }
    }
    
    private var selectedScenes: [CharacterScene] {
        availableScenes.filter { selectedSceneIds.contains($0.id) }
    }
    
    var body: some View {
        let theme = themeManager.resolved
        
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                searchBar(theme: theme)
                
                // Selection controls
                selectionControls(theme: theme)
                
                // Scene list
                sceneList(theme: theme)
                
                // Add button
                addButton(theme: theme)
            }
            .themedBackground()
            .navigationTitle("Add to Scenes")
            .navigationBarTitleDisplayMode(.inline)
            .themedNavigationBar()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(theme.primary)
                }
            }
        }
    }
    
    // MARK: - Search Bar
    
    private func searchBar(theme: ResolvedTheme) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(theme.textSecondary)
            TextField("Search scenes...", text: $searchText)
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
    }
    
    // MARK: - Selection Controls
    
    private func selectionControls(theme: ResolvedTheme) -> some View {
        HStack {
            Text("\(selectedSceneIds.count) selected")
                .font(.subheadline)
                .foregroundColor(theme.textSecondary)
            
            Spacer()
            
            Button("Select All") {
                selectedSceneIds = Set(filteredScenes.map { $0.id })
            }
            .font(.subheadline.weight(.medium))
            .foregroundColor(theme.primary)
            
            Text("•")
                .foregroundColor(theme.textSecondary)
            
            Button("Clear") {
                selectedSceneIds.removeAll()
            }
            .font(.subheadline.weight(.medium))
            .foregroundColor(theme.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(theme.backgroundSecondary)
    }
    
    // MARK: - Scene List
    
    private func sceneList(theme: ResolvedTheme) -> some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                if filteredScenes.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 40))
                            .foregroundColor(theme.textSecondary.opacity(0.5))
                        Text(searchText.isEmpty ? "No other scenes available" : "No scenes match your search")
                            .font(.subheadline)
                            .foregroundColor(theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                } else {
                    ForEach(filteredScenes) { scene in
                        sceneRow(scene, theme: theme)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
    
    private func sceneRow(_ scene: CharacterScene, theme: ResolvedTheme) -> some View {
        let isSelected = selectedSceneIds.contains(scene.id)
        
        return Button {
            if isSelected {
                selectedSceneIds.remove(scene.id)
            } else {
                selectedSceneIds.insert(scene.id)
            }
        } label: {
            HStack(spacing: 12) {
                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? theme.primary : theme.textSecondary.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(theme.primary)
                            .frame(width: 16, height: 16)
                    }
                }
                
                // Scene avatar
                Group {
                    if let imageData = scene.profileImageData,
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                    } else {
                        ZStack {
                            Circle()
                                .fill(theme.primary.opacity(0.2))
                            Image(systemName: "person.3.fill")
                                .font(.system(size: 14))
                                .foregroundColor(theme.primary)
                        }
                    }
                }
                .frame(width: 44, height: 44)
                .clipShape(Circle())
                
                // Scene info
                VStack(alignment: .leading, spacing: 2) {
                    Text(scene.name.isEmpty ? "Untitled Scene" : scene.name)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(theme.textPrimary)
                    
                    Text("\(scene.prompts.count) prompt\(scene.prompts.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                }
                
                Spacer()
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: theme.cornerRadiusMedium)
                    .fill(isSelected ? theme.primary.opacity(0.1) : theme.backgroundTertiary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: theme.cornerRadiusMedium)
                    .stroke(isSelected ? theme.primary : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Add Button
    
    private func addButton(theme: ResolvedTheme) -> some View {
        VStack(spacing: 0) {
            Divider()
                .background(theme.textSecondary.opacity(0.2))
            
            Button {
                onComplete(selectedScenes)
                dismiss()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Add to \(selectedSceneIds.count) Scene\(selectedSceneIds.count == 1 ? "" : "s")")
                        .font(.headline.weight(.semibold))
                }
                .foregroundColor(selectedSceneIds.isEmpty ? theme.textSecondary : theme.textOnPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: theme.cornerRadiusMedium)
                        .fill(selectedSceneIds.isEmpty ? theme.backgroundTertiary : theme.primary)
                )
            }
            .disabled(selectedSceneIds.isEmpty)
            .padding(16)
            .background(theme.backgroundSecondary)
        }
    }
}
