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

    // Save-as-preset flow (same pattern as in character prompt)
    @State private var isShowingPresetSaveAlert: Bool = false
    @State private var pendingPresetKind: PromptSectionKind? = nil
    @State private var pendingPresetText: String = ""
    @State private var pendingPresetLabel: String = ""
    @State private var pendingPresetNameInput: String = ""

    // MARK: - Composed scratch prompt (global defaults only, no character overrides)

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

        // Dummy character with NO overrides so only global defaults are used
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
        NavigationView {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {

                        // Header – no title field, just context + actions
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Scratchpad Prompt")
                                .font(.headline)

                            Text("Use the sections below to build a prompt. Global defaults are applied automatically.")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            HStack(spacing: 12) {
                                Spacer()

                                Button {
                                    saveCurrentScratch()
                                } label: {
                                    Label("Save Scratch", systemImage: "square.and.arrow.down")
                                        .font(.caption.weight(.semibold))
                                }
                                .buttonStyle(.bordered)

                                Button {
                                    addToCharacterTitle = ""
                                    activeSheet = .addToCharacter
                                } label: {
                                    Label("Add to Character", systemImage: "person.crop.circle.badge.plus")
                                        .font(.caption.weight(.semibold))
                                }
                                .buttonStyle(.bordered)
                                .disabled(characters.isEmpty)

                                Button {
                                    activeSheet = .savedScratches
                                } label: {
                                    Label(
                                        "See Saved Scratches" +
                                        (scratchpadSaved.isEmpty ? "" : " (\(scratchpadSaved.count))"),
                                        systemImage: "tray.full"
                                    )
                                    .font(.caption.weight(.semibold))
                                }
                                .buttonStyle(.bordered)

                                Spacer()
                            }
                        }

                        // Preview
                        promptPreviewSection

                        // Decomposed sections (matching character prompt style)
                        VStack(alignment: .leading, spacing: 12) {
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

                            // Additional info (no presets)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Additional Information")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)

                                DynamicGrowingTextEditor(
                                    text: $additionalInfo,
                                    placeholder: "Any extra details that don't fit in other sections",
                                    minLines: 0,
                                    maxLines: 5
                                )
                            }
                        }

                        // Open generator + Clear
                        HStack(spacing: 12) {
                            Spacer()

                            Button {
                                let full = composedScratchPrompt
                                scratchpadPrompt = full      // keep backing string in sync
                                openGenerator(full)
                            } label: {
                                Label("Open Generator", systemImage: "sparkles")
                                    .font(.subheadline.weight(.semibold))
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                            }
                            .buttonStyle(.borderedProminent)

                            Button(role: .destructive) {
                                clearScratchFields()
                            } label: {
                                Label("Clear", systemImage: "trash")
                                    .font(.subheadline.weight(.semibold))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                            }
                            .buttonStyle(.bordered)

                            Spacer()
                        }
                        .padding(.top, 4)
                    }
                    .padding()
                }
            }
            .navigationTitle("Scratchpad")
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        KeyboardHelper.dismiss()
                    }
                }
            }
        }
        // Single sheet router for both overlays
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .savedScratches:
                SavedScratchSheetView(
                    scratchpadSaved: $scratchpadSaved,
                    onSelect: { prompt in
                        loadScratch(prompt)
                    }
                )
                .presentationDetents([.fraction(0.25), .large])
                .presentationDragIndicator(.visible)

            case .addToCharacter:
                AddScratchToCharacterSheet(
                    characters: characters,
                    title: $addToCharacterTitle,
                    onAdd: { characterId, title in
                        addCurrentScratch(to: characterId, withTitle: title)
                    }
                )
                .presentationDetents([.height(260), .medium])
                .presentationDragIndicator(.visible)
            }
        }
        // Save-as-preset alert (same concept as in character view)
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
                    // After saving, the onChange handlers will recompute which preset is in use
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

    // MARK: - Preview section

    private var promptPreviewSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Prompt Preview")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                Button {
                    UIPasteboard.general.string = composedScratchPrompt
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.on.doc")
                        Text("Copy")
                    }
                    .font(.caption)
                }
            }

            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.secondarySystemBackground))
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)

                ScrollView {
                    Text(composedScratchPrompt)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .padding(12)
                }
            }
            .frame(height: 250)
        }
    }

    // MARK: - Section row (styled like character prompt)

    private func sectionRow(
        label: String,
        kind: PromptSectionKind,
        text: Binding<String>,
        presetName: Binding<String?>
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                let presets = presetStore.presets(of: kind)
                let trimmed = text.wrappedValue
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                // Apply menu for known presets
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
                            Text("Apply")
                        }
                        .font(.caption)
                    }
                }

                // Either "Using: <preset>" or "Save as preset"
                if let name = presetName.wrappedValue, !name.isEmpty {
                    Text("(Using: \(name))")
                        .font(.caption)
                        .foregroundColor(.secondary)
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
                    }
                }

                Spacer()
            }

            DynamicGrowingTextEditor(
                text: text,
                placeholder: "Optional \(label.lowercased()) details",
                minLines: 0,
                maxLines: 5
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

    // MARK: - Preset helpers (mirroring character prompt logic)

    private func updatePresetNameForCurrentText(
        kind: PromptSectionKind,
        text: Binding<String>,
        presetName: Binding<String?>
    ) {
        let presets = presetStore.presets(of: kind)
        let trimmed = text.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines)

        // If text is empty, clear any preset info
        guard !trimmed.isEmpty else {
            if presetName.wrappedValue != nil {
                presetName.wrappedValue = nil
            }
            return
        }

        // If we already have a presetName and it still matches exactly, keep it
        if let currentName = presetName.wrappedValue,
           let currentPreset = presets.first(where: { $0.name == currentName }),
           currentPreset.text.trimmingCharacters(in: .whitespacesAndNewlines) == trimmed {
            return
        }

        // Otherwise, see if any preset text matches exactly
        if let match = presets.first(where: {
            $0.text.trimmingCharacters(in: .whitespacesAndNewlines) == trimmed
        }) {
            presetName.wrappedValue = match.name
        } else if presetName.wrappedValue != nil {
            // Text no longer matches any preset → clear the marker
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
        pendingPresetNameInput = label   // default suggestion
        isShowingPresetSaveAlert = true
    }

    // MARK: - Save / load / attach helpers

    private func saveCurrentScratch() {
        let full = composedScratchPrompt
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
            // Old-style saved scratches: treat text as "Additional Information"
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

        scratchpadPrompt = ""
    }

    private func makeTitle(from prompt: String) -> String {
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "Untitled Scratch" }
        let prefix = trimmed.prefix(40)
        return String(prefix) + (trimmed.count > 40 ? "…" : "")
    }
}

// MARK: - Bottom sheet: Saved scratches

private struct SavedScratchSheetView: View {
    @Binding var scratchpadSaved: [SavedPrompt]
    let onSelect: (SavedPrompt) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                if scratchpadSaved.isEmpty {
                    Text("No saved scratch prompts yet.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(scratchpadSaved) { prompt in
                        VStack(alignment: .leading) {
                            Text(prompt.title)
                                .font(.subheadline)
                                .bold()
                            Text(prompt.text)
                                .font(.caption)
                                .lineLimit(3)
                                .foregroundColor(.secondary)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onSelect(prompt)
                            dismiss()
                        }
                    }
                    .onDelete { indices in
                        scratchpadSaved.remove(atOffsets: indices)
                    }
                }
            }
            .navigationTitle("Saved Scratch Prompts")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !scratchpadSaved.isEmpty {
                        EditButton()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Bottom sheet: Add to character

private struct AddScratchToCharacterSheet: View {
    let characters: [CharacterProfile]
    @Binding var title: String
    let onAdd: (CharacterProfile.ID, String) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Add to Character")
                    .font(.headline)

                TextField("Prompt title (required)", text: $title)
                    .textFieldStyle(.roundedBorder)

                if characters.isEmpty {
                    Text("You don't have any characters yet.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                } else {
                    List {
                        ForEach(characters) { character in
                            let disabled = title
                                .trimmingCharacters(in: .whitespacesAndNewlines)
                                .isEmpty
                            Button {
                                let trimmed = title
                                    .trimmingCharacters(in: .whitespacesAndNewlines)
                                guard !trimmed.isEmpty else { return }
                                onAdd(character.id, trimmed)
                                dismiss()
                            } label: {
                                HStack {
                                    Text(character.name.isEmpty ? "Untitled Character" : character.name)
                                    Spacer()
                                }
                            }
                            .disabled(disabled)
                        }
                    }
                    .listStyle(.plain)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Add to Character")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
