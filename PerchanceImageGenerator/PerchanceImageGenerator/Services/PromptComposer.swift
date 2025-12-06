import Foundation

/// Composes a full prompt string from character, prompt, and defaults
enum PromptComposer {
    static func composePrompt(
        character: CharacterProfile,
        prompt: SavedPrompt,
        stylePreset: String?,
        globalDefaults: [GlobalDefaultKey: String]
    ) -> String {

        // Avoid unused-parameter warning
        _ = stylePreset

        // Helper: adds a section only if text exists
        func section(_ title: String, _ text: String?) -> String? {
            guard let raw = text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !raw.isEmpty else { return nil }
            return "\(title):\n\(raw)"
        }

        // Helper: character-level override for a key
        func characterOverride(_ key: GlobalDefaultKey) -> String? {
            character.characterDefaults[key]?.nonEmpty
        }

        var output: [String] = []

        // Name
        let trimmedName = character.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedName.isEmpty {
            output.append("Name:\n\(trimmedName)")
        }

        // Physical Description
        let physicalDescription = prompt.physicalDescription?.nonEmpty
            ?? characterOverride(.physicalDescription)
            ?? globalDefaults[.physicalDescription]?.nonEmpty
        if let block = section("Physical Description", physicalDescription) {
            output.append(block)
        }

        // Outfit
        let outfit = prompt.outfit?.nonEmpty
            ?? characterOverride(.outfit)
            ?? globalDefaults[.outfit]?.nonEmpty
        if let block = section("Outfit", outfit) {
            output.append(block)
        }

        // Pose
        let pose = prompt.pose?.nonEmpty
            ?? characterOverride(.pose)
            ?? globalDefaults[.pose]?.nonEmpty
        if let block = section("Pose", pose) {
            output.append(block)
        }

        // Environment
        let environment = prompt.environment?.nonEmpty
            ?? characterOverride(.environment)
            ?? globalDefaults[.environment]?.nonEmpty
        if let block = section("Environment", environment) {
            output.append(block)
        }

        // Lighting
        let lighting = prompt.lighting?.nonEmpty
            ?? characterOverride(.lighting)
            ?? globalDefaults[.lighting]?.nonEmpty
        if let block = section("Lighting", lighting) {
            output.append(block)
        }

        // Style Modifiers
        let style = prompt.styleModifiers?.nonEmpty
            ?? characterOverride(.style)
            ?? globalDefaults[.style]?.nonEmpty
        if let block = section("Style Modifiers", style) {
            output.append(block)
        }

        // Technical Modifiers
        let tech = prompt.technicalModifiers?.nonEmpty
            ?? characterOverride(.technical)
            ?? globalDefaults[.technical]?.nonEmpty
        if let block = section("Technical Modifiers", tech) {
            output.append(block)
        }

        // Negative Prompt
        let neg = prompt.negativePrompt?.nonEmpty
            ?? characterOverride(.negative)
            ?? globalDefaults[.negative]?.nonEmpty
        if let neg = neg {
            let cleanNeg = neg.lowercased().hasPrefix("negative prompt")
                ? neg
                : "Negative prompt: \(neg)"
            output.append(cleanNeg)
        }

        // Additional Information (doesn't use character/global defaults)
        if let block = section("Additional Information", prompt.additionalInfo) {
            output.append(block)
        }

        // Join sections with spacing for readability
        return output.joined(separator: "\n\n")
    }
}
