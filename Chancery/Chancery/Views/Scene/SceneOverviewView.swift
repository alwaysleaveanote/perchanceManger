//
//  SceneOverviewView.swift
//  Chancery
//
//  Overview section showing scene profile, description, characters, links, and gallery.
//  Mirrors CharacterOverviewView layout for consistency.
//

import SwiftUI

/// Overview section for a scene - mirrors CharacterOverviewView layout
struct SceneOverviewView: View {
    @Binding var scene: CharacterScene
    let characters: [CharacterProfile]
    let allImages: [PromptImage]
    let onImageTap: (Int) -> Void
    let onPromptTap: (Int) -> Void
    let onCreatePrompt: () -> Void
    let onDeletePrompt: (Int) -> Void
    let onDuplicatePrompt: (Int, String) -> Void
    let onCharacterTap: (UUID) -> Void
    let onOpenSettings: () -> Void
    
    @Binding var isEditingInfo: Bool
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var showingProfileImagePicker = false
    @State private var showingProfileImageViewer = false
    @State private var showingGalleryImagePicker = false
    @State private var showNameRequiredToast = false
    @State private var showingDeleteConfirm = false
    @State private var deletePromptIndex: Int? = nil
    @State private var showingDuplicateAlert = false
    @State private var duplicatePromptIndex: Int? = nil
    @State private var duplicatePromptName = ""
    
    private var sceneTheme: ResolvedTheme {
        themeManager.resolvedTheme(forCharacterThemeId: scene.sceneThemeId)
    }
    
    /// Characters included in this scene, ordered by their position in the main characters list
    private var sceneCharacters: [CharacterProfile] {
        // Get characters that are in this scene
        let sceneCharacterSet = Set(scene.characterIds)
        // Filter characters to only those in the scene, preserving characters order
        return characters.filter { sceneCharacterSet.contains($0.id) }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Profile Card - centered hero section (same as character)
            profileCard
            
            // Description & Notes Card (replaces Bio)
            infoCard
            
            // Characters in Scene Card
            charactersCard
            
            // Links Card (using reusable component)
            LinksCard(links: $scene.links, themeId: scene.sceneThemeId)
            
            // Gallery Card (using reusable component)
            GalleryCard(
                images: allImages,
                themeId: scene.sceneThemeId,
                onImageTap: onImageTap,
                onAddImages: { showingGalleryImagePicker = true }
            )
            
            // Prompts Card
            promptsCard
            
            Spacer(minLength: 0)
        }
        .sheet(isPresented: $showingProfileImagePicker) {
            ImagePicker { images in
                if let first = images.first,
                   let data = first.jpegData(compressionQuality: 0.9) {
                    scene.profileImageData = data
                }
            }
        }
        .sheet(isPresented: $showingGalleryImagePicker) {
            ImagePicker(onImagesPicked: { images in
                for image in images {
                    if let data = image.jpegData(compressionQuality: 0.9) {
                        scene.standaloneImages.append(PromptImage(data: data))
                    }
                }
            }, selectionLimit: 0)
        }
        .fullScreenCover(isPresented: $showingProfileImageViewer) {
            ProfileImageViewer(
                imageData: scene.profileImageData,
                characterName: scene.name,
                onReplace: {
                    showingProfileImageViewer = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showingProfileImagePicker = true
                    }
                }
            )
            .environmentObject(themeManager)
        }
        .toast(isPresented: $showNameRequiredToast, message: "Scene name is required", style: .warning, characterThemeId: scene.sceneThemeId)
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
    
    // MARK: - Profile Card (same layout as CharacterOverviewView)
    
    private var profileCard: some View {
        let theme = sceneTheme
        
        return HStack(alignment: .top, spacing: 12) {
            // Edit button
            Button {
                if isEditingInfo {
                    let trimmedName = scene.name.trimmingCharacters(in: .whitespacesAndNewlines)
                    if trimmedName.isEmpty {
                        showNameRequiredToast = true
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
            
            // Profile image
            Button {
                if scene.profileImageData != nil {
                    showingProfileImageViewer = true
                } else {
                    showingProfileImagePicker = true
                }
            } label: {
                ZStack(alignment: .bottomTrailing) {
                    if let data = scene.profileImageData,
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
                                Image(systemName: "person.3.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(theme.textSecondary.opacity(0.5))
                            )
                    }
                    
                    if scene.profileImageData == nil {
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
            
            // Settings button
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
        .themedCard(characterThemeId: scene.sceneThemeId)
    }
    
    // MARK: - Info Card (Description & Notes - replaces Bio)
    
    private let maxTextHeight: CGFloat = 300
    
    private func needsScrolling(_ text: String) -> Bool {
        let lineCount = text.components(separatedBy: .newlines).count
        return lineCount > 15 || text.count > 800
    }
    
    private var infoCard: some View {
        let theme = sceneTheme
        
        return VStack(alignment: .leading, spacing: 16) {
            // Scene Title Section (only visible when editing)
            if isEditingInfo {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Scene Title")
                        .font(.subheadline.weight(.semibold))
                        .fontDesign(theme.fontDesign)
                        .foregroundColor(theme.textPrimary)
                    
                    TextField("Scene title", text: $scene.name)
                        .textFieldStyle(.roundedBorder)
                }
            }
            
            // Description Section
            VStack(alignment: .leading, spacing: 8) {
                Text("Description")
                    .font(.subheadline.weight(.semibold))
                    .fontDesign(theme.fontDesign)
                    .foregroundColor(theme.textPrimary)
                
                if isEditingInfo {
                    DynamicGrowingTextEditor(
                        text: $scene.description,
                        placeholder: "Describe this scene...",
                        minLines: 2,
                        maxLines: 8,
                        characterThemeId: scene.sceneThemeId
                    )
                } else {
                    if scene.description.isEmpty {
                        Text("No description yet")
                            .font(.body)
                            .fontDesign(theme.fontDesign)
                            .foregroundColor(theme.textSecondary)
                            .italic()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else if needsScrolling(scene.description) {
                        ScrollView {
                            Text(scene.description)
                                .font(.body)
                                .fontDesign(theme.fontDesign)
                                .foregroundColor(theme.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxHeight: maxTextHeight)
                    } else {
                        Text(scene.description)
                            .font(.body)
                            .fontDesign(theme.fontDesign)
                            .foregroundColor(theme.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            
        }
        .themedCard(characterThemeId: scene.sceneThemeId)
    }
    
    // MARK: - Characters Card
    
    private var charactersCard: some View {
        let theme = sceneTheme
        
        return VStack(alignment: .leading, spacing: 12) {
            Text("Characters in Scene")
                .font(.subheadline.weight(.semibold))
                .fontDesign(theme.fontDesign)
                .foregroundColor(theme.textPrimary)
            
            if sceneCharacters.isEmpty {
                Text("No characters in this scene")
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
            } else {
                VStack(spacing: 8) {
                    ForEach(sceneCharacters) { character in
                        characterRow(character, theme: theme)
                    }
                }
            }
        }
        .themedCard(characterThemeId: scene.sceneThemeId)
    }
    
    private func characterRow(_ character: CharacterProfile, theme: ResolvedTheme) -> some View {
        Button {
            onCharacterTap(character.id)
        } label: {
            HStack(spacing: 12) {
                // Avatar
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
                .frame(width: 44, height: 44)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(character.name)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(theme.textPrimary)
                    
                    Text("\(character.promptCount) prompts")
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
    
    // MARK: - Prompts Card
    
    private var promptsCard: some View {
        let theme = sceneTheme
        
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
            
            if scene.prompts.isEmpty {
                Text("No prompts yet. Tap + New to create one.")
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
            } else {
                let maxHeight: CGFloat = scene.prompts.count > 5 ? 280 : CGFloat(scene.prompts.count * 56 + 8)
                
                List {
                    ForEach(Array(scene.prompts.enumerated()), id: \.element.id) { index, prompt in
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
                                .tint(sceneTheme.primary)
                            }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .frame(height: maxHeight)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .themedCard(characterThemeId: scene.sceneThemeId)
    }
    
    private func promptRowContent(index: Int, prompt: ScenePrompt, theme: ResolvedTheme) -> some View {
        Button {
            onPromptTap(index)
        } label: {
            HStack(spacing: 12) {
                // Prompt icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(theme.primary.opacity(0.12))
                        .frame(width: 40, height: 40)
                    
                    if let firstImage = prompt.images.first,
                       let uiImage = UIImage(data: firstImage.data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 40, height: 40)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        Image(systemName: "doc.text")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(theme.primary)
                    }
                }
                
                // Prompt info
                VStack(alignment: .leading, spacing: 2) {
                    Text(prompt.title.isEmpty ? "Untitled Prompt" : prompt.title)
                        .font(.subheadline.weight(.medium))
                        .fontDesign(theme.fontDesign)
                        .foregroundColor(theme.textPrimary)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        if !prompt.images.isEmpty {
                            Label("\(prompt.images.count)", systemImage: "photo")
                        }
                    }
                    .font(.caption2)
                    .foregroundColor(theme.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(theme.textSecondary)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: theme.cornerRadiusSmall)
                    .fill(theme.backgroundTertiary)
            )
        }
        .buttonStyle(.plain)
    }
}
