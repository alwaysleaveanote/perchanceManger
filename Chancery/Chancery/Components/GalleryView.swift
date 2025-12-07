import SwiftUI
import UIKit

/// Metadata for gallery images to track their source
struct GalleryImage: Identifiable {
    let id: UUID
    let data: Data
    let promptIndex: Int?  // nil if this is the profile image
    let promptTitle: String?  // Title of the prompt this image belongs to
    let isProfileImage: Bool
    
    init(from promptImage: PromptImage, promptIndex: Int, promptTitle: String) {
        self.id = promptImage.id
        self.data = promptImage.data
        self.promptIndex = promptIndex
        self.promptTitle = promptTitle
        self.isProfileImage = false
    }
    
    init(profileImageData: Data) {
        self.id = UUID()
        self.data = profileImageData
        self.promptIndex = nil
        self.promptTitle = nil
        self.isProfileImage = true
    }
}

/// Full-screen gallery view for browsing images
struct GalleryView: View {
    let images: [GalleryImage]
    let startIndex: Int
    let profileImageData: Data?  // Current profile image data to check if image is already profile
    let onViewPrompt: ((Int) -> Void)?  // Called with prompt index
    let onMakeProfilePicture: ((Data) -> Void)?  // Called with image data

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    @State private var currentIndex: Int = 0
    @State private var dragOffset: CGFloat = 0

    init(images: [GalleryImage], startIndex: Int, profileImageData: Data? = nil, onViewPrompt: ((Int) -> Void)? = nil, onMakeProfilePicture: ((Data) -> Void)? = nil) {
        self.images = images
        self.startIndex = startIndex
        self.profileImageData = profileImageData
        self.onViewPrompt = onViewPrompt
        self.onMakeProfilePicture = onMakeProfilePicture
    }
    
    private var currentImage: GalleryImage? {
        guard currentIndex >= 0 && currentIndex < images.count else { return nil }
        return images[currentIndex]
    }
    
    /// Check if the current image is already the profile picture
    private var isCurrentImageProfilePicture: Bool {
        guard let current = currentImage, let profileData = profileImageData else { return false }
        return current.data == profileData
    }

    var body: some View {
        let theme = themeManager.resolved
        
        ZStack {
            Color.black.ignoresSafeArea()
                .opacity(1 - Double(abs(dragOffset)) / 400)

            if images.isEmpty {
                Text("No images")
                    .foregroundColor(.white)
            } else {
                VStack(spacing: 0) {
                    // Top bar
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.title3.weight(.medium))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.white.opacity(0.2))
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        // Image counter
                        if images.count > 1 {
                            Text("\(currentIndex + 1) / \(images.count)")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        Spacer()
                        
                        // Share button
                        if let current = currentImage, let uiImage = UIImage(data: current.data) {
                            ShareLink(item: Image(uiImage: uiImage), preview: SharePreview("Image", image: Image(uiImage: uiImage))) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.title3.weight(.medium))
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(Color.white.opacity(0.2))
                                    .clipShape(Circle())
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    
                    // Swipeable image area with drag-to-dismiss
                    TabView(selection: $currentIndex) {
                        ForEach(Array(images.enumerated()), id: \.element.id) { index, galleryImage in
                            if let uiImage = UIImage(data: galleryImage.data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .padding(.horizontal, 16)
                                    .tag(index)
                            }
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .offset(y: dragOffset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                // Only allow downward drag
                                if value.translation.height > 0 {
                                    dragOffset = value.translation.height
                                }
                            }
                            .onEnded { value in
                                if value.translation.height > 150 {
                                    dismiss()
                                } else {
                                    withAnimation(.spring(response: 0.3)) {
                                        dragOffset = 0
                                    }
                                }
                            }
                    )
                    
                    // Bottom action card
                    if let current = currentImage {
                        VStack(spacing: 12) {
                            // View Prompt button - only show if image has a prompt
                            if let promptIndex = current.promptIndex, onViewPrompt != nil {
                                Button {
                                    dismiss()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        onViewPrompt?(promptIndex)
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "doc.text.fill")
                                            .foregroundColor(theme.primary)
                                        Text(current.promptTitle ?? "View Prompt")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .lineLimit(1)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.5))
                                    }
                                    .padding(14)
                                    .background(Color.white.opacity(0.15))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                            
                            // Make Profile Picture button - don't show if already profile image or if this image is the current profile
                            if !current.isProfileImage, !isCurrentImageProfilePicture, onMakeProfilePicture != nil {
                                Button {
                                    onMakeProfilePicture?(current.data)
                                    dismiss()
                                } label: {
                                    HStack {
                                        Image(systemName: "person.crop.circle.fill")
                                            .foregroundColor(theme.primary.opacity(0.8))
                                        Text("Set as Profile Picture")
                                            .font(.subheadline)
                                            .foregroundColor(.white.opacity(0.9))
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.5))
                                    }
                                    .padding(14)
                                    .background(Color.white.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.black.opacity(0.6))
                        )
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    }
                }
            }
        }
        .onAppear {
            currentIndex = min(max(startIndex, 0), max(images.count - 1, 0))
        }
    }
}
