//
//  HomeView.swift
//  Chancery
//
//  The home screen with app introduction, image gallery, and quick actions.
//

import SwiftUI

struct HomeView: View {
    let characters: [CharacterProfile]
    let scenes: [CharacterScene]
    let onNavigateToScratchpad: () -> Void
    let onNavigateToCharacters: () -> Void
    let onNavigateToCharacter: ((UUID) -> Void)?
    let onNavigateToPrompt: ((UUID, UUID) -> Void)?
    let onNavigateToScene: ((UUID) -> Void)?
    let onNavigateToScenePrompt: ((UUID, UUID) -> Void)?
    
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showImageGallery = false
    @State private var selectedImageIndex: Int? = nil
    @State private var showAppTour = false
    
    // MARK: - Computed Properties
    
    private var hasAnyImages: Bool {
        // Check character images
        let hasCharacterImages = characters.contains { character in
            character.prompts.contains { !$0.images.isEmpty } ||
            !character.standaloneImages.isEmpty ||
            character.profileImageData != nil
        }
        
        // Check scene images
        let hasSceneImages = scenes.contains { scene in
            scene.prompts.contains { !$0.images.isEmpty } ||
            !scene.standaloneImages.isEmpty ||
            scene.profileImageData != nil
        }
        
        return hasCharacterImages || hasSceneImages
    }
    
    /// All images with full metadata for gallery (includes profile images, standalone images, avoids duplicates)
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
            
            // Add standalone images
            for image in character.standaloneImages {
                if !seenImageData.contains(image.data) {
                    seenImageData.insert(image.data)
                    result.append(AllImagesGallerySheet.GalleryImage(
                        id: image.id,
                        image: image,
                        characterName: character.name,
                        characterId: character.id,
                        promptTitle: "Gallery Image",
                        promptId: UUID(), // Placeholder - not a real prompt
                        isProfileImage: false,
                        isStandaloneImage: true
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
        
        // Add scene images
        for scene in scenes {
            // Scene prompt images
            for prompt in scene.prompts {
                for image in prompt.images {
                    if !seenImageData.contains(image.data) {
                        seenImageData.insert(image.data)
                        // Get character names for the scene
                        let sceneCharacterNames = scene.characterIds.compactMap { id in
                            characters.first { $0.id == id }?.name
                        }.joined(separator: " & ")
                        result.append(AllImagesGallerySheet.GalleryImage(
                            id: image.id,
                            image: image,
                            characterName: sceneCharacterNames.isEmpty ? scene.name : sceneCharacterNames,
                            characterId: scene.characterIds.first ?? UUID(),
                            promptTitle: prompt.title.isEmpty ? "Untitled Prompt" : prompt.title,
                            promptId: prompt.id,  // Use actual prompt ID for navigation
                            isProfileImage: false,
                            sceneId: scene.id,  // Set scene ID for scene prompt navigation
                            sceneName: scene.name
                        ))
                    }
                }
            }
            
            // Scene standalone images
            for image in scene.standaloneImages {
                if !seenImageData.contains(image.data) {
                    seenImageData.insert(image.data)
                    let sceneCharacterNames = scene.characterIds.compactMap { id in
                        characters.first { $0.id == id }?.name
                    }.joined(separator: " & ")
                    result.append(AllImagesGallerySheet.GalleryImage(
                        id: image.id,
                        image: image,
                        characterName: sceneCharacterNames.isEmpty ? scene.name : sceneCharacterNames,
                        characterId: scene.characterIds.first ?? UUID(),
                        promptTitle: "\(scene.name): Gallery",
                        promptId: UUID(),
                        isProfileImage: false,
                        isStandaloneImage: true,
                        sceneId: scene.id,
                        sceneName: scene.name
                    ))
                }
            }
            
            // Scene profile image
            if let profileData = scene.profileImageData,
               !seenImageData.contains(profileData) {
                seenImageData.insert(profileData)
                let profileImage = PromptImage(data: profileData)
                let sceneCharacterNames = scene.characterIds.compactMap { id in
                    characters.first { $0.id == id }?.name
                }.joined(separator: " & ")
                result.append(AllImagesGallerySheet.GalleryImage(
                    id: profileImage.id,
                    image: profileImage,
                    characterName: sceneCharacterNames.isEmpty ? scene.name : sceneCharacterNames,
                    characterId: scene.characterIds.first ?? UUID(),
                    promptTitle: "\(scene.name): Profile",
                    promptId: UUID(),
                    isProfileImage: true,
                    sceneId: scene.id,
                    sceneName: scene.name
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
            
            // Add standalone images
            for image in character.standaloneImages {
                if !seenImageData.contains(image.data) {
                    seenImageData.insert(image.data)
                    result.append((image, character.name, "Gallery Image"))
                }
            }
            
            // Add profile image if unique
            if let profileData = character.profileImageData,
               !seenImageData.contains(profileData) {
                let profileImage = PromptImage(data: profileData)
                result.append((profileImage, character.name, "Profile Image"))
            }
        }
        
        // Add scene images
        for scene in scenes {
            let sceneCharacterNames = scene.characterIds.compactMap { id in
                characters.first { $0.id == id }?.name
            }.joined(separator: " & ")
            let displayName = sceneCharacterNames.isEmpty ? scene.name : sceneCharacterNames
            
            for prompt in scene.prompts {
                for image in prompt.images {
                    if !seenImageData.contains(image.data) {
                        seenImageData.insert(image.data)
                        result.append((image, displayName, "\(scene.name): \(prompt.title)"))
                    }
                }
            }
            
            for image in scene.standaloneImages {
                if !seenImageData.contains(image.data) {
                    seenImageData.insert(image.data)
                    result.append((image, displayName, "\(scene.name): Gallery"))
                }
            }
            
            // Scene profile image
            if let profileData = scene.profileImageData,
               !seenImageData.contains(profileData) {
                seenImageData.insert(profileData)
                let profileImage = PromptImage(data: profileData)
                result.append((profileImage, displayName, "\(scene.name): Profile"))
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
        .fullScreenCover(isPresented: $showAppTour) {
            AppTourView()
                .environmentObject(themeManager)
        }
        .sheet(isPresented: $showImageGallery) {
            AllImagesGallerySheet(
                characters: characters,
                scenes: scenes,
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
                },
                onNavigateToScene: { sceneId in
                    showImageGallery = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        navigateToScene(sceneId)
                    }
                },
                onNavigateToScenePrompt: { sceneId, promptId in
                    showImageGallery = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        navigateToScenePrompt(sceneId, promptId)
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
                },
                onNavigateToScene: { sceneId in
                    selectedImageIndex = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        navigateToScene(sceneId)
                    }
                },
                onNavigateToScenePrompt: { sceneId, promptId in
                    selectedImageIndex = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        navigateToScenePrompt(sceneId, promptId)
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
        // Navigate to specific prompt within a character
        if let callback = onNavigateToPrompt {
            callback(characterId, promptId)
        } else if let charCallback = onNavigateToCharacter {
            charCallback(characterId)
        } else {
            onNavigateToCharacters()
        }
    }
    
    private func navigateToScene(_ sceneId: UUID) {
        if let callback = onNavigateToScene {
            callback(sceneId)
        } else {
            // Fallback to characters tab if no callback provided
            onNavigateToCharacters()
        }
    }
    
    private func navigateToScenePrompt(_ sceneId: UUID, _ promptId: UUID) {
        if let callback = onNavigateToScenePrompt {
            callback(sceneId, promptId)
        } else {
            // Fallback to scene navigation if no prompt callback provided
            navigateToScene(sceneId)
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
            
            // Stats row - modern pill design
            HStack(spacing: 8) {
                statPill(icon: "person.fill", count: characters.count, theme: theme)
                
                if !scenes.isEmpty {
                    statPill(icon: "person.2.fill", count: scenes.count, theme: theme)
                }
                
                statPill(icon: "doc.text.fill", count: totalPromptCount, theme: theme)
                statPill(icon: "photo.fill", count: images.count, theme: theme)
                
                Spacer()
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
    
    /// Modern stat pill for the creations section
    private func statPill(icon: String, count: Int, theme: ResolvedTheme) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(theme.primary)
            Text("\(count)")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(theme.textPrimary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(theme.primary.opacity(0.1))
        )
    }
    
    // MARK: - Features Section
    
    private var featuresSection: some View {
        let theme = themeManager.resolved
        
        return VStack(alignment: .leading, spacing: 20) {
            Text("What You Can Do")
                .font(.title3.weight(.semibold))
                .fontDesign(theme.fontDesign)
                .foregroundColor(theme.textPrimary)
            
            VStack(alignment: .leading, spacing: 16) {
                featureItem(
                    icon: "square.and.pencil",
                    title: "Scratchpad",
                    description: "Quickly compose prompts with structured sections for physical description, outfit, pose, and more.",
                    theme: theme
                )
                
                featureItem(
                    icon: "person.crop.rectangle.stack",
                    title: "Character Profiles",
                    description: "Save and organize characters with their own prompts, images, and custom settings.",
                    theme: theme
                )
                
                featureItem(
                    icon: "star.fill",
                    title: "Presets & Defaults",
                    description: "Create reusable presets for common styles, poses, and settings to speed up your workflow.",
                    theme: theme
                )
                
                featureItem(
                    icon: "paintpalette.fill",
                    title: "Custom Themes",
                    description: "Personalize the app with themes that match your style.",
                    theme: theme
                )
            }
            
            // Tour action - stands out with accent styling
            Button {
                showAppTour = true
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(theme.primary)
                            .frame(width: 40, height: 40)
                        Image(systemName: "play.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(theme.textOnPrimary)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Take a Tour")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(theme.textPrimary)
                        Text("Learn how to get the most out of Chancery")
                            .font(.caption)
                            .foregroundColor(theme.textSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(theme.primary)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: theme.cornerRadiusSmall)
                        .fill(theme.primary.opacity(0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: theme.cornerRadiusSmall)
                        .stroke(theme.primary.opacity(0.2), lineWidth: 1)
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: theme.cornerRadiusMedium)
                .fill(theme.backgroundSecondary)
        )
    }
    
    private func featureItem(icon: String, title: String, description: String, theme: ResolvedTheme) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(theme.primary.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(theme.primary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(theme.textPrimary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
                    .lineSpacing(2)
            }
            
            Spacer(minLength: 0)
        }
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
