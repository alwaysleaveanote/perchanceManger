//
//  SceneDetailView.swift
//  Chancery
//
//  Detail view for a scene showing overview, characters, and prompts.
//

import SwiftUI

struct SceneDetailView: View {
    @Binding var scene: CharacterScene
    @Binding var allCharacters: [CharacterProfile]
    let openGenerator: (String) -> Void
    var initialPromptId: UUID? = nil
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var presetStore: PromptPresetStore
    
    @State private var isEditingInfo = false
    @State private var selectedPromptIndex: Int? = nil
    @State private var showingGallery = false
    @State private var galleryStartIndex: Int = 0
    @State private var showingSettings = false
    @State private var selectedCharacterId: UUID? = nil
    
    private var sceneTheme: ResolvedTheme {
        themeManager.resolvedTheme(forCharacterThemeId: scene.sceneThemeId)
    }
    
    /// Characters in this scene, ordered by their position in the main characters list
    private var sceneCharacters: [CharacterProfile] {
        // Get characters that are in this scene
        let sceneCharacterSet = Set(scene.characterIds)
        // Filter allCharacters to only those in the scene, preserving allCharacters order
        return allCharacters.filter { sceneCharacterSet.contains($0.id) }
    }
    
    /// All images for this scene for thumbnail display
    /// Order: profile image -> prompt images -> standalone images (MUST match allGalleryImages order)
    private var allImages: [PromptImage] {
        var images: [PromptImage] = []
        
        // 1. Profile image first (if unique)
        if let profileData = scene.profileImageData {
            let isFromPrompt = scene.prompts.flatMap { $0.images }.contains { $0.data == profileData }
            let isFromStandalone = scene.standaloneImages.contains { $0.data == profileData }
            if !isFromPrompt && !isFromStandalone {
                images.append(PromptImage(id: UUID(), data: profileData))
            }
        }
        
        // 2. Prompt images
        images.append(contentsOf: scene.prompts.flatMap { $0.images })
        
        // 3. Standalone images
        images.append(contentsOf: scene.standaloneImages)
        
        return images
    }
    
    var body: some View {
        mainScrollView
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .characterThemedNavigationBar(characterThemeId: scene.sceneThemeId)
            .navigationBarBackButtonHidden(selectedPromptIndex != nil || isEditingInfo)
            .toolbar {
                // Custom back button when viewing a prompt or editing info
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
                            .foregroundColor(sceneTheme.primary)
                            .frame(width: 44, height: 44)  // Larger tap target
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    } else if isEditingInfo {
                        Button {
                            KeyboardHelper.dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                isEditingInfo = false
                                dismiss()
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .foregroundColor(sceneTheme.primary)
                            .frame(width: 44, height: 44)  // Larger tap target
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                // Edit button removed - redundant with edit button next to profile image
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
                    profileImageData: scene.profileImageData,
                    onViewPrompt: { promptIndex in
                        selectedPromptIndex = promptIndex
                    },
                    onMakeProfilePicture: { imageData in
                        scene.profileImageData = imageData
                    }
                )
            }
            .sheet(isPresented: $showingSettings) {
                SceneSettingsView(scene: $scene)
                    .environmentObject(themeManager)
                    .environmentObject(presetStore)
            }
            .background(sceneTheme.background.ignoresSafeArea())
            // Character navigation still uses NavigationLink (navigating away from scene is fine)
            .background(
                Group {
                    if let characterId = selectedCharacterId,
                       let index = allCharacters.firstIndex(where: { $0.id == characterId }) {
                        NavigationLink(
                            destination: CharacterDetailView(
                                character: $allCharacters[index],
                                openGenerator: openGenerator,
                                initialPromptId: nil
                            ),
                            isActive: Binding(
                                get: { selectedCharacterId != nil },
                                set: { if !$0 { selectedCharacterId = nil } }
                            )
                        ) {
                            EmptyView()
                        }
                        .hidden()
                    }
                }
            )
            .onAppear {
                applyInitialPromptIfNeeded()
            }
            .onChange(of: initialPromptId) { _, newValue in
                // React to changes in initialPromptId (e.g., when navigating from gallery)
                if let promptId = newValue,
                   let index = scene.prompts.firstIndex(where: { $0.id == promptId }) {
                    selectedPromptIndex = index
                }
            }
            .onDisappear {
                if isEditingInfo {
                    isEditingInfo = false
                }
            }
    }
    
    private var navigationTitle: String {
        if let idx = selectedPromptIndex, scene.prompts.indices.contains(idx) {
            let promptTitle = scene.prompts[idx].title
            return promptTitle.isEmpty ? "Edit Prompt" : promptTitle
        }
        return scene.name.isEmpty ? "Untitled Scene" : scene.name
    }
    
    // MARK: - Main Scroll View (matches CharacterDetailView pattern)
    
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
                withAnimation(.easeOut(duration: 0.1)) {
                    proxy.scrollTo("scrollTop", anchor: .top)
                }
            }
        }
    }
    
    // MARK: - Main Column (conditional view like CharacterDetailView)
    
    private var mainColumn: some View {
        Group {
            if let idx = selectedPromptIndex,
               scene.prompts.indices.contains(idx) {
                // Prompt editor embedded directly (NOT via NavigationLink)
                ScenePromptEditorView(
                    scene: $scene,
                    promptIndex: idx,
                    characters: sceneCharacters,
                    openGenerator: openGenerator,
                    onDelete: {
                        if scene.prompts.indices.contains(idx) {
                            scene.prompts.remove(at: idx)
                            selectedPromptIndex = nil
                        } else {
                            selectedPromptIndex = nil
                        }
                    },
                    onDuplicate: { newPrompt in
                        scene.prompts.insert(newPrompt, at: 0)
                        selectedPromptIndex = 0
                    }
                )
            } else {
                // Scene overview
                SceneOverviewView(
                    scene: $scene,
                    characters: allCharacters,
                    allImages: allImages,
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
                    onDeletePrompt: { index in
                        deletePrompt(at: index)
                    },
                    onDuplicatePrompt: { index, newName in
                        duplicatePrompt(at: index, newName: newName)
                    },
                    onCharacterTap: { characterId in
                        selectedCharacterId = characterId
                    },
                    onOpenSettings: {
                        showingSettings = true
                    },
                    isEditingInfo: $isEditingInfo
                )
            }
        }
    }
    
    // MARK: - Actions
    
    private func createNewPrompt() {
        let globalDefaults = presetStore.globalDefaults
        let sceneDefaults = scene.sceneDefaults
        
        // Scene-specific defaults take priority, then fall back to global defaults
        func effectiveDefault(_ key: GlobalDefaultKey) -> String? {
            sceneDefaults[key]?.nonEmpty
                ?? globalDefaults[key]?.nonEmpty
        }
        
        let newPrompt = ScenePrompt(
            title: "New Prompt",
            environment: effectiveDefault(.environment),
            lighting: effectiveDefault(.lighting),
            styleModifiers: effectiveDefault(.style),
            technicalModifiers: effectiveDefault(.technical),
            negativePrompt: effectiveDefault(.negative)
        )
        scene.prompts.insert(newPrompt, at: 0)
        selectedPromptIndex = 0
    }
    
    private func deletePrompt(at index: Int) {
        guard index < scene.prompts.count else { return }
        scene.prompts.remove(at: index)
    }
    
    private func duplicatePrompt(at index: Int, newName: String) {
        guard index < scene.prompts.count else { return }
        var newPrompt = scene.prompts[index]
        newPrompt = ScenePrompt(
            title: newName,
            environment: newPrompt.environment,
            lighting: newPrompt.lighting,
            styleModifiers: newPrompt.styleModifiers,
            technicalModifiers: newPrompt.technicalModifiers,
            negativePrompt: newPrompt.negativePrompt,
            additionalInfo: newPrompt.additionalInfo,
            characterSettings: newPrompt.characterSettings,
            images: [] // Don't copy images
        )
        scene.prompts.insert(newPrompt, at: 0)
        selectedPromptIndex = 0
    }
    
    // MARK: - Gallery Images (matches CharacterDetailView pattern)
    
    /// Returns all images for the swipeable gallery with metadata
    /// Order: profile image -> prompt images -> standalone images (MUST match SceneOverviewView order)
    private func allGalleryImages() -> [GalleryImage] {
        var images: [GalleryImage] = []
        
        // 1. Profile image first (if unique)
        if let profileData = scene.profileImageData {
            let isFromPrompt = scene.prompts.flatMap { $0.images }.contains { $0.data == profileData }
            let isFromStandalone = scene.standaloneImages.contains { $0.data == profileData }
            if !isFromPrompt && !isFromStandalone {
                images.append(GalleryImage(profileImageData: profileData))
            }
        }
        
        // 2. Prompt images with their prompt index
        for (promptIndex, prompt) in scene.prompts.enumerated() {
            for promptImage in prompt.images {
                images.append(GalleryImage(from: promptImage, promptIndex: promptIndex, promptTitle: prompt.title))
            }
        }
        
        // 3. Standalone images
        for standaloneImage in scene.standaloneImages {
            images.append(GalleryImage(standaloneImage: standaloneImage))
        }
        
        return images
    }
    
    private func applyInitialPromptIfNeeded() {
        if let promptId = initialPromptId,
           let index = scene.prompts.firstIndex(where: { $0.id == promptId }) {
            selectedPromptIndex = index
        }
    }
}

// MARK: - Scene Image Viewer

struct SceneImageViewer: View {
    let images: [PromptImage]
    let currentIndex: Int
    let sceneName: String
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedIndex: Int
    
    init(images: [PromptImage], currentIndex: Int, sceneName: String) {
        self.images = images
        self.currentIndex = currentIndex
        self.sceneName = sceneName
        self._selectedIndex = State(initialValue: currentIndex)
    }
    
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
                    
                    Text("\(selectedIndex + 1) / \(images.count)")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Spacer()
                    
                    // Share button
                    if selectedIndex < images.count,
                       let uiImage = UIImage(data: images[selectedIndex].data) {
                        ShareLink(item: Image(uiImage: uiImage), preview: SharePreview(sceneName, image: Image(uiImage: uiImage))) {
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
                
                // Zoomable image
                TabView(selection: $selectedIndex) {
                    ForEach(Array(images.enumerated()), id: \.element.id) { index, image in
                        if let uiImage = UIImage(data: image.data) {
                            ZoomableImage(uiImage: uiImage)
                                .padding(.horizontal, 16)
                                .tag(index)
                        }
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Scene name
                Text(sceneName)
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
            }
        }
    }
}

// MARK: - Scene Settings View (Matches CharacterSettingsView)

struct SceneSettingsView: View {
    @EnvironmentObject var presetStore: PromptPresetStore
    @EnvironmentObject var themeManager: ThemeManager
    
    @Binding var scene: CharacterScene
    
    /// Local working copy for generator (not theme)
    @State private var workingScene: CharacterScene
    
    @Environment(\.dismiss) private var dismiss
    
    // Generator override state
    @State private var useSceneGenerator: Bool = false
    @State private var generatorSelection: String = ""
    @State private var customGeneratorName: String = ""
    
    // Track the selected theme ID separately to avoid navigation issues
    @State private var selectedThemeId: String?
    
    // Scene defaults section picker
    @State private var selectedDefaultsSection: PromptSectionKind = .environment
    
    init(scene: Binding<CharacterScene>) {
        self._scene = scene
        self._workingScene = State(initialValue: scene.wrappedValue)
        self._selectedThemeId = State(initialValue: scene.wrappedValue.sceneThemeId)
    }
    
    /// Computes the preview theme locally without affecting global themeManager.resolved
    private var previewTheme: ResolvedTheme {
        if let themeId = selectedThemeId,
           let theme = themeManager.availableThemes.first(where: { $0.id == themeId }) {
            return ResolvedTheme(source: theme)
        }
        if let globalTheme = themeManager.availableThemes.first(where: { $0.id == themeManager.globalThemeId }) {
            return ResolvedTheme(source: globalTheme)
        }
        return themeManager.resolved
    }
    
    var body: some View {
        let theme = previewTheme
        
        NavigationView {
            ZStack {
                theme.background
                    .ignoresSafeArea()
                
                Form {
                    themeSection
                    generatorSection
                    defaultsSection
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Scene Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(theme.primary)
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
            .toolbarColorScheme(isLightTheme(previewTheme) ? .light : .dark, for: .navigationBar)
            .toolbarBackground(theme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .tint(theme.primary)
            .onAppear {
                configureInitialGeneratorState()
            }
            .onDisappear {
                // Save ALL changes including theme on dismiss
                scene.sceneThemeId = selectedThemeId
                scene.sceneDefaults = workingScene.sceneDefaults
                scene.sceneDefaultPerchanceGenerator = workingScene.sceneDefaultPerchanceGenerator
            }
        }
    }
    
    /// Determines if a theme has a light background
    private func isLightTheme(_ theme: ResolvedTheme) -> Bool {
        let hex = theme.source.colors.background.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255.0
        let g = Double((int >> 8) & 0xFF) / 255.0
        let b = Double(int & 0xFF) / 255.0
        let luminance = 0.299 * r + 0.587 * g + 0.114 * b
        return luminance > 0.5
    }
    
    // MARK: - Theme Section
    
    private var themeSection: some View {
        let theme = previewTheme
        
        return Section(header: Text("Scene Theme")
            .foregroundColor(theme.textSecondary)
            .fontDesign(theme.fontDesign)
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Override the global theme for this scene. This theme will be applied when viewing this scene's pages.")
                    .font(.caption)
                    .fontDesign(theme.fontDesign)
                    .foregroundColor(theme.textSecondary)
                
                ThemePicker(
                    title: "Scene Theme",
                    selectedThemeId: selectedThemeId,
                    showInheritOption: true,
                    onSelect: { themeId in
                        selectedThemeId = themeId
                    }
                )
            }
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - Generator Section
    
    private var generatorSection: some View {
        let theme = previewTheme
        
        return Section(header: Text("Perchance Generator")
            .foregroundColor(theme.textSecondary)
            .fontDesign(theme.fontDesign)
        ) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Generator used when opening prompts for this scene.")
                    .font(.caption)
                    .fontDesign(theme.fontDesign)
                    .foregroundColor(theme.textSecondary)
                
                Toggle(isOn: $useSceneGenerator) {
                    Text("Use scene-specific generator")
                        .fontDesign(theme.fontDesign)
                        .foregroundColor(theme.textPrimary)
                }
                .tint(theme.primary)
                .onChange(of: useSceneGenerator) { _, newValue in
                    handleUseSceneGeneratorToggle(newValue)
                }
                
                if useSceneGenerator {
                    let isCustomSelection = !perchanceGenerators.contains(where: { $0.name == generatorSelection })
                    
                    Picker("Generator", selection: $generatorSelection) {
                        ForEach(perchanceGenerators) { option in
                            Text(option.name).tag(option.name)
                        }
                        
                        if isCustomSelection && !generatorSelection.isEmpty {
                            Text("Custom: \(generatorSelection)").tag(generatorSelection)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: generatorSelection) { _, newValue in
                        if useSceneGenerator {
                            workingScene.sceneDefaultPerchanceGenerator = newValue
                        }
                    }
                    
                    if let option = perchanceGenerators.first(where: { $0.name == generatorSelection }) {
                        Text(option.title.isEmpty ? option.name : option.title)
                            .font(.subheadline)
                            .fontDesign(theme.fontDesign)
                            .fontWeight(.semibold)
                            .foregroundColor(theme.textPrimary)
                        if !option.description.isEmpty {
                            Text(option.description)
                                .font(.caption)
                                .fontDesign(theme.fontDesign)
                                .foregroundColor(theme.textSecondary)
                        }
                    } else if !generatorSelection.isEmpty {
                        Text("Using custom generator: \(generatorSelection)")
                            .font(.subheadline)
                            .fontDesign(theme.fontDesign)
                            .fontWeight(.semibold)
                            .foregroundColor(theme.textPrimary)
                    }
                    
                    Divider()
                        .background(theme.divider)
                        .padding(.vertical, 4)
                    
                    Text("Custom generator")
                        .font(.subheadline)
                        .fontDesign(theme.fontDesign)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.textPrimary)
                    
                    TextField("Enter generator name (slug, e.g. ai-artgen)", text: $customGeneratorName)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                    
                    Button("Use this generator") {
                        let trimmed = customGeneratorName.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        
                        generatorSelection = trimmed
                        workingScene.sceneDefaultPerchanceGenerator = trimmed
                        useSceneGenerator = true
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 4)
                } else {
                    let global = presetStore.defaultPerchanceGenerator
                    Text("Inheriting global generator: \(global)")
                        .font(.subheadline)
                        .fontDesign(theme.fontDesign)
                        .foregroundColor(theme.textSecondary)
                }
            }
        }
    }
    
    private func configureInitialGeneratorState() {
        let override = scene.sceneDefaultPerchanceGenerator
        let global = presetStore.defaultPerchanceGenerator
        
        workingScene = scene
        
        if let override = override, !override.isEmpty {
            useSceneGenerator = true
            generatorSelection = override
            customGeneratorName = override
            workingScene.sceneDefaultPerchanceGenerator = override
        } else {
            useSceneGenerator = false
            generatorSelection = global
            customGeneratorName = ""
            workingScene.sceneDefaultPerchanceGenerator = nil
        }
    }
    
    private func handleUseSceneGeneratorToggle(_ useOverride: Bool) {
        let global = presetStore.defaultPerchanceGenerator
        
        if useOverride {
            if generatorSelection.isEmpty {
                generatorSelection = workingScene.sceneDefaultPerchanceGenerator ?? global
            }
            workingScene.sceneDefaultPerchanceGenerator = generatorSelection
        } else {
            workingScene.sceneDefaultPerchanceGenerator = nil
            generatorSelection = global
        }
    }
    
    // MARK: - Defaults Section
    
    private var defaultsSection: some View {
        let theme = previewTheme
        
        return Section(header: Text("Scene Defaults (Overrides Global)")
            .foregroundColor(theme.textSecondary)
            .fontDesign(theme.fontDesign)
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Text("These defaults are used when a prompt leaves a section blank. They override the global defaults, but are still overridden by per-prompt text.")
                    .font(.caption)
                    .fontDesign(theme.fontDesign)
                    .foregroundColor(theme.textSecondary)
                
                defaultsSectionPicker
                sceneDefaultEditor
            }
            .padding(.vertical, 4)
        }
    }
    
    private var defaultsSectionPicker: some View {
        let theme = previewTheme
        
        return VStack(alignment: .leading, spacing: 6) {
            Text("Section")
                .font(.subheadline)
                .fontDesign(theme.fontDesign)
                .foregroundColor(theme.textSecondary)
            
            Menu {
                ForEach(PromptSectionKind.allCases, id: \.self) { kind in
                    Button(kind.displayLabel) {
                        selectedDefaultsSection = kind
                    }
                }
            } label: {
                HStack {
                    Text(selectedDefaultsSection.displayLabel)
                        .font(.body)
                        .fontDesign(theme.fontDesign)
                        .foregroundColor(theme.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.subheadline)
                        .foregroundColor(theme.textSecondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(theme.backgroundTertiary)
                )
            }
        }
    }
    
    private var sceneDefaultEditor: some View {
        let theme = previewTheme
        let key = selectedDefaultsSection.defaultKey
        let sceneText = (workingScene.sceneDefaults[key] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let globalText = (presetStore.globalDefaults[key] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let sectionPresets = presetStore.presets(of: selectedDefaultsSection)
        
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Scene default for \(selectedDefaultsSection.displayLabel)")
                    .font(.headline)
                    .fontDesign(theme.fontDesign)
                    .foregroundColor(theme.textPrimary)
                
                Spacer()
                
                if !sectionPresets.isEmpty {
                    Menu {
                        ForEach(sectionPresets) { preset in
                            Button(preset.name) {
                                applyPresetToSceneDefault(preset, for: selectedDefaultsSection)
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "text.badge.plus")
                            Text("Apply preset")
                        }
                        .font(.caption)
                        .foregroundColor(theme.primary)
                    }
                }
            }
            
            if sceneText.isEmpty {
                if !globalText.isEmpty {
                    Text("Currently inheriting global default:")
                        .font(.caption)
                        .fontDesign(theme.fontDesign)
                        .foregroundColor(theme.textSecondary)
                    Text(globalText)
                        .font(.caption)
                        .fontDesign(theme.fontDesign)
                        .foregroundColor(theme.textSecondary)
                        .lineLimit(3)
                        .truncationMode(.tail)
                } else {
                    Text("No scene default set (and global default is also empty).")
                        .font(.caption)
                        .fontDesign(theme.fontDesign)
                        .foregroundColor(theme.textSecondary)
                }
            } else {
                Text("Scene override is active and replaces the global default.")
                    .font(.caption)
                    .fontDesign(theme.fontDesign)
                    .foregroundColor(theme.textSecondary)
            }
            
            DynamicGrowingTextEditor(
                text: sceneDefaultBinding(for: selectedDefaultsSection),
                placeholder: "Default text for this scene's \(selectedDefaultsSection.displayLabel.lowercased()) (optional)",
                minLines: 2,
                maxLines: 10,
                characterThemeId: selectedThemeId
            )
        }
    }
    
    private func applyPresetToSceneDefault(_ preset: PromptPreset, for kind: PromptSectionKind) {
        let key = kind.defaultKey
        workingScene.sceneDefaults[key] = preset.text
    }
    
    private func sceneDefaultBinding(for kind: PromptSectionKind) -> Binding<String> {
        let key = kind.defaultKey
        return Binding(
            get: {
                workingScene.sceneDefaults[key] ?? ""
            },
            set: { newValue in
                workingScene.sceneDefaults[key] = newValue
            }
        )
    }
}
