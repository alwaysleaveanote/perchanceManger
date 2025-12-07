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
