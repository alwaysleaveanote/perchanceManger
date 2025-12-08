//
//  SceneRowView.swift
//  Chancery
//
//  A row view for displaying a scene in a list.
//  Matches CharacterRowView layout for consistency.
//

import SwiftUI

/// A single row in the scenes list displaying scene info with theme support.
/// Matches CharacterRowView layout for visual consistency.
struct SceneRowView: View {
    let scene: CharacterScene
    let characters: [CharacterProfile]
    
    @EnvironmentObject var themeManager: ThemeManager
    
    // MARK: - Configuration (matches CharacterRowView)
    
    private enum Layout {
        static let thumbnailSize: CGFloat = 50
        static let spacing: CGFloat = 12
        static let verticalPadding: CGFloat = 8
        static let horizontalPadding: CGFloat = 12
    }
    
    // MARK: - Computed Properties
    
    private var sceneCharacters: [CharacterProfile] {
        scene.characterIds.compactMap { id in
            characters.first { $0.id == id }
        }
    }
    
    private var theme: ResolvedTheme {
        themeManager.resolvedTheme(forCharacterThemeId: scene.sceneThemeId)
    }
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: Layout.spacing) {
            thumbnailView
            sceneInfoView
            Spacer()
            // Custom themed chevron (matches CharacterRowView)
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(theme.textSecondary)
        }
        .padding(.vertical, Layout.verticalPadding)
        .padding(.horizontal, Layout.horizontalPadding)
        .background(rowBackground)
        .overlay(rowBorder)
    }
    
    // MARK: - Thumbnail View
    
    /// Scene thumbnail - uses profile image if available, otherwise shows character count icon
    @ViewBuilder
    private var thumbnailView: some View {
        if let data = scene.profileImageData,
           let uiImage = UIImage(data: data) {
            // Scene has a profile image
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: Layout.thumbnailSize, height: Layout.thumbnailSize)
                .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadiusSmall))
                .overlay(
                    RoundedRectangle(cornerRadius: theme.cornerRadiusSmall)
                        .stroke(theme.border.opacity(0.3), lineWidth: 1)
                )
        } else {
            // Placeholder with character count indicator
            RoundedRectangle(cornerRadius: theme.cornerRadiusSmall)
                .fill(theme.backgroundTertiary)
                .frame(width: Layout.thumbnailSize, height: Layout.thumbnailSize)
                .overlay(
                    VStack(spacing: 2) {
                        Image(systemName: sceneIcon)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(theme.primary)
                        if sceneCharacters.count > 3 {
                            Text("\(sceneCharacters.count)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(theme.textSecondary)
                        }
                    }
                )
        }
    }
    
    /// Icon that scales based on character count
    private var sceneIcon: String {
        switch sceneCharacters.count {
        case 0, 1:
            return "person.fill"
        case 2:
            return "person.2.fill"
        default:
            return "person.3.fill"
        }
    }
    
    // MARK: - Scene Info View
    
    private var sceneInfoView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(scene.name.isEmpty ? "Untitled Scene" : scene.name)
                .font(.headline)
                .fontDesign(theme.fontDesign)
                .foregroundColor(theme.textPrimary)
                .lineLimit(1)
            
            // Character names as subtitle (like bio in CharacterRowView)
            Text(characterNamesText)
                .font(.caption)
                .fontDesign(theme.fontDesign)
                .foregroundColor(theme.textSecondary)
                .lineLimit(2)
        }
    }
    
    // MARK: - Background & Border (matches CharacterRowView)
    
    private var rowBackground: some View {
        RoundedRectangle(cornerRadius: theme.cornerRadiusMedium)
            .fill(theme.backgroundSecondary)
    }
    
    private var rowBorder: some View {
        RoundedRectangle(cornerRadius: theme.cornerRadiusMedium)
            .stroke(theme.border.opacity(0.3), lineWidth: 1)
    }
    
    // MARK: - Helpers
    
    private var characterNamesText: String {
        let names = sceneCharacters.map { $0.name }
        if names.isEmpty {
            return "No characters"
        } else if names.count <= 2 {
            return names.joined(separator: " & ")
        } else {
            return "\(names[0]), \(names[1]) +\(names.count - 2) more"
        }
    }
}
