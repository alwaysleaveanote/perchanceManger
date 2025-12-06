import SwiftUI

struct CharacterSettingsView: View {
    @EnvironmentObject var presetStore: PromptPresetStore
    @EnvironmentObject var themeManager: ThemeManager

    /// Binding to the real character from CharacterDetailView
    @Binding var character: CharacterProfile

    /// Local working copy so edits don't constantly mutate the source driving navigation.
    /// Local working copy for generator and defaults (not theme)
    @State private var workingCharacter: CharacterProfile

    @Environment(\.dismiss) private var dismiss

    // Generator override state
    @State private var useCharacterGenerator: Bool = false
    @State private var generatorSelection: String = ""
    @State private var customGeneratorName: String = ""
    
    // Track the selected theme ID separately to avoid navigation issues
    @State private var selectedThemeId: String?

    // Character defaults section picker
    @State private var selectedDefaultsSection: PromptSectionKind = .physicalDescription

    init(character: Binding<CharacterProfile>) {
        self._character = character
        self._workingCharacter = State(initialValue: character.wrappedValue)
        self._selectedThemeId = State(initialValue: character.wrappedValue.characterThemeId)
    }
    
    /// Computes the preview theme locally without affecting global themeManager.resolved
    /// This prevents re-renders of parent views when selecting a theme
    private var previewTheme: ResolvedTheme {
        if let themeId = selectedThemeId,
           let theme = themeManager.availableThemes.first(where: { $0.id == themeId }) {
            return ResolvedTheme(source: theme)
        }
        // Fall back to global theme
        if let globalTheme = themeManager.availableThemes.first(where: { $0.id == themeManager.globalThemeId }) {
            return ResolvedTheme(source: globalTheme)
        }
        return themeManager.resolved
    }

    var body: some View {
        // Use local preview theme instead of themeManager.resolved
        // This prevents re-renders when selecting a theme
        let theme = previewTheme
        
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
        .navigationTitle("Character Settings")
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
            Logger.debug("CharacterSettingsView appeared for: \(character.name)", category: .character)
            configureInitialGeneratorState()
        }
        .onDisappear {
            Logger.debug("CharacterSettingsView disappearing, saving changes", category: .character)
            // Save ALL changes including theme on dismiss
            character.characterThemeId = selectedThemeId
            character.characterDefaults = workingCharacter.characterDefaults
            character.characterDefaultPerchanceGenerator = workingCharacter.characterDefaultPerchanceGenerator
        }
        // Theme preview updates automatically via previewTheme computed property
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

    // MARK: - Generator Section

    private var generatorSection: some View {
        let theme = previewTheme
        
        return Section(header: Text("Perchance Generator")
            .foregroundColor(theme.textSecondary)
            .fontDesign(theme.fontDesign)
        ) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Generator used when opening prompts for this character.")
                    .font(.caption)
                    .fontDesign(theme.fontDesign)
                    .foregroundColor(theme.textSecondary)

                Toggle(isOn: $useCharacterGenerator) {
                    Text("Use character-specific generator")
                        .fontDesign(theme.fontDesign)
                        .foregroundColor(theme.textPrimary)
                }
                .tint(theme.primary)
                .onChange(of: useCharacterGenerator) { _, newValue in
                    handleUseCharacterGeneratorToggle(newValue)
                }

                if useCharacterGenerator {
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
                        print("[CharacterSettingsView] generatorSelection changed to '\(newValue)'")
                        if useCharacterGenerator {
                            workingCharacter.characterDefaultPerchanceGenerator = newValue
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
                        workingCharacter.characterDefaultPerchanceGenerator = trimmed
                        useCharacterGenerator = true
                        print("[CharacterSettingsView] custom generator set to '\(trimmed)'")
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
        let override = character.characterDefaultPerchanceGenerator
        let global = presetStore.defaultPerchanceGenerator

        print("[CharacterSettingsView] initial override='\(override ?? "nil")', global='\(global)'")

        workingCharacter = character

        if let override = override, !override.isEmpty {
            useCharacterGenerator = true
            generatorSelection = override
            customGeneratorName = override
            workingCharacter.characterDefaultPerchanceGenerator = override
            print("[CharacterSettingsView] using character override: \(override)")
        } else {
            useCharacterGenerator = false
            generatorSelection = global
            customGeneratorName = ""
            workingCharacter.characterDefaultPerchanceGenerator = nil
            print("[CharacterSettingsView] inheriting global: \(global)")
        }
    }

    private func handleUseCharacterGeneratorToggle(_ useOverride: Bool) {
        let global = presetStore.defaultPerchanceGenerator

        if useOverride {
            if generatorSelection.isEmpty {
                generatorSelection = workingCharacter.characterDefaultPerchanceGenerator ?? global
            }
            workingCharacter.characterDefaultPerchanceGenerator = generatorSelection
            print("[CharacterSettingsView] override enabled, selection='\(generatorSelection)'")
        } else {
            workingCharacter.characterDefaultPerchanceGenerator = nil
            generatorSelection = global
            print("[CharacterSettingsView] override disabled, inheriting global='\(global)'")
        }
    }

    // MARK: - Character Defaults Section

    private var defaultsSection: some View {
        let theme = previewTheme
        
        return Section(header: Text("Character Defaults (Overrides Global)")
            .foregroundColor(theme.textSecondary)
            .fontDesign(theme.fontDesign)
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Text("These defaults are used when a prompt leaves a section blank. They override the global defaults, but are still overridden by per-prompt text.")
                    .font(.caption)
                    .fontDesign(theme.fontDesign)
                    .foregroundColor(theme.textSecondary)

                defaultsSectionPicker
                characterDefaultEditor
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

    private var characterDefaultEditor: some View {
        let theme = previewTheme
        let key = selectedDefaultsSection.defaultKey
        let charText = (workingCharacter.characterDefaults[key] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let globalText = (presetStore.globalDefaults[key] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let sectionPresets = presetStore.presets(of: selectedDefaultsSection)

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Character default for \(selectedDefaultsSection.displayLabel)")
                    .font(.headline)
                    .fontDesign(theme.fontDesign)
                    .foregroundColor(theme.textPrimary)

                Spacer()

                if !sectionPresets.isEmpty {
                    Menu {
                        ForEach(sectionPresets) { preset in
                            Button(preset.name) {
                                applyPresetToCharacterDefault(preset, for: selectedDefaultsSection)
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

            if charText.isEmpty {
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
                    Text("No character default set (and global default is also empty).")
                        .font(.caption)
                        .fontDesign(theme.fontDesign)
                        .foregroundColor(theme.textSecondary)
                }
            } else {
                Text("Character override is active and replaces the global default.")
                    .font(.caption)
                    .fontDesign(theme.fontDesign)
                    .foregroundColor(theme.textSecondary)
            }

            DynamicGrowingTextEditor(
                text: characterDefaultBinding(for: selectedDefaultsSection),
                placeholder: "Default text for this character's \(selectedDefaultsSection.displayLabel.lowercased()) (optional)",
                minLines: 2,
                maxLines: 10
            )
        }
    }

    // MARK: - Helpers

    private func applyPresetToCharacterDefault(_ preset: PromptPreset, for kind: PromptSectionKind) {
        let key = kind.defaultKey
        workingCharacter.characterDefaults[key] = preset.text
        print("[CharacterSettingsView] applied preset '\(preset.name)' to character default \(key)")
    }

    private func characterDefaultBinding(for kind: PromptSectionKind) -> Binding<String> {
        let key = kind.defaultKey
        return Binding(
            get: {
                workingCharacter.characterDefaults[key] ?? ""
            },
            set: { newValue in
                workingCharacter.characterDefaults[key] = newValue
            }
        )
    }

    // MARK: - Theme Section

    private var themeSection: some View {
        let theme = previewTheme
        
        return Section(header: Text("Character Theme")
            .foregroundColor(theme.textSecondary)
            .fontDesign(theme.fontDesign)
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Override the global theme for this character. This theme will be applied when viewing this character's pages.")
                    .font(.caption)
                    .fontDesign(theme.fontDesign)
                    .foregroundColor(theme.textSecondary)

                ThemePicker(
                    title: "Character Theme",
                    selectedThemeId: selectedThemeId,
                    showInheritOption: true,
                    onSelect: { themeId in
                        // Update local state only - don't touch workingCharacter here
                        selectedThemeId = themeId
                    }
                )
            }
            .padding(.vertical, 4)
        }
    }
}
