//
//  ZoomableImage.swift
//  Chancery
//
//  A zoomable image view with pinch-to-zoom and double-tap gestures.
//

import SwiftUI

/// A view that displays an image with pinch-to-zoom and double-tap-to-zoom gestures.
///
/// ## Usage
/// ```swift
/// ZoomableImage(uiImage: myImage)
/// ```
struct ZoomableImage: View {
    let uiImage: UIImage
    var cornerRadius: CGFloat = 12
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    private let minScale: CGFloat = 1.0
    private let maxScale: CGFloat = 5.0
    
    var body: some View {
        GeometryReader { geometry in
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .scaleEffect(scale)
                .offset(offset)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            let delta = value / lastScale
                            lastScale = value
                            scale = min(max(scale * delta, minScale), maxScale)
                        }
                        .onEnded { _ in
                            lastScale = 1.0
                            // Reset offset if zoomed out
                            if scale <= 1.0 {
                                withAnimation(.spring(response: 0.3)) {
                                    offset = .zero
                                    scale = 1.0
                                }
                            }
                        }
                )
                .simultaneousGesture(
                    DragGesture()
                        .onChanged { value in
                            if scale > 1.0 {
                                offset = CGSize(
                                    width: lastOffset.width + value.translation.width,
                                    height: lastOffset.height + value.translation.height
                                )
                            }
                        }
                        .onEnded { _ in
                            lastOffset = offset
                            // Constrain offset when zoomed
                            constrainOffset(in: geometry.size)
                        }
                )
                .onTapGesture(count: 2) {
                    withAnimation(.spring(response: 0.3)) {
                        if scale > 1.0 {
                            // Reset to normal
                            scale = 1.0
                            offset = .zero
                            lastOffset = .zero
                        } else {
                            // Zoom in
                            scale = 2.5
                        }
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
    
    private func constrainOffset(in size: CGSize) {
        // Calculate the maximum allowed offset based on zoom level
        let imageSize = CGSize(
            width: size.width * scale,
            height: size.height * scale
        )
        
        let maxOffsetX = max(0, (imageSize.width - size.width) / 2)
        let maxOffsetY = max(0, (imageSize.height - size.height) / 2)
        
        withAnimation(.spring(response: 0.3)) {
            offset = CGSize(
                width: min(max(offset.width, -maxOffsetX), maxOffsetX),
                height: min(max(offset.height, -maxOffsetY), maxOffsetY)
            )
            lastOffset = offset
        }
    }
}
