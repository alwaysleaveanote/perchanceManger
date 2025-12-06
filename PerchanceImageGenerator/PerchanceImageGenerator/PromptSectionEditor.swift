import SwiftUI

struct PromptSectionEditor: View {
    @EnvironmentObject var presetStore: PromptPresetStore

    let label: String
    let kind: PromptSectionKind
    @Binding var text: String
    @Binding var presetName: String?

    @State private var showPresetNameAlert = false
    @State private var newPresetName: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .bold()
                Spacer()
                Menu("Presets") {
                    let presets = presetStore.presets(of: kind)
                    if presets.isEmpty {
                        Text("No presets yet")
                    } else {
                        ForEach(presets) { preset in
                            Button(preset.name) {
                                text = preset.text
                                presetName = preset.name
                            }
                        }
                    }

                    Divider()

                    Button("Save current as preset…") {
                        let base = text.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !base.isEmpty else { return }
                        newPresetName = label
                        showPresetNameAlert = true
                    }
                }
            }

            if let name = presetName {
                Text("Using preset: \(name)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            DynamicGrowingTextEditor(
                text: $text,
                placeholder: "Enter \(label.lowercased())",
                minLines: 0,
                maxLines: 10
            )
            .onChange(of: text) { newValue in
                let presets = presetStore.presets(of: kind)
                let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)

                // If text exactly matches the current preset, keep it.
                if let currentName = presetName,
                   let currentPreset = presets.first(where: { $0.name == currentName }),
                   currentPreset.text.trimmingCharacters(in: .whitespacesAndNewlines) == trimmed {
                    return
                }

                // If text matches some other preset by text, set that preset.
                if let other = presets.first(where: {
                    $0.text.trimmingCharacters(in: .whitespacesAndNewlines) == trimmed
                }) {
                    presetName = other.name
                } else {
                    // No preset matches this text anymore → user has customized it.
                    if presetName != nil {
                        presetName = nil
                    }
                }
            }
        }
        .alert("Preset name", isPresented: $showPresetNameAlert) {
            DynamicGrowingTextEditor(
                text: $newPresetName,
                placeholder: "Name",
                minLines: 0,
                maxLines: 10
            )

            Button("Save") {
                let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return }
                let nameTrimmed = newPresetName.trimmingCharacters(in: .whitespacesAndNewlines)
                let finalName = nameTrimmed.isEmpty ? label : nameTrimmed
                presetStore.addPreset(kind: kind, name: finalName, text: trimmed)
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Save the current \(label.lowercased()) as a reusable preset.")
        }
    }
}
