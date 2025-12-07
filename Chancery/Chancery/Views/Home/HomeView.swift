//
//  HomeView.swift
//  Chancery
//
//  The home screen with app introduction, image gallery, and quick actions.
//

import SwiftUI

struct HomeView: View {
    let characters: [CharacterProfile]
    let onNavigateToScratchpad: () -> Void
    let onNavigateToCharacters: () -> Void
    let onNavigateToCharacter: ((UUID) -> Void)?
    
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showImageGallery = false
    @State private var selectedImageIndex: Int? = nil
    
    // MARK: - Computed Properties
    
    private var hasAnyImages: Bool {
        characters.contains { character in
            character.prompts.contains { !$0.images.isEmpty }
        }
    }
    
    /// All images with full metadata for gallery (includes profile images, avoids duplicates)
    private var allGalleryImages: [AllImagesGallerySheet.GalleryImage] {
        var result: [AllImagesGallerySheet.GalleryImage] = []
        var seenImageData = Set<Data>()
        
        for character in characters {
            // Add prompt images
            for prompt in character.prompts {
                for image in prompt.images {
                    seenImageData.insert(image.data)
                    result.append(AllImagesGallerySheet.GalleryImage(
                        id: image.id,
                        image: image,
                        characterName: character.name,
                        characterId: character.id,
                        promptTitle: prompt.title,
                        promptId: prompt.id,
                        isProfileImage: false
                    ))
                }
            }
            
            // Add profile image if it's unique (not already in a prompt)
            if let profileData = character.profileImageData,
               !seenImageData.contains(profileData) {
                let profileImage = PromptImage(data: profileData)
                result.append(AllImagesGallerySheet.GalleryImage(
                    id: profileImage.id,
                    image: profileImage,
                    characterName: character.name,
                    characterId: character.id,
                    promptTitle: "Profile Image",
                    promptId: UUID(), // Placeholder - not a real prompt
                    isProfileImage: true
                ))
            }
        }
        return result
    }
    
    private var allImages: [(image: PromptImage, characterName: String, promptTitle: String)] {
        var result: [(PromptImage, String, String)] = []
        var seenImageData = Set<Data>()
        
        for character in characters {
            // Add prompt images
            for prompt in character.prompts {
                for image in prompt.images {
                    seenImageData.insert(image.data)
                    result.append((image, character.name, prompt.title))
                }
            }
            
            // Add profile image if unique
            if let profileData = character.profileImageData,
               !seenImageData.contains(profileData) {
                let profileImage = PromptImage(data: profileData)
                result.append((profileImage, character.name, "Profile Image"))
            }
        }
        return result
    }
    
    private var totalPromptCount: Int {
        characters.reduce(0) { $0 + $1.prompts.count }
    }
    
    // MARK: - Body
    
    var body: some View {
        let theme = themeManager.resolved
        
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Hero Section
                    heroSection
                    
                    // Your Creations Gallery (always show)
                    creationsGallerySection
                    
                    // Getting Started / Features
                    featuresSection
                    
                    // Call to Action
                    callToActionSection
                    
                    Spacer(minLength: 40)
                }
                .padding()
            }
            .themedBackground()
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)
        .sheet(isPresented: $showImageGallery) {
            AllImagesGallerySheet(
                characters: characters,
                onNavigateToCharacter: { characterId in
                    showImageGallery = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        navigateToCharacter(characterId)
                    }
                },
                onNavigateToPrompt: { characterId, promptId in
                    showImageGallery = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        navigateToPrompt(characterId, promptId)
                    }
                }
            )
        }
        .fullScreenCover(item: Binding(
            get: { selectedImageIndex.map { HomeImageViewerItem(index: $0) } },
            set: { selectedImageIndex = $0?.index }
        )) { item in
            SwipeableImageViewer(
                images: allGalleryImages,
                currentIndex: item.index,
                onNavigateToCharacter: { characterId in
                    selectedImageIndex = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        navigateToCharacter(characterId)
                    }
                },
                onNavigateToPrompt: { characterId, promptId in
                    selectedImageIndex = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        navigateToPrompt(characterId, promptId)
                    }
                }
            )
        }
    }
    
    // Helper struct for fullScreenCover item binding
    private struct HomeImageViewerItem: Identifiable {
        let index: Int
        var id: Int { index }
    }
    
    // MARK: - Navigation Helpers
    
    private func navigateToCharacter(_ characterId: UUID) {
        // Navigate to specific character
        if let callback = onNavigateToCharacter {
            callback(characterId)
        } else {
            onNavigateToCharacters()
        }
    }
    
    private func navigateToPrompt(_ characterId: UUID, _ promptId: UUID) {
        // Navigate to specific character (prompt navigation would require deeper integration)
        if let callback = onNavigateToCharacter {
            callback(characterId)
        } else {
            onNavigateToCharacters()
        }
    }
    
    // MARK: - Hero Section
    
    private var heroSection: some View {
        let theme = themeManager.resolved
        
        return VStack(alignment: .leading, spacing: 16) {
            // App icon and title
            HStack(spacing: 16) {
                // App icon
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [theme.primary, theme.primary.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(theme.textOnPrimary)
                }
                .frame(width: 60, height: 60)
                .shadow(color: theme.primary.opacity(0.4), radius: 12, x: 0, y: 6)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Chancery")
                        .font(.largeTitle.weight(.bold))
                        .fontDesign(theme.fontDesign)
                        .foregroundColor(theme.textPrimary)
                    
                    Text("AI Prompt and Image Manager")
                        .font(.subheadline)
                        .foregroundColor(theme.textSecondary)
                }
            }
            
            // Tagline
            Text("Build prompts, organize characters, and keep track of your AI-generated images.")
                .font(.body)
                .foregroundColor(theme.textSecondary)
                .lineSpacing(4)
                .padding(.top, 8)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: theme.cornerRadiusMedium)
                .fill(theme.backgroundSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: theme.cornerRadiusMedium)
                .stroke(theme.primary.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Creations Gallery Section
    
    private var creationsGallerySection: some View {
        let theme = themeManager.resolved
        let images = allImages
        let previewImages = Array(images.prefix(6))
        let remainingCount = max(0, images.count - 6)
        
        return VStack(alignment: .leading, spacing: 16) {
            // Header with title
            HStack {
                HStack(spacing: 10) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .foregroundColor(theme.primary)
                        .font(.title3)
                    
                    Text("Your Creations")
                        .font(.title3.weight(.semibold))
                        .fontDesign(theme.fontDesign)
                        .foregroundColor(theme.textPrimary)
                }
                
                Spacer()
                
                if !images.isEmpty {
                    Button {
                        showImageGallery = true
                    } label: {
                        HStack(spacing: 4) {
                            Text("View All")
                                .font(.subheadline.weight(.medium))
                            Image(systemName: "chevron.right")
                                .font(.caption)
                        }
                        .foregroundColor(theme.primary)
                    }
                }
            }
            
            // Inline stats row
            HStack(spacing: 16) {
                HStack(spacing: 5) {
                    Image(systemName: "person.3.fill")
                        .font(.caption2)
                        .foregroundColor(theme.primary)
                    Text("\(characters.count)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(theme.textPrimary)
                    Text(characters.count == 1 ? "character" : "characters")
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                }
                
                Text("•")
                    .font(.caption)
                    .foregroundColor(theme.textSecondary.opacity(0.4))
                
                HStack(spacing: 5) {
                    Image(systemName: "doc.text.fill")
                        .font(.caption2)
                        .foregroundColor(theme.primary)
                    Text("\(totalPromptCount)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(theme.textPrimary)
                    Text(totalPromptCount == 1 ? "prompt" : "prompts")
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                }
                
                Text("•")
                    .font(.caption)
                    .foregroundColor(theme.textSecondary.opacity(0.4))
                
                HStack(spacing: 5) {
                    Image(systemName: "photo.fill")
                        .font(.caption2)
                        .foregroundColor(theme.primary)
                    Text("\(images.count)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(theme.textPrimary)
                    Text(images.count == 1 ? "image" : "images")
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                }
            }
            
            // Image grid preview - clicking opens that specific image
            if !images.isEmpty {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10)
                ], spacing: 10) {
                    ForEach(Array(previewImages.enumerated()), id: \.offset) { index, item in
                        if let uiImage = UIImage(data: item.image.data) {
                            Button {
                                selectedImageIndex = index
                            } label: {
                                ZStack {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(height: 100)
                                        .clipped()
                                        .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadiusSmall))
                                    
                                    // Show remaining count on last image
                                    if index == previewImages.count - 1 && remainingCount > 0 {
                                        RoundedRectangle(cornerRadius: theme.cornerRadiusSmall)
                                            .fill(Color.black.opacity(0.6))
                                        
                                        Text("+\(remainingCount)")
                                            .font(.title2.weight(.bold))
                                            .foregroundColor(.white)
                                    }
                                }
                                .frame(height: 100)
                            }
                        }
                    }
                }
            } else {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "photo.badge.plus")
                        .font(.largeTitle)
                        .foregroundColor(theme.textSecondary.opacity(0.5))
                    
                    if characters.isEmpty {
                        Text("Create characters to start building your collection")
                            .font(.subheadline)
                            .foregroundColor(theme.textSecondary)
                            .multilineTextAlignment(.center)
                    } else {
                        Text("Add images to your prompts to see them here")
                            .font(.subheadline)
                            .foregroundColor(theme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: theme.cornerRadiusMedium)
                .fill(theme.backgroundSecondary)
        )
    }
    
    // MARK: - Features Section
    
    private var featuresSection: some View {
        let theme = themeManager.resolved
        
        return VStack(alignment: .leading, spacing: 16) {
            Text("What You Can Do")
                .font(.title3.weight(.semibold))
                .fontDesign(theme.fontDesign)
                .foregroundColor(theme.textPrimary)
            
            VStack(spacing: 12) {
                featureRow(
                    icon: "square.and.pencil",
                    title: "Scratchpad",
                    description: "Quickly compose prompts with structured sections for physical description, outfit, pose, and more.",
                    theme: theme
                )
                
                featureRow(
                    icon: "person.crop.rectangle.stack",
                    title: "Character Profiles",
                    description: "Save and organize characters with their own prompts, images, and custom settings.",
                    theme: theme
                )
                
                featureRow(
                    icon: "star.fill",
                    title: "Presets & Defaults",
                    description: "Create reusable presets for common styles, poses, and settings to speed up your workflow.",
                    theme: theme
                )
                
                featureRow(
                    icon: "paintpalette.fill",
                    title: "Custom Themes",
                    description: "Personalize the app with themes that match your style.",
                    theme: theme
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: theme.cornerRadiusMedium)
                .fill(theme.backgroundSecondary)
        )
    }
    
    private func featureRow(icon: String, title: String, description: String, theme: ResolvedTheme) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(theme.primary)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(theme.textPrimary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
                    .lineSpacing(2)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: theme.cornerRadiusSmall)
                .fill(theme.backgroundTertiary)
        )
    }
    
    // MARK: - Call to Action Section
    
    private var callToActionSection: some View {
        let theme = themeManager.resolved
        
        return VStack(spacing: 16) {
            // Primary CTA - Start Generating
            Button {
                onNavigateToScratchpad()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.title3.weight(.semibold))
                    
                    Text("Start Generating")
                        .font(.headline.weight(.semibold))
                }
                .foregroundColor(theme.textOnPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(
                        colors: [theme.primary, theme.primary.opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadiusMedium))
                .shadow(color: theme.primary.opacity(0.4), radius: 12, x: 0, y: 6)
            }
            
            // Secondary CTA - View Characters (always show)
            Button {
                onNavigateToCharacters()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "person.3.fill")
                        .font(.subheadline)
                    
                    Text("View Your Characters")
                        .font(.subheadline.weight(.medium))
                }
                .foregroundColor(theme.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: theme.cornerRadiusMedium)
                        .stroke(theme.primary, lineWidth: 1.5)
                )
            }
        }
    }
}
