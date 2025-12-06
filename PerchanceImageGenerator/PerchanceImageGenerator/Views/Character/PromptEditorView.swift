import SwiftUI
import UIKit

/// Editor view for a single prompt with all sections and preset support
struct PromptEditorView: View {
    @Binding var character: CharacterProfile
    let promptIndex: Int
    let openGenerator: (String) -> Void
    let onDelete: () -> Void
    
    @State private var showingDeleteConfirm: Bool = false

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

    var body: some View {
        let theme = themeManager.resolved
        
        VStack(alignment: .leading, spacing: 24) {
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

            // Composed preview - Card style
            VStack(alignment: .leading, spacing: 0) {
                PromptPreviewSection(composedPrompt: composedPrompt, height: 180)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: theme.cornerRadiusMedium)
                    .fill(theme.backgroundSecondary)
            )
            .shadow(color: theme.shadow.opacity(0.06), radius: 8, x: 0, y: 2)

            // Decomposed sections - Card style
            VStack(alignment: .leading, spacing: 24) {
                Text("Prompt Sections")
                    .font(.headline)
                    .fontDesign(theme.fontDesign)
                    .foregroundColor(theme.textPrimary)
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
                        .fontDesign(themeManager.resolved.fontDesign)
                        .foregroundColor(themeManager.resolved.textPrimary)

                    DynamicGrowingTextEditor(
                        text: additionalInfoBinding,
                        placeholder: "Any extra details that don't fit in other sections",
                        minLines: 0,
                        maxLines: 5
                    )
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: themeManager.resolved.cornerRadiusMedium)
                    .fill(themeManager.resolved.backgroundSecondary)
            )
            .shadow(color: themeManager.resolved.shadow.opacity(0.06), radius: 8, x: 0, y: 2)

            // Action buttons - Card style
            HStack(spacing: 16) {
                ThemedButton("Open Generator", icon: "sparkles", style: .primary) {
                    openGeneratorForCurrentPrompt()
                }

                Spacer()

                ThemedButton("Delete", icon: "trash", style: .destructive) {
                    showingDeleteConfirm = true
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: themeManager.resolved.cornerRadiusMedium)
                    .fill(themeManager.resolved.backgroundSecondary)
            )
            .shadow(color: themeManager.resolved.shadow.opacity(0.06), radius: 8, x: 0, y: 2)
        }
        .alert("Delete this prompt?", isPresented: $showingDeleteConfirm) {
            Button("Delete", role: .destructive) {
                onDelete()
            }
            Button("Cancel", role: .cancel) { }
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
                images: promptBinding.wrappedValue.images.map { GalleryImage(from: $0, promptIndex: promptIndex) },
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
    }
    
    // MARK: - Open Generator
    
    private func openGeneratorForCurrentPrompt() {
        let slug = character.characterDefaultPerchanceGenerator?.nonEmpty
            ?? presetStore.defaultPerchanceGenerator.nonEmpty
            ?? "furry-ai"

        let urlString = "https://perchance.org/\(slug)"
        guard let url = URL(string: urlString) else { return }

        UIPasteboard.general.string = composedPrompt
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    // MARK: - Images Section
    
    private var imagesSection: some View {
        let theme = themeManager.resolved
        
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
