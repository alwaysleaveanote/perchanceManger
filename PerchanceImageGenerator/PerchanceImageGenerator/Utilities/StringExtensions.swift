//
//  StringExtensions.swift
//  PerchanceImageGenerator
//
//  Provides useful extensions to the String type used throughout the app.
//

import Foundation

// MARK: - String Extensions

extension String {
    
    /// Returns the trimmed string if it contains non-whitespace characters, otherwise `nil`.
    ///
    /// This is useful for optional binding when you want to treat empty or
    /// whitespace-only strings as "no value".
    ///
    /// ## Usage
    /// ```swift
    /// let input = "  hello  "
    /// if let text = input.nonEmpty {
    ///     print(text) // "hello"
    /// }
    ///
    /// let empty = "   "
    /// empty.nonEmpty // nil
    /// ```
    var nonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
    
    /// Whether this string contains only whitespace characters or is empty.
    var isBlank: Bool {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /// Returns the string truncated to a maximum length, with an ellipsis if truncated.
    /// - Parameter maxLength: The maximum length (including ellipsis)
    /// - Returns: The truncated string
    func truncated(to maxLength: Int) -> String {
        guard count > maxLength else { return self }
        let endIndex = index(startIndex, offsetBy: max(0, maxLength - 1))
        return String(self[..<endIndex]) + "…"
    }
}
