import Foundation

/// An image attached to a saved prompt
struct PromptImage: Identifiable, Codable, Equatable {
    var id = UUID()
    var data: Data
}
