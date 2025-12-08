import SwiftUI
import UIKit

/// Main detail view for a character, showing overview or prompt editor
struct CharacterDetailView: View {
    @Binding var character: CharacterProfile
    let openGenerator: (String) -> Void
    
    /// Optional prompt ID to navigate to on appear (for deep linking)
    var initialPromptId: UUID? = nil
    
    /// All scenes (to show which scenes this character is in)
    var scenes: [CharacterScene] = []
    
    /// Navigate to a scene
    var onSceneTap: ((UUID) -> Void)? = nil

    @EnvironmentObject var presetStore: PromptPresetStore
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPromptIndex: Int? = nil

    // Character-wide gallery
    @State private var showingGallery: Bool = false
    @State private var galleryStartIndex: Int = 0

    // Editing mode for overview (bio + notes)
    @State private var isEditingCharacterInfo: Bool = false
    
    // Settings sheet
    @State private var showingSettings: Bool = false
    
    /// The theme for this character - resolved locally, not globally
    private var characterTheme: ResolvedTheme {
        themeManager.resolvedTheme(forCharacterThemeId: character.characterThemeId)
    }

    var body: some View {
        mainScrollView
        .navigationTitle(character.name.isEmpty ? "Character" : character.name)
        .navigationBarTitleDisplayMode(.inline)
        .characterThemedNavigationBar(characterThemeId: character.characterThemeId)
        .navigationBarBackButtonHidden(selectedPromptIndex != nil || isEditingCharacterInfo)
        .toolbar {
            // Custom back button when viewing a prompt or editing character info
            ToolbarItem(placement: .navigationBarLeading) {
                if selectedPromptIndex != nil {
                    Button {
                        // Dismiss keyboard first, then navigate after a brief delay
                        // This ensures the button works even when keyboard is open
                        KeyboardHelper.dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            withAnimation {
                                selectedPromptIndex = nil
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(characterTheme.primary)
                        .frame(width: 44, height: 44)  // Larger tap target
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                } else if isEditingCharacterInfo {
                    Button {
                        // Dismiss keyboard first, then navigate after a brief delay
                        KeyboardHelper.dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            isEditingCharacterInfo = false
                            dismiss()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(characterTheme.primary)
                        .frame(width: 44, height: 44)  // Larger tap target
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button {
                    KeyboardHelper.dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.secondary)
                }
            }
        }
        .sheet(isPresented: $showingGallery) {
            GalleryView(
                images: allGalleryImages(),
                startIndex: galleryStartIndex,
                profileImageData: character.profileImageData,
                onViewPrompt: { promptIndex in
                    selectedPromptIndex = promptIndex
                },
                onMakeProfilePicture: { imageData in
                    character.profileImageData = imageData
                }
            )
        }
        .sheet(isPresented: $showingSettings) {
            NavigationView {
                CharacterSettingsView(character: $character)
                    .environmentObject(presetStore)
                    .environmentObject(themeManager)
            }
        }
        // Theme is resolved locally via characterTheme - no global state management needed
        .background(characterTheme.background.ignoresSafeArea())
        .onAppear {
            // Navigate to initial prompt if specified (for deep linking)
            applyInitialPromptIfNeeded()
        }
        .onChange(of: initialPromptId) { _, newPromptId in
            // Handle navigation to a new prompt (when view is reused)
            if let promptId = newPromptId,
               let index = character.prompts.firstIndex(where: { $0.id == promptId }) {
                selectedPromptIndex = index
            }
        }
        .onChange(of: character.id) { _, _ in
            // Reset when character changes
            selectedPromptIndex = nil
            applyInitialPromptIfNeeded()
        }
        .onDisappear {
            // Auto-save when view disappears while editing
            if isEditingCharacterInfo {
                isEditingCharacterInfo = false
            }
        }
    }
    
    private func applyInitialPromptIfNeeded() {
        if let promptId = initialPromptId,
           let index = character.prompts.firstIndex(where: { $0.id == promptId }) {
            selectedPromptIndex = index
        }
    }

    // MARK: - Main Scroll View

    private var mainScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    mainColumn
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .padding(.horizontal)
                .padding(.vertical, 16)
                .id("scrollTop")
            }
            .onChange(of: selectedPromptIndex) { _, _ in
                // Reset scroll position when switching between overview and prompt
                withAnimation(.easeOut(duration: 0.1)) {
                    proxy.scrollTo("scrollTop", anchor: .top)
                }
            }
        }
    }

    // MARK: - Main column

    private var mainColumn: some View {
        Group {
            if let idx = selectedPromptIndex,
               character.prompts.indices.contains(idx) {
                PromptEditorView(
                    character: $character,
                    promptIndex: idx,
                    openGenerator: openGenerator,
                    onDelete: {
                        if character.prompts.indices.contains(idx) {
                            character.prompts.remove(at: idx)
                            selectedPromptIndex = nil
                        } else {
                            selectedPromptIndex = nil
                        }
                    },
                    onDuplicate: { newPrompt in
                        character.prompts.append(newPrompt)
                        selectedPromptIndex = character.prompts.count - 1
                    }
                )
            } else {
                CharacterOverviewView(
                    character: $character,
                    allImages: allPromptImages(),
                    onImageTap: { index in
                        galleryStartIndex = index
                        showingGallery = true
                    },
                    onPromptTap: { index in
                        selectedPromptIndex = index
                    },
                    onCreatePrompt: {
                        createNewPrompt()
                    },
                    onOpenSettings: {
                        showingSettings = true
                    },
                    onDeletePrompt: { index in
                        if character.prompts.indices.contains(index) {
                            character.prompts.remove(at: index)
                        }
                    },
                    onDuplicatePrompt: { index, newName in
                        duplicatePrompt(at: index, withName: newName)
                    },
                    scenes: scenes,
                    onSceneTap: onSceneTap,
                    isEditingInfo: $isEditingCharacterInfo
                )
            }
        }
    }

        // MARK: - Actions
    
    private func createNewPrompt() {
        let globalDefaults = presetStore.globalDefaults
        let characterDefaults = character.characterDefaults
        
        func effectiveDefault(_ key: GlobalDefaultKey) -> String? {
            characterDefaults[key]?.nonEmpty
                ?? globalDefaults[key]?.nonEmpty
        }

        let newPrompt = SavedPrompt(
            title: "New Prompt",
            text: "",
            physicalDescription: effectiveDefault(.physicalDescription),
            outfit:              effectiveDefault(.outfit),
            pose:                effectiveDefault(.pose),
            environment:         effectiveDefault(.environment),
            lighting:            effectiveDefault(.lighting),
            styleModifiers:      effectiveDefault(.style),
            technicalModifiers:  effectiveDefault(.technical),
            negativePrompt:      effectiveDefault(.negative)
        )

        character.prompts.append(newPrompt)
        selectedPromptIndex = character.prompts.count - 1
    }
    
    private func duplicatePrompt(at index: Int, withName name: String) {
        guard character.prompts.indices.contains(index) else { return }
        
        let original = character.prompts[index]
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = trimmedName.isEmpty ? "\(original.title) (Copy)" : trimmedName
        
        let newPrompt = SavedPrompt(
            id: UUID(),
            title: finalName,
            physicalDescription: original.physicalDescription,
            outfit: original.outfit,
            pose: original.pose,
            environment: original.environment,
            lighting: original.lighting,
            styleModifiers: original.styleModifiers,
            technicalModifiers: original.technicalModifiers,
            negativePrompt: original.negativePrompt,
            additionalInfo: original.additionalInfo,
            physicalDescriptionPresetName: original.physicalDescriptionPresetName,
            outfitPresetName: original.outfitPresetName,
            posePresetName: original.posePresetName,
            environmentPresetName: original.environmentPresetName,
            lightingPresetName: original.lightingPresetName,
            stylePresetName: original.stylePresetName,
            technicalPresetName: original.technicalPresetName,
            negativePresetName: original.negativePresetName,
            images: [] // Don't copy images
        )
        
        character.prompts.append(newPrompt)
        selectedPromptIndex = character.prompts.count - 1
    }
    
    // MARK: - Images collection (character-wide)

    /// Returns all images for the thumbnail gallery display
    /// Order: profile image -> prompt images -> standalone images
    private func allPromptImages() -> [PromptImage] {
        var images: [PromptImage] = []
        
        // 1. Profile image first (if unique)
        if let profileData = character.profileImageData {
            let isFromPrompt = character.prompts.flatMap { $0.images }.contains { $0.data == profileData }
            let isFromStandalone = character.standaloneImages.contains { $0.data == profileData }
            if !isFromPrompt && !isFromStandalone {
                images.append(PromptImage(id: UUID(), data: profileData))
            }
        }
        
        // 2. Prompt images
        images.append(contentsOf: character.prompts.flatMap { $0.images })
        
        // 3. Standalone images
        images.append(contentsOf: character.standaloneImages)

        return images
    }
    
    /// Returns all images for the swipeable gallery with metadata
    /// Order: profile image -> prompt images -> standalone images (MUST match allPromptImages order)
    private func allGalleryImages() -> [GalleryImage] {
        var images: [GalleryImage] = []
        
        // 1. Profile image first (if unique)
        if let profileData = character.profileImageData {
            let isFromPrompt = character.prompts.flatMap { $0.images }.contains { $0.data == profileData }
            let isFromStandalone = character.standaloneImages.contains { $0.data == profileData }
            if !isFromPrompt && !isFromStandalone {
                images.append(GalleryImage(profileImageData: profileData))
            }
        }
        
        // 2. Prompt images with their prompt index
        for (promptIndex, prompt) in character.prompts.enumerated() {
            for promptImage in prompt.images {
                images.append(GalleryImage(from: promptImage, promptIndex: promptIndex, promptTitle: prompt.title))
            }
        }
        
        // 3. Standalone images
        for standaloneImage in character.standaloneImages {
            images.append(GalleryImage(standaloneImage: standaloneImage))
        }

        return images
    }
}
