import SwiftUI
import UIKit

/// Overview section showing character profile, bio, notes, links, and gallery
struct CharacterOverviewView: View {
    @Binding var character: CharacterProfile

    let allImages: [PromptImage]
    let onImageTap: (Int) -> Void
    let onPromptTap: (Int) -> Void
    let onCreatePrompt: () -> Void
    let onOpenSettings: () -> Void
    let onDeletePrompt: (Int) -> Void
    let onDuplicatePrompt: (Int, String) -> Void  // index, new name
    var scenes: [CharacterScene] = []  // Scenes this character is in
    var onSceneTap: ((UUID) -> Void)? = nil  // Navigate to scene

    @Binding var isEditingInfo: Bool
    @EnvironmentObject var themeManager: ThemeManager

    @State private var showingProfileImagePicker: Bool = false
    @State private var showingProfileImageViewer: Bool = false
    @State private var showingGalleryImagePicker: Bool = false
    @State private var showNameRequiredToast: Bool = false
    @State private var showingDuplicateAlert: Bool = false
    @State private var duplicatePromptIndex: Int? = nil
    @State private var duplicatePromptName: String = ""
    @State private var showingDeleteConfirm: Bool = false
    @State private var deletePromptIndex: Int? = nil
    
    /// The theme for this character - resolved locally
    private var characterTheme: ResolvedTheme {
        themeManager.resolvedTheme(forCharacterThemeId: character.characterThemeId)
    }

    var body: some View {
        let theme = characterTheme
        
        VStack(alignment: .leading, spacing: 20) {
            // Profile Card - centered hero section
            profileCard
            
            // Bio & Notes Card
            infoCard
            
            // Links Card (using reusable component)
            LinksCard(links: $character.links, themeId: character.characterThemeId)
            
            // Gallery Card
            galleryCard
            
            // Prompts Card
            promptsCard
            
            // Scenes This Character is In Card
            if !scenes.isEmpty || onSceneTap != nil {
                scenesCard
            }

            Spacer(minLength: 0)
        }
        .sheet(isPresented: $showingProfileImagePicker) {
            ImagePicker { images in
                if let first = images.first,
                   let data = first.jpegData(compressionQuality: 0.9) {
                    character.profileImageData = data
                }
            }
        }
        .sheet(isPresented: $showingGalleryImagePicker) {
            ImagePicker(onImagesPicked: { images in
                for image in images {
                    if let data = image.jpegData(compressionQuality: 0.9) {
                        character.standaloneImages.append(PromptImage(data: data))
                    }
                }
            }, selectionLimit: 0)
        }
        .fullScreenCover(isPresented: $showingProfileImageViewer) {
            ProfileImageViewer(
                imageData: character.profileImageData,
                characterName: character.name,
                onReplace: {
                    showingProfileImageViewer = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showingProfileImagePicker = true
                    }
                }
            )
            .environmentObject(themeManager)
        }
        .toast(isPresented: $showNameRequiredToast, message: "Character name is required", style: .warning, characterThemeId: character.characterThemeId)
        .alert("Delete this prompt?", isPresented: $showingDeleteConfirm) {
            Button("Delete", role: .destructive) {
                if let index = deletePromptIndex {
                    onDeletePrompt(index)
                }
                deletePromptIndex = nil
            }
            Button("Cancel", role: .cancel) {
                deletePromptIndex = nil
            }
        }
        .alert("Duplicate Prompt", isPresented: $showingDuplicateAlert) {
            TextField("New prompt name", text: $duplicatePromptName)
            Button("Create") {
                if let index = duplicatePromptIndex {
                    onDuplicatePrompt(index, duplicatePromptName)
                }
                duplicatePromptIndex = nil
                duplicatePromptName = ""
            }
            Button("Cancel", role: .cancel) {
                duplicatePromptIndex = nil
                duplicatePromptName = ""
            }
        } message: {
            Text("Enter a name for the duplicated prompt")
        }
    }
    
    // MARK: - Toast Helper
    
    private func showNameRequiredFeedback() {
        showNameRequiredToast = true
    }
    
    // MARK: - Profile Card
    
    private var profileCard: some View {
        let theme = characterTheme
        
        return HStack(alignment: .top, spacing: 12) {
            // Edit button aligned with top of profile image
            Button {
                if isEditingInfo {
                    // Trying to save - validate name
                    let trimmedName = character.name.trimmingCharacters(in: .whitespacesAndNewlines)
                    if trimmedName.isEmpty {
                        showNameRequiredFeedback()
                        return
                    }
                }
                withAnimation {
                    isEditingInfo.toggle()
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: isEditingInfo ? "checkmark" : "pencil")
                        .font(.system(size: 12, weight: .medium))
                    Text(isEditingInfo ? "Done" : "Edit")
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
            
            Spacer()
            
            // Profile image - centered
            Button {
                if character.profileImageData != nil {
                    // Show enlarged image viewer
                    showingProfileImageViewer = true
                } else {
                    // No image yet, show picker
                    showingProfileImagePicker = true
                }
            } label: {
                ZStack(alignment: .bottomTrailing) {
                    if let data = character.profileImageData,
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
                    if character.profileImageData == nil {
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
            
            Spacer()
            
            // Settings button aligned with top of profile image
            Button {
                onOpenSettings()
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
        .themedCard(characterThemeId: character.characterThemeId)
    }

    // MARK: - Info Card (Bio)
    
    /// Maximum height for scrollable text sections (approximately 15 lines)
    private let maxTextHeight: CGFloat = 300
    
    /// Check if text exceeds the line limit for scrolling
    private func needsScrolling(_ text: String) -> Bool {
        let lineCount = text.components(separatedBy: .newlines).count
        return lineCount > 15 || text.count > 800
    }
    
    private var infoCard: some View {
        let theme = characterTheme
        
        return VStack(alignment: .leading, spacing: 16) {
            // Name Section (only visible when editing)
            if isEditingInfo {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Name")
                        .font(.subheadline.weight(.semibold))
                        .fontDesign(theme.fontDesign)
                        .foregroundColor(theme.textPrimary)
                    
                    ThemedTextField(
                        placeholder: "Character name",
                        text: $character.name,
                        characterThemeId: character.characterThemeId
                    )
                }
                
                ThemedDivider()
            }
            
            // Bio Section
            VStack(alignment: .leading, spacing: 8) {
                Text("Bio")
                    .font(.subheadline.weight(.semibold))
                    .fontDesign(theme.fontDesign)
                    .foregroundColor(theme.textPrimary)

                if isEditingInfo {
                    DynamicGrowingTextEditor(
                        text: $character.bio,
                        placeholder: "Character bio / description",
                        minLines: 2,
                        maxLines: 10,
                        fontSize: 14,
                        characterThemeId: character.characterThemeId
                    )
                } else {
                    if character.bio.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("No bio yet. Tap 'Edit' to add one.")
                            .font(.caption)
                            .fontDesign(theme.fontDesign)
                            .foregroundColor(theme.textSecondary)
                    } else {
                        scrollableTextView(text: character.bio, theme: theme)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
        .themedCard(characterThemeId: character.characterThemeId)
    }
    
    /// A text view that becomes scrollable when content exceeds 15 lines
    @ViewBuilder
    private func scrollableTextView(text: String, theme: ResolvedTheme) -> some View {
        if needsScrolling(text) {
            ScrollView {
                Text(text)
                    .font(.subheadline)
                    .fontDesign(theme.fontDesign)
                    .foregroundColor(theme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: maxTextHeight)
        } else {
            Text(text)
                .font(.subheadline)
                .fontDesign(theme.fontDesign)
                .foregroundColor(theme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Links Card
    // Now using reusable LinksCard component - see body

    // MARK: - Gallery Card

    private var galleryCard: some View {
        let theme = characterTheme
        
        return VStack(alignment: .leading, spacing: 12) {
            // Header with add button
            HStack {
                Text("Image Gallery")
                    .font(.subheadline.weight(.semibold))
                    .fontDesign(theme.fontDesign)
                    .foregroundColor(theme.textPrimary)
                
                Spacer()
                
                Button {
                    showingGalleryImagePicker = true
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

            if allImages.isEmpty {
                Text("No images yet. Tap + Add to upload images for this character.")
                    .font(.caption)
                    .fontDesign(theme.fontDesign)
                    .foregroundColor(theme.textSecondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Array(allImages.enumerated()), id: \.element.id) { index, promptImage in
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
        .themedCard(characterThemeId: character.characterThemeId)
    }
    
    // MARK: - Prompts Card
    
    private var promptsCard: some View {
        let theme = characterTheme
        
        return VStack(alignment: .leading, spacing: 12) {
            // Header with create button
            HStack {
                Text("Prompts")
                    .font(.subheadline.weight(.semibold))
                    .fontDesign(theme.fontDesign)
                    .foregroundColor(theme.textPrimary)
                
                Spacer()
                
                Button {
                    onCreatePrompt()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .semibold))
                        Text("New")
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
            
            if character.prompts.isEmpty {
                Text("No prompts yet. Tap + New to create one.")
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
            } else {
                // Use List for swipe actions support
                let maxHeight: CGFloat = character.prompts.count > 5 ? 280 : CGFloat(character.prompts.count * 56 + 8)
                
                List {
                    ForEach(Array(character.prompts.enumerated()), id: \.element.id) { index, prompt in
                        promptRowContent(index: index, prompt: prompt, theme: theme)
                            .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    deletePromptIndex = index
                                    showingDeleteConfirm = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                .tint(.red)
                                
                                Button {
                                    duplicatePromptIndex = index
                                    duplicatePromptName = "\(prompt.title) (Copy)"
                                    showingDuplicateAlert = true
                                } label: {
                                    Label("Duplicate", systemImage: "doc.on.doc")
                                }
                                .tint(characterTheme.primary)
                            }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .frame(height: maxHeight)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .themedCard(characterThemeId: character.characterThemeId)
    }
    
    private func promptRowContent(index: Int, prompt: SavedPrompt, theme: ResolvedTheme) -> some View {
        Button {
            onPromptTap(index)
        } label: {
            HStack(spacing: 12) {
                // Prompt icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(theme.primary.opacity(0.12))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "doc.text")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(theme.primary)
                }
                
                // Prompt info
                VStack(alignment: .leading, spacing: 2) {
                    Text(prompt.title.isEmpty ? "Untitled Prompt" : prompt.title)
                        .font(.subheadline.weight(.medium))
                        .fontDesign(theme.fontDesign)
                        .foregroundColor(theme.textPrimary)
                        .lineLimit(1)
                    
                    if !prompt.images.isEmpty {
                        Text("\(prompt.images.count) image\(prompt.images.count == 1 ? "" : "s")")
                            .font(.caption2)
                            .foregroundColor(theme.textSecondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.medium))
                    .foregroundColor(theme.textSecondary)
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: theme.cornerRadiusSmall)
                    .fill(theme.backgroundTertiary)
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Scenes Card
    
    /// Scenes this character is in - mirrors charactersCard in SceneOverviewView
    private var scenesCard: some View {
        let theme = characterTheme
        let characterScenes = scenes.filter { $0.characterIds.contains(character.id) }
        
        return VStack(alignment: .leading, spacing: 12) {
            Text("Scenes This Character is In")
                .font(.subheadline.weight(.semibold))
                .fontDesign(theme.fontDesign)
                .foregroundColor(theme.textPrimary)
            
            if characterScenes.isEmpty {
                Text("Not in any scenes yet")
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
            } else {
                VStack(spacing: 8) {
                    ForEach(characterScenes) { scene in
                        sceneRow(scene, theme: theme)
                    }
                }
            }
        }
        .themedCard(characterThemeId: character.characterThemeId)
    }
    
    private func sceneRow(_ scene: CharacterScene, theme: ResolvedTheme) -> some View {
        Button {
            onSceneTap?(scene.id)
        } label: {
            HStack(spacing: 12) {
                // Avatar
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
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(scene.name.isEmpty ? "Untitled Scene" : scene.name)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(theme.textPrimary)
                    
                    Text("\(scene.prompts.count) prompt\(scene.prompts.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.medium))
                    .foregroundColor(theme.textSecondary)
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: theme.cornerRadiusSmall)
                    .fill(theme.backgroundTertiary)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Profile Image Viewer

/// Full-screen viewer for profile image with replace option
struct ProfileImageViewer: View {
    let imageData: Data?
    let characterName: String
    let onReplace: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        let theme = themeManager.resolved
        
        ZStack {
            Color.black.ignoresSafeArea()
            
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
                    
                    Text(characterName)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Share button
                    if let data = imageData, let uiImage = UIImage(data: data) {
                        ShareLink(item: Image(uiImage: uiImage), preview: SharePreview(characterName, image: Image(uiImage: uiImage))) {
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
                
                // Zoomable Image
                if let data = imageData, let uiImage = UIImage(data: data) {
                    ZoomableImage(uiImage: uiImage)
                        .padding(16)
                } else {
                    Spacer()
                    Text("No image")
                        .foregroundColor(.white.opacity(0.5))
                    Spacer()
                }
                
                // Bottom action card
                VStack(spacing: 12) {
                    Button {
                        onReplace()
                    } label: {
                        HStack {
                            Image(systemName: "photo.badge.arrow.down")
                                .foregroundColor(theme.primary)
                            Text("Replace Profile Image")
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
