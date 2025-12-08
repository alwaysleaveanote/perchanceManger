//
//  ScenePromptEditorView.swift
//  Chancery
//
//  Editor for scene prompts with tabs for scene-wide and per-character settings.
//

import SwiftUI

struct ScenePromptEditorView: View {
    @Binding var scene: CharacterScene
    let promptIndex: Int
    let characters: [CharacterProfile]
    let openGenerator: (String) -> Void
    let onDelete: () -> Void
    let onDuplicate: (ScenePrompt) -> Void
    
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var presetStore: PromptPresetStore
    
    @State private var selectedTab: PromptTab = .scene
    @State private var showingImagePicker = false
    @State private var showCopiedToast = false
    @State private var showingDeleteConfirm = false
    @State private var showingDuplicateAlert = false
    @State private var duplicatePromptName = ""
    @State private var showingPromptGallery = false
    @State private var promptGalleryStartIndex = 0
    @State private var showingAddToOtherScenes = false
    @State private var showAddedToast = false
    @State private var addedToSceneCount = 0
    @State private var pendingPresetKind: PromptSectionKind? = nil
    @State private var pendingPresetText: String = ""
    @State private var pendingPresetLabel: String = ""
    @State private var pendingPresetNameInput: String = ""
    @State private var showingPresetAlert: Bool = false
    
    private var promptBinding: Binding<ScenePrompt> {
        Binding(
            get: { scene.prompts[promptIndex] },
            set: { scene.prompts[promptIndex] = $0 }
        )
    }
    
    private var prompt: ScenePrompt {
        promptBinding.wrappedValue
    }
    
    private var sceneTheme: ResolvedTheme {
        themeManager.resolvedTheme(forCharacterThemeId: scene.sceneThemeId)
    }
    
    enum PromptTab: Hashable {
        case scene
        case character(UUID)
    }
    
    // MARK: - Bindings (matching PromptEditorView pattern)
    
    private var titleBinding: Binding<String> {
        Binding(
            get: { promptBinding.wrappedValue.title },
            set: { promptBinding.wrappedValue.title = $0 }
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Title + Images (combined like character prompt)
            titleSection
            
            // Quick Actions Bar (matching character prompt style)
            quickActionsBar
            
            // Prompt Preview Card
            promptPreviewCard
            
            // Tab selector for scene/character settings
            tabSelector
            
            // Content based on selected tab
            tabContent
            
            // Delete button - full width at bottom
            ThemedButton("Delete Prompt", icon: "trash", style: .destructive) {
                showingDeleteConfirm = true
            }
        }
        .toast(isPresented: $showCopiedToast, message: "Copied to clipboard", style: .success, characterThemeId: scene.sceneThemeId)
        .alert("Delete this prompt?", isPresented: $showingDeleteConfirm) {
            Button("Delete", role: .destructive) {
                onDelete()
            }
            Button("Cancel", role: .cancel) { }
        }
        .alert("Duplicate Prompt", isPresented: $showingDuplicateAlert) {
            TextField("New prompt name", text: $duplicatePromptName)
            Button("Create") {
                let newPrompt = createDuplicatePrompt(withName: duplicatePromptName)
                onDuplicate(newPrompt)
                duplicatePromptName = ""
            }
            Button("Cancel", role: .cancel) {
                duplicatePromptName = ""
            }
        } message: {
            Text("Enter a name for the duplicated prompt")
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker { uiImages in
                var updated = promptBinding.wrappedValue
                for image in uiImages {
                    if let data = image.jpegData(compressionQuality: 0.9) {
                        updated.images.append(PromptImage(id: UUID(), data: data))
                    }
                }
                promptBinding.wrappedValue = updated
            }
        }
        .fullScreenCover(isPresented: $showingPromptGallery) {
            GalleryView(
                images: promptBinding.wrappedValue.images.map { GalleryImage(from: $0, promptIndex: promptIndex, promptTitle: promptBinding.wrappedValue.title) },
                startIndex: promptGalleryStartIndex,
                onMakeProfilePicture: { imageData in
                    scene.profileImageData = imageData
                }
            )
        }
        .sheet(isPresented: $showingAddToOtherScenes) {
            MultiScenePickerSheet(
                scenes: DataStore.shared.scenes,
                prompt: prompt,
                onComplete: { selectedScenes in
                    // Add prompt to selected scenes
                    for targetScene in selectedScenes {
                        // Copy character settings for characters that exist in both scenes
                        var copiedCharacterSettings: [UUID: SceneCharacterSettings] = [:]
                        for characterId in targetScene.characterIds {
                            if let settings = prompt.characterSettings[characterId] {
                                copiedCharacterSettings[characterId] = settings
                            }
                        }
                        
                        // Create a copy of the prompt with new ID
                        let newPrompt = ScenePrompt(
                            title: prompt.title,
                            environment: prompt.environment,
                            lighting: prompt.lighting,
                            styleModifiers: prompt.styleModifiers,
                            technicalModifiers: prompt.technicalModifiers,
                            negativePrompt: prompt.negativePrompt,
                            additionalInfo: prompt.additionalInfo,
                            characterSettings: copiedCharacterSettings,
                            images: [] // Don't copy images
                        )
                        
                        // Find and update the scene
                        if let index = DataStore.shared.scenes.firstIndex(where: { $0.id == targetScene.id }) {
                            var updatedScene = DataStore.shared.scenes[index]
                            updatedScene.prompts.append(newPrompt)
                            DataStore.shared.updateScene(updatedScene)
                        }
                    }
                    
                    // Show toast
                    addedToSceneCount = selectedScenes.count
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showAddedToast = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showAddedToast = false
                        }
                    }
                },
                excludeSceneId: scene.id
            )
            .environmentObject(themeManager)
        }
        .overlay(alignment: .top) {
            if showAddedToast {
                addedToastView
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .alert("Save as Preset", isPresented: $showingPresetAlert) {
            TextField("Preset name", text: $pendingPresetNameInput)
            Button("Save") {
                let nameTrimmed = pendingPresetNameInput.trimmingCharacters(in: .whitespacesAndNewlines)
                let finalName = nameTrimmed.isEmpty ? pendingPresetLabel : nameTrimmed
                
                if let kind = pendingPresetKind {
                    presetStore.addPreset(kind: kind, name: finalName, text: pendingPresetText)
                    // Re-sync all preset markers after a brief delay to ensure store is updated
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        resyncAllPresetMarkers()
                    }
                }
                
                pendingPresetKind = nil
                pendingPresetText = ""
                pendingPresetLabel = ""
                pendingPresetNameInput = ""
            }
            Button("Cancel", role: .cancel) {
                pendingPresetKind = nil
                pendingPresetText = ""
                pendingPresetLabel = ""
                pendingPresetNameInput = ""
            }
        } message: {
            Text("Save the current text as a reusable preset for this section.")
        }
    }
    
    // MARK: - Added Toast
    
    private var addedToastView: some View {
        let theme = sceneTheme
        
        return HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(theme.textOnPrimary)
            Text("Added to \(addedToSceneCount) scene\(addedToSceneCount == 1 ? "" : "s")")
                .font(.subheadline.weight(.medium))
                .fontDesign(theme.fontDesign)
                .foregroundColor(theme.textOnPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(theme.success)
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        )
        .padding(.top, 60)
    }
    
    private func createDuplicatePrompt(withName name: String) -> ScenePrompt {
        let original = promptBinding.wrappedValue
        return ScenePrompt(
            title: name.isEmpty ? "\(original.title) (Copy)" : name,
            environment: original.environment,
            lighting: original.lighting,
            styleModifiers: original.styleModifiers,
            technicalModifiers: original.technicalModifiers,
            negativePrompt: original.negativePrompt,
            additionalInfo: original.additionalInfo,
            characterSettings: original.characterSettings,
            images: [] // Don't copy images
        )
    }
    
    // MARK: - Title Section (matches PromptEditorView style)
    
    private var titleSection: some View {
        let theme = sceneTheme
        
        return VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Prompt title")
                    .font(.caption)
                    .fontDesign(theme.fontDesign)
                    .foregroundColor(theme.textSecondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
                
                TextField("Untitled prompt", text: titleBinding)
                    .font(.title2.weight(.bold))
                    .fontDesign(theme.fontDesign)
                    .foregroundColor(theme.textPrimary)
                    .textFieldStyle(.plain)
            }
            
            // Images section inline with title (like character prompt)
            imagesSection
        }
        .themedCard(characterThemeId: scene.sceneThemeId)
    }
    
    // MARK: - Tab Selector
    
    private var tabSelector: some View {
        let theme = sceneTheme
        
        return VStack(alignment: .leading, spacing: 8) {
            // Section label
            Text("Edit Settings For:")
                .font(.caption)
                .fontDesign(theme.fontDesign)
                .foregroundColor(theme.textSecondary)
                .textCase(.uppercase)
                .tracking(0.5)
                .padding(.horizontal, 4)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    // Scene tab
                    tabButton(
                        title: "Scene",
                        subtitle: "Environment & Style",
                        icon: "sparkles",
                        isSelected: selectedTab == .scene,
                        theme: theme
                    ) {
                        selectedTab = .scene
                    }
                    
                    // Character tabs
                    ForEach(characters) { character in
                        tabButton(
                            title: character.name,
                            subtitle: "Appearance & Pose",
                            icon: "person.fill",
                            isSelected: selectedTab == .character(character.id),
                            theme: theme,
                            profileImage: character.profileImageData
                        ) {
                            selectedTab = .character(character.id)
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    private func tabButton(
        title: String,
        subtitle: String,
        icon: String,
        isSelected: Bool,
        theme: ResolvedTheme,
        profileImage: Data? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // Icon or profile image - larger and more prominent
                if let imageData = profileImage, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(isSelected ? theme.primary : Color.clear, lineWidth: 3)
                        )
                        .shadow(color: isSelected ? theme.primary.opacity(0.3) : .clear, radius: 4)
                } else {
                    ZStack {
                        Circle()
                            .fill(isSelected ? theme.primary : theme.backgroundTertiary)
                            .frame(width: 44, height: 44)
                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(isSelected ? theme.textOnPrimary : theme.textSecondary)
                    }
                    .shadow(color: isSelected ? theme.primary.opacity(0.3) : .clear, radius: 4)
                }
                
                // Title and subtitle - centered below icon
                VStack(spacing: 2) {
                    Text(title)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(isSelected ? theme.primary : theme.textSecondary)
                        .lineLimit(1)
                    
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(theme.textSecondary.opacity(0.7))
                        .lineLimit(1)
                }
            }
            .frame(minWidth: 80)
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? theme.primary.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Tab Content
    
    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .scene:
            sceneSettingsSection
        case .character(let characterId):
            if let character = characters.first(where: { $0.id == characterId }) {
                characterSettingsSection(for: character)
            }
        }
    }
    
    // MARK: - Scene Settings Section
    
    private var sceneSettingsSection: some View {
        let theme = sceneTheme
        
        return VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Scene Settings")
                    .font(.headline)
                    .foregroundColor(theme.textPrimary)
                
                Spacer()
                
                // Load from any character's prompt - modern styled button
                Menu {
                    ForEach(characters) { character in
                        if !character.prompts.isEmpty {
                            Menu(character.name) {
                                ForEach(character.prompts) { characterPrompt in
                                    Button(characterPrompt.title.isEmpty ? "Untitled" : characterPrompt.title) {
                                        loadSceneSettingsFromPrompt(characterPrompt)
                                    }
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Load from Prompt")
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
            }
            
            VStack(alignment: .leading, spacing: 16) {
                sectionRow(
                    label: "Environment",
                    text: Binding(
                        get: { promptBinding.wrappedValue.environment ?? "" },
                        set: { promptBinding.wrappedValue.environment = $0.isEmpty ? nil : $0 }
                    ),
                    kind: .environment,
                    theme: theme,
                    presetName: Binding(
                        get: { promptBinding.wrappedValue.environmentPresetName },
                        set: { promptBinding.wrappedValue.environmentPresetName = $0 }
                    )
                )
                sectionRow(
                    label: "Lighting",
                    text: Binding(
                        get: { promptBinding.wrappedValue.lighting ?? "" },
                        set: { promptBinding.wrappedValue.lighting = $0.isEmpty ? nil : $0 }
                    ),
                    kind: .lighting,
                    theme: theme,
                    presetName: Binding(
                        get: { promptBinding.wrappedValue.lightingPresetName },
                        set: { promptBinding.wrappedValue.lightingPresetName = $0 }
                    )
                )
                sectionRow(
                    label: "Style Modifiers",
                    text: Binding(
                        get: { promptBinding.wrappedValue.styleModifiers ?? "" },
                        set: { promptBinding.wrappedValue.styleModifiers = $0.isEmpty ? nil : $0 }
                    ),
                    kind: .style,
                    theme: theme,
                    presetName: Binding(
                        get: { promptBinding.wrappedValue.stylePresetName },
                        set: { promptBinding.wrappedValue.stylePresetName = $0 }
                    )
                )
                sectionRow(
                    label: "Technical Modifiers",
                    text: Binding(
                        get: { promptBinding.wrappedValue.technicalModifiers ?? "" },
                        set: { promptBinding.wrappedValue.technicalModifiers = $0.isEmpty ? nil : $0 }
                    ),
                    kind: .technical,
                    theme: theme,
                    presetName: Binding(
                        get: { promptBinding.wrappedValue.technicalPresetName },
                        set: { promptBinding.wrappedValue.technicalPresetName = $0 }
                    )
                )
                sectionRow(
                    label: "Negative Prompt",
                    text: Binding(
                        get: { promptBinding.wrappedValue.negativePrompt ?? "" },
                        set: { promptBinding.wrappedValue.negativePrompt = $0.isEmpty ? nil : $0 }
                    ),
                    kind: .negative,
                    theme: theme,
                    presetName: Binding(
                        get: { promptBinding.wrappedValue.negativePresetName },
                        set: { promptBinding.wrappedValue.negativePresetName = $0 }
                    )
                )
            }
        }
        .themedCard(characterThemeId: scene.sceneThemeId)
    }
    
    // MARK: - Character Settings Section
    
    private func characterSettingsSection(for character: CharacterProfile) -> some View {
        let theme = sceneTheme
        let settings = characterSettings(for: character.id)
        
        return VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("\(character.name)'s Settings")
                    .font(.headline)
                    .foregroundColor(theme.textPrimary)
                
                Spacer()
                
                // Load from prompt menu - modern styled button
                if !character.prompts.isEmpty {
                    Menu {
                        ForEach(character.prompts) { characterPrompt in
                            Button(characterPrompt.title.isEmpty ? "Untitled" : characterPrompt.title) {
                                loadFromCharacterPrompt(characterPrompt, for: character.id)
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "square.and.arrow.down")
                                .font(.system(size: 12, weight: .semibold))
                            Text("Load from Prompt")
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundColor(theme.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(theme.primary.opacity(0.15))
                        )
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 16) {
                sectionRow(
                    label: "Physical Description",
                    text: Binding(
                        get: { settings.wrappedValue.physicalDescription ?? "" },
                        set: { settings.wrappedValue.physicalDescription = $0.isEmpty ? nil : $0 }
                    ),
                    kind: .physicalDescription,
                    theme: theme,
                    presetName: Binding(
                        get: { settings.wrappedValue.physicalDescriptionPresetName },
                        set: { settings.wrappedValue.physicalDescriptionPresetName = $0 }
                    )
                )
                
                sectionRow(
                    label: "Outfit",
                    text: Binding(
                        get: { settings.wrappedValue.outfit ?? "" },
                        set: { settings.wrappedValue.outfit = $0.isEmpty ? nil : $0 }
                    ),
                    kind: .outfit,
                    theme: theme,
                    presetName: Binding(
                        get: { settings.wrappedValue.outfitPresetName },
                        set: { settings.wrappedValue.outfitPresetName = $0 }
                    )
                )
                
                sectionRow(
                    label: "Pose",
                    text: Binding(
                        get: { settings.wrappedValue.pose ?? "" },
                        set: { settings.wrappedValue.pose = $0.isEmpty ? nil : $0 }
                    ),
                    kind: .pose,
                    theme: theme,
                    presetName: Binding(
                        get: { settings.wrappedValue.posePresetName },
                        set: { settings.wrappedValue.posePresetName = $0 }
                    )
                )
                
                // Additional info
                VStack(alignment: .leading, spacing: 4) {
                    Text("Additional Details")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(theme.textPrimary)
                    
                    DynamicGrowingTextEditor(
                        text: Binding(
                            get: { settings.wrappedValue.additionalInfo ?? "" },
                            set: { settings.wrappedValue.additionalInfo = $0.isEmpty ? nil : $0 }
                        ),
                        placeholder: "Any extra details for \(character.name)",
                        minLines: 0,
                        maxLines: 5,
                        characterThemeId: scene.sceneThemeId
                    )
                }
            }
        }
        .themedCard(characterThemeId: scene.sceneThemeId)
    }
    
    private func characterSettings(for characterId: UUID) -> Binding<SceneCharacterSettings> {
        Binding(
            get: {
                promptBinding.wrappedValue.characterSettings[characterId] ?? SceneCharacterSettings()
            },
            set: { newValue in
                promptBinding.wrappedValue.characterSettings[characterId] = newValue
            }
        )
    }
    
    private func loadFromCharacterPrompt(_ characterPrompt: SavedPrompt, for characterId: UUID) {
        // Use local copy pattern to avoid navigation triggers
        var updatedPrompt = promptBinding.wrappedValue
        var settings = updatedPrompt.characterSettings[characterId] ?? SceneCharacterSettings()
        // Use physicalDescription field (not legacy text field)
        settings.physicalDescription = characterPrompt.physicalDescription
        settings.outfit = characterPrompt.outfit
        settings.pose = characterPrompt.pose
        settings.additionalInfo = characterPrompt.additionalInfo
        settings.sourcePromptId = characterPrompt.id
        updatedPrompt.characterSettings[characterId] = settings
        promptBinding.wrappedValue = updatedPrompt
    }
    
    private func loadSceneSettingsFromPrompt(_ characterPrompt: SavedPrompt) {
        // Use local copy pattern to avoid navigation triggers
        var updatedPrompt = promptBinding.wrappedValue
        updatedPrompt.environment = characterPrompt.environment
        updatedPrompt.lighting = characterPrompt.lighting
        updatedPrompt.styleModifiers = characterPrompt.styleModifiers
        updatedPrompt.technicalModifiers = characterPrompt.technicalModifiers
        updatedPrompt.negativePrompt = characterPrompt.negativePrompt
        promptBinding.wrappedValue = updatedPrompt
    }
    
    // MARK: - Section Row Helper (matches character prompt style)
    
    private func sectionRow(
        label: String,
        text: Binding<String>,
        kind: PromptSectionKind,
        theme: ResolvedTheme,
        presetName: Binding<String?>? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Label row with preset controls
            HStack(spacing: 8) {
                Text(label)
                    .font(.subheadline.weight(.semibold))
                    .fontDesign(theme.fontDesign)
                    .foregroundColor(theme.textPrimary)
                
                let presets = presetStore.presets(of: kind)
                let trimmed = text.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Apply Preset menu
                if !presets.isEmpty {
                    Menu {
                        ForEach(presets) { preset in
                            Button {
                                text.wrappedValue = preset.text
                                presetName?.wrappedValue = preset.name
                            } label: {
                                Text(preset.name)
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                            Text("Apply Preset")
                        }
                        .font(.caption)
                        .foregroundColor(theme.primary)
                    }
                }
                
                // Show current preset name or save as preset option
                if let presetNameBinding = presetName {
                    if let name = presetNameBinding.wrappedValue, !name.isEmpty {
                        Text("(Using: \(name))")
                            .font(.caption2)
                            .fontDesign(theme.fontDesign)
                            .foregroundColor(theme.textSecondary)
                    } else if !trimmed.isEmpty {
                        Button {
                            beginSavingPreset(from: text.wrappedValue, kind: kind, label: label)
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "star.badge.plus")
                                Text("Save as preset")
                            }
                            .font(.caption)
                            .foregroundColor(theme.primary)
                        }
                    }
                }
                
                Spacer()
            }
            
            DynamicGrowingTextEditor(
                text: text,
                placeholder: "Optional \(label.lowercased())",
                minLines: 0,
                maxLines: 5,
                fontSize: 14,
                characterThemeId: scene.sceneThemeId
            )
            .onAppear {
                if let presetNameBinding = presetName {
                    updatePresetNameForCurrentText(
                        kind: kind,
                        text: text,
                        presetName: presetNameBinding
                    )
                }
            }
            .onChange(of: text.wrappedValue) { _, _ in
                if let presetNameBinding = presetName {
                    updatePresetNameForCurrentText(
                        kind: kind,
                        text: text,
                        presetName: presetNameBinding
                    )
                }
            }
        }
    }
    
    // MARK: - Preset Helpers
    
    private func beginSavingPreset(from text: String, kind: PromptSectionKind, label: String) {
        pendingPresetKind = kind
        pendingPresetText = text
        pendingPresetLabel = label
        pendingPresetNameInput = ""
        showingPresetAlert = true
    }
    
    /// Re-syncs all preset markers after saving a new preset
    /// This ensures the UI updates to show "(Using: preset name)" after saving
    private func resyncAllPresetMarkers() {
        // Scene-level settings
        updatePresetNameForCurrentText(
            kind: .environment,
            text: Binding(
                get: { promptBinding.wrappedValue.environment ?? "" },
                set: { promptBinding.wrappedValue.environment = $0.isEmpty ? nil : $0 }
            ),
            presetName: Binding(
                get: { promptBinding.wrappedValue.environmentPresetName },
                set: { promptBinding.wrappedValue.environmentPresetName = $0 }
            )
        )
        updatePresetNameForCurrentText(
            kind: .lighting,
            text: Binding(
                get: { promptBinding.wrappedValue.lighting ?? "" },
                set: { promptBinding.wrappedValue.lighting = $0.isEmpty ? nil : $0 }
            ),
            presetName: Binding(
                get: { promptBinding.wrappedValue.lightingPresetName },
                set: { promptBinding.wrappedValue.lightingPresetName = $0 }
            )
        )
        updatePresetNameForCurrentText(
            kind: .style,
            text: Binding(
                get: { promptBinding.wrappedValue.styleModifiers ?? "" },
                set: { promptBinding.wrappedValue.styleModifiers = $0.isEmpty ? nil : $0 }
            ),
            presetName: Binding(
                get: { promptBinding.wrappedValue.stylePresetName },
                set: { promptBinding.wrappedValue.stylePresetName = $0 }
            )
        )
        updatePresetNameForCurrentText(
            kind: .technical,
            text: Binding(
                get: { promptBinding.wrappedValue.technicalModifiers ?? "" },
                set: { promptBinding.wrappedValue.technicalModifiers = $0.isEmpty ? nil : $0 }
            ),
            presetName: Binding(
                get: { promptBinding.wrappedValue.technicalPresetName },
                set: { promptBinding.wrappedValue.technicalPresetName = $0 }
            )
        )
        updatePresetNameForCurrentText(
            kind: .negative,
            text: Binding(
                get: { promptBinding.wrappedValue.negativePrompt ?? "" },
                set: { promptBinding.wrappedValue.negativePrompt = $0.isEmpty ? nil : $0 }
            ),
            presetName: Binding(
                get: { promptBinding.wrappedValue.negativePresetName },
                set: { promptBinding.wrappedValue.negativePresetName = $0 }
            )
        )
        
        // Per-character settings
        for character in characters {
            let settings = characterSettings(for: character.id)
            updatePresetNameForCurrentText(
                kind: .physicalDescription,
                text: Binding(
                    get: { settings.wrappedValue.physicalDescription ?? "" },
                    set: { settings.wrappedValue.physicalDescription = $0.isEmpty ? nil : $0 }
                ),
                presetName: Binding(
                    get: { settings.wrappedValue.physicalDescriptionPresetName },
                    set: { settings.wrappedValue.physicalDescriptionPresetName = $0 }
                )
            )
            updatePresetNameForCurrentText(
                kind: .outfit,
                text: Binding(
                    get: { settings.wrappedValue.outfit ?? "" },
                    set: { settings.wrappedValue.outfit = $0.isEmpty ? nil : $0 }
                ),
                presetName: Binding(
                    get: { settings.wrappedValue.outfitPresetName },
                    set: { settings.wrappedValue.outfitPresetName = $0 }
                )
            )
            updatePresetNameForCurrentText(
                kind: .pose,
                text: Binding(
                    get: { settings.wrappedValue.pose ?? "" },
                    set: { settings.wrappedValue.pose = $0.isEmpty ? nil : $0 }
                ),
                presetName: Binding(
                    get: { settings.wrappedValue.posePresetName },
                    set: { settings.wrappedValue.posePresetName = $0 }
                )
            )
        }
    }
    
    /// Updates the preset name binding based on whether the current text matches a preset
    /// This mimics the functionality in PromptEditorView for character prompts
    private func updatePresetNameForCurrentText(
        kind: PromptSectionKind,
        text: Binding<String>,
        presetName: Binding<String?>
    ) {
        let presets = presetStore.presets(of: kind)
        let trimmed = text.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmed.isEmpty else {
            if presetName.wrappedValue != nil {
                presetName.wrappedValue = nil
            }
            return
        }
        
        // If current preset name still matches the text, keep it
        if let currentName = presetName.wrappedValue,
           let currentPreset = presets.first(where: { $0.name == currentName }),
           currentPreset.text.trimmingCharacters(in: .whitespacesAndNewlines) == trimmed {
            return
        }
        
        // Check if text matches any preset
        if let match = presets.first(where: {
            $0.text.trimmingCharacters(in: .whitespacesAndNewlines) == trimmed
        }) {
            presetName.wrappedValue = match.name
        } else if presetName.wrappedValue != nil {
            presetName.wrappedValue = nil
        }
    }
    
    // MARK: - Quick Actions Bar (matches character prompt style)
    
    private var quickActionsBar: some View {
        let theme = sceneTheme
        let composedPrompt = composePrompt()
        
        return VStack(spacing: 12) {
            // Primary action row
            HStack(spacing: 10) {
                // Copy Prompt button
                Button {
                    UIPasteboard.general.string = composedPrompt
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showCopiedToast = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showCopiedToast = false
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 16, weight: .medium))
                        Text("Copy Prompt")
                            .font(.subheadline.weight(.medium))
                    }
                    .foregroundColor(theme.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .background(theme.backgroundTertiary)
                    .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadiusMedium))
                    .overlay(
                        RoundedRectangle(cornerRadius: theme.cornerRadiusMedium)
                            .stroke(theme.primary.opacity(0.3), lineWidth: 1)
                    )
                }
                
                // Open Generator - Primary action (larger)
                Button {
                    openGenerator(composedPrompt)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 18, weight: .semibold))
                        Text("Generate")
                            .font(.headline.weight(.semibold))
                    }
                    .foregroundColor(theme.textOnPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [theme.primary, theme.primary.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadiusMedium))
                    .shadow(color: theme.primary.opacity(0.4), radius: 8, x: 0, y: 4)
                }
            }
            
            // Secondary actions row - styled as subtle but intentional actions
            HStack(spacing: 12) {
                // Duplicate button - uses success color to indicate positive action
                Button {
                    duplicatePromptName = prompt.title.isEmpty ? "Untitled (Copy)" : "\(prompt.title) (Copy)"
                    showingDuplicateAlert = true
                } label: {
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(theme.success.opacity(0.15))
                                .frame(width: 44, height: 44)
                            Image(systemName: "plus.square.on.square")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(theme.success)
                        }
                        Text("Duplicate")
                            .font(.caption.weight(.medium))
                            .foregroundColor(theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(theme.backgroundTertiary)
                    .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadiusMedium))
                }
                
                // Add to Other Scenes button - uses primary color for sharing action
                Button {
                    showingAddToOtherScenes = true
                } label: {
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(theme.primary.opacity(0.15))
                                .frame(width: 44, height: 44)
                            Image(systemName: "person.2.badge.plus")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(theme.primary)
                        }
                        Text("Add to Others")
                            .font(.caption.weight(.medium))
                            .foregroundColor(theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(theme.backgroundTertiary)
                    .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadiusMedium))
                }
            }
        }
        .themedCard(characterThemeId: scene.sceneThemeId)
    }
    
    // MARK: - Prompt Preview Card
    
    private var promptPreviewCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            PromptPreviewSection(
                composedPrompt: composePromptFormatted(),
                characterThemeId: scene.sceneThemeId
            )
        }
        .themedCard(characterThemeId: scene.sceneThemeId)
    }
    
    // MARK: - Images Section (inline, no card - used inside titleSection)
    
    private var imagesSection: some View {
        let theme = sceneTheme
        let images = prompt.images
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Images")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(theme.textPrimary)
                
                Spacer()
                
                Button {
                    showingImagePicker = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Add")
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundColor(theme.textOnPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(theme.primary))
                }
                .buttonStyle(.plain)
            }
            
            if images.isEmpty {
                Text("No images yet. Add images generated from this prompt.")
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Array(images.enumerated()), id: \.element.id) { index, image in
                            if let uiImage = UIImage(data: image.data) {
                                Button {
                                    promptGalleryStartIndex = index
                                    showingPromptGallery = true
                                } label: {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 80, height: 80)
                                        .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadiusSmall))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
        // No themedCard here - this is embedded in titleSection
    }
    
    // MARK: - Prompt Composition
    
    /// Compose prompt for copying/generating (single line format)
    private func composePrompt() -> String {
        var parts: [String] = []
        
        // Add each character's description
        for character in characters {
            let settings = prompt.characterSettings[character.id]
            var characterParts: [String] = []
            
            // Character name and physical description
            if let physical = settings?.physicalDescription, !physical.isEmpty {
                characterParts.append("\(character.name), \(physical)")
            } else {
                characterParts.append(character.name)
            }
            
            // Outfit
            if let outfit = settings?.outfit, !outfit.isEmpty {
                characterParts.append("wearing \(outfit)")
            }
            
            // Pose
            if let pose = settings?.pose, !pose.isEmpty {
                characterParts.append(pose)
            }
            
            // Additional info
            if let additional = settings?.additionalInfo, !additional.isEmpty {
                characterParts.append(additional)
            }
            
            if !characterParts.isEmpty {
                parts.append(characterParts.joined(separator: ", "))
            }
        }
        
        // Scene-wide settings
        if let environment = prompt.environment, !environment.isEmpty {
            parts.append(environment)
        }
        
        if let lighting = prompt.lighting, !lighting.isEmpty {
            parts.append(lighting)
        }
        
        if let style = prompt.styleModifiers, !style.isEmpty {
            parts.append(style)
        }
        
        if let technical = prompt.technicalModifiers, !technical.isEmpty {
            parts.append(technical)
        }
        
        // Additional scene info
        if let additional = prompt.additionalInfo, !additional.isEmpty {
            parts.append(additional)
        }
        
        var result = parts.joined(separator: ", ")
        
        // Add negative prompt if present
        if let negative = prompt.negativePrompt, !negative.isEmpty {
            result += " ### \(negative)"
        }
        
        return result
    }
    
    /// Compose prompt for display with distinct sections (matches CharacterPromptEditorView style)
    private func composePromptFormatted() -> String {
        var sections: [String] = []
        
        // Character sections - each character gets its own labeled section with distinct subsections
        for character in characters {
            let settings = prompt.characterSettings[character.id]
            var characterLines: [String] = []
            
            // Physical description - labeled
            if let physical = settings?.physicalDescription, !physical.isEmpty {
                characterLines.append("Description: \(physical)")
            }
            
            // Outfit - labeled
            if let outfit = settings?.outfit, !outfit.isEmpty {
                characterLines.append("Outfit: \(outfit)")
            }
            
            // Pose - labeled
            if let pose = settings?.pose, !pose.isEmpty {
                characterLines.append("Pose: \(pose)")
            }
            
            // Additional info - labeled
            if let additional = settings?.additionalInfo, !additional.isEmpty {
                characterLines.append("Additional: \(additional)")
            }
            
            if !characterLines.isEmpty {
                let characterSection = "[\(character.name)]\n\(characterLines.joined(separator: "\n"))"
                sections.append(characterSection)
            } else {
                sections.append("[\(character.name)]\n(No settings)")
            }
        }
        
        // Scene settings section
        var sceneLines: [String] = []
        
        if let environment = prompt.environment, !environment.isEmpty {
            sceneLines.append("Environment: \(environment)")
        }
        
        if let lighting = prompt.lighting, !lighting.isEmpty {
            sceneLines.append("Lighting: \(lighting)")
        }
        
        if let style = prompt.styleModifiers, !style.isEmpty {
            sceneLines.append("Style: \(style)")
        }
        
        if let technical = prompt.technicalModifiers, !technical.isEmpty {
            sceneLines.append("Technical: \(technical)")
        }
        
        if let additional = prompt.additionalInfo, !additional.isEmpty {
            sceneLines.append("Additional: \(additional)")
        }
        
        if !sceneLines.isEmpty {
            sections.append("[Scene Settings]\n\(sceneLines.joined(separator: "\n"))")
        }
        
        // Negative prompt section
        if let negative = prompt.negativePrompt, !negative.isEmpty {
            sections.append("[Negative]\n\(negative)")
        }
        
        return sections.isEmpty ? "No prompt content yet" : sections.joined(separator: "\n\n")
    }
}
