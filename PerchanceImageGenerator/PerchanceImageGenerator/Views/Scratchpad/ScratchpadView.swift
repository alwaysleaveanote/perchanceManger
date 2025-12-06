//
//  ScratchpadView.swift
//  PerchanceImageGenerator
//
//  Completely redesigned to mirror the character prompt editor,
//  with saved scratches + add-to-character support.
//

import SwiftUI

struct ScratchpadView: View {
    @Binding var scratchpadPrompt: String
    @Binding var scratchpadSaved: [SavedPrompt]
    @Binding var characters: [CharacterProfile]

    let openGenerator: (String) -> Void

    @EnvironmentObject var presetStore: PromptPresetStore
    @EnvironmentObject var themeManager: ThemeManager

    // Section texts (same structure as character prompts)
    @State private var physicalDescription: String = ""
    @State private var outfit: String = ""
    @State private var pose: String = ""
    @State private var environment: String = ""
    @State private var lighting: String = ""
    @State private var styleModifiers: String = ""
    @State private var technicalModifiers: String = ""
    @State private var negativePrompt: String = ""
    @State private var additionalInfo: String = ""

    // Preset markers (same idea as character prompts)
    @State private var physicalPresetName: String? = nil
    @State private var outfitPresetName: String? = nil
    @State private var posePresetName: String? = nil
    @State private var environmentPresetName: String? = nil
    @State private var lightingPresetName: String? = nil
    @State private var stylePresetName: String? = nil
    @State private var technicalPresetName: String? = nil
    @State private var negativePresetName: String? = nil

    // Sheet routing
    private enum ActiveSheet: Identifiable {
        case savedScratches
        case addToCharacter

        var id: Int {
            switch self {
            case .savedScratches: return 0
            case .addToCharacter: return 1
            }
        }
    }

    @State private var activeSheet: ActiveSheet? = nil

    // Add-to-character flow
    @State private var addToCharacterTitle: String = ""

    // Save-as-preset flow
    @State private var isShowingPresetSaveAlert: Bool = false
    @State private var pendingPresetKind: PromptSectionKind? = nil
    @State private var pendingPresetText: String = ""
    @State private var pendingPresetLabel: String = ""
    @State private var pendingPresetNameInput: String = ""
    
    // Duplicate warning
    @State private var showDuplicateWarning: Bool = false
    
    // Empty scratch warning
    @State private var showEmptyWarning: Bool = false
    
    // Clear confirmation
    @State private var showClearConfirmation: Bool = false

    // MARK: - Composed scratch prompt

    private var composedScratchPrompt: String {
        let scratch = SavedPrompt(
            title: "Scratchpad Prompt",
            text: "",
            physicalDescription: physicalDescription.nonEmpty,
            outfit: outfit.nonEmpty,
            pose: pose.nonEmpty,
            environment: environment.nonEmpty,
            lighting: lighting.nonEmpty,
            styleModifiers: styleModifiers.nonEmpty,
            technicalModifiers: technicalModifiers.nonEmpty,
            negativePrompt: negativePrompt.nonEmpty,
            additionalInfo: additionalInfo.nonEmpty,
            physicalDescriptionPresetName: physicalPresetName,
            outfitPresetName: outfitPresetName,
            posePresetName: posePresetName,
            environmentPresetName: environmentPresetName,
            lightingPresetName: lightingPresetName,
            stylePresetName: stylePresetName,
            technicalPresetName: technicalPresetName,
            negativePresetName: negativePresetName
        )

        let scratchCharacter = CharacterProfile(
            name: "",
            bio: "",
            notes: "",
            prompts: []
        )

        return PromptComposer.composePrompt(
            character: scratchCharacter,
            prompt: scratch,
            stylePreset: nil,
            globalDefaults: presetStore.globalDefaults
        )
    }

    // MARK: - Body

    var body: some View {
        let theme = themeManager.resolved
        
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Prompt Preview Card
                    VStack(alignment: .leading, spacing: 0) {
                        PromptPreviewSection(composedPrompt: composedScratchPrompt)
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
                                fillWithGlobalDefaults()
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.down.doc")
                                        .font(.caption)
                                    Text("Set Defaults")
                                        .font(.caption)
                                }
                                .foregroundColor(theme.primary)
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
                    
                    // Action buttons at bottom of scroll
                    actionButtonsSection
                }
                .padding()
            }
            .themedBackground()
            .navigationTitle("Scratchpad")
            .navigationBarTitleDisplayMode(.inline)
            .themedNavigationBar()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            activeSheet = .savedScratches
                        } label: {
                            Label("Saved Scratches" + (scratchpadSaved.isEmpty ? "" : " (\(scratchpadSaved.count))"), systemImage: "tray.full")
                        }
                        
                        Button {
                            saveCurrentScratch()
                        } label: {
                            Label("Save Current", systemImage: "square.and.arrow.down")
                        }
                        
                        if !characters.isEmpty {
                            Button {
                                addToCharacterTitle = ""
                                activeSheet = .addToCharacter
                            } label: {
                                Label("Add to Character", systemImage: "person.badge.plus")
                            }
                        }
                        
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 18))
                            .foregroundColor(theme.primary)
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
        }
        .navigationViewStyle(.stack)
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .savedScratches:
                SavedScratchSheetView(
                    scratchpadSaved: $scratchpadSaved,
                    onSelect: { prompt in
                        loadScratch(prompt)
                    }
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)

            case .addToCharacter:
                AddScratchToCharacterSheet(
                    characters: characters,
                    title: $addToCharacterTitle,
                    onAdd: { characterId, title in
                        addCurrentScratch(to: characterId, withTitle: title)
                    }
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
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
        .alert("Duplicate Scratch", isPresented: $showDuplicateWarning) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("This scratch prompt has already been saved. Make some changes before saving again.")
        }
        .alert("Empty Scratch", isPresented: $showEmptyWarning) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Please fill out at least one field before saving a scratch prompt.")
        }
        .alert("Clear Scratchpad?", isPresented: $showClearConfirmation) {
            Button("Clear", role: .destructive) {
                clearScratchFields()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to clear all fields? This cannot be undone.")
        }
    }

    // MARK: - Action Buttons Section

    private var actionButtonsSection: some View {
        let theme = themeManager.resolved
        
        return HStack(spacing: 12) {
            // Clear button - Dangerous action
            Button {
                showClearConfirmation = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "trash")
                        .font(.system(size: 14, weight: .medium))
                    Text("Clear")
                        .font(.subheadline.weight(.medium))
                }
                .foregroundColor(theme.error)
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(theme.backgroundSecondary)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(theme.error.opacity(0.3), lineWidth: 1)
                )
            }
            
            // Open Generator - Primary action
            Button {
                let full = composedScratchPrompt
                scratchpadPrompt = full
                openGenerator(full)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Open Generator")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundColor(theme.textOnPrimary)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(theme.primary)
                .clipShape(Capsule())
                .shadow(color: theme.primary.opacity(0.4), radius: 8, x: 0, y: 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    // MARK: - Sections Editor

    private var sectionsEditor: some View {
        VStack(alignment: .leading, spacing: 24) {
            sectionRow(
                label: "Physical Description",
                kind: .physicalDescription,
                text: $physicalDescription,
                presetName: $physicalPresetName
            )

            sectionRow(
                label: "Outfit",
                kind: .outfit,
                text: $outfit,
                presetName: $outfitPresetName
            )

            sectionRow(
                label: "Pose",
                kind: .pose,
                text: $pose,
                presetName: $posePresetName
            )

            sectionRow(
                label: "Environment",
                kind: .environment,
                text: $environment,
                presetName: $environmentPresetName
            )

            sectionRow(
                label: "Lighting",
                kind: .lighting,
                text: $lighting,
                presetName: $lightingPresetName
            )

            sectionRow(
                label: "Style Modifiers",
                kind: .style,
                text: $styleModifiers,
                presetName: $stylePresetName
            )

            sectionRow(
                label: "Technical Modifiers",
                kind: .technical,
                text: $technicalModifiers,
                presetName: $technicalPresetName
            )

            sectionRow(
                label: "Negative Prompt",
                kind: .negative,
                text: $negativePrompt,
                presetName: $negativePresetName
            )

            VStack(alignment: .leading, spacing: 4) {
                Text("Additional Information")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .fontDesign(themeManager.resolved.fontDesign)
                    .foregroundColor(themeManager.resolved.textPrimary)

                DynamicGrowingTextEditor(
                    text: $additionalInfo,
                    placeholder: "Any extra details that don't fit in other sections",
                    minLines: 0,
                    maxLines: 5
                )
            }
        }
    }


    // MARK: - Section Row

    private func sectionRow(
        label: String,
        kind: PromptSectionKind,
        text: Binding<String>,
        presetName: Binding<String?>
    ) -> some View {
        let theme = themeManager.resolved
        
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
                fontSize: 14
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

    // MARK: - Save / Load / Attach Helpers
    
    private var hasAnyContent: Bool {
        !physicalDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !outfit.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !pose.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !environment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !lighting.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !styleModifiers.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !technicalModifiers.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !negativePrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !additionalInfo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func saveCurrentScratch() {
        // Check for empty scratch
        if !hasAnyContent {
            showEmptyWarning = true
            return
        }
        
        let full = composedScratchPrompt
        
        // Check for duplicate
        let isDuplicate = scratchpadSaved.contains { existing in
            existing.text.trimmingCharacters(in: .whitespacesAndNewlines) == full.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        if isDuplicate {
            showDuplicateWarning = true
            return
        }
        
        let titleToUse = makeTitle(from: full)

        let saved = SavedPrompt(
            title: titleToUse,
            text: full,
            physicalDescription: physicalDescription.nonEmpty,
            outfit: outfit.nonEmpty,
            pose: pose.nonEmpty,
            environment: environment.nonEmpty,
            lighting: lighting.nonEmpty,
            styleModifiers: styleModifiers.nonEmpty,
            technicalModifiers: technicalModifiers.nonEmpty,
            negativePrompt: negativePrompt.nonEmpty,
            additionalInfo: additionalInfo.nonEmpty,
            physicalDescriptionPresetName: physicalPresetName,
            outfitPresetName: outfitPresetName,
            posePresetName: posePresetName,
            environmentPresetName: environmentPresetName,
            lightingPresetName: lightingPresetName,
            stylePresetName: stylePresetName,
            technicalPresetName: technicalPresetName,
            negativePresetName: negativePresetName
        )

        scratchpadSaved.insert(saved, at: 0)
    }

    private func addCurrentScratch(
        to characterId: CharacterProfile.ID,
        withTitle title: String
    ) {
        let full = composedScratchPrompt

        let newPrompt = SavedPrompt(
            title: title,
            text: full,
            physicalDescription: physicalDescription.nonEmpty,
            outfit: outfit.nonEmpty,
            pose: pose.nonEmpty,
            environment: environment.nonEmpty,
            lighting: lighting.nonEmpty,
            styleModifiers: styleModifiers.nonEmpty,
            technicalModifiers: technicalModifiers.nonEmpty,
            negativePrompt: negativePrompt.nonEmpty,
            additionalInfo: additionalInfo.nonEmpty,
            physicalDescriptionPresetName: physicalPresetName,
            outfitPresetName: outfitPresetName,
            posePresetName: posePresetName,
            environmentPresetName: environmentPresetName,
            lightingPresetName: lightingPresetName,
            stylePresetName: stylePresetName,
            technicalPresetName: technicalPresetName,
            negativePresetName: negativePresetName
        )

        guard let index = characters.firstIndex(where: { $0.id == characterId }) else { return }
        characters[index].prompts.append(newPrompt)
    }

    private func loadScratch(_ prompt: SavedPrompt) {
        let hasStructuredFields =
            prompt.physicalDescription != nil ||
            prompt.outfit != nil ||
            prompt.pose != nil ||
            prompt.environment != nil ||
            prompt.lighting != nil ||
            prompt.styleModifiers != nil ||
            prompt.technicalModifiers != nil ||
            prompt.negativePrompt != nil ||
            prompt.additionalInfo != nil

        if hasStructuredFields {
            physicalDescription = prompt.physicalDescription ?? ""
            outfit = prompt.outfit ?? ""
            pose = prompt.pose ?? ""
            environment = prompt.environment ?? ""
            lighting = prompt.lighting ?? ""
            styleModifiers = prompt.styleModifiers ?? ""
            technicalModifiers = prompt.technicalModifiers ?? ""
            negativePrompt = prompt.negativePrompt ?? ""
            additionalInfo = prompt.additionalInfo ?? ""
        } else {
            physicalDescription = ""
            outfit = ""
            pose = ""
            environment = ""
            lighting = ""
            styleModifiers = ""
            technicalModifiers = ""
            negativePrompt = ""
            additionalInfo = prompt.text
        }

        physicalPresetName = prompt.physicalDescriptionPresetName
        outfitPresetName = prompt.outfitPresetName
        posePresetName = prompt.posePresetName
        environmentPresetName = prompt.environmentPresetName
        lightingPresetName = prompt.lightingPresetName
        stylePresetName = prompt.stylePresetName
        technicalPresetName = prompt.technicalPresetName
        negativePresetName = prompt.negativePresetName
    }

    private func clearScratchFields() {
        physicalDescription = ""
        outfit = ""
        pose = ""
        environment = ""
        lighting = ""
        styleModifiers = ""
        technicalModifiers = ""
        negativePrompt = ""
        additionalInfo = ""

        physicalPresetName = nil
        outfitPresetName = nil
        posePresetName = nil
        environmentPresetName = nil
        lightingPresetName = nil
        stylePresetName = nil
        technicalPresetName = nil
        negativePresetName = nil
    }
    
    /// Fills empty fields with global default values
    private func fillWithGlobalDefaults() {
        let defaults = presetStore.globalDefaults
        
        if physicalDescription.isEmpty {
            physicalDescription = defaults[PromptSectionKind.physicalDescription.defaultKey] ?? ""
        }
        if outfit.isEmpty {
            outfit = defaults[PromptSectionKind.outfit.defaultKey] ?? ""
        }
        if pose.isEmpty {
            pose = defaults[PromptSectionKind.pose.defaultKey] ?? ""
        }
        if environment.isEmpty {
            environment = defaults[PromptSectionKind.environment.defaultKey] ?? ""
        }
        if lighting.isEmpty {
            lighting = defaults[PromptSectionKind.lighting.defaultKey] ?? ""
        }
        if styleModifiers.isEmpty {
            styleModifiers = defaults[PromptSectionKind.style.defaultKey] ?? ""
        }
        if technicalModifiers.isEmpty {
            technicalModifiers = defaults[PromptSectionKind.technical.defaultKey] ?? ""
        }
        if negativePrompt.isEmpty {
            negativePrompt = defaults[PromptSectionKind.negative.defaultKey] ?? ""
        }

        scratchpadPrompt = ""
    }

    private func makeTitle(from prompt: String) -> String {
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "Untitled Scratch" }
        let prefix = trimmed.prefix(40)
        return String(prefix) + (trimmed.count > 40 ? "…" : "")
    }
}
