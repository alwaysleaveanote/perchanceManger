import SwiftUI
import UIKit

/// A horizontal scrolling carousel of images with tap-to-view and add button
struct ImageCarousel: View {
    let images: [PromptImage]
    let onImageTap: (Int) -> Void
    let onAddImages: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Images")
                .font(.subheadline)
                .fontWeight(.semibold)

            if images.isEmpty {
                Text("No images yet. Upload some!")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(images.enumerated()), id: \.element.id) { index, img in
                            if let uiImage = UIImage(data: img.data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .onTapGesture {
                                        onImageTap(index)
                                    }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            Button {
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
}
