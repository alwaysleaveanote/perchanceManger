import Foundation

/// A link attached to a character profile for reference materials
struct RelatedLink: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var urlString: String
}
