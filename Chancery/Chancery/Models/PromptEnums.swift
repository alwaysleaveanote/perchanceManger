//
//  PromptEnums.swift
//  Chancery
//
//  Defines the core enumerations used throughout the prompt system.
//  These enums provide type-safe identifiers for prompt sections and their defaults.
//

import Foundation

// MARK: - PromptSectionKind

/// Represents the different sections that make up a complete image generation prompt.
///
/// Each section corresponds to a specific aspect of the image description:
/// - Physical attributes of the subject
/// - Clothing and accessories
/// - Body positioning and expression
/// - Background and setting
/// - Light sources and atmosphere
/// - Artistic style preferences
/// - Technical generation parameters
/// - Elements to exclude from generation
///
/// ## Usage
/// ```swift
/// let section: PromptSectionKind = .outfit
/// print(section.displayLabel) // "Outfit"
/// ```
enum PromptSectionKind: String, CaseIterable, Hashable, Codable, Identifiable {
    case physicalDescription
    case outfit
    case pose
    case environment
    case lighting
    case style
    case technical
    case negative
    
    /// Conformance to Identifiable using the raw string value
    var id: String { rawValue }
}

// MARK: - GlobalDefaultKey

/// Keys for storing and retrieving default values at both global and character levels.
///
/// These keys map directly to `PromptSectionKind` values and are used to persist
/// user preferences for default prompt content.
///
/// ## Storage Locations
/// - **Global defaults**: Stored in `PromptPresetStore.globalDefaults`
/// - **Character defaults**: Stored in `CharacterProfile.characterDefaults`
enum GlobalDefaultKey: String, CaseIterable, Hashable, Codable, Identifiable {
    case physicalDescription
    case outfit
    case pose
    case environment
    case lighting
    case style
    case technical
    case negative
    
    /// Conformance to Identifiable using the raw string value
    var id: String { rawValue }
}

// MARK: - PromptSectionKind Display Properties

extension PromptSectionKind {
    
    /// Human-readable label for display in the UI
    ///
    /// Use this property when showing section names to users in forms,
    /// headers, or selection lists.
    var displayLabel: String {
        switch self {
        case .physicalDescription: return "Physical Description"
        case .outfit: return "Outfit"
        case .pose: return "Pose"
        case .environment: return "Environment"
        case .lighting: return "Lighting"
        case .style: return "Style Modifiers"
        case .technical: return "Technical Modifiers"
        case .negative: return "Negative Prompt"
        }
    }
    
    /// Placeholder text shown in empty text fields for this section
    var placeholder: String {
        switch self {
        case .physicalDescription: return "Describe physical features..."
        case .outfit: return "Describe clothing and accessories..."
        case .pose: return "Describe pose and expression..."
        case .environment: return "Describe the setting and background..."
        case .lighting: return "Describe lighting conditions..."
        case .style: return "Add artistic style modifiers..."
        case .technical: return "Add technical parameters..."
        case .negative: return "Elements to exclude..."
        }
    }
    
    /// SF Symbol icon name representing this section
    var iconName: String {
        switch self {
        case .physicalDescription: return "person.fill"
        case .outfit: return "tshirt.fill"
        case .pose: return "figure.stand"
        case .environment: return "mountain.2.fill"
        case .lighting: return "sun.max.fill"
        case .style: return "paintbrush.fill"
        case .technical: return "slider.horizontal.3"
        case .negative: return "xmark.circle.fill"
        }
    }
    
    /// The corresponding `GlobalDefaultKey` for this section
    ///
    /// Used when looking up or storing default values for this section type.
    var defaultKey: GlobalDefaultKey {
        switch self {
        case .physicalDescription: return .physicalDescription
        case .outfit: return .outfit
        case .pose: return .pose
        case .environment: return .environment
        case .lighting: return .lighting
        case .style: return .style
        case .technical: return .technical
        case .negative: return .negative
        }
    }
}

// MARK: - GlobalDefaultKey Conversion

extension GlobalDefaultKey {
    
    /// The corresponding `PromptSectionKind` for this default key
    var sectionKind: PromptSectionKind {
        switch self {
        case .physicalDescription: return .physicalDescription
        case .outfit: return .outfit
        case .pose: return .pose
        case .environment: return .environment
        case .lighting: return .lighting
        case .style: return .style
        case .technical: return .technical
        case .negative: return .negative
        }
    }
    
    /// Human-readable label (delegates to the section kind)
    var displayLabel: String {
        sectionKind.displayLabel
    }
}
