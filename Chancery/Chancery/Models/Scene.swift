//
//  Scene.swift
//  Chancery
//
//  Represents a scene containing multiple characters for group prompts.
//

import Foundation

// MARK: - CharacterScene

/// A scene that groups multiple characters together for creating group prompts.
///
/// Scenes allow users to create prompts featuring multiple characters in a single image.
/// Each scene maintains references to the included characters and has its own prompts
/// with per-character customizations.
///
/// ## Usage
/// ```swift
/// let scene = CharacterScene(
///     name: "Beach Day",
///     characterIds: [luna.id, aria.id],
///     description: "A fun day at the beach"
/// )
/// ```
struct CharacterScene: Identifiable, Codable, Equatable {
    
    // MARK: - Identity
    
    /// Unique identifier for this scene
    let id: UUID
    
    /// The scene's display name
    var name: String
    
    /// A brief description of the scene
    var description: String
    
    /// Private notes about the scene
    var notes: String
    
    // MARK: - Characters
    
    /// IDs of characters included in this scene
    var characterIds: [UUID]
    
    // MARK: - Prompts
    
    /// Collection of saved prompts for this scene
    var prompts: [ScenePrompt]
    
    // MARK: - Media
    
    /// Profile image data for this scene
    var profileImageData: Data?
    
    /// Standalone images for this scene (not attached to prompts)
    var standaloneImages: [PromptImage]
    
    // MARK: - Related Links
    
    /// Related links for this scene (reference images, inspiration, etc.)
    var links: [RelatedLink]
    
    // MARK: - Customization
    
    /// Per-scene theme override
    var sceneThemeId: String?
    
    /// Per-scene Perchance generator override
    var sceneDefaultPerchanceGenerator: String?
    
    /// Per-scene default values for prompt sections (mirrors CharacterProfile.characterDefaults)
    var sceneDefaults: [GlobalDefaultKey: String]
    
    // MARK: - Initialization
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        notes: String = "",
        characterIds: [UUID] = [],
        prompts: [ScenePrompt] = [],
        profileImageData: Data? = nil,
        standaloneImages: [PromptImage] = [],
        links: [RelatedLink] = [],
        sceneThemeId: String? = nil,
        sceneDefaultPerchanceGenerator: String? = nil,
        sceneDefaults: [GlobalDefaultKey: String] = [:]
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.notes = notes
        self.characterIds = characterIds
        self.prompts = prompts
        self.profileImageData = profileImageData
        self.standaloneImages = standaloneImages
        self.links = links
        self.sceneThemeId = sceneThemeId
        self.sceneDefaultPerchanceGenerator = sceneDefaultPerchanceGenerator
        self.sceneDefaults = sceneDefaults
    }
}

// MARK: - Computed Properties

extension CharacterScene {
    
    /// The total number of prompts for this scene
    var promptCount: Int {
        prompts.count
    }
    
    /// The total number of images across all prompts and standalone images
    var totalImageCount: Int {
        prompts.reduce(0) { $0 + $1.images.count } + standaloneImages.count
    }
    
    /// All images for this scene
    var allImages: [PromptImage] {
        var images: [PromptImage] = []
        for prompt in prompts {
            images.append(contentsOf: prompt.images)
        }
        images.append(contentsOf: standaloneImages)
        return images
    }
    
    /// Number of characters in this scene
    var characterCount: Int {
        characterIds.count
    }
}

// MARK: - ScenePrompt

/// A prompt for a scene, containing global settings and per-character customizations.
struct ScenePrompt: Identifiable, Codable, Equatable {
    
    // MARK: - Identity
    
    let id: UUID
    
    /// Display title for this prompt
    var title: String
    
    // MARK: - Global Scene Settings
    
    /// Environment/setting for the entire scene
    var environment: String?
    
    /// Lighting for the entire scene
    var lighting: String?
    
    /// Style modifiers for the entire scene
    var styleModifiers: String?
    
    /// Technical modifiers for the entire scene
    var technicalModifiers: String?
    
    /// Negative prompt for the entire scene
    var negativePrompt: String?
    
    /// Additional scene-wide information
    var additionalInfo: String?
    
    // MARK: - Per-Character Settings
    
    /// Customizations for each character in the scene
    /// Key is the character's UUID
    var characterSettings: [UUID: SceneCharacterSettings]
    
    // MARK: - Media
    
    /// Images attached to this prompt
    var images: [PromptImage]
    
    // MARK: - Preset Tracking
    
    var environmentPresetName: String?
    var lightingPresetName: String?
    var stylePresetName: String?
    var technicalPresetName: String?
    var negativePresetName: String?
    
    // MARK: - Initialization
    
    init(
        id: UUID = UUID(),
        title: String = "",
        environment: String? = nil,
        lighting: String? = nil,
        styleModifiers: String? = nil,
        technicalModifiers: String? = nil,
        negativePrompt: String? = nil,
        additionalInfo: String? = nil,
        characterSettings: [UUID: SceneCharacterSettings] = [:],
        images: [PromptImage] = [],
        environmentPresetName: String? = nil,
        lightingPresetName: String? = nil,
        stylePresetName: String? = nil,
        technicalPresetName: String? = nil,
        negativePresetName: String? = nil
    ) {
        self.id = id
        self.title = title
        self.environment = environment
        self.lighting = lighting
        self.styleModifiers = styleModifiers
        self.technicalModifiers = technicalModifiers
        self.negativePrompt = negativePrompt
        self.additionalInfo = additionalInfo
        self.characterSettings = characterSettings
        self.images = images
        self.environmentPresetName = environmentPresetName
        self.lightingPresetName = lightingPresetName
        self.stylePresetName = stylePresetName
        self.technicalPresetName = technicalPresetName
        self.negativePresetName = negativePresetName
    }
}

// MARK: - SceneCharacterSettings

/// Per-character settings within a scene prompt.
struct SceneCharacterSettings: Codable, Equatable {
    
    /// Physical description for this character in the scene
    var physicalDescription: String?
    
    /// Outfit for this character in the scene
    var outfit: String?
    
    /// Pose for this character in the scene
    var pose: String?
    
    /// Additional character-specific details
    var additionalInfo: String?
    
    /// ID of the source prompt these settings were loaded from (if any)
    var sourcePromptId: UUID?
    
    // MARK: - Preset Tracking
    
    var physicalDescriptionPresetName: String?
    var outfitPresetName: String?
    var posePresetName: String?
    
    init(
        physicalDescription: String? = nil,
        outfit: String? = nil,
        pose: String? = nil,
        additionalInfo: String? = nil,
        sourcePromptId: UUID? = nil,
        physicalDescriptionPresetName: String? = nil,
        outfitPresetName: String? = nil,
        posePresetName: String? = nil
    ) {
        self.physicalDescription = physicalDescription
        self.outfit = outfit
        self.pose = pose
        self.additionalInfo = additionalInfo
        self.sourcePromptId = sourcePromptId
        self.physicalDescriptionPresetName = physicalDescriptionPresetName
        self.outfitPresetName = outfitPresetName
        self.posePresetName = posePresetName
    }
}

// MARK: - ScenePrompt Computed Properties

extension ScenePrompt {
    
    /// Number of images attached to this prompt
    var imageCount: Int {
        images.count
    }
    
    /// Whether this prompt has any content
    var hasContent: Bool {
        environment?.isEmpty == false ||
        lighting?.isEmpty == false ||
        styleModifiers?.isEmpty == false ||
        technicalModifiers?.isEmpty == false ||
        negativePrompt?.isEmpty == false ||
        additionalInfo?.isEmpty == false ||
        !characterSettings.isEmpty
    }
}
