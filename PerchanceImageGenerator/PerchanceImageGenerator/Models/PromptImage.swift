//
//  PromptImage.swift
//  PerchanceImageGenerator
//
//  Represents an image generated from or attached to a prompt.
//

import Foundation
import UIKit

// MARK: - PromptImage

/// An image associated with a saved prompt.
///
/// `PromptImage` stores the raw image data (typically PNG or JPEG encoded)
/// and provides convenience methods for converting to/from `UIImage`.
///
/// ## Usage
/// ```swift
/// // Create from UIImage
/// if let image = PromptImage(uiImage: someUIImage) {
///     prompt.images.append(image)
/// }
///
/// // Convert back to UIImage
/// if let uiImage = promptImage.uiImage {
///     imageView.image = uiImage
/// }
/// ```
struct PromptImage: Identifiable, Codable, Equatable, Hashable {
    
    // MARK: - Properties
    
    /// Unique identifier for this image
    let id: UUID
    
    /// The raw image data (PNG or JPEG encoded)
    var data: Data
    
    // MARK: - Initialization
    
    /// Creates a new prompt image with raw data
    /// - Parameters:
    ///   - id: Unique identifier (defaults to new UUID)
    ///   - data: The raw image data
    init(id: UUID = UUID(), data: Data) {
        self.id = id
        self.data = data
    }
    
    /// Creates a new prompt image from a UIImage
    /// - Parameters:
    ///   - uiImage: The UIImage to encode
    ///   - compressionQuality: JPEG compression quality (0.0-1.0), defaults to 0.8
    /// - Returns: A new PromptImage, or nil if encoding fails
    init?(uiImage: UIImage, compressionQuality: CGFloat = 0.8) {
        guard let data = uiImage.jpegData(compressionQuality: compressionQuality) else {
            return nil
        }
        self.id = UUID()
        self.data = data
    }
}

// MARK: - Computed Properties

extension PromptImage {
    
    /// Converts the stored data back to a UIImage
    var uiImage: UIImage? {
        UIImage(data: data)
    }
    
    /// The size of the image data in bytes
    var dataSize: Int {
        data.count
    }
    
    /// A human-readable string representing the data size
    var formattedDataSize: String {
        ByteCountFormatter.string(fromByteCount: Int64(dataSize), countStyle: .file)
    }
}
