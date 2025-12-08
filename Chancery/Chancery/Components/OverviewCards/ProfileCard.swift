//
//  ProfileCard.swift
//  Chancery
//
//  Reusable profile card component for Character and Scene overview pages.
//

import SwiftUI

/// A reusable profile card showing profile image, edit button, and settings button.
/// Used by both CharacterOverviewView and SceneOverviewView.
struct ProfileCard<Content: View>: View {
    let profileImageData: Data?
    let isEditing: Bool
    let themeId: String?
    let onEditToggle: () -> Void
    let onSettingsTap: () -> Void
    let onProfileImageTap: () -> Void
    let additionalContent: (() -> Content)?
    
    @EnvironmentObject var themeManager: ThemeManager
    
    private var theme: ResolvedTheme {
        themeManager.resolvedTheme(forCharacterThemeId: themeId)
    }
    
    init(
        profileImageData: Data?,
        isEditing: Bool,
        themeId: String?,
        onEditToggle: @escaping () -> Void,
        onSettingsTap: @escaping () -> Void,
        onProfileImageTap: @escaping () -> Void,
        @ViewBuilder additionalContent: @escaping () -> Content
    ) {
        self.profileImageData = profileImageData
        self.isEditing = isEditing
        self.themeId = themeId
        self.onEditToggle = onEditToggle
        self.onSettingsTap = onSettingsTap
        self.onProfileImageTap = onProfileImageTap
        self.additionalContent = additionalContent
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Edit button
            editButton
            
            Spacer()
            
            // Profile image
            profileImageButton
            
            Spacer()
            
            // Settings button
            settingsButton
        }
        .themedCard(characterThemeId: themeId)
    }
    
    // MARK: - Edit Button
    
    private var editButton: some View {
        Button {
            onEditToggle()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: isEditing ? "checkmark" : "pencil")
                    .font(.system(size: 12, weight: .medium))
                Text(isEditing ? "Done" : "Edit")
                    .font(.caption.weight(.medium))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
            .foregroundColor(theme.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(theme.primary.opacity(0.12))
            )
        }
        .buttonStyle(.plain)
        .fixedSize()
    }
    
    // MARK: - Profile Image
    
    private var profileImageButton: some View {
        Button {
            onProfileImageTap()
        } label: {
            ZStack(alignment: .bottomTrailing) {
                if let data = profileImageData,
                   let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 200, height: 200)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(theme.backgroundTertiary)
                        .frame(width: 200, height: 200)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 80))
                                .foregroundColor(theme.textSecondary.opacity(0.5))
                        )
                }
                
                // Edit badge - only show when no image
                if profileImageData == nil {
                    Circle()
                        .fill(theme.primary)
                        .frame(width: 36, height: 36)
                        .overlay(
                            Image(systemName: "camera.fill")
                                .font(.system(size: 16))
                                .foregroundColor(theme.textOnPrimary)
                        )
                        .offset(x: -8, y: -8)
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Settings Button
    
    private var settingsButton: some View {
        Button {
            onSettingsTap()
        } label: {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(theme.primary)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(theme.primary.opacity(0.12))
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Convenience initializer without additional content

extension ProfileCard where Content == EmptyView {
    init(
        profileImageData: Data?,
        isEditing: Bool,
        themeId: String?,
        onEditToggle: @escaping () -> Void,
        onSettingsTap: @escaping () -> Void,
        onProfileImageTap: @escaping () -> Void
    ) {
        self.profileImageData = profileImageData
        self.isEditing = isEditing
        self.themeId = themeId
        self.onEditToggle = onEditToggle
        self.onSettingsTap = onSettingsTap
        self.onProfileImageTap = onProfileImageTap
        self.additionalContent = nil
    }
}
