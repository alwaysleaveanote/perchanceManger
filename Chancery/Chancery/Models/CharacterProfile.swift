//
//  CharacterProfile.swift
//  Chancery
//
//  Represents a complete character profile with biographical information,
//  saved prompts, customization settings, and associated media.
//

import Foundation

// MARK: - CharacterProfile

/// A complete character profile for organizing prompts and settings around a specific character.
///
/// `CharacterProfile` serves as the primary organizational unit in the app, containing:
/// - **Identity**: Name and biographical information
/// - **Prompts**: Saved prompt configurations for this character
/// - **Customization**: Per-character defaults and theme overrides
/// - **Media**: Profile image and related links
///
/// ## Character-Specific Overrides
/// Characters can override global settings:
/// - `characterDefaults`: Override global prompt section defaults
/// - `characterDefaultPerchanceGenerator`: Override the default generator
/// - `characterThemeId`: Override the global theme
///
/// ## Usage
/// ```swift
/// var character = CharacterProfile(
///     name: "Rin",
///     bio: "A curious explorer",
///     notes: "Use for adventure scenes"
/// )
/// character.prompts.append(newPrompt)
/// ```
struct CharacterProfile: Identifiable, Codable, Equatable {
    
    // MARK: - Identity
    
    /// Unique identifier for this character
    let id: UUID
    
    /// The character's display name
    var name: String
    
    /// A brief description or biography of the character
    var bio: String
    
    /// Private notes about the character (not included in prompts)
    var notes: String
    
    // MARK: - Prompts
    
    /// Collection of saved prompts associated with this character
    var prompts: [SavedPrompt]
    
    // MARK: - Media
    
    /// Profile image data (PNG/JPEG encoded)
    var profileImageData: Data?
    
    /// Related links (reference images, inspiration boards, etc.)
    var links: [RelatedLink]
    
    // MARK: - Customization
    
    /// Per-character default values for prompt sections
    ///
    /// These override the global defaults when editing prompts for this character.
    var characterDefaults: [GlobalDefaultKey: String]
    
    /// Per-character Perchance generator override
    ///
    /// When set, this generator is used instead of the global default
    /// when opening the generator from this character's prompts.
    var characterDefaultPerchanceGenerator: String?
    
    /// Per-character theme override
    ///
    /// When set, this theme is applied when viewing this character's details.
    /// When `nil`, the global theme is used.
    var characterThemeId: String?
    
    // MARK: - Initialization
    
    /// Creates a new character profile
    /// - Parameters:
    ///   - id: Unique identifier (defaults to new UUID)
    ///   - name: Character's display name
    ///   - bio: Brief description
    ///   - notes: Private notes
    ///   - prompts: Initial prompts (defaults to empty)
    ///   - profileImageData: Profile image data
    ///   - links: Related links
    ///   - characterDefaults: Per-character defaults
    ///   - characterDefaultPerchanceGenerator: Generator override
    ///   - characterThemeId: Theme override
    init(
        id: UUID = UUID(),
        name: String,
        bio: String = "",
        notes: String = "",
        prompts: [SavedPrompt] = [],
        profileImageData: Data? = nil,
        links: [RelatedLink] = [],
        characterDefaults: [GlobalDefaultKey: String] = [:],
        characterDefaultPerchanceGenerator: String? = nil,
        characterThemeId: String? = nil
    ) {
        self.id = id
        self.name = name
        self.bio = bio
        self.notes = notes
        self.prompts = prompts
        self.profileImageData = profileImageData
        self.links = links
        self.characterDefaults = characterDefaults
        self.characterDefaultPerchanceGenerator = characterDefaultPerchanceGenerator
        self.characterThemeId = characterThemeId
    }
}

// MARK: - Computed Properties

extension CharacterProfile {
    
    /// Whether this character has a profile image set
    var hasProfileImage: Bool {
        profileImageData != nil
    }
    
    /// The total number of prompts for this character
    var promptCount: Int {
        prompts.count
    }
    
    /// The total number of images across all prompts
    var totalImageCount: Int {
        prompts.reduce(0) { $0 + $1.imageCount }
    }
    
    /// Whether this character has any custom defaults set
    var hasCustomDefaults: Bool {
        !characterDefaults.isEmpty
    }
    
    /// Whether this character uses a custom theme
    var hasCustomTheme: Bool {
        characterThemeId != nil
    }
    
    /// Whether this character uses a custom generator
    var hasCustomGenerator: Bool {
        characterDefaultPerchanceGenerator != nil
    }
}

// MARK: - Default Access

extension CharacterProfile {
    
    /// Gets the effective default value for a section, checking character defaults first
    /// - Parameters:
    ///   - key: The default key to look up
    ///   - globalDefaults: The global defaults to fall back to
    /// - Returns: The character default if set, otherwise the global default
    func effectiveDefault(
        for key: GlobalDefaultKey,
        globalDefaults: [GlobalDefaultKey: String]
    ) -> String? {
        characterDefaults[key] ?? globalDefaults[key]
    }
}

// MARK: - Sample Data

extension CharacterProfile {
    
    /// Default starter character for new users
    static let starterCharacter: CharacterProfile = CharacterProfile(
        name: "Luna",
        bio: "A cheerful adventurer with silver hair and bright amber eyes. She's always ready for the next journey, whether it's exploring ancient ruins or relaxing at a cozy tavern.",
        notes: "This is your starter character! Feel free to edit her details, add prompts, or use her as a template for your own characters.\n\nTips:\n• Add prompts to save your favorite image generation settings\n• Upload images to keep track of your creations\n• Set character-specific defaults to speed up prompt creation\n• Try different themes to personalize her profile",
        prompts: [
            SavedPrompt(
                title: "Portrait",
                text: "Luna, portrait shot",
                outfit: "light traveling cloak, leather armor accents, silver pendant",
                pose: "looking at viewer, slight smile, wind in hair",
                environment: "soft blurred background, golden hour",
                lighting: "warm sunlight from the side, soft shadows",
                styleModifiers: "detailed, painterly, fantasy art style",
                technicalModifiers: "high quality, sharp focus on face",
                negativePrompt: "blurry, low quality, extra limbs"
            ),
            SavedPrompt(
                title: "Adventure Scene",
                text: "Luna exploring ancient ruins",
                outfit: "explorer outfit, backpack, gloves, sturdy boots",
                pose: "walking through a stone archway, torch in hand, curious expression",
                environment: "ancient temple ruins, overgrown with vines, mysterious glowing runes",
                lighting: "torch light casting warm glow, cool ambient light from cracks in ceiling",
                styleModifiers: "cinematic, atmospheric, detailed environment",
                technicalModifiers: "wide shot, depth of field",
                negativePrompt: "modern elements, text, watermark"
            )
        ],
        profileImageData: nil,
        links: [
            RelatedLink(title: "Perchance AI Generator", urlString: "https://perchance.org/ai-text-to-image-generator"),
            RelatedLink(title: "Prompt Writing Tips", urlString: "https://perchance.org/ai-photo-prompt-generator")
        ],
        characterDefaults: [
            .style: "detailed, high quality"
        ],
        characterDefaultPerchanceGenerator: nil,
        characterThemeId: nil
    )
    
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
                    outfit: "soft sweater, comfy pants, casual look",
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
    
    // MARK: - Test Character Generator
    
    /// Generates a random test character with varied data for demo/testing
    static func generateTestCharacter(availableThemes: [AppTheme]) -> CharacterProfile {
        let names = [
            "Aria Stormwind", "Zephyr Nightshade", "Ember Thornwood", "Frost Silvermoon",
            "Sage Ironheart", "Nova Starfire", "Raven Shadowmere", "Phoenix Goldleaf",
            "Willow Mistwalker", "Storm Blackwood", "Crystal Sunblade", "Ash Winterborn"
        ]
        
        let bios = [
            "A wandering mage with a mysterious past and a talent for elemental magic.",
            "A skilled warrior from the northern mountains, known for their unwavering loyalty.",
            "A cunning rogue who operates in the shadows, always three steps ahead.",
            "A gentle healer with the power to mend both body and spirit.",
            "An ambitious scholar seeking forbidden knowledge in ancient ruins.",
            "A charismatic bard whose songs can inspire armies or bring foes to tears."
        ]
        
        let notes = [
            "Great for action scenes and dramatic poses.",
            "Works well with both fantasy and modern settings.",
            "Best in soft lighting with warm color palettes.",
            "Experiment with different outfits and environments.",
            "Try various expressions from stoic to playful."
        ]
        
        let outfits = [
            "elegant flowing robes with silver embroidery",
            "practical leather armor with brass buckles",
            "casual modern streetwear, hoodie and jeans",
            "formal Victorian attire with lace details",
            "futuristic bodysuit with glowing accents"
        ]
        
        let poses = [
            "standing confidently, arms crossed",
            "sitting thoughtfully, chin resting on hand",
            "dynamic action pose, mid-leap",
            "relaxed pose, leaning against a wall",
            "dramatic pose, looking over shoulder"
        ]
        
        let environments = [
            "mystical forest with glowing mushrooms",
            "bustling city street at night, neon lights",
            "ancient library with floating books",
            "snowy mountain peak at sunset",
            "cozy tavern interior, warm firelight"
        ]
        
        let linkTitles = [
            ("Character Reference", "https://example.com/ref"),
            ("Inspiration Board", "https://pinterest.com/board"),
            ("Art Commission Info", "https://example.com/commission")
        ]
        
        // Generate random prompts
        let promptCount = Int.random(in: 1...4)
        var prompts: [SavedPrompt] = []
        
        for i in 0..<promptCount {
            let promptTitles = ["Portrait", "Action Shot", "Casual Scene", "Dramatic Moment", "Full Body"]
            prompts.append(SavedPrompt(
                title: promptTitles[i % promptTitles.count],
                text: "\(names.randomElement()!), \(poses.randomElement()!)",
                outfit: outfits.randomElement(),
                pose: poses.randomElement(),
                environment: environments.randomElement(),
                lighting: ["soft natural light", "dramatic rim lighting", "warm golden hour", "cool moonlight"].randomElement(),
                styleModifiers: ["detailed", "painterly", "anime style", "realistic", "stylized"].randomElement(),
                technicalModifiers: ["high quality", "8k", "sharp focus"].randomElement(),
                negativePrompt: "low quality, blurry"
            ))
        }
        
        // Generate random links
        let linkCount = Int.random(in: 0...2)
        var links: [RelatedLink] = []
        for _ in 0..<linkCount {
            if let link = linkTitles.randomElement() {
                links.append(RelatedLink(title: link.0, urlString: link.1))
            }
        }
        
        // Random theme
        let themeId: String? = Bool.random() ? availableThemes.randomElement()?.id : nil
        
        // Random defaults
        var defaults: [GlobalDefaultKey: String] = [:]
        if Bool.random() {
            defaults[.style] = ["detailed", "painterly", "anime"].randomElement()!
        }
        if Bool.random() {
            defaults[.lighting] = ["soft lighting", "dramatic lighting"].randomElement()!
        }
        
        return CharacterProfile(
            name: names.randomElement()!,
            bio: bios.randomElement()!,
            notes: notes.randomElement()!,
            prompts: prompts,
            profileImageData: nil,
            links: links,
            characterDefaults: defaults,
            characterDefaultPerchanceGenerator: Bool.random() ? "ai-photo-generator" : nil,
            characterThemeId: themeId
        )
    }
}
