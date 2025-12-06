import Foundation

/// The different sections of a prompt that can have presets and defaults
enum PromptSectionKind: String, CaseIterable, Hashable, Codable {
    case physicalDescription
    case outfit
    case pose
    case environment
    case lighting
    case style
    case technical
    case negative
}

/// Keys for global and character-level default values
enum GlobalDefaultKey: String, CaseIterable, Hashable, Codable {
    case physicalDescription
    case outfit
    case pose
    case environment
    case lighting
    case style
    case technical
    case negative
}

// MARK: - Display Labels

extension PromptSectionKind {
    /// Human-readable label for the section
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
    
    /// Corresponding GlobalDefaultKey
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
