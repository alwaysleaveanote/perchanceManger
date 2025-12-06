import Foundation

/// A character profile containing bio, notes, prompts, and settings
struct CharacterProfile: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var bio: String
    var notes: String
    var prompts: [SavedPrompt]

    // Overview-level info
    var profileImageData: Data? = nil
    var links: [RelatedLink] = []

    // Per-character defaults for each section
    var characterDefaults: [GlobalDefaultKey: String] = [:]

    // Per-character Perchance generator override
    var characterDefaultPerchanceGenerator: String? = nil
    
    // Per-character theme override (nil = use global theme)
    var characterThemeId: String? = nil
}

// MARK: - Sample Data

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
