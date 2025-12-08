//
//  AllImagesGallerySheet.swift
//  Chancery
//
//  Full-screen gallery view for all character images across the app.
//

import SwiftUI

struct AllImagesGallerySheet: View {
    let characters: [CharacterProfile]
    var scenes: [CharacterScene] = []
    var onNavigateToCharacter: ((UUID) -> Void)? = nil
    var onNavigateToPrompt: ((UUID, UUID) -> Void)? = nil
    var onNavigateToScene: ((UUID) -> Void)? = nil
    var onNavigateToScenePrompt: ((UUID, UUID) -> Void)? = nil  // (sceneId, promptId)
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var selectedFilter: FilterOption = .all
    @State private var selectedImageIndex: Int? = nil
    @State private var cachedImages: [GalleryImage] = []
    
    enum FilterOption: String, CaseIterable {
        case all = "All"
        case byCharacter = "By Character"
        case byScene = "By Scene"
    }
    
    struct GalleryImage: Identifiable, Equatable {
        let id: UUID
        let image: PromptImage
        let characterName: String
        let characterId: UUID
        let promptTitle: String
        let promptId: UUID
        var isProfileImage: Bool = false
        var isStandaloneImage: Bool = false
        var sceneId: UUID? = nil  // If this image belongs to a scene
        var sceneName: String? = nil
        
        static func == (lhs: GalleryImage, rhs: GalleryImage) -> Bool {
            lhs.id == rhs.id
        }
    }
    
    private var allImages: [GalleryImage] {
        var result: [GalleryImage] = []
        var seenImageData = Set<Data>()
        
        for character in characters {
            // Add prompt images
            for prompt in character.prompts {
                for image in prompt.images {
                    seenImageData.insert(image.data)
                    result.append(GalleryImage(
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
                    result.append(GalleryImage(
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
            // Use a deterministic ID based on character ID to prevent regeneration
            if let profileData = character.profileImageData,
               !seenImageData.contains(profileData) {
                let profileImageId = UUID(uuidString: "00000000-0000-0000-0000-\(String(format: "%012x", character.id.hashValue & 0xFFFFFFFFFFFF))") ?? UUID()
                let profileImage = PromptImage(id: profileImageId, data: profileData)
                result.append(GalleryImage(
                    id: profileImageId,
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
            let sceneCharacterNames = scene.characterIds.compactMap { id in
                characters.first { $0.id == id }?.name
            }.joined(separator: " & ")
            let displayName = sceneCharacterNames.isEmpty ? scene.name : sceneCharacterNames
            
            // Scene prompt images
            for prompt in scene.prompts {
                for image in prompt.images {
                    if !seenImageData.contains(image.data) {
                        seenImageData.insert(image.data)
                        result.append(GalleryImage(
                            id: image.id,
                            image: image,
                            characterName: displayName,
                            characterId: scene.characterIds.first ?? UUID(),
                            promptTitle: prompt.title.isEmpty ? "Untitled Prompt" : prompt.title,
                            promptId: prompt.id,  // Store actual prompt ID for navigation
                            sceneId: scene.id,
                            sceneName: scene.name
                        ))
                    }
                }
            }
            
            // Scene standalone images
            for image in scene.standaloneImages {
                if !seenImageData.contains(image.data) {
                    seenImageData.insert(image.data)
                    result.append(GalleryImage(
                        id: image.id,
                        image: image,
                        characterName: displayName,
                        characterId: scene.characterIds.first ?? UUID(),
                        promptTitle: "\(scene.name): Gallery",
                        promptId: UUID(),
                        isStandaloneImage: true,
                        sceneId: scene.id,
                        sceneName: scene.name
                    ))
                }
            }
            
            // Scene profile image - use deterministic ID based on scene ID
            if let profileData = scene.profileImageData,
               !seenImageData.contains(profileData) {
                seenImageData.insert(profileData)
                let profileImageId = UUID(uuidString: "11111111-1111-1111-1111-\(String(format: "%012x", scene.id.hashValue & 0xFFFFFFFFFFFF))") ?? UUID()
                let profileImage = PromptImage(id: profileImageId, data: profileData)
                result.append(GalleryImage(
                    id: profileImageId,
                    image: profileImage,
                    characterName: displayName,
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
    
    /// Images grouped by character - MUST use cachedImages to match swipe order
    private var imagesByCharacter: [(character: CharacterProfile, images: [GalleryImage])] {
        let sourceImages = cachedImages.isEmpty ? allImages : cachedImages
        return characters.map { character in
            let images = sourceImages.filter { $0.characterId == character.id && $0.sceneId == nil }
            return (character, images)
        }
    }
    
    /// Images grouped by scene - MUST use cachedImages to match swipe order
    private var imagesByScene: [(scene: CharacterScene, images: [GalleryImage])] {
        let sourceImages = cachedImages.isEmpty ? allImages : cachedImages
        return scenes.map { scene in
            let images = sourceImages.filter { $0.sceneId == scene.id }
            return (scene, images)
        }
    }
    
    /// Ensures cachedImages is populated - called at start of body to guarantee consistency
    private func ensureCachePopulated() {
        if cachedImages.isEmpty {
            // Use DispatchQueue to avoid modifying state during view update
            DispatchQueue.main.async {
                if cachedImages.isEmpty {
                    cachedImages = allImages
                }
            }
        }
    }
    
    var body: some View {
        let theme = themeManager.resolved
        
        // Ensure cachedImages is populated before rendering
        // This is critical for consistent ID matching between grid and swipe viewer
        let _ = ensureCachePopulated()
        
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Stats header
                    statsHeader
                    
                    // Filter picker
                    filterPicker
                    
                    // Content based on filter
                    switch selectedFilter {
                    case .all:
                        allImagesGrid
                    case .byCharacter:
                        characterGroupedView
                    case .byScene:
                        sceneGroupedView
                    }
                }
                .padding()
            }
            .themedBackground()
            .navigationTitle("All Images")
            .navigationBarTitleDisplayMode(.inline)
            .themedNavigationBar()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(theme.primary)
                }
            }
        }
        .onAppear {
            // Cache images on appear to prevent ID regeneration during swiping
            if cachedImages.isEmpty {
                cachedImages = allImages
            }
        }
        .fullScreenCover(item: Binding(
            get: { selectedImageIndex.map { ImageViewerItem(index: $0) } },
            set: { selectedImageIndex = $0?.index }
        )) { item in
            SwipeableImageViewer(
                images: cachedImages,
                currentIndex: item.index,
                onNavigateToCharacter: { characterId in
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onNavigateToCharacter?(characterId)
                    }
                },
                onNavigateToPrompt: { characterId, promptId in
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onNavigateToPrompt?(characterId, promptId)
                    }
                },
                onNavigateToScene: { sceneId in
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onNavigateToScene?(sceneId)
                    }
                },
                onNavigateToScenePrompt: { sceneId, promptId in
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onNavigateToScenePrompt?(sceneId, promptId)
                    }
                }
            )
        }
    }
    
    private struct ImageViewerItem: Identifiable {
        let index: Int
        var id: Int { index }
    }
    
    // MARK: - Stats Header
    
    private var statsHeader: some View {
        let theme = themeManager.resolved
        let images = allImages
        let totalPrompts = characters.reduce(0) { $0 + $1.prompts.count } + scenes.reduce(0) { $0 + $1.prompts.count }
        
        return HStack(spacing: 16) {
            statItem(value: "\(characters.count)", label: "Characters", icon: "person.fill", theme: theme)
            if !scenes.isEmpty {
                statItem(value: "\(scenes.count)", label: "Scenes", icon: "person.3.fill", theme: theme)
            }
            statItem(value: "\(totalPrompts)", label: "Prompts", icon: "doc.text.fill", theme: theme)
            statItem(value: "\(images.count)", label: "Images", icon: "photo.fill", theme: theme)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: theme.cornerRadiusMedium)
                .fill(theme.backgroundSecondary)
        )
    }
    
    private func statItem(value: String, label: String, icon: String, theme: ResolvedTheme) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(theme.primary)
            
            Text(value)
                .font(.title.weight(.bold))
                .foregroundColor(theme.textPrimary)
            
            Text(label)
                .font(.caption)
                .foregroundColor(theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Filter Picker
    
    private var filterPicker: some View {
        let theme = themeManager.resolved
        
        return HStack(spacing: 0) {
            ForEach(FilterOption.allCases, id: \.self) { option in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedFilter = option
                    }
                } label: {
                    Text(option.rawValue)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(selectedFilter == option ? theme.textOnPrimary : theme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            selectedFilter == option
                                ? theme.primary
                                : Color.clear
                        )
                }
            }
        }
        .background(theme.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadiusSmall))
    }
    
    // MARK: - All Images Grid
    
    private var allImagesGrid: some View {
        let theme = themeManager.resolved
        // Use cachedImages for display to ensure consistency with SwipeableImageViewer
        let images = cachedImages.isEmpty ? allImages : cachedImages
        
        return LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8)
        ], spacing: 8) {
            ForEach(images) { galleryImage in
                if let uiImage = UIImage(data: galleryImage.image.data) {
                    Button {
                        // Find the index in cachedImages to ensure correct image opens
                        let searchImages = cachedImages.isEmpty ? allImages : cachedImages
                        if let index = searchImages.firstIndex(where: { $0.id == galleryImage.id }) {
                            if cachedImages.isEmpty {
                                cachedImages = allImages
                            }
                            selectedImageIndex = index
                        }
                    } label: {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 120)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadiusSmall))
                            .overlay(
                                // Character name overlay
                                VStack {
                                    Spacer()
                                    Text(galleryImage.characterName)
                                        .font(.caption2.weight(.medium))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 3)
                                        .background(Color.black.opacity(0.6))
                                        .clipShape(Capsule())
                                        .padding(6)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            )
                    }
                }
            }
        }
    }
    
    // MARK: - Character Grouped View
    
    private var characterGroupedView: some View {
        let theme = themeManager.resolved
        
        return VStack(alignment: .leading, spacing: 24) {
            ForEach(imagesByCharacter, id: \.character.id) { item in
                characterCard(for: item.character, images: item.images, theme: theme)
            }
        }
    }
    
    private func characterCard(for character: CharacterProfile, images: [GalleryImage], theme: ResolvedTheme) -> some View {
        VStack(alignment: .leading, spacing: images.isEmpty ? 0 : 12) {
            // Character header - tappable to navigate to character
            Button {
                dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onNavigateToCharacter?(character.id)
                }
            } label: {
                HStack(spacing: 10) {
                    // Profile image or placeholder
                    if let imageData = character.profileImageData,
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 36, height: 36)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(theme.primary.opacity(0.2))
                            .frame(width: 36, height: 36)
                            .overlay(
                                Text(String(character.name.prefix(1)).uppercased())
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(theme.primary)
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(character.name)
                            .font(.headline)
                            .fontDesign(theme.fontDesign)
                            .foregroundColor(theme.textPrimary)
                        
                        Text(images.isEmpty ? "No images" : "\(images.count) image\(images.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundColor(theme.textSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            // Only show image grid if there are images
            if !images.isEmpty {
                // Images grid for this character
                // Make scrollable if more than 4 rows (12 images with 3 columns)
                let needsScroll = images.count > 12
                
                if needsScroll {
                    ScrollView {
                        characterImageGrid(images: images, theme: theme)
                    }
                    .frame(maxHeight: 440) // ~4 rows of 100pt + spacing + padding
                } else {
                    characterImageGrid(images: images, theme: theme)
                }
            }
        }
        .padding(images.isEmpty ? 12 : 16)
        .background(
            RoundedRectangle(cornerRadius: theme.cornerRadiusMedium)
                .fill(theme.backgroundSecondary)
        )
    }
    
    private func characterImageGrid(images: [GalleryImage], theme: ResolvedTheme) -> some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8)
        ], spacing: 8) {
            ForEach(images) { galleryImage in
                if let uiImage = UIImage(data: galleryImage.image.data) {
                    Button {
                        // Find the index in cachedImages (or allImages if not cached yet)
                        let searchImages = cachedImages.isEmpty ? allImages : cachedImages
                        if let index = searchImages.firstIndex(where: { $0.id == galleryImage.id }) {
                            // Update cache before opening viewer
                            if cachedImages.isEmpty {
                                cachedImages = allImages
                            }
                            selectedImageIndex = index
                        }
                    } label: {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 100)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadiusSmall))
                    }
                }
            }
        }
    }
    
    // MARK: - Scene Grouped View
    
    private var sceneGroupedView: some View {
        let theme = themeManager.resolved
        
        return VStack(alignment: .leading, spacing: 24) {
            if scenes.isEmpty {
                Text("No scenes yet")
                    .font(.subheadline)
                    .foregroundColor(theme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
            } else {
                ForEach(imagesByScene, id: \.scene.id) { item in
                    sceneCard(for: item.scene, images: item.images, theme: theme)
                }
            }
        }
    }
    
    private func sceneCard(for scene: CharacterScene, images: [GalleryImage], theme: ResolvedTheme) -> some View {
        VStack(alignment: .leading, spacing: images.isEmpty ? 0 : 12) {
            // Scene header - tappable to navigate to scene
            Button {
                dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onNavigateToScene?(scene.id)
                }
            } label: {
                HStack(spacing: 10) {
                    // Profile image or placeholder
                    if let imageData = scene.profileImageData,
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 36, height: 36)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(theme.primary.opacity(0.2))
                            .frame(width: 36, height: 36)
                            .overlay(
                                Image(systemName: "person.3.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(theme.primary)
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(scene.name)
                            .font(.headline)
                            .fontDesign(theme.fontDesign)
                            .foregroundColor(theme.textPrimary)
                        
                        Text(images.isEmpty ? "No images" : "\(images.count) image\(images.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundColor(theme.textSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            // Only show image grid if there are images
            if !images.isEmpty {
                let needsScroll = images.count > 12
                
                if needsScroll {
                    ScrollView {
                        characterImageGrid(images: images, theme: theme)
                    }
                    .frame(maxHeight: 440)
                } else {
                    characterImageGrid(images: images, theme: theme)
                }
            }
        }
        .padding(images.isEmpty ? 12 : 16)
        .background(
            RoundedRectangle(cornerRadius: theme.cornerRadiusMedium)
                .fill(theme.backgroundSecondary)
        )
    }
}

// MARK: - Swipeable Image Viewer

struct SwipeableImageViewer: View {
    let images: [AllImagesGallerySheet.GalleryImage]
    let currentIndex: Int
    var onNavigateToCharacter: ((UUID) -> Void)? = nil
    var onNavigateToPrompt: ((UUID, UUID) -> Void)? = nil
    var onNavigateToScene: ((UUID) -> Void)? = nil
    var onNavigateToScenePrompt: ((UUID, UUID) -> Void)? = nil  // (sceneId, promptId)
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedIndex: Int
    @State private var dragOffset: CGFloat = 0
    
    init(images: [AllImagesGallerySheet.GalleryImage], currentIndex: Int, onNavigateToCharacter: ((UUID) -> Void)? = nil, onNavigateToPrompt: ((UUID, UUID) -> Void)? = nil, onNavigateToScene: ((UUID) -> Void)? = nil, onNavigateToScenePrompt: ((UUID, UUID) -> Void)? = nil) {
        self.images = images
        self.currentIndex = currentIndex
        self.onNavigateToCharacter = onNavigateToCharacter
        self.onNavigateToPrompt = onNavigateToPrompt
        self.onNavigateToScene = onNavigateToScene
        self.onNavigateToScenePrompt = onNavigateToScenePrompt
        self._selectedIndex = State(initialValue: currentIndex)
    }
    
    private var currentImage: AllImagesGallerySheet.GalleryImage? {
        guard selectedIndex >= 0 && selectedIndex < images.count else { return nil }
        return images[selectedIndex]
    }
    
    var body: some View {
        let theme = themeManager.resolved
        
        ZStack {
            // Dark background
            Color.black.ignoresSafeArea()
                .opacity(1 - Double(abs(dragOffset)) / 400)
            
            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title3.weight(.medium))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    // Image counter
                    Text("\(selectedIndex + 1) / \(images.count)")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Spacer()
                    
                    // Share button
                    if let image = currentImage, let uiImage = UIImage(data: image.image.data) {
                        ShareLink(item: Image(uiImage: uiImage), preview: SharePreview(image.promptTitle, image: Image(uiImage: uiImage))) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.title3.weight(.medium))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.white.opacity(0.2))
                                .clipShape(Circle())
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                // Swipeable image area with drag-to-dismiss
                // NOTE: Using simple Image instead of ZoomableImage to avoid gesture conflicts
                // ZoomableImage has its own DragGesture that interferes with TabView swiping
                TabView(selection: $selectedIndex) {
                    ForEach(Array(images.enumerated()), id: \.element.id) { index, galleryImage in
                        if let uiImage = UIImage(data: galleryImage.image.data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .padding(.horizontal, 16)
                                .tag(index)
                        }
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .offset(y: dragOffset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            // Only allow downward drag (matches working GalleryView)
                            if value.translation.height > 0 {
                                dragOffset = value.translation.height
                            }
                        }
                        .onEnded { value in
                            if value.translation.height > 150 {
                                dismiss()
                            } else {
                                withAnimation(.spring(response: 0.3)) {
                                    dragOffset = 0
                                }
                            }
                        }
                )
                
                // Bottom info card
                if let image = currentImage {
                    VStack(spacing: 12) {
                        // Character or Scene button - navigate to scene if it's a scene image
                        Button {
                            if let sceneId = image.sceneId {
                                onNavigateToScene?(sceneId)
                            } else {
                                onNavigateToCharacter?(image.characterId)
                            }
                        } label: {
                            HStack {
                                Image(systemName: image.sceneId != nil ? "person.3.fill" : "person.fill")
                                    .foregroundColor(theme.primary)
                                Text(image.sceneId != nil ? (image.sceneName ?? image.characterName) : image.characterName)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            .padding(14)
                            .background(Color.white.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        
                        // Prompt button (hide for profile images and standalone images)
                        if !image.isProfileImage && !image.isStandaloneImage {
                            Button {
                                if let sceneId = image.sceneId {
                                    // Navigate to scene prompt
                                    onNavigateToScenePrompt?(sceneId, image.promptId)
                                } else {
                                    onNavigateToPrompt?(image.characterId, image.promptId)
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "doc.text.fill")
                                        .foregroundColor(theme.primary.opacity(0.8))
                                    Text(image.promptTitle)
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.9))
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.5))
                                }
                                .padding(14)
                                .background(Color.white.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.black.opacity(0.6))
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
        }
    }
}
