import Foundation
import SwiftUI
import Combine

/// Observable store for managing presets, global defaults, and generator settings
final class PromptPresetStore: ObservableObject {
    @Published var presets: [PromptPreset] = []
    @Published var globalDefaults: [GlobalDefaultKey: String] = [:]
    @Published var defaultPerchanceGenerator: String =
        UserDefaults.standard.string(forKey: "defaultPerchanceGenerator") ?? "ai-vibrant-image-generator" {
        didSet {
            print("[PromptPresetStore] defaultPerchanceGenerator didSet -> '\(defaultPerchanceGenerator)'")
            UserDefaults.standard.set(defaultPerchanceGenerator, forKey: "defaultPerchanceGenerator")
        }
    }

    init() {
        print("[PromptPresetStore] init() – in-memory defaultPerchanceGenerator = '\(defaultPerchanceGenerator)'")
        loadSampleData()
    }
    
    // MARK: - Preset Access
    
    func presets(of kind: PromptSectionKind) -> [PromptPreset] {
        presets.filter { $0.kind == kind }
    }

    func addPreset(kind: PromptSectionKind, name: String, text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if let index = presets.firstIndex(where: {
            $0.kind == kind && $0.name.caseInsensitiveCompare(name) == .orderedSame
        }) {
            presets[index].text = trimmed
        } else {
            presets.append(PromptPreset(kind: kind, name: name, text: trimmed))
        }
    }
    
    // MARK: - Sample Data
    
    private func loadSampleData() {
        // Sample presets for testing
        presets = [
            // Outfit
            PromptPreset(kind: .outfit, name: "Casual Outfit", text: "hoodie, jeans, sneakers, relaxed casual style"),
            PromptPreset(kind: .outfit, name: "Fantasy Armor", text: "ornate plate armor, engraved runes, flowing cape"),

            // Pose
            PromptPreset(kind: .pose, name: "Hero Pose", text: "standing tall, chest out, confident stance, looking at viewer"),
            PromptPreset(kind: .pose, name: "Relaxed Sitting", text: "sitting cross-legged, relaxed shoulders, soft expression"),

            // Environment
            PromptPreset(kind: .environment, name: "Cozy Room", text: "warm cozy bedroom, soft blankets, fairy lights, bookshelves"),
            PromptPreset(kind: .environment, name: "Sci-Fi Lab", text: "sleek futuristic lab, holographic screens, glowing consoles"),

            // Lighting
            PromptPreset(kind: .lighting, name: "Soft Studio Lighting", text: "soft even studio lighting, gentle shadows, flattering light"),
            PromptPreset(kind: .lighting, name: "Dramatic Rim Light", text: "strong rim light from behind, deep shadows, high contrast"),

            // Style
            PromptPreset(kind: .style, name: "Painterly", text: "digital painting, visible brush strokes, rich colors"),
            PromptPreset(kind: .style, name: "Anime Cel-Shaded", text: "anime style, crisp lineart, cel-shaded coloring"),

            // Technical
            PromptPreset(kind: .technical, name: "High Detail", text: "8k resolution, ultra-detailed, sharp focus"),
            PromptPreset(kind: .technical, name: "Soft Focus Portrait", text: "soft focus background, bokeh, subject in crisp focus"),

            // Negative
            PromptPreset(kind: .negative, name: "Clean Image", text: "no text, no watermark, no extra limbs, no distortions"),
            PromptPreset(kind: .negative, name: "Simple Background", text: "no cluttered background, no busy patterns")
        ]

        // Sample global defaults
        globalDefaults = [
            .outfit: "casual modern outfit, comfortable and practical",
            .pose: "natural relaxed pose",
            .environment: "simple neutral background",
            .lighting: "soft even lighting, no harsh shadows",
            .style: "high quality digital illustration",
            .technical: "high detail, clean lines, sharp focus",
            .negative: "no text, no watermark, no extra limbs, no distortions"
        ]
    }
}
