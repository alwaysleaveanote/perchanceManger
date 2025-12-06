import SwiftUI

struct GlobalSettingsView: View {
    @EnvironmentObject var presetStore: PromptPresetStore

    @State private var selectedSection: PromptSectionKind = .outfit

    // Preset editor state
    @State private var selectedPresetId: UUID? = nil
    @State private var editablePresetName: String = ""
    @State private var editablePresetText: String = ""

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    Text("Global Defaults & Saved Presets")
                        .font(.title3)
                        .bold()

                    // Section dropdown
                    sectionPicker

                    // Global default editor
                    globalDefaultSection

                    Divider()
                        .padding(.vertical, 8)

                    // Presets
                    presetsSection

                    Spacer(minLength: 0)
                }
                .padding()
            }
            .dismissKeyboardOnDrag()
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        KeyboardHelper.dismiss()
                    }
                }
            }

            

        }
        .onChange(of: selectedSection) { _ in
            startNewPreset()
        }
    }

    // MARK: - Section dropdown

    private var sectionPicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Section")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Menu {
                ForEach(PromptSectionKind.allCases, id: \.self) { kind in
                    Button(label(for: kind)) {
                        selectedSection = kind
                    }
                }
            } label: {
                HStack {
                    Text(label(for: selectedSection))
                        .font(.body)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.secondarySystemBackground))
                )
            }
        }
    }

    // MARK: - Global default editor

    private var globalDefaultSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Global default for \(label(for: selectedSection))")
                    .font(.headline)

                Spacer()

                let sectionPresets = presetStore.presets(of: selectedSection)

                if !sectionPresets.isEmpty {
                    Menu {
                        ForEach(sectionPresets) { preset in
                            Button(preset.name) {
                                applyPresetToGlobalDefault(preset)
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "text.badge.plus")
                            Text("Apply preset")
                        }
                        .font(.caption)
                    }
                }
            }

            DynamicGrowingTextEditor(
                text: defaultBinding(for: selectedSection),
                placeholder: "Default text for all prompts in this section (optional)",
                minLines: 0,
                maxLines: 10
            )

            Text("If set, this will be used whenever a prompt leaves this section empty.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Presets section

    private var presetsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Saved presets for \(label(for: selectedSection))")
                    .font(.headline)
                Spacer()
                Button {
                    startNewPreset()
                } label: {
                    Label("New", systemImage: "plus")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.plain)
            }

            let sectionPresets = presetStore.presets(of: selectedSection)

            if sectionPresets.isEmpty {
                Text("No presets yet. Tap + to create one.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                // List of presets
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(sectionPresets) { preset in
                        Button {
                            loadPreset(preset)
                        } label: {
                            HStack {
                                Text(preset.name)
                                    .font(.subheadline)
                                    .foregroundColor(
                                        preset.id == selectedPresetId ? .accentColor : .primary
                                    )
                                Spacer()
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(
                                        preset.id == selectedPresetId
                                        ? Color.accentColor.opacity(0.08)
                                        : Color.clear
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(role: .destructive) {
                                deletePreset(preset)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }

            // Editor for currently selected / new preset
            VStack(alignment: .leading, spacing: 8) {
                Text(selectedPresetId == nil ? "New Preset" : "Edit Preset")
                    .font(.headline)

                DynamicGrowingTextEditor(
                    text: $editablePresetName,
                    placeholder: "Preset name",
                    minLines: 0,
                    maxLines: 2
                )
                .textFieldStyle(.roundedBorder)

                DynamicGrowingTextEditor(
                    text: $editablePresetText,
                    placeholder: "Preset text",
                    minLines: 0,
                    maxLines: 10
                )

                HStack {
                    Button("Save") {
                        savePreset()
                    }
                    .buttonStyle(.borderedProminent)

                    if selectedPresetId != nil {
                        Button("Delete", role: .destructive) {
                            if let id = selectedPresetId,
                               let preset = presetStore.presets.first(where: { $0.id == id }) {
                                deletePreset(preset)
                            }
                        }
                        .buttonStyle(.bordered)
                    }

                    Button("Clear") {
                        startNewPreset()
                    }
                    .buttonStyle(.bordered)

                    Spacer()
                }
                .font(.subheadline)
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Helpers

    private func label(for kind: PromptSectionKind) -> String {
        switch kind {
        case .outfit: return "Outfit"
        case .pose: return "Pose"
        case .environment: return "Environment"
        case .lighting: return "Lighting"
        case .style: return "Style Modifiers"
        case .technical: return "Technical Modifiers"
        case .negative: return "Negative Prompt"
        }
    }

    private func defaultKey(for kind: PromptSectionKind) -> GlobalDefaultKey {
        switch kind {
        case .outfit: return .outfit
        case .pose: return .pose
        case .environment: return .environment
        case .lighting: return .lighting
        case .style: return .style
        case .technical: return .technical
        case .negative: return .negative
        }
    }

    private func defaultBinding(for kind: PromptSectionKind) -> Binding<String> {
        let key = defaultKey(for: kind)
        return Binding<String>(
            get: {
                presetStore.globalDefaults[key] ?? ""
            },
            set: { newValue in
                let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty {
                    presetStore.globalDefaults.removeValue(forKey: key)
                } else {
                    presetStore.globalDefaults[key] = trimmed
                }
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
    }

    private func savePreset() {
        let trimmedText = editablePresetText.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedName = editablePresetName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedText.isEmpty else { return }

        let nameToUse = trimmedName.isEmpty ? label(for: selectedSection) : trimmedName

        if let id = selectedPresetId,
           let index = presetStore.presets.firstIndex(where: { $0.id == id }) {
            // Update existing
            presetStore.presets[index].name = nameToUse
            presetStore.presets[index].text = trimmedText
        } else {
            // Add new
            presetStore.addPreset(
                kind: selectedSection,
                name: nameToUse,
                text: trimmedText
            )

            // Try to reselect the new one
            if let newPreset = presetStore.presets.last(where: {
                $0.kind == selectedSection && $0.name == nameToUse && $0.text == trimmedText
            }) {
                selectedPresetId = newPreset.id
            }
        }
    }
    
    private func applyPresetToGlobalDefault(_ preset: PromptPreset) {
        // We only ever offer presets that match selectedSection,
        // but this keeps it robust if that changes later.
        let keyKind = preset.kind
        var binding = defaultBinding(for: keyKind)
        binding.wrappedValue = preset.text
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
