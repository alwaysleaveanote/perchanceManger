//
//  PromptSectionRow.swift
//  PerchanceImageGenerator
//
//  A reusable row component for editing individual prompt sections with preset support.
//

import SwiftUI

// MARK: - PromptSectionRow

/// A reusable row for editing a single prompt section with preset support.
///
/// Provides a text editor for the section content along with:
/// - A menu to apply saved presets
/// - Automatic detection of when text matches a preset
/// - Option to save current text as a new preset
///
/// ## Preset Detection
/// The row automatically detects when the entered text exactly matches
/// a saved preset and displays the preset name. When text is modified
/// to no longer match, the preset indicator is cleared.
///
/// ## Usage
/// ```swift
/// PromptSectionRow(
///     label: "Outfit",
///     kind: .outfit,
///     text: $outfitText,
///     presetName: $outfitPresetName,
///     onSaveAsPreset: { text, kind, label in
///         showSavePresetDialog(text: text, kind: kind)
///     }
/// )
/// ```
struct PromptSectionRow: View {
    
    // MARK: - Properties
    
    /// Display label for the section
    let label: String
    
    /// The type of prompt section this row represents
    let kind: PromptSectionKind
    
    /// Binding to the section's text content
    @Binding var text: String
    
    /// Binding to the name of the currently applied preset (nil if none)
    @Binding var presetName: String?
    
    /// Callback when user wants to save current text as a preset
    /// Parameters: (text, kind, label)
    var onSaveAsPreset: ((String, PromptSectionKind, String) -> Void)?
    
    // MARK: - Environment
    
    @EnvironmentObject var presetStore: PromptPresetStore
    
    // MARK: - Computed Properties
    
    /// Available presets for this section type
    private var availablePresets: [PromptPreset] {
        presetStore.presets(of: kind)
    }
    
    /// Whether the current text is non-empty (trimmed)
    private var hasContent: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            headerRow
            textEditor
        }
    }
    
    // MARK: - Subviews
    
    /// Header row with label, preset menu, and status
    private var headerRow: some View {
        HStack(spacing: 8) {
            // Section label
            Text(label)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            // Preset menu (if presets exist)
            if !availablePresets.isEmpty {
                presetMenu
            }
            
            // Status indicator or save button
            statusView
            
            Spacer()
        }
    }
    
    /// Menu for applying saved presets
    private var presetMenu: some View {
        Menu {
            ForEach(availablePresets) { preset in
                Button {
                    applyPreset(preset)
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
    
    /// Shows either the current preset name or a save button
    @ViewBuilder
    private var statusView: some View {
        if let name = presetName, !name.isEmpty {
            // Currently using a preset
            Text("(Using: \(name))")
                .font(.caption)
                .foregroundColor(.secondary)
        } else if hasContent {
            // Has content but not a preset - offer to save
            saveAsPresetButton
        }
    }
    
    /// Button to save current text as a new preset
    private var saveAsPresetButton: some View {
        Button {
            Logger.debug("Save as preset tapped for \(kind.displayLabel)", category: .preset)
            onSaveAsPreset?(text, kind, label)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "star.badge.plus")
                Text("Save as preset")
            }
            .font(.caption)
        }
    }
    
    /// Text editor for section content
    private var textEditor: some View {
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
    
    // MARK: - Actions
    
    /// Applies a preset to this section
    private func applyPreset(_ preset: PromptPreset) {
        Logger.debug("Applying preset '\(preset.name)' to \(kind.displayLabel)", category: .preset)
        text = preset.text
        presetName = preset.name
    }
    
    // MARK: - Preset Detection
    
    /// Updates the preset name based on whether current text matches a saved preset
    private func updatePresetNameForCurrentText() {
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
           let currentPreset = availablePresets.first(where: { $0.name == currentName }),
           currentPreset.text.trimmingCharacters(in: .whitespacesAndNewlines) == trimmed {
            return
        }
        
        // Otherwise, see if any preset text matches exactly
        if let match = availablePresets.first(where: {
            $0.text.trimmingCharacters(in: .whitespacesAndNewlines) == trimmed
        }) {
            presetName = match.name
        } else if presetName != nil {
            // Text no longer matches any preset → clear the marker
            presetName = nil
        }
    }
}
