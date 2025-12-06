import SwiftUI
import UIKit

/// Overview section showing character profile, bio, notes, links, and gallery
struct CharacterOverviewView: View {
    @Binding var character: CharacterProfile

    let allImages: [PromptImage]
    let onImageTap: (Int) -> Void

    @Binding var isEditingInfo: Bool
    @EnvironmentObject var themeManager: ThemeManager

    @State private var newLinkTitle: String = ""
    @State private var newLinkURL: String = ""
    @State private var showAddLinkForm: Bool = false
    @State private var showingProfileImagePicker: Bool = false

    var body: some View {
        let theme = themeManager.resolved
        
        VStack(alignment: .leading, spacing: 20) {
            // Profile Card - centered hero section
            profileCard
            
            // Bio & Notes Card
            infoCard
            
            // Links Card
            linksCard
            
            // Gallery Card
            galleryCard

            Spacer(minLength: 0)
        }
        .sheet(isPresented: $showingProfileImagePicker) {
            ImagePicker { images in
                if let first = images.first,
                   let data = first.jpegData(compressionQuality: 0.9) {
                    character.profileImageData = data
                }
            }
        }
    }
    
    // MARK: - Profile Card
    
    private var profileCard: some View {
        let theme = themeManager.resolved
        
        return VStack(spacing: 12) {
            // Edit button at top left
            HStack {
                Button {
                    withAnimation {
                        isEditingInfo.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: isEditingInfo ? "checkmark" : "pencil")
                            .font(.system(size: 12, weight: .medium))
                        Text(isEditingInfo ? "Done" : "Edit")
                            .font(.caption.weight(.medium))
                    }
                    .foregroundColor(theme.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(theme.primary.opacity(0.12))
                    )
                }
                .buttonStyle(.plain)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            
            // Profile image - large circular for profile page
            Button {
                showingProfileImagePicker = true
            } label: {
                ZStack(alignment: .bottomTrailing) {
                    if let data = character.profileImageData,
                       let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 160, height: 160)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(theme.backgroundTertiary)
                            .frame(width: 160, height: 160)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 64))
                                    .foregroundColor(theme.textSecondary.opacity(0.5))
                            )
                    }
                    
                    // Edit badge
                    Circle()
                        .fill(theme.primary)
                        .frame(width: 36, height: 36)
                        .overlay(
                            Image(systemName: "camera.fill")
                                .font(.system(size: 16))
                                .foregroundColor(theme.textOnPrimary)
                        )
                        .offset(x: -8, y: -8)
                }
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: theme.cornerRadiusMedium)
                .fill(theme.backgroundSecondary)
        )
        .shadow(color: theme.shadow.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    // MARK: - Info Card (Bio & Notes)
    
    private var infoCard: some View {
        let theme = themeManager.resolved
        
        return VStack(alignment: .leading, spacing: 16) {
            // Bio Section
            VStack(alignment: .leading, spacing: 8) {
                Text("Bio")
                    .font(.subheadline.weight(.semibold))
                    .fontDesign(theme.fontDesign)
                    .foregroundColor(theme.textPrimary)

                if isEditingInfo {
                    DynamicGrowingTextEditor(
                        text: $character.bio,
                        placeholder: "Character bio / description",
                        minLines: 2,
                        maxLines: 6,
                        fontSize: 14
                    )
                } else {
                    if character.bio.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("No bio yet. Tap 'Edit Character Info' to add one.")
                            .font(.caption)
                            .fontDesign(theme.fontDesign)
                            .foregroundColor(theme.textSecondary)
                    } else {
                        Text(character.bio)
                            .font(.subheadline)
                            .fontDesign(theme.fontDesign)
                            .foregroundColor(theme.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }

            ThemedDivider()

            // Notes Section
            VStack(alignment: .leading, spacing: 8) {
                Text("Notes")
                    .font(.subheadline.weight(.semibold))
                    .fontDesign(theme.fontDesign)
                    .foregroundColor(theme.textPrimary)

                if isEditingInfo {
                    DynamicGrowingTextEditor(
                        text: $character.notes,
                        placeholder: "Any extra notes about this character",
                        minLines: 1,
                        maxLines: 6,
                        fontSize: 14
                    )
                } else {
                    if character.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("No notes yet.")
                            .font(.caption)
                            .fontDesign(theme.fontDesign)
                            .foregroundColor(theme.textSecondary)
                    } else {
                        Text(character.notes)
                            .font(.subheadline)
                            .fontDesign(theme.fontDesign)
                            .foregroundColor(theme.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: theme.cornerRadiusMedium)
                .fill(theme.backgroundSecondary)
        )
        .shadow(color: theme.shadow.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    // MARK: - Links Card

    private var linksCard: some View {
        let theme = themeManager.resolved
        
        return VStack(alignment: .leading, spacing: 12) {
            Text("Related Links")
                .font(.subheadline.weight(.semibold))
                .fontDesign(theme.fontDesign)
                .foregroundColor(theme.textPrimary)

            if character.links.isEmpty {
                Text("No related links yet.")
                    .font(.caption)
                    .fontDesign(theme.fontDesign)
                    .foregroundColor(theme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(character.links) { link in
                        HStack(spacing: 8) {
                            if let url = URL(string: link.urlString) {
                                Link(destination: url) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "link")
                                        Text(link.title.isEmpty ? link.urlString : link.title)
                                            .lineLimit(1)
                                            .truncationMode(.tail)
                                    }
                                    .font(.subheadline)
                                    .foregroundColor(theme.primary)
                                }
                            } else {
                                HStack(spacing: 6) {
                                    Image(systemName: "exclamationmark.triangle")
                                        .foregroundColor(theme.warning)
                                    Text(link.title.isEmpty ? link.urlString : link.title)
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                }
                                .font(.subheadline)
                            }

                            Spacer(minLength: 8)

                            Button {
                                removeLink(link)
                            } label: {
                                Image(systemName: "trash")
                                    .font(.caption)
                                    .foregroundColor(theme.error)
                            }
                            .buttonStyle(.borderless)
                            .accessibilityLabel("Delete link")
                        }
                    }
                }
            }

            // Add link area
            if showAddLinkForm {
                HStack(spacing: 8) {
                    ThemedTextField(placeholder: "Title", text: $newLinkTitle)
                        .frame(minWidth: 60)

                    ThemedTextField(placeholder: "https://...", text: $newLinkURL)

                    Button {
                        addLink()
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(theme.success)
                    }
                    .disabled(newLinkURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    Button {
                        newLinkTitle = ""
                        newLinkURL = ""
                        withAnimation {
                            showAddLinkForm = false
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(theme.error)
                    }
                }
                .font(.subheadline)
            } else {
                Button {
                    withAnimation {
                        showAddLinkForm = true
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle")
                        Text("Add Link")
                    }
                    .font(.subheadline)
                    .foregroundColor(theme.primary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: theme.cornerRadiusMedium)
                .fill(theme.backgroundSecondary)
        )
        .shadow(color: theme.shadow.opacity(0.06), radius: 8, x: 0, y: 2)
    }
    
    private func removeLink(_ link: RelatedLink) {
        if let index = character.links.firstIndex(where: { $0.id == link.id }) {
            character.links.remove(at: index)
        }
    }

    private func addLink() {
        let trimmedURL = newLinkURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedURL.isEmpty else { return }

        let trimmedTitle = newLinkTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let link = RelatedLink(
            title: trimmedTitle.isEmpty ? trimmedURL : trimmedTitle,
            urlString: trimmedURL
        )
        character.links.append(link)
        newLinkTitle = ""
        newLinkURL = ""
        withAnimation {
            showAddLinkForm = false
        }
    }

    // MARK: - Gallery Card

    private var galleryCard: some View {
        let theme = themeManager.resolved
        
        return VStack(alignment: .leading, spacing: 12) {
            Text("Image Gallery")
                .font(.subheadline.weight(.semibold))
                .fontDesign(theme.fontDesign)
                .foregroundColor(theme.textPrimary)

            if allImages.isEmpty {
                Text("No images yet. Profile image and prompt images will appear here.")
                    .font(.caption)
                    .fontDesign(theme.fontDesign)
                    .foregroundColor(theme.textSecondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Array(allImages.enumerated()), id: \.element.id) { index, promptImage in
                            if let uiImage = UIImage(data: promptImage.data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 72, height: 72)
                                    .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadiusSmall))
                                    .shadow(color: theme.shadow.opacity(0.1), radius: 4, x: 0, y: 2)
                                    .onTapGesture {
                                        onImageTap(index)
                                    }
                            }
                        }
                    }
                }

                Text("Tap to view full-screen")
                    .font(.caption2)
                    .fontDesign(theme.fontDesign)
                    .foregroundColor(theme.textSecondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: theme.cornerRadiusMedium)
                .fill(theme.backgroundSecondary)
        )
        .shadow(color: theme.shadow.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}
