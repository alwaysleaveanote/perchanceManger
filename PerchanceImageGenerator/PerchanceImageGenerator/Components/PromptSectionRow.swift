import SwiftUI

/// A reusable row for editing a prompt section with preset support
struct PromptSectionRow: View {
    let label: String
    let kind: PromptSectionKind
    @Binding var text: String
    @Binding var presetName: String?
    
    @EnvironmentObject var presetStore: PromptPresetStore
    
    /// Callback when user wants to save current text as a preset
    var onSaveAsPreset: ((String, PromptSectionKind, String) -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                let presets = presetStore.presets(of: kind)
                let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

                // Apply menu for known presets
                if !presets.isEmpty {
                    Menu {
                        ForEach(presets) { preset in
                            Button {
                                text = preset.text
                                presetName = preset.name
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

                // Show either "Using: <preset>" or "Save as preset" button
                if let name = presetName, !name.isEmpty {
                    Text("(Using: \(name))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if !trimmed.isEmpty {
                    Button {
                        onSaveAsPreset?(text, kind, label)
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
                text: $text,
                placeholder: "Optional \(label.lowercased()) details",
                minLines: 0,
                maxLines: 5
            )
            .onAppear {
                updatePresetNameForCurrentText()
            }
            .onChange(of: text) { _, _ in
                updatePresetNameForCurrentText()
            }
        }
    }
    
    // MARK: - Preset Detection
    
    private func updatePresetNameForCurrentText() {
        let presets = presetStore.presets(of: kind)
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // If text is empty, clear any preset info
        guard !trimmed.isEmpty else {
            if presetName != nil {
                presetName = nil
            }
            return
        }

        // If we already have a presetName and it still matches exactly, keep it
        if let currentName = presetName,
           let currentPreset = presets.first(where: { $0.name == currentName }),
           currentPreset.text.trimmingCharacters(in: .whitespacesAndNewlines) == trimmed {
            return
        }

        // Otherwise, see if any preset text matches exactly
        if let match = presets.first(where: {
            $0.text.trimmingCharacters(in: .whitespacesAndNewlines) == trimmed
        }) {
            presetName = match.name
        } else if presetName != nil {
            // Text no longer matches any preset → clear the marker
            presetName = nil
        }
    }
}
