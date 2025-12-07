import SwiftUI
import UIKit

/// Overview section showing character profile, bio, notes, links, and gallery
struct CharacterOverviewView: View {
    @Binding var character: CharacterProfile

    let allImages: [PromptImage]
    let onImageTap: (Int) -> Void
    let onPromptTap: (Int) -> Void
    let onCreatePrompt: () -> Void
    let onOpenSettings: () -> Void
    let onDeletePrompt: (Int) -> Void
    let onDuplicatePrompt: (Int, String) -> Void  // index, new name

    @Binding var isEditingInfo: Bool
    @EnvironmentObject var themeManager: ThemeManager

    @State private var newLinkTitle: String = ""
    @State private var newLinkURL: String = ""
    @State private var showAddLinkForm: Bool = false
    @State private var showingProfileImagePicker: Bool = false
    @State private var showingProfileImageViewer: Bool = false
    @State private var showNameRequiredToast: Bool = false
    @State private var showingDuplicateAlert: Bool = false
    @State private var duplicatePromptIndex: Int? = nil
    @State private var duplicatePromptName: String = ""
    @State private var showingDeleteConfirm: Bool = false
    @State private var deletePromptIndex: Int? = nil
    
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
            
            // Prompts Card
            promptsCard

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
        .fullScreenCover(isPresented: $showingProfileImageViewer) {
            ProfileImageViewer(
                imageData: character.profileImageData,
                characterName: character.name,
                onReplace: {
                    showingProfileImageViewer = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showingProfileImagePicker = true
                    }
                }
            )
            .environmentObject(themeManager)
        }
        .overlay(alignment: .top) {
            if showNameRequiredToast {
                nameRequiredToastView
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .alert("Delete this prompt?", isPresented: $showingDeleteConfirm) {
            Button("Delete", role: .destructive) {
                if let index = deletePromptIndex {
                    onDeletePrompt(index)
                }
                deletePromptIndex = nil
            }
            Button("Cancel", role: .cancel) {
                deletePromptIndex = nil
            }
        }
        .alert("Duplicate Prompt", isPresented: $showingDuplicateAlert) {
            TextField("New prompt name", text: $duplicatePromptName)
            Button("Create") {
                if let index = duplicatePromptIndex {
                    onDuplicatePrompt(index, duplicatePromptName)
                }
                duplicatePromptIndex = nil
                duplicatePromptName = ""
            }
            Button("Cancel", role: .cancel) {
                duplicatePromptIndex = nil
                duplicatePromptName = ""
            }
        } message: {
            Text("Enter a name for the duplicated prompt")
        }
    }
    
    // MARK: - Toast Views
    
    private var nameRequiredToastView: some View {
        let theme = characterTheme
        return HStack(spacing: 8) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(theme.textOnPrimary)
            Text("Character name is required")
                .font(.subheadline.weight(.medium))
                .fontDesign(theme.fontDesign)
                .foregroundColor(theme.textOnPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(theme.warning)
        )
        .padding(.top, 8)
    }
    
    private func showNameRequiredFeedback() {
        withAnimation(.easeInOut(duration: 0.2)) {
            showNameRequiredToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.2)) {
                showNameRequiredToast = false
            }
        }
    }
    
    // MARK: - Profile Card
    
    private var profileCard: some View {
        let theme = characterTheme
        
        return HStack(alignment: .top, spacing: 12) {
            // Edit button aligned with top of profile image
            Button {
                if isEditingInfo {
                    // Trying to save - validate name
                    let trimmedName = character.name.trimmingCharacters(in: .whitespacesAndNewlines)
                    if trimmedName.isEmpty {
                        showNameRequiredFeedback()
                        return
                    }
                }
                withAnimation {
                    isEditingInfo.toggle()
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: isEditingInfo ? "checkmark" : "pencil")
                        .font(.system(size: 12, weight: .medium))
                    Text(isEditingInfo ? "Done" : "Edit")
                        .font(.caption.weight(.medium))
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                }
                .foregroundColor(theme.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(theme.primary.opacity(0.12))
                )
            }
            .buttonStyle(.plain)
            .fixedSize()
            
            Spacer()
            
            // Profile image - centered
            Button {
                if character.profileImageData != nil {
                    // Show enlarged image viewer
                    showingProfileImageViewer = true
                } else {
                    // No image yet, show picker
                    showingProfileImagePicker = true
                }
            } label: {
                ZStack(alignment: .bottomTrailing) {
                    if let data = character.profileImageData,
                       let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 200, height: 200)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(theme.backgroundTertiary)
                            .frame(width: 200, height: 200)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 80))
                                    .foregroundColor(theme.textSecondary.opacity(0.5))
                            )
                    }
                    
                    // Edit badge - only show when no image
                    if character.profileImageData == nil {
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
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            // Settings button aligned with top of profile image
            Button {
                onOpenSettings()
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(theme.primary)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(theme.primary.opacity(0.12))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: theme.cornerRadiusMedium)
                .fill(theme.backgroundSecondary)
        )
        .shadow(color: theme.shadow.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    // MARK: - Info Card (Bio)
    
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
            // Name Section (only visible when editing)
            if isEditingInfo {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Name")
                        .font(.subheadline.weight(.semibold))
                        .fontDesign(theme.fontDesign)
                        .foregroundColor(theme.textPrimary)
                    
                    ThemedTextField(
                        placeholder: "Character name",
                        text: $character.name,
                        characterThemeId: character.characterThemeId
                    )
                }
                
                ThemedDivider()
            }
            
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
                        fontSize: 14,
                        characterThemeId: character.characterThemeId
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
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
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
                        ThemedTextField(placeholder: "e.g. Character Reference", text: $newLinkTitle, characterThemeId: character.characterThemeId)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("URL")
                            .font(.caption.weight(.medium))
                            .foregroundColor(theme.textSecondary)
                        ThemedTextField(placeholder: "https://...", text: $newLinkURL, characterThemeId: character.characterThemeId)
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
                Text("Tap + to add reference links")
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
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

                }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: theme.cornerRadiusMedium)
                .fill(theme.backgroundSecondary)
        )
        .shadow(color: theme.shadow.opacity(0.06), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Prompts Card
    
    private var promptsCard: some View {
        let theme = characterTheme
        
        return VStack(alignment: .leading, spacing: 12) {
            // Header with create button
            HStack {
                Text("Prompts")
                    .font(.subheadline.weight(.semibold))
                    .fontDesign(theme.fontDesign)
                    .foregroundColor(theme.textPrimary)
                
                Spacer()
                
                Button {
                    onCreatePrompt()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .semibold))
                        Text("New")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundColor(theme.textOnPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(theme.primary)
                    )
                }
                .buttonStyle(.plain)
            }
            
            if character.prompts.isEmpty {
                Text("No prompts yet. Tap + New to create one.")
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
            } else {
                // Use List for swipe actions support
                let maxHeight: CGFloat = character.prompts.count > 5 ? 280 : CGFloat(character.prompts.count * 56 + 8)
                
                List {
                    ForEach(Array(character.prompts.enumerated()), id: \.element.id) { index, prompt in
                        promptRowContent(index: index, prompt: prompt, theme: theme)
                            .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    deletePromptIndex = index
                                    showingDeleteConfirm = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                
                                Button {
                                    duplicatePromptIndex = index
                                    duplicatePromptName = "\(prompt.title) (Copy)"
                                    showingDuplicateAlert = true
                                } label: {
                                    Label("Duplicate", systemImage: "doc.on.doc")
                                }
                                .tint(theme.primary)
                            }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .frame(height: maxHeight)
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
    
    private func promptRowContent(index: Int, prompt: SavedPrompt, theme: ResolvedTheme) -> some View {
        Button {
            onPromptTap(index)
        } label: {
            HStack(spacing: 12) {
                // Prompt icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(theme.primary.opacity(0.12))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "doc.text")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(theme.primary)
                }
                
                // Prompt info
                VStack(alignment: .leading, spacing: 2) {
                    Text(prompt.title.isEmpty ? "Untitled Prompt" : prompt.title)
                        .font(.subheadline.weight(.medium))
                        .fontDesign(theme.fontDesign)
                        .foregroundColor(theme.textPrimary)
                        .lineLimit(1)
                    
                    if !prompt.images.isEmpty {
                        Text("\(prompt.images.count) image\(prompt.images.count == 1 ? "" : "s")")
                            .font(.caption2)
                            .foregroundColor(theme.textSecondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.medium))
                    .foregroundColor(theme.textSecondary)
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: theme.cornerRadiusSmall)
                    .fill(theme.backgroundTertiary)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Profile Image Viewer

/// Full-screen viewer for profile image with replace option
struct ProfileImageViewer: View {
    let imageData: Data?
    let characterName: String
    let onReplace: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        let theme = themeManager.resolved
        
        ZStack {
            Color.black.ignoresSafeArea()
            
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
                    
                    Text(characterName)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Share button
                    if let data = imageData, let uiImage = UIImage(data: data) {
                        ShareLink(item: Image(uiImage: uiImage), preview: SharePreview(characterName, image: Image(uiImage: uiImage))) {
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
                
                // Image
                if let data = imageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(16)
                } else {
                    Spacer()
                    Text("No image")
                        .foregroundColor(.white.opacity(0.5))
                    Spacer()
                }
                
                // Bottom action card
                VStack(spacing: 12) {
                    Button {
                        onReplace()
                    } label: {
                        HStack {
                            Image(systemName: "photo.badge.arrow.down")
                                .foregroundColor(theme.primary)
                            Text("Replace Profile Image")
                                .font(.headline)
                                .foregroundColor(.white)
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
