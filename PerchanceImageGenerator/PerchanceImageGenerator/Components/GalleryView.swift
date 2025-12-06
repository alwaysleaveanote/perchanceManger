import SwiftUI
import UIKit

/// Metadata for gallery images to track their source
struct GalleryImage: Identifiable {
    let id: UUID
    let data: Data
    let promptIndex: Int?  // nil if this is the profile image
    let isProfileImage: Bool
    
    init(from promptImage: PromptImage, promptIndex: Int) {
        self.id = promptImage.id
        self.data = promptImage.data
        self.promptIndex = promptIndex
        self.isProfileImage = false
    }
    
    init(profileImageData: Data) {
        self.id = UUID()
        self.data = profileImageData
        self.promptIndex = nil
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

            if images.isEmpty {
                Text("No images")
                    .foregroundColor(.white)
            } else {
                VStack(spacing: 0) {
                    TabView(selection: $currentIndex) {
                        ForEach(Array(images.enumerated()), id: \.element.id) { index, galleryImage in
                            if let uiImage = UIImage(data: galleryImage.data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .tag(index)
                            }
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .automatic))
                    
                    // Action buttons
                    if let current = currentImage {
                        HStack(spacing: 16) {
                            // View Prompt button - only show if image has a prompt
                            if let promptIndex = current.promptIndex, onViewPrompt != nil {
                                Button {
                                    dismiss()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        onViewPrompt?(promptIndex)
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "doc.text")
                                        Text("View Prompt")
                                    }
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(theme.primary.opacity(0.8))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                            
                            // Make Profile Picture button - don't show if already profile image or if this image is the current profile
                            if !current.isProfileImage, !isCurrentImageProfilePicture, onMakeProfilePicture != nil {
                                Button {
                                    onMakeProfilePicture?(current.data)
                                    dismiss()
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "person.crop.circle")
                                        Text("Make Profile Picture")
                                    }
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(theme.secondary.opacity(0.8))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal, 20)
                    }
                }
            }
            
            // X button overlay at top right
            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .padding(.trailing, 16)
                    .padding(.top, 16)
                }
                Spacer()
            }
        }
        .onAppear {
            currentIndex = min(max(startIndex, 0), max(images.count - 1, 0))
        }
    }
}
