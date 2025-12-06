import SwiftUI
import UIKit

/// Main detail view for a character, showing overview or prompt editor
struct CharacterDetailView: View {
    @Binding var character: CharacterProfile
    let openGenerator: (String) -> Void

    @EnvironmentObject var presetStore: PromptPresetStore
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    @State private var isSidebarVisible: Bool = false
    @State private var selectedPromptIndex: Int? = nil

    // Character-wide gallery
    @State private var showingGallery: Bool = false
    @State private var galleryStartIndex: Int = 0

    // Editing mode for overview (bio + notes)
    @State private var isEditingCharacterInfo: Bool = false
    
    // Settings sheet
    @State private var showingSettings: Bool = false

    var body: some View {
        ZStack {
            mainScrollView

            // Sidebar overlay
            if isSidebarVisible {
                Color.black.opacity(0.25)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isSidebarVisible = false
                        }
                    }

                HStack {
                    Spacer()
                    sidebar
                        .frame(width: 260)
                        .padding(.trailing, 8)
                        .transition(.move(edge: .trailing))
                }
            }
        }
        .navigationTitle(character.name.isEmpty ? "Character" : character.name)
        .navigationBarTitleDisplayMode(.inline)
        .themedNavigationBar()
        .navigationBarBackButtonHidden(selectedPromptIndex != nil)
        .toolbar {
            // Custom back button when viewing a prompt - goes to overview instead of character list
            ToolbarItem(placement: .navigationBarLeading) {
                if selectedPromptIndex != nil {
                    Button {
                        withAnimation {
                            selectedPromptIndex = nil
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(themeManager.resolved.primary)
                    }
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isSidebarVisible.toggle()
                    }
                } label: {
                    Image(systemName: isSidebarVisible ? "line.3.horizontal.decrease" : "line.3.horizontal")
                        .foregroundColor(themeManager.resolved.primary)
                }
                .accessibilityLabel("Toggle saved prompts sidebar")
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
        .onAppear {
            print("[CharacterDetailView] onAppear - character id=\(character.id) name='\(character.name)'")
            // Apply character-specific theme if set
            themeManager.setCharacterTheme(character.characterThemeId)
        }
        .onDisappear {
            print("[CharacterDetailView] onDisappear - clearing character theme")
            // Clear character theme when leaving to prevent flash on characters list
            themeManager.clearCharacterTheme()
        }
        .themedBackground()
    }

    // MARK: - Main Scroll View

    private var mainScrollView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                mainColumn
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding(.horizontal)
            .padding(.vertical, 16)
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
                    isEditingInfo: $isEditingCharacterInfo
                )
            }
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        let theme = themeManager.resolved
        
        return VStack(alignment: .leading, spacing: 12) {
            Button(action: {
                func effectiveDefault(_ key: GlobalDefaultKey) -> String? {
                    character.characterDefaults[key]?.nonEmpty
                        ?? presetStore.globalDefaults[key]?.nonEmpty
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

                withAnimation {
                    isSidebarVisible = false
                }
            }) {
                Text("Create New Prompt")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .fontDesign(theme.fontDesign)
                    .foregroundColor(theme.primary)
            }

            Divider()
                .background(theme.divider)

            DisclosureGroup(
                isExpanded: .constant(true),
                content: {
                    if character.prompts.isEmpty {
                        Text("No saved prompts yet.")
                            .font(.caption)
                            .fontDesign(theme.fontDesign)
                            .foregroundColor(theme.textSecondary)
                            .padding(.top, 4)
                    } else {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(character.prompts.indices, id: \.self) { index in
                                let prompt = character.prompts[index]
                                Button {
                                    selectedPromptIndex = index
                                    withAnimation {
                                        isSidebarVisible = false
                                    }
                                } label: {
                                    HStack {
                                        Text(prompt.title.isEmpty ? "Untitled Prompt" : prompt.title)
                                            .font(.subheadline)
                                            .fontDesign(theme.fontDesign)
                                            .foregroundColor(
                                                selectedPromptIndex == index ? theme.primary : theme.textPrimary
                                            )
                                        Spacer()
                                    }
                                    .padding(.vertical, 4)
                                    .padding(.leading, 12)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.top, 4)
                    }
                },
                label: {
                    Text("Saved Prompts")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .fontDesign(theme.fontDesign)
                        .foregroundColor(theme.textPrimary)
                }
            )
            .tint(theme.primary)
            
            // Character Settings button
            Button {
                print("[CharacterDetailView] Settings button tapped - opening settings sheet")
                withAnimation {
                    isSidebarVisible = false
                }
                // Small delay to let sidebar close before showing sheet
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    showingSettings = true
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "gearshape")
                    Text("Character Settings")
                }
                .font(.subheadline.weight(.semibold))
                .fontDesign(theme.fontDesign)
                .foregroundColor(theme.primary)
                .padding(.top, 12)
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding(12)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(
            themeManager.resolved.backgroundSecondary
        )
    }

    // MARK: - Images collection (character-wide)

    private func allPromptImages() -> [PromptImage] {
        var images = character.prompts.flatMap { $0.images }

        // Only add profile image if it wasn't uploaded from a prompt
        if let profileData = character.profileImageData {
            let isFromPrompt = character.prompts.flatMap { $0.images }.contains { $0.data == profileData }
            if !isFromPrompt {
                images.insert(PromptImage(id: UUID(), data: profileData), at: 0)
            }
        }

        return images
    }
    
    private func allGalleryImages() -> [GalleryImage] {
        var images: [GalleryImage] = []
        
        // Only add profile image if it wasn't uploaded from a prompt (i.e., uploaded separately)
        if let profileData = character.profileImageData {
            let isFromPrompt = character.prompts.flatMap { $0.images }.contains { $0.data == profileData }
            if !isFromPrompt {
                images.append(GalleryImage(profileImageData: profileData))
            }
        }
        
        // Add images from each prompt with their prompt index
        for (promptIndex, prompt) in character.prompts.enumerated() {
            for promptImage in prompt.images {
                images.append(GalleryImage(from: promptImage, promptIndex: promptIndex))
            }
        }

        return images
    }
}
