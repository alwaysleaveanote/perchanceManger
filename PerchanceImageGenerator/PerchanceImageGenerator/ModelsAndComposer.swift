import Foundation
import SwiftUI
import Combine   // ⬅️ add this

// MARK: - Related links attached to a character

struct RelatedLink: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var urlString: String
}

// MARK: - Prompt images

struct PromptImage: Identifiable, Codable, Equatable {
    var id = UUID()
    var data: Data
}

// MARK: - Saved prompt

struct SavedPrompt: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var text: String

    var outfit: String?
    var pose: String?
    var environment: String?
    var lighting: String?
    var styleModifiers: String?
    var technicalModifiers: String?
    var negativePrompt: String?
    var additionalInfo: String?      // ⬅️ NEW

    var outfitPresetName: String?
    var posePresetName: String?
    var environmentPresetName: String?
    var lightingPresetName: String?
    var stylePresetName: String?
    var technicalPresetName: String?
    var negativePresetName: String?

    var images: [PromptImage] = []

    init(
        title: String,
        text: String,
        outfit: String? = nil,
        pose: String? = nil,
        environment: String? = nil,
        lighting: String? = nil,
        styleModifiers: String? = nil,
        technicalModifiers: String? = nil,
        negativePrompt: String? = nil,
        additionalInfo: String? = nil,          // ⬅️ NEW
        outfitPresetName: String? = nil,
        posePresetName: String? = nil,
        environmentPresetName: String? = nil,
        lightingPresetName: String? = nil,
        stylePresetName: String? = nil,
        technicalPresetName: String? = nil,
        negativePresetName: String? = nil,
        images: [PromptImage] = []
    ) {
        self.title = title
        self.text = text
        self.outfit = outfit
        self.pose = pose
        self.environment = environment
        self.lighting = lighting
        self.styleModifiers = styleModifiers
        self.technicalModifiers = technicalModifiers
        self.negativePrompt = negativePrompt
        self.additionalInfo = additionalInfo      // ⬅️ NEW

        self.outfitPresetName = outfitPresetName
        self.posePresetName = posePresetName
        self.environmentPresetName = environmentPresetName
        self.lightingPresetName = lightingPresetName
        self.stylePresetName = stylePresetName
        self.technicalPresetName = technicalPresetName
        self.negativePresetName = negativePresetName
        self.images = images
    }
}

// MARK: - Character profile

struct CharacterProfile: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var bio: String
    var notes: String
    var prompts: [SavedPrompt]

    // New: overview-level info
    var profileImageData: Data? = nil
    var links: [RelatedLink] = []
}

// MARK: - Prompt composition helpers & enums

enum PromptSectionKind: String, CaseIterable, Hashable, Codable {
    case outfit
    case pose
    case environment
    case lighting
    case style
    case technical
    case negative
}

enum GlobalDefaultKey: String, CaseIterable, Hashable, Codable {
    case outfit
    case pose
    case environment
    case lighting
    case style
    case technical
    case negative
}

struct PromptPreset: Identifiable, Codable, Equatable {
    var id = UUID()
    var kind: PromptSectionKind
    var name: String
    var text: String
}

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

    // ⬇️ ADD THIS
    init() {
        print("[PromptPresetStore] init() – in-memory defaultPerchanceGenerator = '\(defaultPerchanceGenerator)'")

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
    // ⬆️ END ADDED INIT

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
}

enum PromptComposer {
    static func composePrompt(
        character: CharacterProfile,
        prompt: SavedPrompt,
        stylePreset: String?,
        globalDefaults: [GlobalDefaultKey: String]
    ) -> String {

        // Helper: Adds a section only if text exists
        func section(_ title: String, _ text: String?) -> String? {
            guard let raw = text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !raw.isEmpty else { return nil }
            return "\(title):\n\(raw)"
        }

        var output: [String] = []

        // Character name
        if !character.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            output.append("Name:\n\(character.name)")
        }

        // Bio
        if !character.bio.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            output.append("Bio:\n\(character.bio)")
        }

        // Outfit
        let outfit = prompt.outfit?.nonEmpty
            ?? globalDefaults[.outfit]?.nonEmpty
        if let block = section("Outfit", outfit) {
            output.append(block)
        }

        // Pose
        let pose = prompt.pose?.nonEmpty
            ?? globalDefaults[.pose]?.nonEmpty
        if let block = section("Pose", pose) {
            output.append(block)
        }

        // Environment
        let environment = prompt.environment?.nonEmpty
            ?? globalDefaults[.environment]?.nonEmpty
        if let block = section("Environment", environment) {
            output.append(block)
        }

        // Lighting
        let lighting = prompt.lighting?.nonEmpty
            ?? globalDefaults[.lighting]?.nonEmpty
        if let block = section("Lighting", lighting) {
            output.append(block)
        }

        // Style
        let style = prompt.styleModifiers?.nonEmpty
            ?? globalDefaults[.style]?.nonEmpty
        if let block = section("Style Modifiers", style) {
            output.append(block)
        }

        // Technical Modifiers
        let tech = prompt.technicalModifiers?.nonEmpty
            ?? globalDefaults[.technical]?.nonEmpty
        if let block = section("Technical Modifiers", tech) {
            output.append(block)
        }

        // Negative Prompt
        let neg = prompt.negativePrompt?.nonEmpty
            ?? globalDefaults[.negative]?.nonEmpty
        if let neg = neg {
            let cleanNeg = neg.lowercased().hasPrefix("negative prompt")
                ? neg
                : "Negative prompt: \(neg)"
            output.append(cleanNeg)
        }

        // Additional Information
        if let block = section("Additional Information", prompt.additionalInfo) {
            output.append(block)
        }

        // Join sections with spacing for readability
        return output.joined(separator: "\n\n")
    }
}

// MARK: - Small helpers

extension String {
    var nonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
extension CharacterProfile {
    static let sampleCharacters: [CharacterProfile] = [
        CharacterProfile(
            name: "Rin",
            bio: "A curious tabaxi who loves tinkering with old tech and exploring frozen ruins.",
            notes: "Main test character. Great for trying cozy vs. dramatic prompts.",
            prompts: [
                SavedPrompt(
                    title: "Hero Shot",
                    text: "Rin hero pose in the snow",
                    outfit: "winter explorer outfit, thick jacket, scarf, utility belt",
                    pose: "standing on a snowy ledge, one hand on hip, confident smile",
                    environment: "snowy tundra, distant mountains, aurora in the sky",
                    lighting: "cool blue ambient light, soft rim light from behind",
                    styleModifiers: "cinematic, detailed fur, slight depth of field",
                    technicalModifiers: "8k, ultra detailed, sharp focus",
                    negativePrompt: "no humans, no city skyline, no text"
                ),
                SavedPrompt(
                    title: "Cozy Cabin Portrait",
                    text: "Rin relaxing in a warm cabin",
                    outfit: "soft sweater, comfy pants, casual looksoft sweater, comfy pants, casual looksoft sweater, comfy pants, casual looksoft sweater, comfy pants, casual looksoft sweater, comfy pants, casual look",
                    pose: "sitting cross-legged on a couch, holding a mug",
                    environment: "cozy wooden cabin, fireplace, bookshelves, warm lighting",
                    lighting: "warm soft lamp light, gentle shadows",
                    styleModifiers: "soft shading, painterly, warm palette",
                    technicalModifiers: "high detail, clean lines",
                    negativePrompt: "no harsh shadows, no clutter on the floor"
                )
            ],
            profileImageData: nil,
            links: [
                RelatedLink(title: "Rin Inspiration Board", urlString: "https://example.com/rin-board")
            ]
        ),
        CharacterProfile(
            name: "Kael the Dragon Scholar",
            bio: "A scholarly dragon obsessed with forbidden tomes and ancient magic.",
            notes: "Use for more dramatic fantasy scenes and complex environments.",
            prompts: [
                SavedPrompt(
                    title: "Library Study Scene",
                    text: "Kael studying in a magical library",
                    outfit: "flowing robe with arcane symbols, golden accents",
                    pose: "leaning over a large book, one claw turning a page",
                    environment: "towering bookshelves, floating candles, magical glyphs in the air",
                    lighting: "dramatic golden light from the side, soft blue ambient glow",
                    styleModifiers: "fantasy painting, rich textures, intricate details",
                    technicalModifiers: "sharp focus on face and hands, slight blur on background",
                    negativePrompt: "no other characters, no modern tech devices"
                )
            ],
            profileImageData: nil,
            links: []
        )
    ]
}
