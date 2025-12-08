//
//  GalleryCard.swift
//  Chancery
//
//  Reusable gallery card component for Character and Scene overview pages.
//

import SwiftUI

/// A reusable card for displaying an image gallery with add functionality.
/// Used by both CharacterOverviewView and SceneOverviewView.
struct GalleryCard: View {
    let images: [PromptImage]
    let themeId: String?
    let onImageTap: (Int) -> Void
    let onAddImages: () -> Void
    
    @EnvironmentObject var themeManager: ThemeManager
    
    private var theme: ResolvedTheme {
        themeManager.resolvedTheme(forCharacterThemeId: themeId)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with add button
            HStack {
                Text("Image Gallery")
                    .font(.subheadline.weight(.semibold))
                    .fontDesign(theme.fontDesign)
                    .foregroundColor(theme.textPrimary)
                
                Spacer()
                
                Button {
                    onAddImages()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Add")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundColor(theme.textOnPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(theme.primary)
                    )
                }
                .buttonStyle(.plain)
            }
            
            if images.isEmpty {
                Text("No images yet. Tap + Add to upload images.")
                    .font(.caption)
                    .fontDesign(theme.fontDesign)
                    .foregroundColor(theme.textSecondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Array(images.enumerated()), id: \.element.id) { index, promptImage in
                            if let uiImage = UIImage(data: promptImage.data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 72, height: 72)
                                    .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadiusSmall))
                                    .shadow(color: theme.shadow.opacity(0.1), radius: 4, x: 0, y: 2)
                                    .onTapGesture {
                                        onImageTap(index)
                                    }
                            }
                        }
                    }
                }
            }
        }
        .themedCard(characterThemeId: themeId)
    }
}
