//
//  ScenesListView.swift
//  Chancery
//
//  List view for displaying and managing scenes (multi-character groups).
//

import SwiftUI

struct ScenesListView: View {
    @Binding var scenes: [CharacterScene]
    let characters: [CharacterProfile]
    let onSceneTap: (CharacterScene) -> Void
    let onCreateScene: () -> Void
    let onDeleteScene: (CharacterScene) -> Void
    
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        let theme = themeManager.resolved
        
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Your Scenes")
                    .font(.title2.weight(.bold))
                    .fontDesign(theme.fontDesign)
                    .foregroundColor(theme.textPrimary)
                
                Spacer()
                
                Button {
                    onCreateScene()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .semibold))
                        Text("New Scene")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundColor(theme.textOnPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(theme.primary)
                    )
                }
                .buttonStyle(.plain)
            }
            
            if scenes.isEmpty {
                emptyState
            } else {
                scenesList
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        let theme = themeManager.resolved
        
        return VStack(spacing: 16) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 48))
                .foregroundColor(theme.textSecondary.opacity(0.5))
            
            Text("No Scenes Yet")
                .font(.headline)
                .foregroundColor(theme.textPrimary)
            
            Text("Create a scene to generate prompts featuring multiple characters together.")
                .font(.subheadline)
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)
            
            Button {
                onCreateScene()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                    Text("Create Your First Scene")
                }
                .font(.subheadline.weight(.medium))
                .foregroundColor(theme.primary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .themedCard()
    }
    
    // MARK: - Scenes List
    
    private var scenesList: some View {
        let theme = themeManager.resolved
        
        return VStack(spacing: 12) {
            ForEach(scenes) { scene in
                sceneRow(scene, theme: theme)
            }
        }
    }
    
    private func sceneRow(_ scene: CharacterScene, theme: ResolvedTheme) -> some View {
        let sceneCharacters = characters.filter { scene.characterIds.contains($0.id) }
        
        return Button {
            onSceneTap(scene)
        } label: {
            HStack(spacing: 12) {
                // Character avatars (stacked)
                characterAvatars(sceneCharacters, theme: theme)
                
                // Scene info
                VStack(alignment: .leading, spacing: 4) {
                    Text(scene.name.isEmpty ? "Untitled Scene" : scene.name)
                        .font(.headline)
                        .fontDesign(theme.fontDesign)
                        .foregroundColor(theme.textPrimary)
                        .lineLimit(1)
                    
                    // Character names
                    Text(characterNames(sceneCharacters))
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                        .lineLimit(1)
                    
                    // Stats
                    HStack(spacing: 12) {
                        Label("\(scene.promptCount)", systemImage: "doc.text")
                        Label("\(scene.totalImageCount)", systemImage: "photo")
                    }
                    .font(.caption2)
                    .foregroundColor(theme.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.medium))
                    .foregroundColor(theme.textSecondary)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: theme.cornerRadiusMedium)
                    .fill(theme.backgroundSecondary)
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                onDeleteScene(scene)
            } label: {
                Label("Delete Scene", systemImage: "trash")
            }
        }
    }
    
    // MARK: - Helpers
    
    private func characterAvatars(_ characters: [CharacterProfile], theme: ResolvedTheme) -> some View {
        ZStack {
            ForEach(Array(characters.prefix(3).enumerated()), id: \.element.id) { index, character in
                Group {
                    if let imageData = character.profileImageData,
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                    } else {
                        ZStack {
                            Circle()
                                .fill(theme.primary.opacity(0.2))
                            Text(String(character.name.prefix(1)).uppercased())
                                .font(.caption.weight(.bold))
                                .foregroundColor(theme.primary)
                        }
                    }
                }
                .frame(width: 36, height: 36)
                .clipShape(Circle())
                .overlay(Circle().stroke(theme.backgroundSecondary, lineWidth: 2))
                .offset(x: CGFloat(index) * 16)
            }
        }
        .frame(width: 36 + CGFloat(min(characters.count - 1, 2)) * 16, height: 36)
    }
    
    private func characterNames(_ characters: [CharacterProfile]) -> String {
        let names = characters.map { $0.name }
        if names.count <= 2 {
            return names.joined(separator: " & ")
        } else {
            return "\(names[0]), \(names[1]) +\(names.count - 2) more"
        }
    }
}
