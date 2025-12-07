//
//  RelatedLink.swift
//  Chancery
//
//  Represents a URL link attached to a character for reference materials.
//

import Foundation

// MARK: - RelatedLink

/// A URL link associated with a character profile.
///
/// `RelatedLink` stores reference materials like inspiration boards,
/// character sheets, or other external resources related to a character.
///
/// ## Usage
/// ```swift
/// let link = RelatedLink(
///     title: "Character Reference",
///     urlString: "https://example.com/reference"
/// )
///
/// if let url = link.url {
///     UIApplication.shared.open(url)
/// }
/// ```
struct RelatedLink: Identifiable, Codable, Equatable, Hashable {
    
    // MARK: - Properties
    
    /// Unique identifier for this link
    let id: UUID
    
    /// Display title for the link
    var title: String
    
    /// The URL as a string
    var urlString: String
    
    // MARK: - Initialization
    
    /// Creates a new related link
    /// - Parameters:
    ///   - id: Unique identifier (defaults to new UUID)
    ///   - title: Display title
    ///   - urlString: The URL string
    init(id: UUID = UUID(), title: String, urlString: String) {
        self.id = id
        self.title = title
        self.urlString = urlString
    }
}

// MARK: - Computed Properties

extension RelatedLink {
    
    /// The URL parsed from the string, or nil if invalid
    var url: URL? {
        URL(string: urlString)
    }
    
    /// Whether the URL string represents a valid URL
    var isValid: Bool {
        url != nil
    }
    
    /// The host/domain of the URL, if available
    var host: String? {
        url?.host
    }
}
