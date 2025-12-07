import SwiftUI
import UIKit

/// Editor view for a single prompt with all sections and preset support
struct PromptEditorView: View {
    @Binding var character: CharacterProfile
    let promptIndex: Int
    let openGenerator: (String) -> Void
    let onDelete: () -> Void
    let onDuplicate: (SavedPrompt) -> Void
    
    @State private var showingDeleteConfirm: Bool = false
    @State private var showingDuplicateAlert: Bool = false
    @State private var duplicatePromptName: String = ""
    @State private var showingClearConfirm: Bool = false
    @State private var showingAddToOtherCharacters: Bool = false
    @State private var showAddedToast: Bool = false
    @State private var addedToCharacterCount: Int = 0

    @EnvironmentObject var presetStore: PromptPresetStore
    @EnvironmentObject var themeManager: ThemeManager

    // Per-prompt gallery & picker
    @State private var showingPromptGallery: Bool = false
    @State private var promptGalleryStartIndex: Int = 0
    @State private var showingPromptImagePicker: Bool = false
    
    // State for creating presets from section text
    @State private var isShowingPresetSaveAlert: Bool = false
    @State private var pendingPresetKind: PromptSectionKind? = nil
    @State private var pendingPresetText: String = ""
    @State private var pendingPresetLabel: String = ""
    @State private var pendingPresetNameInput: String = ""
    @State private var showCopiedToast: Bool = false

    private var promptBinding: Binding<SavedPrompt> {
        Binding(
            get: { character.prompts[promptIndex] },
            set: { character.prompts[promptIndex] = $0 }
        )
    }

    private var prompt: SavedPrompt {
        promptBinding.wrappedValue
    }
    
    private var composedPrompt: String {
        PromptComposer.composePrompt(
            character: character,
            prompt: promptBinding.wrappedValue,
            stylePreset: nil,
            globalDefaults: presetStore.globalDefaults
        )
    }
    
    /// The theme for this character - resolved locally
    private var characterTheme: ResolvedTheme {
        themeManager.resolvedTheme(forCharacterThemeId: character.characterThemeId)
    }

    var body: some View {
        let theme = characterTheme
        
        VStack(alignment: .leading, spacing: 20) {
            // Title + images section - Card style
            VStack(alignment: .leading, spacing: 12) {
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

                if !prompt.images.isEmpty || true {
                    imagesSection
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: theme.cornerRadiusMedium)
                    .fill(theme.backgroundSecondary)
            )
            .shadow(color: theme.shadow.opacity(0.06), radius: 8, x: 0, y: 2)
            
            // Quick Actions Bar - matching Scratchpad style
            quickActionsBar
            
            // Prompt Preview Card
            VStack(alignment: .leading, spacing: 0) {
                PromptPreviewSection(
                    composedPrompt: composedPrompt,
                    characterThemeId: character.characterThemeId
                )
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: theme.cornerRadiusMedium)
                    .fill(theme.backgroundSecondary)
            )
            .shadow(color: theme.shadow.opacity(0.06), radius: 8, x: 0, y: 2)

            // Prompt Sections Card
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    Text("Prompt Sections")
                        .font(.headline)
                        .fontDesign(theme.fontDesign)
                        .foregroundColor(theme.textPrimary)
                    
                    Spacer()
                    
                    Button {
                        fillWithCharacterDefaults()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down.doc")
                                .font(.caption)
                            Text("Set Defaults")
                                .font(.caption)
                        }
                        .foregroundColor(theme.primary)
                    }
                    
                    Button {
                        showingClearConfirm = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "trash")
                                .font(.caption)
                            Text("Clear")
                                .font(.caption)
                        }
                        .foregroundColor(theme.error)
                    }
                }
                
                sectionsEditor
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: theme.cornerRadiusMedium)
                    .fill(theme.backgroundSecondary)
            )
            .shadow(color: theme.shadow.opacity(0.06), radius: 8, x: 0, y: 2)
            
            // Delete button - full width at bottom
            ThemedButton("Delete Prompt", icon: "trash", style: .destructive) {
                showingDeleteConfirm = true
            }
        }
        .overlay(alignment: .top) {
            if showCopiedToast {
                copiedToastView
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
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
            }
            Button("Cancel", role: .cancel) {
                duplicatePromptName = ""
            }
        } message: {
            Text("Enter a name for the duplicated prompt")
        }
        .alert("Clear all prompt sections?", isPresented: $showingClearConfirm) {
            Button("Clear", role: .destructive) {
                clearAllSections()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will clear all prompt section fields. This cannot be undone.")
        }
        .sheet(isPresented: $showingPromptImagePicker) {
            ImagePicker { uiImages in
                var updated = promptBinding.wrappedValue
                for image in uiImages {
                    if let data = image.jpegData(compressionQuality: 0.9) {
                        updated.images.append(
                            PromptImage(id: UUID(), data: data)
                        )
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
                    character.profileImageData = imageData
                }
            )
        }
        .alert("Save as preset", isPresented: $isShowingPresetSaveAlert) {
            TextField("Preset name", text: $pendingPresetNameInput)

            Button("Save") {
                let nameTrimmed = pendingPresetNameInput
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                let finalName = nameTrimmed.isEmpty
                    ? pendingPresetLabel
                    : nameTrimmed

                if let kind = pendingPresetKind {
                    presetStore.addPreset(
                        kind: kind,
                        name: finalName,
                        text: pendingPresetText
                    )
                    resyncAllPresetMarkers()
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
        .sheet(isPresented: $showingAddToOtherCharacters) {
            MultiCharacterPickerSheet(
                characters: DataStore.shared.characters,
                prompt: prompt,
                onComplete: { selectedCharacters in
                    // Add prompt to selected characters
                    for targetCharacter in selectedCharacters {
                        // Create a copy of the prompt with new ID
                        let newPrompt = SavedPrompt(
                            title: prompt.title,
                            text: prompt.text,
                            physicalDescription: prompt.physicalDescription,
                            outfit: prompt.outfit,
                            pose: prompt.pose,
                            environment: prompt.environment,
                            lighting: prompt.lighting,
                            styleModifiers: prompt.styleModifiers,
                            technicalModifiers: prompt.technicalModifiers,
                            negativePrompt: prompt.negativePrompt,
                            additionalInfo: prompt.additionalInfo,
                            physicalDescriptionPresetName: prompt.physicalDescriptionPresetName,
                            outfitPresetName: prompt.outfitPresetName,
                            posePresetName: prompt.posePresetName,
                            environmentPresetName: prompt.environmentPresetName,
                            lightingPresetName: prompt.lightingPresetName,
                            stylePresetName: prompt.stylePresetName,
                            technicalPresetName: prompt.technicalPresetName,
                            negativePresetName: prompt.negativePresetName,
                            images: [] // Don't copy images
                        )
                        
                        // Find and update the character
                        if let index = DataStore.shared.characters.firstIndex(where: { $0.id == targetCharacter.id }) {
                            var updatedCharacter = DataStore.shared.characters[index]
                            updatedCharacter.prompts.append(newPrompt)
                            DataStore.shared.updateCharacter(updatedCharacter)
                        }
                    }
                    
                    // Show toast
                    addedToCharacterCount = selectedCharacters.count
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showAddedToast = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showAddedToast = false
                        }
                    }
                },
                excludeCharacterId: character.id
            )
            .environmentObject(themeManager)
        }
        .overlay(alignment: .top) {
            if showAddedToast {
                addedToastView
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
    
    // MARK: - Added Toast
    
    private var addedToastView: some View {
        let theme = characterTheme
        
        return HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(theme.textOnPrimary)
            Text("Added to \(addedToCharacterCount) character\(addedToCharacterCount == 1 ? "" : "s")")
                .font(.subheadline.weight(.medium))
                .fontDesign(theme.fontDesign)
                .foregroundColor(theme.textOnPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(theme.success)
        )
        .padding(.top, 8)
    }
    
    // MARK: - Quick Actions Bar
    
    private var quickActionsBar: some View {
        let theme = characterTheme
        
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
                    openGeneratorForCurrentPrompt()
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
                    duplicatePromptName = "\(prompt.title) (Copy)"
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
                
                // Add to Other Characters button - uses primary color for sharing action
                Button {
                    showingAddToOtherCharacters = true
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
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: theme.cornerRadiusMedium)
                .fill(theme.backgroundSecondary)
        )
        .shadow(color: theme.shadow.opacity(0.06), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Copied Toast
    
    private var copiedToastView: some View {
        let theme = characterTheme
        
        return HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(theme.textOnPrimary)
            Text("Copied to clipboard")
                .font(.subheadline.weight(.medium))
                .fontDesign(theme.fontDesign)
                .foregroundColor(theme.textOnPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(theme.success)
        )
        .padding(.top, 8)
    }
    
    // MARK: - Sections Editor
    
    private var sectionsEditor: some View {
        VStack(alignment: .leading, spacing: 24) {
            sectionRow(
                label: "Physical Description",
                kind: .physicalDescription,
                text: physicalDescriptionBinding,
                presetName: physicalDescriptionPresetNameBinding
            )

            sectionRow(
                label: "Outfit",
                kind: .outfit,
                text: outfitBinding,
                presetName: outfitPresetNameBinding
            )

            sectionRow(
                label: "Pose",
                kind: .pose,
                text: poseBinding,
                presetName: posePresetNameBinding
            )

            sectionRow(
                label: "Environment",
                kind: .environment,
                text: environmentBinding,
                presetName: environmentPresetNameBinding
            )

            sectionRow(
                label: "Lighting",
                kind: .lighting,
                text: lightingBinding,
                presetName: lightingPresetNameBinding
            )

            sectionRow(
                label: "Style Modifiers",
                kind: .style,
                text: styleModifiersBinding,
                presetName: stylePresetNameBinding
            )

            sectionRow(
                label: "Technical Modifiers",
                kind: .technical,
                text: technicalModifiersBinding,
                presetName: technicalPresetNameBinding
            )

            sectionRow(
                label: "Negative Prompt",
                kind: .negative,
                text: negativePromptBinding,
                presetName: negativePresetNameBinding
            )

            // Additional Information
            VStack(alignment: .leading, spacing: 6) {
                Text("Additional Information")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .fontDesign(characterTheme.fontDesign)
                    .foregroundColor(characterTheme.textPrimary)

                DynamicGrowingTextEditor(
                    text: additionalInfoBinding,
                    placeholder: "Any extra details that don't fit in other sections",
                    minLines: 0,
                    maxLines: 5,
                    characterThemeId: character.characterThemeId
                )
            }
        }
    }
    
    // MARK: - Fill With Defaults
    
    private func fillWithCharacterDefaults() {
        let globalDefaults = presetStore.globalDefaults
        let characterDefaults = character.characterDefaults
        
        func effectiveDefault(_ key: GlobalDefaultKey) -> String? {
            characterDefaults[key]?.nonEmpty ?? globalDefaults[key]?.nonEmpty
        }
        
        var updated = promptBinding.wrappedValue
        updated.physicalDescription = effectiveDefault(.physicalDescription)
        updated.outfit = effectiveDefault(.outfit)
        updated.pose = effectiveDefault(.pose)
        updated.environment = effectiveDefault(.environment)
        updated.lighting = effectiveDefault(.lighting)
        updated.styleModifiers = effectiveDefault(.style)
        updated.technicalModifiers = effectiveDefault(.technical)
        updated.negativePrompt = effectiveDefault(.negative)
        promptBinding.wrappedValue = updated
        
        resyncAllPresetMarkers()
    }
    
    // MARK: - Clear All Sections
    
    private func clearAllSections() {
        var updated = promptBinding.wrappedValue
        updated.physicalDescription = nil
        updated.outfit = nil
        updated.pose = nil
        updated.environment = nil
        updated.lighting = nil
        updated.styleModifiers = nil
        updated.technicalModifiers = nil
        updated.negativePrompt = nil
        updated.additionalInfo = nil
        updated.physicalDescriptionPresetName = nil
        updated.outfitPresetName = nil
        updated.posePresetName = nil
        updated.environmentPresetName = nil
        updated.lightingPresetName = nil
        updated.stylePresetName = nil
        updated.technicalPresetName = nil
        updated.negativePresetName = nil
        promptBinding.wrappedValue = updated
    }
    
    // MARK: - Duplicate Prompt
    
    private func createDuplicatePrompt(withName name: String) -> SavedPrompt {
        let original = prompt
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = trimmedName.isEmpty ? "\(original.title) (Copy)" : trimmedName
        
        return SavedPrompt(
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
    }
    
    // MARK: - Open Generator
    
    private func openGeneratorForCurrentPrompt() {
        let slug = character.characterDefaultPerchanceGenerator?.nonEmpty
            ?? presetStore.defaultPerchanceGenerator.nonEmpty
            ?? "ai-artgen"

        let urlString = "https://perchance.org/\(slug)"
        guard let url = URL(string: urlString) else { return }

        UIPasteboard.general.string = composedPrompt
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    // MARK: - Images Section
    
    private var imagesSection: some View {
        let theme = characterTheme
        
        return VStack(alignment: .leading, spacing: 12) {
            Text("Images")
                .font(.subheadline)
                .fontWeight(.semibold)
                .fontDesign(theme.fontDesign)
                .foregroundColor(theme.textPrimary)

            if promptBinding.wrappedValue.images.isEmpty {
                Text("No images yet. Upload some!")
                    .font(.caption)
                    .fontDesign(theme.fontDesign)
                    .foregroundColor(theme.textSecondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(promptBinding.wrappedValue.images.enumerated()), id: \.element.id) { index, img in
                            if let uiImage = UIImage(data: img.data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadiusSmall))
                                    .onTapGesture {
                                        promptGalleryStartIndex = index
                                        showingPromptGallery = true
                                    }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            Button {
                showingPromptImagePicker = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus.circle")
                    Text("Add Images")
                }
                .font(.caption.weight(.medium))
                .foregroundColor(theme.primary)
                .padding(.top, 2)
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    // MARK: - Section Row
    
    private func sectionRow(
        label: String,
        kind: PromptSectionKind,
        text: Binding<String>,
        presetName: Binding<String?>
    ) -> some View {
        let theme = characterTheme
        
        return VStack(alignment: .leading, spacing: 10) {
            // Label row
            HStack(spacing: 8) {
                Text(label)
                    .font(.subheadline.weight(.semibold))
                    .fontDesign(theme.fontDesign)
                    .foregroundColor(theme.textPrimary)

                let presets = presetStore.presets(of: kind)
                let trimmed = text.wrappedValue
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                if !presets.isEmpty {
                    Menu {
                        ForEach(presets) { preset in
                            Button {
                                text.wrappedValue = preset.text
                                presetName.wrappedValue = preset.name
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

                if let name = presetName.wrappedValue, !name.isEmpty {
                    Text("(Using: \(name))")
                        .font(.caption2)
                        .fontDesign(theme.fontDesign)
                        .foregroundColor(theme.textSecondary)
                } else if !trimmed.isEmpty {
                    Button {
                        beginSavingPreset(
                            from: text.wrappedValue,
                            kind: kind,
                            label: label
                        )
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "star.badge.plus")
                            Text("Save as preset")
                        }
                        .font(.caption)
                        .foregroundColor(theme.primary)
                    }
                }

                Spacer()
            }

            // Text input - slightly smaller font than label
            DynamicGrowingTextEditor(
                text: text,
                placeholder: "Optional \(label.lowercased()) details",
                minLines: 0,
                maxLines: 5,
                fontSize: 14,
                characterThemeId: character.characterThemeId
            )
            .onAppear {
                updatePresetNameForCurrentText(
                    kind: kind,
                    text: text,
                    presetName: presetName
                )
            }
            .onChange(of: text.wrappedValue) { _, _ in
                updatePresetNameForCurrentText(
                    kind: kind,
                    text: text,
                    presetName: presetName
                )
            }
        }
    }
    
    // MARK: - Preset Helpers
    
    private func beginSavingPreset(
        from text: String,
        kind: PromptSectionKind,
        label: String
    ) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        pendingPresetText = trimmed
        pendingPresetKind = kind
        pendingPresetLabel = label
        pendingPresetNameInput = label
        isShowingPresetSaveAlert = true
    }

    private func resyncAllPresetMarkers() {
        updatePresetNameForCurrentText(
            kind: .physicalDescription,
            text: physicalDescriptionBinding,
            presetName: physicalDescriptionPresetNameBinding
        )
        updatePresetNameForCurrentText(
            kind: .outfit,
            text: outfitBinding,
            presetName: outfitPresetNameBinding
        )
        updatePresetNameForCurrentText(
            kind: .pose,
            text: poseBinding,
            presetName: posePresetNameBinding
        )
        updatePresetNameForCurrentText(
            kind: .environment,
            text: environmentBinding,
            presetName: environmentPresetNameBinding
        )
        updatePresetNameForCurrentText(
            kind: .lighting,
            text: lightingBinding,
            presetName: lightingPresetNameBinding
        )
        updatePresetNameForCurrentText(
            kind: .style,
            text: styleModifiersBinding,
            presetName: stylePresetNameBinding
        )
        updatePresetNameForCurrentText(
            kind: .technical,
            text: technicalModifiersBinding,
            presetName: technicalPresetNameBinding
        )
        updatePresetNameForCurrentText(
            kind: .negative,
            text: negativePromptBinding,
            presetName: negativePresetNameBinding
        )
    }

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

        if let currentName = presetName.wrappedValue,
           let currentPreset = presets.first(where: { $0.name == currentName }),
           currentPreset.text.trimmingCharacters(in: .whitespacesAndNewlines) == trimmed {
            return
        }

        if let match = presets.first(where: {
            $0.text.trimmingCharacters(in: .whitespacesAndNewlines) == trimmed
        }) {
            presetName.wrappedValue = match.name
        } else if presetName.wrappedValue != nil {
            presetName.wrappedValue = nil
        }
    }

    // MARK: - Bindings

    private var titleBinding: Binding<String> {
        Binding(
            get: { promptBinding.wrappedValue.title },
            set: { promptBinding.wrappedValue.title = $0 }
        )
    }

    private var textBinding: Binding<String> {
        Binding(
            get: { promptBinding.wrappedValue.text },
            set: { promptBinding.wrappedValue.text = $0 }
        )
    }
    
    private var physicalDescriptionBinding: Binding<String> {
        Binding(
            get: { promptBinding.wrappedValue.physicalDescription ?? "" },
            set: { promptBinding.wrappedValue.physicalDescription = $0 }
        )
    }

    private var outfitBinding: Binding<String> {
        Binding(
            get: { promptBinding.wrappedValue.outfit ?? "" },
            set: { promptBinding.wrappedValue.outfit = $0 }
        )
    }

    private var poseBinding: Binding<String> {
        Binding(
            get: { promptBinding.wrappedValue.pose ?? "" },
            set: { promptBinding.wrappedValue.pose = $0 }
        )
    }

    private var environmentBinding: Binding<String> {
        Binding(
            get: { promptBinding.wrappedValue.environment ?? "" },
            set: { promptBinding.wrappedValue.environment = $0 }
        )
    }

    private var lightingBinding: Binding<String> {
        Binding(
            get: { promptBinding.wrappedValue.lighting ?? "" },
            set: { promptBinding.wrappedValue.lighting = $0 }
        )
    }

    private var styleModifiersBinding: Binding<String> {
        Binding(
            get: { promptBinding.wrappedValue.styleModifiers ?? "" },
            set: { promptBinding.wrappedValue.styleModifiers = $0 }
        )
    }

    private var technicalModifiersBinding: Binding<String> {
        Binding(
            get: { promptBinding.wrappedValue.technicalModifiers ?? "" },
            set: { promptBinding.wrappedValue.technicalModifiers = $0 }
        )
    }

    private var negativePromptBinding: Binding<String> {
        Binding(
            get: { promptBinding.wrappedValue.negativePrompt ?? "" },
            set: { promptBinding.wrappedValue.negativePrompt = $0 }
        )
    }

    private var additionalInfoBinding: Binding<String> {
        Binding(
            get: { promptBinding.wrappedValue.additionalInfo ?? "" },
            set: { promptBinding.wrappedValue.additionalInfo = $0 }
        )
    }
    
    private var physicalDescriptionPresetNameBinding: Binding<String?> {
        Binding(
            get: { promptBinding.wrappedValue.physicalDescriptionPresetName },
            set: { promptBinding.wrappedValue.physicalDescriptionPresetName = $0 }
        )
    }

    private var outfitPresetNameBinding: Binding<String?> {
        Binding(
            get: { promptBinding.wrappedValue.outfitPresetName },
            set: { promptBinding.wrappedValue.outfitPresetName = $0 }
        )
    }

    private var posePresetNameBinding: Binding<String?> {
        Binding(
            get: { promptBinding.wrappedValue.posePresetName },
            set: { promptBinding.wrappedValue.posePresetName = $0 }
        )
    }

    private var environmentPresetNameBinding: Binding<String?> {
        Binding(
            get: { promptBinding.wrappedValue.environmentPresetName },
            set: { promptBinding.wrappedValue.environmentPresetName = $0 }
        )
    }

    private var lightingPresetNameBinding: Binding<String?> {
        Binding(
            get: { promptBinding.wrappedValue.lightingPresetName },
            set: { promptBinding.wrappedValue.lightingPresetName = $0 }
        )
    }

    private var stylePresetNameBinding: Binding<String?> {
        Binding(
            get: { promptBinding.wrappedValue.stylePresetName },
            set: { promptBinding.wrappedValue.stylePresetName = $0 }
        )
    }

    private var technicalPresetNameBinding: Binding<String?> {
        Binding(
            get: { promptBinding.wrappedValue.technicalPresetName },
            set: { promptBinding.wrappedValue.technicalPresetName = $0 }
        )
    }

    private var negativePresetNameBinding: Binding<String?> {
        Binding(
            get: { promptBinding.wrappedValue.negativePresetName },
            set: { promptBinding.wrappedValue.negativePresetName = $0 }
        )
    }
}
