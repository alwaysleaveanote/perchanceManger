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
    
    /// The theme for this character - resolved locally
    private var characterTheme: ResolvedTheme {
        themeManager.resolvedTheme(forCharacterThemeId: character.characterThemeId)
    }

    var body: some View {
        let theme = characterTheme
        
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
        let theme = characterTheme
        
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
    
    /// Maximum height for scrollable text sections (approximately 15 lines)
    private let maxTextHeight: CGFloat = 300
    
    /// Check if text exceeds the line limit for scrolling
    private func needsScrolling(_ text: String) -> Bool {
        let lineCount = text.components(separatedBy: .newlines).count
        return lineCount > 15 || text.count > 800
    }
    
    private var infoCard: some View {
        let theme = characterTheme
        
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
                        maxLines: 10,
                        fontSize: 14
                    )
                } else {
                    if character.bio.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("No bio yet. Tap 'Edit' to add one.")
                            .font(.caption)
                            .fontDesign(theme.fontDesign)
                            .foregroundColor(theme.textSecondary)
                    } else {
                        scrollableTextView(text: character.bio, theme: theme)
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
                        maxLines: 10,
                        fontSize: 14
                    )
                } else {
                    if character.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("No notes yet.")
                            .font(.caption)
                            .fontDesign(theme.fontDesign)
                            .foregroundColor(theme.textSecondary)
                    } else {
                        scrollableTextView(text: character.notes, theme: theme)
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
    
    /// A text view that becomes scrollable when content exceeds 15 lines
    @ViewBuilder
    private func scrollableTextView(text: String, theme: ResolvedTheme) -> some View {
        if needsScrolling(text) {
            ScrollView {
                Text(text)
                    .font(.subheadline)
                    .fontDesign(theme.fontDesign)
                    .foregroundColor(theme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: maxTextHeight)
        } else {
            Text(text)
                .font(.subheadline)
                .fontDesign(theme.fontDesign)
                .foregroundColor(theme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Links Card

    private var linksCard: some View {
        let theme = characterTheme
        
        return VStack(alignment: .leading, spacing: 16) {
            // Header with add button
            HStack {
                Text("Related Links")
                    .font(.subheadline.weight(.semibold))
                    .fontDesign(theme.fontDesign)
                    .foregroundColor(theme.textPrimary)
                
                Spacer()
                
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showAddLinkForm.toggle()
                        if !showAddLinkForm {
                            newLinkTitle = ""
                            newLinkURL = ""
                        }
                    }
                } label: {
                    Image(systemName: showAddLinkForm ? "xmark" : "plus")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(theme.textOnPrimary)
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(showAddLinkForm ? theme.textSecondary : theme.primary)
                        )
                }
                .buttonStyle(.plain)
            }
            
            // Add link form (expandable)
            if showAddLinkForm {
                VStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Title")
                            .font(.caption.weight(.medium))
                            .foregroundColor(theme.textSecondary)
                        ThemedTextField(placeholder: "e.g. Character Reference", text: $newLinkTitle)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("URL")
                            .font(.caption.weight(.medium))
                            .foregroundColor(theme.textSecondary)
                        ThemedTextField(placeholder: "https://...", text: $newLinkURL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                    
                    Button {
                        addLink()
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Link")
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(theme.textOnPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: theme.cornerRadiusSmall)
                                .fill(newLinkURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty 
                                      ? theme.primary.opacity(0.5) 
                                      : theme.primary)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(newLinkURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: theme.cornerRadiusSmall)
                        .fill(theme.backgroundTertiary)
                )
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.95).combined(with: .opacity),
                    removal: .scale(scale: 0.95).combined(with: .opacity)
                ))
            }

            // Links list
            if character.links.isEmpty && !showAddLinkForm {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "link.circle")
                            .font(.system(size: 32))
                            .foregroundColor(theme.textSecondary.opacity(0.4))
                        Text("No links yet")
                            .font(.caption)
                            .foregroundColor(theme.textSecondary)
                        Text("Tap + to add reference links")
                            .font(.caption2)
                            .foregroundColor(theme.textSecondary.opacity(0.7))
                    }
                    .padding(.vertical, 16)
                    Spacer()
                }
            } else if !character.links.isEmpty {
                // Make scrollable if more than 4 links
                if character.links.count > 4 {
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(character.links) { link in
                                linkRow(link: link, theme: theme)
                            }
                        }
                    }
                    .frame(maxHeight: 280) // Approximately 4 link rows
                } else {
                    VStack(spacing: 8) {
                        ForEach(character.links) { link in
                            linkRow(link: link, theme: theme)
                        }
                    }
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
    
    /// Individual link row with modern styling
    private func linkRow(link: RelatedLink, theme: ResolvedTheme) -> some View {
        HStack(spacing: 12) {
            // Icon with background
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(theme.primary.opacity(0.12))
                    .frame(width: 36, height: 36)
                
                Image(systemName: link.isValid ? "link" : "exclamationmark.triangle")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(link.isValid ? theme.primary : theme.warning)
            }
            
            // Link info
            VStack(alignment: .leading, spacing: 2) {
                Text(link.title.isEmpty ? "Untitled Link" : link.title)
                    .font(.subheadline.weight(.medium))
                    .fontDesign(theme.fontDesign)
                    .foregroundColor(theme.textPrimary)
                    .lineLimit(1)
                
                if let host = link.host {
                    Text(host)
                        .font(.caption2)
                        .foregroundColor(theme.textSecondary)
                        .lineLimit(1)
                } else {
                    Text(link.urlString)
                        .font(.caption2)
                        .foregroundColor(theme.textSecondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 4) {
                // Open link button
                if let url = link.url {
                    Button {
                        UIApplication.shared.open(url)
                    } label: {
                        Image(systemName: "arrow.up.right.square")
                            .font(.system(size: 16))
                            .foregroundColor(theme.primary)
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.plain)
                }
                
                // Delete button
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        removeLink(link)
                    }
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundColor(theme.error.opacity(0.8))
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: theme.cornerRadiusSmall)
                .fill(theme.backgroundTertiary)
        )
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
            title: trimmedTitle,
            urlString: trimmedURL
        )
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            character.links.append(link)
            newLinkTitle = ""
            newLinkURL = ""
            showAddLinkForm = false
        }
    }

    // MARK: - Gallery Card

    private var galleryCard: some View {
        let theme = characterTheme
        
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
