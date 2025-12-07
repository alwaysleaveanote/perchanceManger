//
//  PromptPreset.swift
//  Chancery
//
//  Represents a reusable text snippet that can be applied to prompt sections.
//

import Foundation

// MARK: - PromptPreset

/// A reusable text snippet for a specific prompt section.
///
/// Presets allow users to save commonly used descriptions and quickly
/// apply them when creating new prompts. Each preset is associated with
/// a specific `PromptSectionKind`.
///
/// ## Usage
/// ```swift
/// let preset = PromptPreset(
///     kind: .outfit,
///     name: "Casual Wear",
///     text: "hoodie, jeans, sneakers"
/// )
/// ```
struct PromptPreset: Identifiable, Codable, Equatable, Hashable {
    
    // MARK: - Properties
    
    /// Unique identifier for this preset
    let id: UUID
    
    /// The prompt section this preset applies to
    var kind: PromptSectionKind
    
    /// Display name for the preset
    var name: String
    
    /// The preset content to be inserted into the prompt
    var text: String
    
    // MARK: - Initialization
    
    /// Creates a new preset
    /// - Parameters:
    ///   - id: Unique identifier (defaults to new UUID)
    ///   - kind: The section type this preset applies to
    ///   - name: Display name
    ///   - text: The preset content
    init(
        id: UUID = UUID(),
        kind: PromptSectionKind,
        name: String,
        text: String
    ) {
        self.id = id
        self.kind = kind
        self.name = name
        self.text = text
    }
}
