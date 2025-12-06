//
//  ImageCarousel.swift
//  PerchanceImageGenerator
//
//  A horizontal scrolling carousel for displaying and managing prompt images.
//

import SwiftUI
import UIKit

// MARK: - ImageCarousel

/// A horizontal scrolling carousel for displaying prompt images.
///
/// Displays images in a horizontally scrollable row with tap-to-view functionality
/// and an add button for uploading new images.
///
/// ## Features
/// - Horizontal scrolling with momentum
/// - Tap to view individual images
/// - Add button for uploading new images
/// - Empty state message when no images exist
///
/// ## Usage
/// ```swift
/// ImageCarousel(
///     images: prompt.images,
///     onImageTap: { index in
///         selectedImageIndex = index
///         showingGallery = true
///     },
///     onAddImages: {
///         showingImagePicker = true
///     }
/// )
/// ```
struct ImageCarousel: View {
    
    // MARK: - Properties
    
    /// The images to display in the carousel
    let images: [PromptImage]
    
    /// Callback when an image is tapped, providing the index
    let onImageTap: (Int) -> Void
    
    /// Callback when the add images button is tapped
    let onAddImages: () -> Void
    
    // MARK: - Configuration
    
    /// Size of each thumbnail in the carousel
    private let thumbnailSize: CGFloat = 80
    
    /// Corner radius for thumbnails
    private let thumbnailCornerRadius: CGFloat = 10
    
    /// Spacing between thumbnails
    private let thumbnailSpacing: CGFloat = 8
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerView
            contentView
            addButton
        }
    }
    
    // MARK: - Subviews
    
    /// Section header
    private var headerView: some View {
        Text("Images")
            .font(.subheadline)
            .fontWeight(.semibold)
    }
    
    /// Main content area (images or empty state)
    @ViewBuilder
    private var contentView: some View {
        if images.isEmpty {
            emptyStateView
        } else {
            imageScrollView
        }
    }
    
    /// Empty state message
    private var emptyStateView: some View {
        Text("No images yet. Upload some!")
            .font(.caption)
            .foregroundColor(.secondary)
    }
    
    /// Horizontal scrolling image row
    private var imageScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: thumbnailSpacing) {
                ForEach(Array(images.enumerated()), id: \.element.id) { index, promptImage in
                    thumbnailView(for: promptImage, at: index)
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    /// Individual thumbnail view
    @ViewBuilder
    private func thumbnailView(for promptImage: PromptImage, at index: Int) -> some View {
        if let uiImage = promptImage.uiImage {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: thumbnailSize, height: thumbnailSize)
                .clipShape(RoundedRectangle(cornerRadius: thumbnailCornerRadius))
                .onTapGesture {
                    Logger.debug("Image tapped at index \(index)", category: .ui)
                    onImageTap(index)
                }
        }
    }
    
    /// Add images button
    private var addButton: some View {
        Button {
            Logger.debug("Add images button tapped", category: .ui)
            onAddImages()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "plus.circle")
                Text("Add Images")
            }
            .font(.caption.weight(.medium))
            .foregroundColor(.accentColor)
            .padding(.top, 2)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .center)
    }
}
