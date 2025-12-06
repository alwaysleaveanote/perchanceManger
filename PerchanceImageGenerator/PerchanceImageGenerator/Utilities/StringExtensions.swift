import Foundation

extension String {
    /// Returns nil if the string is empty or whitespace-only, otherwise returns the trimmed string
    var nonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
