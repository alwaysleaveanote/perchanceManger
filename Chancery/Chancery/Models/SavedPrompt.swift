//
//  SavedPrompt.swift
//  Chancery
//
//  Represents a complete saved prompt with all section fields, preset markers,
//  and associated generated images.
//

import Foundation

// MARK: - SavedPrompt

/// A complete prompt configuration that can be saved, edited, and used for image generation.
///
/// `SavedPrompt` stores:
/// - **Content fields**: The actual text for each prompt section
/// - **Preset markers**: Names of presets used (for UI display)
/// - **Generated images**: Images created using this prompt
///
/// ## Prompt Composition
/// The `composedPrompt` property combines all non-empty sections into a single
/// string suitable for image generation, with the negative prompt separated.
///
/// ## Usage
/// ```swift
/// let prompt = SavedPrompt(
///     title: "Hero Shot",
///     text: "Character in heroic pose",
///     outfit: "armor, cape",
///     pose: "standing tall"
/// )
/// print(prompt.composedPrompt) // Combined prompt text
/// ```
struct SavedPrompt: Identifiable, Codable, Equatable {
    
    // MARK: - Identity
    
    /// Unique identifier for this prompt
    let id: UUID
    
    /// User-provided title for easy identification
    var title: String
    
    /// Legacy/fallback text field (used when sections are empty)
    var text: String
    
    // MARK: - Prompt Sections
    
    /// Physical characteristics of the subject
    var physicalDescription: String?
    
    /// Clothing, accessories, and worn items
    var outfit: String?
    
    /// Body position, gesture, and facial expression
    var pose: String?
    
    /// Background, setting, and surroundings
    var environment: String?
    
    /// Light sources, shadows, and atmospheric effects
    var lighting: String?
    
    /// Artistic style, medium, and aesthetic preferences
    var styleModifiers: String?
    
    /// Technical parameters (resolution, detail level, etc.)
    var technicalModifiers: String?
    
    /// Elements to exclude from the generated image
    var negativePrompt: String?
    
    /// Any additional information or notes
    var additionalInfo: String?
    
    // MARK: - Preset Markers
    
    /// Name of preset used for physical description (for UI display)
    var physicalDescriptionPresetName: String?
    
    /// Name of preset used for outfit
    var outfitPresetName: String?
    
    /// Name of preset used for pose
    var posePresetName: String?
    
    /// Name of preset used for environment
    var environmentPresetName: String?
    
    /// Name of preset used for lighting
    var lightingPresetName: String?
    
    /// Name of preset used for style
    var stylePresetName: String?
    
    /// Name of preset used for technical modifiers
    var technicalPresetName: String?
    
    /// Name of preset used for negative prompt
    var negativePresetName: String?
    
    // MARK: - Associated Data
    
    /// Images generated using this prompt
    var images: [PromptImage]
    
    // MARK: - Initialization
    
    /// Creates a new saved prompt with the specified values
    /// - Parameters:
    ///   - id: Unique identifier (defaults to new UUID)
    ///   - title: Display title for the prompt
    ///   - text: Legacy text field
    ///   - physicalDescription: Physical characteristics
    ///   - outfit: Clothing description
    ///   - pose: Pose description
    ///   - environment: Environment description
    ///   - lighting: Lighting description
    ///   - styleModifiers: Style modifiers
    ///   - technicalModifiers: Technical parameters
    ///   - negativePrompt: Elements to exclude
    ///   - additionalInfo: Additional notes
    ///   - physicalDescriptionPresetName: Preset name for physical description
    ///   - outfitPresetName: Preset name for outfit
    ///   - posePresetName: Preset name for pose
    ///   - environmentPresetName: Preset name for environment
    ///   - lightingPresetName: Preset name for lighting
    ///   - stylePresetName: Preset name for style
    ///   - technicalPresetName: Preset name for technical
    ///   - negativePresetName: Preset name for negative
    ///   - images: Associated generated images
    init(
        id: UUID = UUID(),
        title: String,
        text: String = "",
        physicalDescription: String? = nil,
        outfit: String? = nil,
        pose: String? = nil,
        environment: String? = nil,
        lighting: String? = nil,
        styleModifiers: String? = nil,
        technicalModifiers: String? = nil,
        negativePrompt: String? = nil,
        additionalInfo: String? = nil,
        physicalDescriptionPresetName: String? = nil,
        outfitPresetName: String? = nil,
        posePresetName: String? = nil,
        environmentPresetName: String? = nil,
        lightingPresetName: String? = nil,
        stylePresetName: String? = nil,
        technicalPresetName: String? = nil,
        negativePresetName: String? = nil,
        images: [PromptImage] = []
    ) {
        self.id = id
        self.title = title
        self.text = text
        self.physicalDescription = physicalDescription
        self.outfit = outfit
        self.pose = pose
        self.environment = environment
        self.lighting = lighting
        self.styleModifiers = styleModifiers
        self.technicalModifiers = technicalModifiers
        self.negativePrompt = negativePrompt
        self.additionalInfo = additionalInfo
        self.physicalDescriptionPresetName = physicalDescriptionPresetName
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

// MARK: - Computed Properties

extension SavedPrompt {
    
    /// Combines all non-empty sections into a single prompt string
    ///
    /// The sections are joined with ", " and the negative prompt is appended
    /// with " | " separator if present.
    var composedPrompt: String {
        // Collect all positive prompt sections
        let positiveSections: [String?] = [
            physicalDescription,
            outfit,
            pose,
            environment,
            lighting,
            styleModifiers,
            technicalModifiers,
            additionalInfo
        ]
        
        // Filter and join non-empty sections
        let positivePrompt = positiveSections
            .compactMap { $0?.nonEmpty }
            .joined(separator: ", ")
        
        // Append negative prompt if present
        if let negative = negativePrompt?.nonEmpty {
            return positivePrompt.isEmpty
                ? "| \(negative)"
                : "\(positivePrompt) | \(negative)"
        }
        
        return positivePrompt
    }
    
    /// Whether this prompt has any content in its sections
    var hasContent: Bool {
        let allSections: [String?] = [
            physicalDescription, outfit, pose, environment,
            lighting, styleModifiers, technicalModifiers,
            negativePrompt, additionalInfo
        ]
        return allSections.contains { $0?.nonEmpty != nil }
    }
    
    /// The number of images associated with this prompt
    var imageCount: Int {
        images.count
    }
}

// MARK: - Section Access

extension SavedPrompt {
    
    /// Gets the content for a specific section
    /// - Parameter kind: The section to retrieve
    /// - Returns: The section content, or nil if empty
    func content(for kind: PromptSectionKind) -> String? {
        switch kind {
        case .physicalDescription: return physicalDescription
        case .outfit: return outfit
        case .pose: return pose
        case .environment: return environment
        case .lighting: return lighting
        case .style: return styleModifiers
        case .technical: return technicalModifiers
        case .negative: return negativePrompt
        }
    }
    
    /// Gets the preset name for a specific section
    /// - Parameter kind: The section to retrieve
    /// - Returns: The preset name, or nil if not using a preset
    func presetName(for kind: PromptSectionKind) -> String? {
        switch kind {
        case .physicalDescription: return physicalDescriptionPresetName
        case .outfit: return outfitPresetName
        case .pose: return posePresetName
        case .environment: return environmentPresetName
        case .lighting: return lightingPresetName
        case .style: return stylePresetName
        case .technical: return technicalPresetName
        case .negative: return negativePresetName
        }
    }
    
    /// Sets the content for a specific section
    /// - Parameters:
    ///   - content: The new content (nil to clear)
    ///   - kind: The section to update
    mutating func setContent(_ content: String?, for kind: PromptSectionKind) {
        switch kind {
        case .physicalDescription: physicalDescription = content
        case .outfit: outfit = content
        case .pose: pose = content
        case .environment: environment = content
        case .lighting: lighting = content
        case .style: styleModifiers = content
        case .technical: technicalModifiers = content
        case .negative: negativePrompt = content
        }
    }
    
    /// Sets the preset name for a specific section
    /// - Parameters:
    ///   - name: The preset name (nil to clear)
    ///   - kind: The section to update
    mutating func setPresetName(_ name: String?, for kind: PromptSectionKind) {
        switch kind {
        case .physicalDescription: physicalDescriptionPresetName = name
        case .outfit: outfitPresetName = name
        case .pose: posePresetName = name
        case .environment: environmentPresetName = name
        case .lighting: lightingPresetName = name
        case .style: stylePresetName = name
        case .technical: technicalPresetName = name
        case .negative: negativePresetName = name
        }
    }
}
