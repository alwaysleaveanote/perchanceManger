import SwiftUI

struct GlobalSettingsView: View {
    @EnvironmentObject var presetStore: PromptPresetStore
    @EnvironmentObject var themeManager: ThemeManager

    @State private var selectedSection: PromptSectionKind = .physicalDescription
    @State private var customGeneratorName: String = ""

    // Collapse state for sections
    @State private var isThemeExpanded: Bool = false
    @State private var isGeneratorExpanded: Bool = false
    @State private var isGlobalDefaultsExpanded: Bool = false

    // Preset editor state
    @State private var selectedPresetId: UUID? = nil
    @State private var editablePresetName: String = ""
    @State private var editablePresetText: String = ""
    @State private var isShowingPresetEditor: Bool = false
    
    // Save as preset alert
    @State private var isShowingSavePresetAlert: Bool = false
    @State private var savePresetName: String = ""
    
    // Delete preset confirmation
    @State private var presetToDelete: PromptPreset? = nil
    @State private var showingDeletePresetConfirmation = false

    private var selectedGeneratorOption: PerchanceGeneratorOption? {
        perchanceGenerators.first(where: { $0.name == presetStore.defaultPerchanceGenerator }) ?? perchanceGenerators.first
    }

    var body: some View {
        let theme = themeManager.resolved
        
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    themeSection
                    ThemedDivider().padding(.vertical, 8)
                    generatorSection
                    ThemedDivider().padding(.vertical, 8)
                    globalDefaultsSection
                    Spacer(minLength: 0)
                }
                .padding()
            }
            .themedBackground()
            .dismissKeyboardOnDrag()
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .themedNavigationBar()
            .toolbar {
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
        .onChange(of: selectedSection) { _ in
            startNewPreset()
        }
        .alert("Save as Preset", isPresented: $isShowingSavePresetAlert) {
            TextField("Preset name", text: $savePresetName)
            Button("Cancel", role: .cancel) {
                savePresetName = ""
            }
            Button("Save") {
                let trimmedName = savePresetName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedName.isEmpty else { return }
                presetStore.addPreset(
                    kind: selectedSection,
                    name: trimmedName,
                    text: editablePresetText
                )
                savePresetName = ""
            }
        } message: {
            Text("Enter a name for this preset")
        }
        .alert("Delete Preset?", isPresented: $showingDeletePresetConfirmation) {
            Button("Delete", role: .destructive) {
                if let preset = presetToDelete {
                    deletePreset(preset)
                }
                presetToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                presetToDelete = nil
            }
        } message: {
            if let preset = presetToDelete {
                Text("Are you sure you want to delete \"\(preset.name)\"?")
            } else {
                Text("Are you sure you want to delete this preset?")
            }
        }
    }

    // MARK: - Theme Section

    private var themeSection: some View {
        let theme = themeManager.resolved
        
        return VStack(alignment: .leading, spacing: 8) {
            Button(action: {
                withAnimation {
                    isThemeExpanded.toggle()
                }
            }) {
                HStack {
                    Text("App Theme")
                        .font(.title3)
                        .bold()
                        .fontDesign(theme.fontDesign)
                        .foregroundColor(theme.textPrimary)

                    Spacer()

                    Image(systemName: isThemeExpanded ? "chevron.down" : "chevron.right")
                        .font(.subheadline)
                        .foregroundColor(theme.textSecondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isThemeExpanded {
                Text("Choose a visual theme for the entire app. Character-specific themes can override this in character settings.")
                    .font(.caption)
                    .foregroundColor(themeManager.resolved.textSecondary)
                    .padding(.bottom, 8)

                ThemePicker(
                    title: "Global Theme",
                    selectedThemeId: themeManager.globalThemeId,
                    showInheritOption: false,
                    onSelect: { themeId in
                        if let id = themeId {
                            themeManager.setGlobalTheme(id)
                        }
                    }
                )
            }
        }
    }

    // MARK: - Generator Section

    private var generatorSection: some View {
        let theme = themeManager.resolved
        let isUsingCustom = !perchanceGenerators.contains(where: { $0.name == presetStore.defaultPerchanceGenerator })
        
        return VStack(alignment: .leading, spacing: 8) {
            Button(action: {
                withAnimation {
                    isGeneratorExpanded.toggle()
                }
            }) {
                HStack {
                    Text("Default Perchance Generator")
                        .font(.title3)
                        .bold()
                        .fontDesign(theme.fontDesign)
                        .foregroundColor(theme.textPrimary)

                    Spacer()

                    Image(systemName: isGeneratorExpanded ? "chevron.down" : "chevron.right")
                        .font(.subheadline)
                        .foregroundColor(theme.textSecondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isGeneratorExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Choose which Perchance generator to open when generating images. You can select a popular generator or enter a custom one.")
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                    
                    // Current selection display
                    HStack {
                        Text("Current: ")
                            .font(.subheadline)
                            .foregroundColor(theme.textSecondary)
                        Text(presetStore.defaultPerchanceGenerator)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(theme.textPrimary)
                        
                        Spacer()
                        
                        Button {
                            if let url = URL(string: "https://perchance.org/\(presetStore.defaultPerchanceGenerator)") {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            Text("Open")
                                .font(.caption.weight(.medium))
                                .foregroundColor(theme.primary)
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: theme.cornerRadiusSmall)
                            .fill(theme.backgroundSecondary)
                    )
                    
                    // Predefined generators
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Popular Generators")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(theme.textSecondary)
                        
                        ScrollView {
                            VStack(spacing: 6) {
                                ForEach(perchanceGenerators) { option in
                                    Button {
                                        presetStore.defaultPerchanceGenerator = option.name
                                        customGeneratorName = ""
                                    } label: {
                                        HStack {
                                            Image(systemName: presetStore.defaultPerchanceGenerator == option.name ? "checkmark.circle.fill" : "circle")
                                                .foregroundColor(presetStore.defaultPerchanceGenerator == option.name ? theme.primary : theme.textSecondary)
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(option.title.isEmpty ? option.name : option.title)
                                                    .font(.subheadline)
                                                    .foregroundColor(theme.textPrimary)
                                                if !option.description.isEmpty {
                                                    Text(option.description)
                                                        .font(.caption2)
                                                        .foregroundColor(theme.textSecondary)
                                                        .lineLimit(1)
                                                }
                                            }
                                            
                                            Spacer()
                                        }
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: theme.cornerRadiusSmall)
                                                .fill(presetStore.defaultPerchanceGenerator == option.name ? theme.primary.opacity(0.1) : theme.backgroundTertiary)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .frame(maxHeight: 320) // Approximately 8 items
                    }

                    ThemedDivider()

                    // Custom generator section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Custom Generator")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(theme.textSecondary)
                        
                        Text("Enter the slug from any perchance.org generator URL")
                            .font(.caption)
                            .foregroundColor(theme.textSecondary)

                        HStack(spacing: 8) {
                            ThemedTextField(placeholder: "e.g. best-ai-image-generator", text: $customGeneratorName)
                            
                            Button {
                                let trimmed = customGeneratorName.trimmingCharacters(in: .whitespacesAndNewlines)
                                guard !trimmed.isEmpty else { return }
                                presetStore.defaultPerchanceGenerator = trimmed
                            } label: {
                                Text("Use")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(theme.textOnPrimary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(theme.primary)
                                    .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadiusSmall))
                            }
                            .disabled(customGeneratorName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                        
                        if isUsingCustom {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(theme.success)
                                Text("Using custom generator: \(presetStore.defaultPerchanceGenerator)")
                                    .font(.caption)
                                    .foregroundColor(theme.success)
                            }
                        }
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: theme.cornerRadiusMedium)
                        .fill(theme.backgroundSecondary)
                )
            }
        }
    }

    // MARK: - Global Defaults Section

    private var globalDefaultsSection: some View {
        let theme = themeManager.resolved
        
        return VStack(alignment: .leading, spacing: 12) {
            // Header
            Button(action: {
                withAnimation {
                    isGlobalDefaultsExpanded.toggle()
                }
            }) {
                HStack {
                    Text("Prompt Defaults & Presets")
                        .font(.title3)
                        .bold()
                        .fontDesign(theme.fontDesign)
                        .foregroundColor(theme.textPrimary)

                    Spacer()

                    Image(systemName: isGlobalDefaultsExpanded ? "chevron.down" : "chevron.right")
                        .font(.subheadline)
                        .foregroundColor(theme.textSecondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isGlobalDefaultsExpanded {
                // Explanation
                Text("Set default text that auto-fills prompt sections, and create reusable presets you can quickly apply.")
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
                    .padding(.bottom, 4)
                
                // Section tabs - horizontal scrolling pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(PromptSectionKind.allCases, id: \.self) { kind in
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedSection = kind
                                }
                            } label: {
                                Text(kind.displayLabel)
                                    .font(.caption.weight(selectedSection == kind ? .semibold : .regular))
                                    .foregroundColor(selectedSection == kind ? theme.textOnPrimary : theme.textPrimary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .fill(selectedSection == kind ? theme.primary : theme.backgroundSecondary)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                // Content card for selected section
                VStack(alignment: .leading, spacing: 16) {
                    // Default value section
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "text.alignleft")
                                .foregroundColor(theme.primary)
                            Text("Default Value")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(theme.textPrimary)
                            
                            Spacer()
                            
                            // Save as preset button - only show if there's custom text
                            let currentDefault = presetStore.globalDefaults[selectedSection.defaultKey] ?? ""
                            if !currentDefault.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Button {
                                    editablePresetText = currentDefault
                                    savePresetName = ""
                                    isShowingSavePresetAlert = true
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "star.badge.plus")
                                        Text("Save as Preset")
                                    }
                                    .font(.caption.weight(.medium))
                                    .foregroundColor(theme.primary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        
                        Text("This text auto-fills when creating new prompts.")
                            .font(.caption)
                            .foregroundColor(theme.textSecondary)
                        
                        DynamicGrowingTextEditor(
                            text: defaultBinding(for: selectedSection),
                            placeholder: "Enter default \(selectedSection.displayLabel.lowercased())...",
                            minLines: 1,
                            maxLines: 6
                        )
                    }
                    
                    ThemedDivider()
                    
                    // Presets section
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(theme.primary)
                            Text("Saved Presets")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(theme.textPrimary)
                            
                            Spacer()
                            
                            Button {
                                selectedPresetId = nil
                                editablePresetName = ""
                                editablePresetText = ""
                                isShowingPresetEditor = true
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus")
                                    Text("New")
                                }
                                .font(.caption.weight(.medium))
                                .foregroundColor(theme.primary)
                            }
                            .buttonStyle(.plain)
                        }
                        
                        Text("Quick-apply saved text snippets to any prompt.")
                            .font(.caption)
                            .foregroundColor(theme.textSecondary)
                        
                        presetsList
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: theme.cornerRadiusMedium)
                        .fill(theme.backgroundSecondary)
                )
            }
        }
    }

    // MARK: - Presets List

    private var presetsList: some View {
        let theme = themeManager.resolved
        let sectionPresets = presetStore.presets(of: selectedSection)
        
        return VStack(alignment: .leading, spacing: 8) {
            if sectionPresets.isEmpty && selectedPresetId == nil {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "star")
                            .font(.title2)
                            .foregroundColor(theme.textSecondary.opacity(0.5))
                        Text("No presets yet")
                            .font(.caption)
                            .foregroundColor(theme.textSecondary)
                    }
                    .padding(.vertical, 16)
                    Spacer()
                }
            } else {
                // Existing presets
                ForEach(sectionPresets) { preset in
                    HStack {
                        Button {
                            loadPreset(preset)
                        } label: {
                            HStack {
                                Image(systemName: preset.id == selectedPresetId ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(preset.id == selectedPresetId ? theme.primary : theme.textSecondary)
                                Text(preset.name)
                                    .font(.subheadline)
                                    .foregroundColor(theme.textPrimary)
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)
                        
                        // Apply to default button
                        Button {
                            applyPresetToGlobalDefault(preset)
                        } label: {
                            Text("Use as Default")
                                .font(.caption2)
                                .foregroundColor(theme.primary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .stroke(theme.primary.opacity(0.5), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                        
                        // Delete button
                        Button {
                            presetToDelete = preset
                            showingDeletePresetConfirmation = true
                        } label: {
                            Image(systemName: "trash")
                                .font(.caption)
                                .foregroundColor(theme.error)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(
                        RoundedRectangle(cornerRadius: theme.cornerRadiusSmall)
                            .fill(preset.id == selectedPresetId ? theme.primary.opacity(0.08) : theme.backgroundTertiary)
                    )
                }
            }
            
            // Preset editor (visible when isShowingPresetEditor is true)
            if isShowingPresetEditor {
                VStack(alignment: .leading, spacing: 8) {
                    ThemedDivider()
                    
                    HStack {
                        Text(selectedPresetId == nil ? "New Preset" : "Edit Preset")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(theme.textSecondary)
                        
                        Spacer()
                        
                        Button {
                            isShowingPresetEditor = false
                            startNewPreset()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(theme.textSecondary)
                        }
                        .buttonStyle(.plain)
                    }

                    ThemedTextField(placeholder: "Preset name", text: $editablePresetName)

                    DynamicGrowingTextEditor(
                        text: $editablePresetText,
                        placeholder: "Preset text...",
                        minLines: 1,
                        maxLines: 6
                    )

                    HStack {
                        ThemedButton("Save Preset", icon: "checkmark.circle.fill", style: .primary) {
                            savePreset()
                            isShowingPresetEditor = false
                        }

                        ThemedButton("Cancel", icon: "xmark", style: .secondary) {
                            isShowingPresetEditor = false
                            startNewPreset()
                        }

                        Spacer()
                    }
                    .font(.subheadline)
                }
                .padding(.top, 8)
            }
        }
    }

    // MARK: - Helpers

    private func defaultBinding(for kind: PromptSectionKind) -> Binding<String> {
        let key = kind.defaultKey
        return Binding(
            get: {
                presetStore.globalDefaults[key] ?? ""
            },
            set: { newValue in
                presetStore.globalDefaults[key] = newValue
            }
        )
    }

    private func startNewPreset() {
        selectedPresetId = nil
        editablePresetName = ""
        editablePresetText = ""
    }

    private func loadPreset(_ preset: PromptPreset) {
        selectedPresetId = preset.id
        editablePresetName = preset.name
        editablePresetText = preset.text
        isShowingPresetEditor = true
    }

    private func savePreset() {
        let trimmedName = editablePresetName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedText = editablePresetText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, !trimmedText.isEmpty else { return }

        if let id = selectedPresetId,
           let index = presetStore.presets.firstIndex(where: { $0.id == id }) {
            presetStore.presets[index].name = trimmedName
            presetStore.presets[index].text = trimmedText
        } else {
            presetStore.addPreset(
                kind: selectedSection,
                name: trimmedName,
                text: trimmedText
            )
        }

        startNewPreset()
    }

    private func applyPresetToGlobalDefault(_ preset: PromptPreset) {
        let keyKind = selectedSection.defaultKey
        presetStore.globalDefaults[keyKind] = preset.text
    }

    private func deletePreset(_ preset: PromptPreset) {
        if let index = presetStore.presets.firstIndex(where: { $0.id == preset.id }) {
            presetStore.presets.remove(at: index)
            if selectedPresetId == preset.id {
                startNewPreset()
            }
        }
    }
}
