import SwiftUI

struct GlobalSettingsView: View {
    @EnvironmentObject var presetStore: PromptPresetStore
    @EnvironmentObject var themeManager: ThemeManager
    
    /// Central data store for offline storage management
    @ObservedObject private var dataStore = DataStore.shared

    @State private var selectedSection: PromptSectionKind = .physicalDescription
    @State private var customGeneratorName: String = ""

    // Collapse state for sections - use @AppStorage to persist across theme changes
    @AppStorage("globalSettings_isThemeExpanded") private var isThemeExpanded: Bool = false
    @AppStorage("globalSettings_isGeneratorExpanded") private var isGeneratorExpanded: Bool = false
    @AppStorage("globalSettings_isGlobalDefaultsExpanded") private var isGlobalDefaultsExpanded: Bool = false
    @AppStorage("globalSettings_isOfflineStorageExpanded") private var isOfflineStorageExpanded: Bool = false

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
    
    // Offline storage confirmation
    @State private var showingDisableOfflineStorageConfirmation = false

    private var selectedGeneratorOption: PerchanceGeneratorOption? {
        perchanceGenerators.first(where: { $0.name == presetStore.defaultPerchanceGenerator }) ?? perchanceGenerators.first
    }

    var body: some View {
        let theme = themeManager.resolved
        let globalTheme = themeManager.availableThemes.first(where: { $0.id == themeManager.globalThemeId }) ?? themeManager.currentTheme
        
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    themeSection
                    ThemedDivider().padding(.vertical, 8)
                    generatorSection
                    ThemedDivider().padding(.vertical, 8)
                    globalDefaultsSection
                    ThemedDivider().padding(.vertical, 8)
                    offlineStorageSection
                    Spacer(minLength: 0)
                }
                .padding()
            }
            .themedBackground()
            .dismissKeyboardOnDrag()
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(isLightTheme(globalTheme) ? .light : .dark, for: .navigationBar)
            .toolbarBackground(theme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .tint(theme.primary)
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
        .onChange(of: selectedSection) { _, _ in
            startNewPreset()
        }
        .onChange(of: themeManager.globalThemeId) { oldValue, newValue in
            print("[GlobalSettingsView] globalThemeId changed: \(oldValue) -> \(newValue)")
            // Force navigation bar appearance update via UIKit
            updateNavigationBarAppearance()
        }
        .onAppear {
            updateNavigationBarAppearance()
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
        .alert("Disable Offline Access?", isPresented: $showingDisableOfflineStorageConfirmation) {
            Button("Disable", role: .destructive) {
                dataStore.disableOfflineStorage()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Your data will remain safely stored in iCloud, but will no longer be available when you're offline. You can re-enable this anytime to download your data again.")
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
    
    // MARK: - Offline Storage Section
    
    private var offlineStorageSection: some View {
        let theme = themeManager.resolved
        
        return VStack(alignment: .leading, spacing: 8) {
            Button(action: {
                withAnimation {
                    isOfflineStorageExpanded.toggle()
                }
            }) {
                HStack {
                    Text("Offline Access")
                        .font(.title3)
                        .bold()
                        .fontDesign(theme.fontDesign)
                        .foregroundColor(theme.textPrimary)

                    Spacer()

                    Image(systemName: isOfflineStorageExpanded ? "chevron.down" : "chevron.right")
                        .font(.subheadline)
                        .foregroundColor(theme.textSecondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isOfflineStorageExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Keep a copy of your characters, prompts, and images stored on this device. This allows you to view and use your data even without an internet connection.")
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                    
                    // Toggle row
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Store Data Locally")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(theme.textPrimary)
                            
                            Text(dataStore.isOfflineStorageEnabled 
                                 ? "Your data is available offline" 
                                 : "Data requires internet connection")
                                .font(.caption)
                                .foregroundColor(theme.textSecondary)
                        }
                        
                        Spacer()
                        
                        if dataStore.isModifyingOfflineStorage {
                            ProgressView()
                                .tint(theme.primary)
                        } else {
                            Toggle("", isOn: Binding(
                                get: { dataStore.isOfflineStorageEnabled },
                                set: { newValue in
                                    if newValue {
                                        // Enable - download data
                                        Task {
                                            await dataStore.enableOfflineStorage()
                                        }
                                    } else {
                                        // Disable - show confirmation first
                                        showingDisableOfflineStorageConfirmation = true
                                    }
                                }
                            ))
                            .labelsHidden()
                            .tint(theme.primary)
                        }
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: theme.cornerRadiusSmall)
                            .fill(theme.backgroundTertiary)
                    )
                    
                    // Info box
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "icloud.fill")
                            .foregroundColor(theme.primary)
                            .font(.subheadline)
                        
                        Text("Your data is always securely stored in iCloud. Offline access creates an additional local copy on this device.")
                            .font(.caption)
                            .foregroundColor(theme.textSecondary)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: theme.cornerRadiusSmall)
                            .fill(theme.primary.opacity(0.1))
                    )
                    
                    // Storage usage section
                    storageUsageView
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: theme.cornerRadiusMedium)
                        .fill(theme.backgroundSecondary)
                )
            }
        }
    }
    
    // MARK: - Storage Usage View
    
    private var storageUsageView: some View {
        let theme = themeManager.resolved
        let stats = dataStore.calculateStorageStats()
        
        return VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "internaldrive.fill")
                    .foregroundColor(theme.primary)
                    .font(.subheadline)
                Text("Storage Usage")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(theme.textPrimary)
            }
            
            // Data summary cards
            HStack(spacing: 12) {
                // Characters card
                storageStatCard(
                    icon: "person.3.fill",
                    count: stats.characterCount,
                    label: "Characters",
                    theme: theme
                )
                
                // Prompts card
                storageStatCard(
                    icon: "doc.text.fill",
                    count: stats.promptCount,
                    label: "Prompts",
                    theme: theme
                )
                
                // Images card
                storageStatCard(
                    icon: "photo.fill",
                    count: stats.imageCount,
                    label: "Images",
                    theme: theme
                )
            }
            
            // Storage breakdown
            VStack(spacing: 8) {
                // Total storage bar
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Local Storage")
                            .font(.caption.weight(.medium))
                            .foregroundColor(theme.textPrimary)
                        Spacer()
                        Text(stats.formattedTotalSize)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(theme.primary)
                    }
                    
                    // Visual bar showing breakdown
                    GeometryReader { geometry in
                        let totalWidth = geometry.size.width
                        let total = max(stats.totalLocalSize, 1) // Avoid division by zero
                        let charWidth = CGFloat(stats.charactersSize) / CGFloat(total) * totalWidth
                        let presetWidth = CGFloat(stats.presetsSize) / CGFloat(total) * totalWidth
                        
                        HStack(spacing: 2) {
                            // Characters portion (includes images)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(theme.primary)
                                .frame(width: max(charWidth, stats.charactersSize > 0 ? 4 : 0))
                            
                            // Presets portion
                            RoundedRectangle(cornerRadius: 3)
                                .fill(theme.primary.opacity(0.6))
                                .frame(width: max(presetWidth, stats.presetsSize > 0 ? 4 : 0))
                            
                            // Settings portion (remaining)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(theme.primary.opacity(0.3))
                        }
                    }
                    .frame(height: 8)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(theme.backgroundTertiary)
                    )
                }
                
                // Legend
                HStack(spacing: 16) {
                    storageLegendItem(
                        color: theme.primary,
                        label: "Characters & Images",
                        size: stats.formattedCharactersSize,
                        theme: theme
                    )
                    storageLegendItem(
                        color: theme.primary.opacity(0.6),
                        label: "Presets",
                        size: stats.formattedPresetsSize,
                        theme: theme
                    )
                }
                .font(.caption2)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: theme.cornerRadiusSmall)
                    .fill(theme.backgroundTertiary)
            )
        }
        .padding(.top, 8)
    }
    
    private func storageStatCard(icon: String, count: Int, label: String, theme: ResolvedTheme) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(theme.primary)
            
            Text("\(count)")
                .font(.title2.weight(.bold))
                .foregroundColor(theme.textPrimary)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: theme.cornerRadiusSmall)
                .fill(theme.backgroundTertiary)
        )
    }
    
    private func storageLegendItem(color: Color, label: String, size: String, theme: ResolvedTheme) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .foregroundColor(theme.textSecondary)
            Text("(\(size))")
                .foregroundColor(theme.textSecondary.opacity(0.7))
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
    
    /// Determines if a theme has a light background
    private func isLightTheme(_ theme: AppTheme) -> Bool {
        let hex = theme.colors.background.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255.0
        let g = Double((int >> 8) & 0xFF) / 255.0
        let b = Double(int & 0xFF) / 255.0
        let luminance = 0.299 * r + 0.587 * g + 0.114 * b
        return luminance > 0.5
    }
    
    /// Updates the navigation bar appearance via UIKit to ensure title is visible
    private func updateNavigationBarAppearance() {
        let globalTheme = themeManager.availableThemes.first(where: { $0.id == themeManager.globalThemeId }) ?? themeManager.currentTheme
        let theme = ResolvedTheme(source: globalTheme)
        
        print("[GlobalSettingsView] updateNavigationBarAppearance - theme: \(globalTheme.id)")
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(theme.background)
        
        // Get the appropriate font for the theme
        let titleFont: UIFont
        switch globalTheme.typography.fontFamily {
        case "serif":
            titleFont = UIFont(descriptor: UIFontDescriptor.preferredFontDescriptor(withTextStyle: .headline).withDesign(.serif)!, size: 18)
        case "rounded":
            titleFont = UIFont(descriptor: UIFontDescriptor.preferredFontDescriptor(withTextStyle: .headline).withDesign(.rounded)!, size: 18)
        case "monospaced":
            titleFont = UIFont(descriptor: UIFontDescriptor.preferredFontDescriptor(withTextStyle: .headline).withDesign(.monospaced)!, size: 18)
        default:
            titleFont = UIFont(descriptor: UIFontDescriptor.preferredFontDescriptor(withTextStyle: .headline).withDesign(.default)!, size: 18)
        }
        
        // Title text attributes
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor(theme.primary),
            .font: titleFont
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(theme.primary),
            .font: UIFont(descriptor: titleFont.fontDescriptor, size: 34)
        ]
        
        // Button appearance
        let buttonAppearance = UIBarButtonItemAppearance()
        buttonAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(theme.primary)
        ]
        appearance.buttonAppearance = buttonAppearance
        appearance.doneButtonAppearance = buttonAppearance
        
        // Apply globally
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
        // Force existing navigation bars to update immediately
        DispatchQueue.main.async {
            for window in UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).flatMap({ $0.windows }) {
                for navBar in window.subviews(ofType: UINavigationBar.self) {
                    navBar.standardAppearance = appearance
                    navBar.compactAppearance = appearance
                    navBar.scrollEdgeAppearance = appearance
                    navBar.setNeedsLayout()
                    navBar.layoutIfNeeded()
                }
            }
        }
    }
}
