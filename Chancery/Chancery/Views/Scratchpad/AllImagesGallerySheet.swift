//
//  AllImagesGallerySheet.swift
//  Chancery
//
//  Full-screen gallery view for all character images across the app.
//

import SwiftUI

struct AllImagesGallerySheet: View {
    let characters: [CharacterProfile]
    var onNavigateToCharacter: ((UUID) -> Void)? = nil
    var onNavigateToPrompt: ((UUID, UUID) -> Void)? = nil
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var selectedFilter: FilterOption = .all
    @State private var selectedImageIndex: Int? = nil
    
    enum FilterOption: String, CaseIterable {
        case all = "All"
        case byCharacter = "By Character"
    }
    
    struct GalleryImage: Identifiable, Equatable {
        let id: UUID
        let image: PromptImage
        let characterName: String
        let characterId: UUID
        let promptTitle: String
        let promptId: UUID
        var isProfileImage: Bool = false
        
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
            
            // Add profile image if it's unique (not already in a prompt)
            if let profileData = character.profileImageData,
               !seenImageData.contains(profileData) {
                let profileImage = PromptImage(data: profileData)
                result.append(GalleryImage(
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
    
    private var imagesByCharacter: [(character: CharacterProfile, images: [GalleryImage])] {
        characters.compactMap { character in
            let images = allImages.filter { $0.characterId == character.id }
            return images.isEmpty ? nil : (character, images)
        }
    }
    
    var body: some View {
        let theme = themeManager.resolved
        
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Stats header
                    statsHeader
                    
                    // Filter picker
                    filterPicker
                    
                    // Content based on filter
                    if selectedFilter == .all {
                        allImagesGrid
                    } else {
                        characterGroupedView
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
        .fullScreenCover(item: Binding(
            get: { selectedImageIndex.map { ImageViewerItem(index: $0) } },
            set: { selectedImageIndex = $0?.index }
        )) { item in
            SwipeableImageViewer(
                images: allImages,
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
        let totalPrompts = characters.reduce(0) { $0 + $1.prompts.count }
        
        return HStack(spacing: 20) {
            statItem(value: "\(characters.count)", label: "Characters", icon: "person.3.fill", theme: theme)
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
        let images = allImages
        
        return LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8)
        ], spacing: 8) {
            ForEach(Array(images.enumerated()), id: \.element.id) { index, galleryImage in
                if let uiImage = UIImage(data: galleryImage.image.data) {
                    Button {
                        selectedImageIndex = index
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
                VStack(alignment: .leading, spacing: 12) {
                    // Character header
                    HStack(spacing: 10) {
                        // Profile image or placeholder
                        if let imageData = item.character.profileImageData,
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
                                    Text(String(item.character.name.prefix(1)).uppercased())
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(theme.primary)
                                )
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.character.name)
                                .font(.headline)
                                .fontDesign(theme.fontDesign)
                                .foregroundColor(theme.textPrimary)
                            
                            Text("\(item.images.count) images")
                                .font(.caption)
                                .foregroundColor(theme.textSecondary)
                        }
                    }
                    
                    // Images grid for this character
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 8),
                        GridItem(.flexible(), spacing: 8),
                        GridItem(.flexible(), spacing: 8)
                    ], spacing: 8) {
                        ForEach(item.images) { galleryImage in
                            if let uiImage = UIImage(data: galleryImage.image.data) {
                                Button {
                                    // Find the index in allImages
                                    if let index = allImages.firstIndex(where: { $0.id == galleryImage.id }) {
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
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: theme.cornerRadiusMedium)
                        .fill(theme.backgroundSecondary)
                )
            }
        }
    }
}

// MARK: - Swipeable Image Viewer

struct SwipeableImageViewer: View {
    let images: [AllImagesGallerySheet.GalleryImage]
    let currentIndex: Int
    var onNavigateToCharacter: ((UUID) -> Void)? = nil
    var onNavigateToPrompt: ((UUID, UUID) -> Void)? = nil
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedIndex: Int
    @State private var dragOffset: CGFloat = 0
    
    init(images: [AllImagesGallerySheet.GalleryImage], currentIndex: Int, onNavigateToCharacter: ((UUID) -> Void)? = nil, onNavigateToPrompt: ((UUID, UUID) -> Void)? = nil) {
        self.images = images
        self.currentIndex = currentIndex
        self.onNavigateToCharacter = onNavigateToCharacter
        self.onNavigateToPrompt = onNavigateToPrompt
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
                            // Only allow downward drag
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
                        // Character button
                        Button {
                            onNavigateToCharacter?(image.characterId)
                        } label: {
                            HStack {
                                Image(systemName: "person.fill")
                                    .foregroundColor(theme.primary)
                                Text(image.characterName)
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
                        
                        // Prompt button (hide for profile images)
                        if !image.isProfileImage {
                            Button {
                                onNavigateToPrompt?(image.characterId, image.promptId)
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
