import Foundation

/// A reusable preset for a specific prompt section
struct PromptPreset: Identifiable, Codable, Equatable {
    var id = UUID()
    var kind: PromptSectionKind
    var name: String
    var text: String
}
