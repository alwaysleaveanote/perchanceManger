import SwiftUI
import UIKit

struct CharacterDetailView: View {
    @Binding var character: CharacterProfile
    let openGenerator: (String) -> Void

    @EnvironmentObject var presetStore: PromptPresetStore
    @Environment(\.dismiss) private var dismiss

    @State private var isSidebarVisible: Bool = false
    @State private var selectedPromptIndex: Int? = nil

    // Character-wide gallery
    @State private var showingGallery: Bool = false
    @State private var galleryStartIndex: Int = 0

    // Editing mode for overview (bio + notes)
    @State private var isEditingCharacterInfo: Bool = false


    var body: some View {
        ZStack {

            // Main scroll content
            mainScrollView

            // Sidebar overlay
            if isSidebarVisible {
                Color.black.opacity(0.25)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isSidebarVisible = false
                        }
                    }

                HStack {
                    Spacer()
                    sidebar
                        .frame(width: 260)
                        .padding(.trailing, 8)
                        .transition(.move(edge: .trailing))
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Leading: Edit Character Info (only on overview)

            // Trailing: Sidebar toggle
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isSidebarVisible.toggle()
                    }
                } label: {
                    Image(systemName: isSidebarVisible ? "line.3.horizontal.decrease" : "line.3.horizontal")
                }
                .accessibilityLabel("Toggle saved prompts sidebar")
            }

            // Keyboard toolbar (unchanged)
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    KeyboardHelper.dismiss()
                }
            }
        }
        .sheet(isPresented: $showingGallery) {
            GalleryView(
                images: allPromptImages(),
                startIndex: galleryStartIndex
            )
        }

    }

    // MARK: - Main Scroll View

    private var mainScrollView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {

                mainColumn
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding(.horizontal)
            .padding(.vertical, 16)
        }
    }

    // MARK: - Main column

    private var mainColumn: some View {
        Group {
            if let idx = selectedPromptIndex,
               character.prompts.indices.contains(idx) {
                PromptEditorView(
                    character: $character,
                    promptIndex: idx,
                    openGenerator: openGenerator,
                    onDelete: {
                        // Safely remove this prompt and update selection
                        if character.prompts.indices.contains(idx) {
                            character.prompts.remove(at: idx)
                                selectedPromptIndex = nil
                        } else {
                            selectedPromptIndex = nil
                        }
                    }
                )
            } else {
                CharacterOverviewView(
                    character: $character,
                    allImages: allPromptImages(),
                    onImageTap: { index in
                        galleryStartIndex = index
                        showingGallery = true
                    },
                    isEditingInfo: $isEditingCharacterInfo
                )
            }
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: {
                // Helper to get the effective default for this character:
                // 1) character-specific default if set
                // 2) otherwise global default
                func effectiveDefault(_ key: GlobalDefaultKey) -> String? {
                    character.characterDefaults[key]?.nonEmpty
                        ?? presetStore.globalDefaults[key]?.nonEmpty
                }

                let newPrompt = SavedPrompt(
                    title: "New Prompt",
                    text: "",
                    physicalDescription: effectiveDefault(.physicalDescription),
                    outfit:              effectiveDefault(.outfit),
                    pose:                effectiveDefault(.pose),
                    environment:         effectiveDefault(.environment),
                    lighting:            effectiveDefault(.lighting),
                    styleModifiers:      effectiveDefault(.style),
                    technicalModifiers:  effectiveDefault(.technical),
                    negativePrompt:      effectiveDefault(.negative)
                )

                character.prompts.append(newPrompt)
                selectedPromptIndex = character.prompts.count - 1

                withAnimation {
                    isSidebarVisible = false
                }
            })
 {
                Text("Create New Prompt")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            Divider()

            DisclosureGroup(
                isExpanded: .constant(true),
                content: {
                    if character.prompts.isEmpty {
                        Text("No saved prompts yet.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    } else {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(character.prompts.indices, id: \.self) { index in
                                let prompt = character.prompts[index]
                                Button {
                                    selectedPromptIndex = index
                                    withAnimation {
                                        isSidebarVisible = false
                                    }
                                } label: {
                                    HStack {
                                        Text(prompt.title.isEmpty ? "Untitled Prompt" : prompt.title)
                                            .font(.subheadline)
                                            .foregroundColor(
                                                selectedPromptIndex == index ? .accentColor : .primary
                                            )
                                        Spacer()
                                    }
                                    .padding(.vertical, 4)
                                    .padding(.leading, 12) // indent the list
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.top, 4)
                    }
                },
                label: {
                    Text("Saved Prompts")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            )
            
            // 🔹 NEW: Character Settings link
            NavigationLink {
                CharacterSettingsView(character: $character)
                    .environmentObject(presetStore)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "gearshape")
                    Text("Character Settings")
                }
                .font(.subheadline.weight(.semibold))
                .padding(.top, 12)
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding(12)
        .frame(maxHeight: .infinity, alignment: .top)  // ⬅️ stretch to full height
        .background(
            Color(.secondarySystemBackground)           // ⬅️ full-height panel
        )
    }

    // MARK: - Images collection (character-wide)

    private func allPromptImages() -> [PromptImage] {
        var images = character.prompts.flatMap { $0.images }

        // Include profile image as part of the gallery (first)
        if let data = character.profileImageData {
            images.insert(PromptImage(id: UUID(), data: data), at: 0)
        }

        return images
    }
}

//////////////////////////////////////////////////////////////
// MARK: - Overview View
//////////////////////////////////////////////////////////////

struct CharacterOverviewView: View {
    @Binding var character: CharacterProfile

    let allImages: [PromptImage]
    let onImageTap: (Int) -> Void

    @Binding var isEditingInfo: Bool

    @State private var newLinkTitle: String = ""
    @State private var newLinkURL: String = ""
    @State private var showAddLinkForm: Bool = false
    @State private var showingProfileImagePicker: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Top row: profile image + main info
            HStack(alignment: .center, spacing: 16) {
                profileImageSection
                mainInfoSection
            }

            Divider()

            linksSection

            Divider()
            gallerySection

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

    // MARK: Profile image

    private var profileImageSection: some View {
        VStack(alignment: .center, spacing: 8) {
            Button {
                showingProfileImagePicker = true
            } label: {
                ZStack {
                    if let data = character.profileImageData,
                       let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .clipped()
                    } else {
                        Circle()
                            .fill(Color(.secondarySystemBackground))
                            .frame(width: 120, height: 120)
                            .overlay(
                                Image(systemName: "person.crop.circle")
                                    .font(.system(size: 50))
                                    .foregroundColor(.secondary)
                            )
                    }

                    Circle()
                        .strokeBorder(Color.accentColor.opacity(0.4), lineWidth: 2)
                        .frame(width: 120, height: 120)
                }
            }
            .buttonStyle(.plain)

            Text("Tap to set profile image")
                .font(.caption)
                .foregroundColor(.secondary)

            // ⬇️ New: edit toggle lives under the avatar
            Button(action: {
                withAnimation {
                    isEditingInfo.toggle()
                }
            }) {
                Text(isEditingInfo ? "Done Editing Info" : "Edit Character Info")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.accentColor.opacity(0.15))
                    .foregroundColor(.accentColor)
                    .clipShape(Capsule())
            }
            .padding(.top, 4)
        }
        .frame(width: 160) // a bit wider to comfortably fit the button
    }

    // MARK: Main info (bio, notes)

    private var mainInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Bio
            VStack(alignment: .leading, spacing: 8) {
                Text("Bio")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                if isEditingInfo {
                    DynamicGrowingTextEditor(
                        text: $character.bio,
                        placeholder: "Character bio / description",
                        minLines: 2,
                        maxLines: 6
                    )
                } else {
                    if character.bio.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("No bio yet.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        ScrollView {
                            Text(character.bio)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.trailing, 4) // small padding so scrollbar doesn't overlap text
                        }
                        .frame(maxHeight: 120) // ≈ 6 lines
                        .scrollIndicators(.automatic)
                    }
                }
            }


            // Notes
            VStack(alignment: .leading, spacing: 8) {
                Text("Notes")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                if isEditingInfo {
                    DynamicGrowingTextEditor(
                        text: $character.notes,
                        placeholder: "Any extra notes about this character",
                        minLines: 1,
                        maxLines: 6
                    )
                } else {
                    if character.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("No notes yet.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        ScrollView {
                            Text(character.notes)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.trailing, 4)
                        }
                        .frame(maxHeight: 120) // ≈ 6 lines
                        .scrollIndicators(.automatic)
                    }
                }
            }

        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    // MARK: Links section

    private var linksSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Related Links")
                .font(.headline)

            if character.links.isEmpty {
                Text("No related links yet.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(character.links) { link in
                        HStack(spacing: 8) {

                            // Existing link display
                            if let url = URL(string: link.urlString) {
                                Link(destination: url) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "link")
                                        Text(link.title.isEmpty ? link.urlString : link.title)
                                            .lineLimit(1)
                                            .truncationMode(.tail)
                                    }
                                }
                            } else {
                                HStack(spacing: 6) {
                                    Image(systemName: "exclamationmark.triangle")
                                        .foregroundColor(.yellow)
                                    Text(link.title.isEmpty ? link.urlString : link.title)
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                }
                            }

                            Spacer(minLength: 8)

                            // 🔴 New: delete button
                            Button {
                                removeLink(link)
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
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

                    // 🔹 Title field with placeholder
                    ZStack(alignment: .leading) {
                        if newLinkTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text("Link title")
                                .foregroundColor(.secondary)
                                .padding(.leading, 6)
                        }
                        DynamicGrowingTextEditor(
                            text: $newLinkTitle,
                            placeholder: "",
                            minLines: 1,
                            maxLines: 1
                        )
                    }
                    .frame(minWidth: 80)

                    // 🔹 URL field with placeholder
                    ZStack(alignment: .leading) {
                        if newLinkURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text("https://example.com")
                                .foregroundColor(.secondary)
                                .padding(.leading, 6)
                        }
                        DynamicGrowingTextEditor(
                            text: $newLinkURL,
                            placeholder: "",
                            minLines: 1,
                            maxLines: 1
                        )
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                    }

                    // Save button
                    Button {
                        addLink()
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                    }
                    .disabled(newLinkURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    // Cancel button
                    Button {
                        newLinkTitle = ""
                        newLinkURL = ""
                        withAnimation {
                            showAddLinkForm = false
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                    }
                }
                .font(.subheadline)
            }
 else {
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
                }
            }
        }
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

    // MARK: Gallery section

    private var gallerySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Image Gallery")
                .font(.headline)

            if allImages.isEmpty {
                Text("No images have been uploaded for this character yet. Profile image and images attached to prompts will appear here.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(allImages.enumerated()), id: \.element.id) { index, promptImage in
                            if let uiImage = UIImage(data: promptImage.data) {
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
                }

                Text("Tap an image to view full-screen and swipe through all attached images.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

//////////////////////////////////////////////////////////////
// MARK: - Prompt Editor View
//////////////////////////////////////////////////////////////

struct PromptEditorView: View {
    @Binding var character: CharacterProfile
    let promptIndex: Int
    let openGenerator: (String) -> Void
    let onDelete: () -> Void
    @State private var showingDeleteConfirm: Bool = false

    @EnvironmentObject var presetStore: PromptPresetStore

    // Per-prompt gallery & picker
    @State private var showingPromptGallery: Bool = false
    @State private var promptGalleryStartIndex: Int = 0
    @State private var showingPromptImagePicker: Bool = false
    
    // 🔹 New: state for creating presets from section text
    @State private var isShowingPresetSaveAlert: Bool = false
    @State private var pendingPresetKind: PromptSectionKind? = nil
    @State private var pendingPresetText: String = ""
    @State private var pendingPresetLabel: String = ""
    @State private var pendingPresetNameInput: String = ""


    private var promptBinding: Binding<SavedPrompt> {
        Binding(
            get: { character.prompts[promptIndex] },
            set: { character.prompts[promptIndex] = $0 }
        )
    }

    private var prompt: SavedPrompt {
        promptBinding.wrappedValue
    }
    
    
    // Start the "save as preset" flow for a section
    private func beginSavingPreset(
        from text: String,
        kind: PromptSectionKind,
        label: String
    ) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        pendingPresetText = trimmed
        pendingPresetKind = kind
        pendingPresetLabel = label
        pendingPresetNameInput = label   // default suggestion
        isShowingPresetSaveAlert = true
    }

    // After we add a preset, re-run detection so "Using: X" appears immediately
    private func resyncAllPresetMarkers() {
        updatePresetNameForCurrentText(
            kind: .physicalDescription,
            text: physicalDescriptionBinding,
            presetName: physicalDescriptionPresetNameBinding
        )
        updatePresetNameForCurrentText(
            kind: .outfit,
            text: outfitBinding,
            presetName: outfitPresetNameBinding
        )
        updatePresetNameForCurrentText(
            kind: .pose,
            text: poseBinding,
            presetName: posePresetNameBinding
        )
        updatePresetNameForCurrentText(
            kind: .environment,
            text: environmentBinding,
            presetName: environmentPresetNameBinding
        )
        updatePresetNameForCurrentText(
            kind: .lighting,
            text: lightingBinding,
            presetName: lightingPresetNameBinding
        )
        updatePresetNameForCurrentText(
            kind: .style,
            text: styleModifiersBinding,
            presetName: stylePresetNameBinding
        )
        updatePresetNameForCurrentText(
            kind: .technical,
            text: technicalModifiersBinding,
            presetName: technicalPresetNameBinding
        )
        updatePresetNameForCurrentText(
            kind: .negative,
            text: negativePromptBinding,
            presetName: negativePresetNameBinding
        )
    }

    // MARK: - Preset detection helper

    private func updatePresetNameForCurrentText(
        kind: PromptSectionKind,
        text: Binding<String>,
        presetName: Binding<String?>
    ) {
        let presets = presetStore.presets(of: kind)
        let trimmed = text.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines)

        // If text is empty, clear any preset info
        guard !trimmed.isEmpty else {
            if presetName.wrappedValue != nil {
                presetName.wrappedValue = nil
            }
            return
        }

        // If we already have a presetName and it still matches exactly, keep it
        if let currentName = presetName.wrappedValue,
           let currentPreset = presets.first(where: { $0.name == currentName }),
           currentPreset.text.trimmingCharacters(in: .whitespacesAndNewlines) == trimmed {
            return
        }

        // Otherwise, see if any preset text matches exactly
        if let match = presets.first(where: {
            $0.text.trimmingCharacters(in: .whitespacesAndNewlines) == trimmed
        }) {
            presetName.wrappedValue = match.name
        } else if presetName.wrappedValue != nil {
            // Text no longer matches any preset → clear the marker
            presetName.wrappedValue = nil
        }
    }


    private var composedPrompt: String {
        PromptComposer.composePrompt(
            character: character,
            prompt: promptBinding.wrappedValue,
            stylePreset: nil,
            globalDefaults: presetStore.globalDefaults
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            // Title + open button (restyled)
            VStack(alignment: .leading, spacing: 8) {
                // Title label + inline editable title
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Prompt title")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        TextField("Untitled prompt", text: titleBinding)
                            .font(.title3.weight(.semibold))
                            .textFieldStyle(.plain)
                    }

                    Spacer()
                }

                // Open Generator button, separated from the title
                imagesSection
            }

            


            
            // Composed preview (we’ll update this next)
            promptPreviewSection

            // Decomposed sections
            VStack(alignment: .leading, spacing: 12) {
                sectionRow(
                    label: "Physical Description",
                    kind: .physicalDescription,
                    text: physicalDescriptionBinding,
                    presetName: physicalDescriptionPresetNameBinding
                )

                sectionRow(
                    label: "Outfit",
                    kind: .outfit,
                    text: outfitBinding,
                    presetName: outfitPresetNameBinding
                )

                sectionRow(
                    label: "Pose",
                    kind: .pose,
                    text: poseBinding,
                    presetName: posePresetNameBinding
                )

                sectionRow(
                    label: "Environment",
                    kind: .environment,
                    text: environmentBinding,
                    presetName: environmentPresetNameBinding
                )

                sectionRow(
                    label: "Lighting",
                    kind: .lighting,
                    text: lightingBinding,
                    presetName: lightingPresetNameBinding
                )

                sectionRow(
                    label: "Style Modifiers",
                    kind: .style,
                    text: styleModifiersBinding,
                    presetName: stylePresetNameBinding
                )

                sectionRow(
                    label: "Technical Modifiers",
                    kind: .technical,
                    text: technicalModifiersBinding,
                    presetName: technicalPresetNameBinding
                )

                sectionRow(
                    label: "Negative Prompt",
                    kind: .negative,
                    text: negativePromptBinding,
                    presetName: negativePresetNameBinding
                )

                // Additional Information
                VStack(alignment: .leading, spacing: 4) {
                    Text("Additional Information")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    DynamicGrowingTextEditor(
                        text: additionalInfoBinding,
                        placeholder: "Any extra details that don't fit in other sections",
                        minLines: 0,
                        maxLines: 5
                    )
                }
            }

            Spacer(minLength: 0)
            HStack(spacing: 16) {
                Spacer()

                Button {
                    openGeneratorForCurrentPrompt()
                } label: {
                    Label("Open Generator", systemImage: "sparkles")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)

                Button(role: .destructive) {
                    showingDeleteConfirm = true
                } label: {
                    Label("Delete Prompt", systemImage: "trash")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)

                Spacer()
            }
        }
        .alert("Delete this prompt?", isPresented: $showingDeleteConfirm) {
            Button("Delete", role: .destructive) {
                onDelete()
            }
            Button("Cancel", role: .cancel) { }
        }
        .sheet(isPresented: $showingPromptImagePicker) {
            ImagePicker { uiImages in
                var updated = promptBinding.wrappedValue
                for image in uiImages {
                    if let data = image.jpegData(compressionQuality: 0.9) {
                        updated.images.append(
                            PromptImage(id: UUID(), data: data)
                        )
                    }
                }
                promptBinding.wrappedValue = updated
            }
        }
        // 🔽 (Optional but already wired via showingPromptGallery)
        .fullScreenCover(isPresented: $showingPromptGallery) {
            GalleryView(
                images: promptBinding.wrappedValue.images,
                startIndex: promptGalleryStartIndex
            )
        }
        .alert("Save as preset", isPresented: $isShowingPresetSaveAlert) {
            TextField("Preset name", text: $pendingPresetNameInput)

            Button("Save") {
                let nameTrimmed = pendingPresetNameInput
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                let finalName = nameTrimmed.isEmpty
                    ? pendingPresetLabel
                    : nameTrimmed

                if let kind = pendingPresetKind {
                    presetStore.addPreset(
                        kind: kind,
                        name: finalName,
                        text: pendingPresetText
                    )
                    // Immediately refresh the "Using: ..." markers
                    resyncAllPresetMarkers()
                }

                // Reset state
                pendingPresetKind = nil
                pendingPresetText = ""
                pendingPresetLabel = ""
                pendingPresetNameInput = ""
            }

            Button("Cancel", role: .cancel) {
                pendingPresetKind = nil
                pendingPresetText = ""
                pendingPresetLabel = ""
                pendingPresetNameInput = ""
            }
        } message: {
            Text("Save the current text as a reusable preset for this section.")
        }

    }
    
    private func openGeneratorForCurrentPrompt() {
        // Character-level generator takes precedence; then global; then fallback.
        let slug = character.characterDefaultPerchanceGenerator?.nonEmpty
            ?? presetStore.defaultPerchanceGenerator.nonEmpty
            ?? "furry-ai"

        let urlString = "https://perchance.org/\(slug)"
        guard let url = URL(string: urlString) else { return }

        // Copy prompt for convenience
        UIPasteboard.general.string = composedPrompt

        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }


    private var promptPreviewSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Prompt Preview")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                Button {
                    UIPasteboard.general.string = composedPrompt
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.on.doc")
                        Text("Copy")
                    }
                    .font(.caption)
                }
            }

            ZStack {
                // Background + border
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.secondarySystemBackground))
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)

                // Scrollable text with nice padding
                ScrollView {
                    Text(composedPrompt)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .padding(12)
                }
            }
            .frame(height: 250) // fixed preview height
        }
    }




    // MARK: - Bindings

    private var titleBinding: Binding<String> {
        Binding(
            get: { promptBinding.wrappedValue.title },
            set: { promptBinding.wrappedValue.title = $0 }
        )
    }

    private var textBinding: Binding<String> {
        Binding(
            get: { promptBinding.wrappedValue.text },
            set: { promptBinding.wrappedValue.text = $0 }
        )
    }
    
    private var physicalDescriptionBinding: Binding<String> {
        Binding(
            get: { promptBinding.wrappedValue.physicalDescription ?? "" },
            set: { promptBinding.wrappedValue.physicalDescription = $0 }
        )
    }


    private var outfitBinding: Binding<String> {
        Binding(
            get: { promptBinding.wrappedValue.outfit ?? "" },
            set: { promptBinding.wrappedValue.outfit = $0 }
        )
    }

    private var poseBinding: Binding<String> {
        Binding(
            get: { promptBinding.wrappedValue.pose ?? "" },
            set: { promptBinding.wrappedValue.pose = $0 }
        )
    }

    private var environmentBinding: Binding<String> {
        Binding(
            get: { promptBinding.wrappedValue.environment ?? "" },
            set: { promptBinding.wrappedValue.environment = $0 }
        )
    }

    private var lightingBinding: Binding<String> {
        Binding(
            get: { promptBinding.wrappedValue.lighting ?? "" },
            set: { promptBinding.wrappedValue.lighting = $0 }
        )
    }

    private var styleModifiersBinding: Binding<String> {
        Binding(
            get: { promptBinding.wrappedValue.styleModifiers ?? "" },
            set: { promptBinding.wrappedValue.styleModifiers = $0 }
        )
    }

    private var technicalModifiersBinding: Binding<String> {
        Binding(
            get: { promptBinding.wrappedValue.technicalModifiers ?? "" },
            set: { promptBinding.wrappedValue.technicalModifiers = $0 }
        )
    }

    private var negativePromptBinding: Binding<String> {
        Binding(
            get: { promptBinding.wrappedValue.negativePrompt ?? "" },
            set: { promptBinding.wrappedValue.negativePrompt = $0 }
        )
    }

    private var additionalInfoBinding: Binding<String> {
        Binding(
            get: { promptBinding.wrappedValue.additionalInfo ?? "" },
            set: { promptBinding.wrappedValue.additionalInfo = $0 }
        )
    }
    
    private var physicalDescriptionPresetNameBinding: Binding<String?> {
        Binding(
            get: { promptBinding.wrappedValue.physicalDescriptionPresetName },
            set: { promptBinding.wrappedValue.physicalDescriptionPresetName = $0 }
        )
    }

    private var outfitPresetNameBinding: Binding<String?> {
        Binding(
            get: { promptBinding.wrappedValue.outfitPresetName },
            set: { promptBinding.wrappedValue.outfitPresetName = $0 }
        )
    }

    private var posePresetNameBinding: Binding<String?> {
        Binding(
            get: { promptBinding.wrappedValue.posePresetName },
            set: { promptBinding.wrappedValue.posePresetName = $0 }
        )
    }

    private var environmentPresetNameBinding: Binding<String?> {
        Binding(
            get: { promptBinding.wrappedValue.environmentPresetName },
            set: { promptBinding.wrappedValue.environmentPresetName = $0 }
        )
    }

    private var lightingPresetNameBinding: Binding<String?> {
        Binding(
            get: { promptBinding.wrappedValue.lightingPresetName },
            set: { promptBinding.wrappedValue.lightingPresetName = $0 }
        )
    }

    private var stylePresetNameBinding: Binding<String?> {
        Binding(
            get: { promptBinding.wrappedValue.stylePresetName },
            set: { promptBinding.wrappedValue.stylePresetName = $0 }
        )
    }

    private var technicalPresetNameBinding: Binding<String?> {
        Binding(
            get: { promptBinding.wrappedValue.technicalPresetName },
            set: { promptBinding.wrappedValue.technicalPresetName = $0 }
        )
    }

    private var negativePresetNameBinding: Binding<String?> {
        Binding(
            get: { promptBinding.wrappedValue.negativePresetName },
            set: { promptBinding.wrappedValue.negativePresetName = $0 }
        )
    }

    // MARK: - Section row with presets

    private func sectionRow(
        label: String,
        kind: PromptSectionKind,
        text: Binding<String>,
        presetName: Binding<String?>
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                let presets = presetStore.presets(of: kind)
                let trimmed = text.wrappedValue
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                // Existing: Apply menu for known presets
                if !presets.isEmpty {
                    Menu {
                        ForEach(presets) { preset in
                            Button {
                                text.wrappedValue = preset.text
                                presetName.wrappedValue = preset.name
                            } label: {
                                Text(preset.name)
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                            Text("Apply")
                        }
                        .font(.caption)
                    }
                }

                // Show either "Using: <preset>" *or* a "Save as preset" button
                if let name = presetName.wrappedValue, !name.isEmpty {
                    Text("(Using: \(name))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if !trimmed.isEmpty {
                    Button {
                        beginSavingPreset(
                            from: text.wrappedValue,
                            kind: kind,
                            label: label
                        )
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "star.badge.plus")
                            Text("Save as preset")
                        }
                        .font(.caption)
                    }
                }

                Spacer()
            }

            DynamicGrowingTextEditor(
                text: text,
                placeholder: "Optional \(label.lowercased()) details",
                minLines: 0,
                maxLines: 5
            )
            .onAppear {
                // Initial detection when the row first appears
                updatePresetNameForCurrentText(
                    kind: kind,
                    text: text,
                    presetName: presetName
                )
            }
            .onChange(of: text.wrappedValue) { _, _ in
                // Keep matching / clearing as the user types
                updatePresetNameForCurrentText(
                    kind: kind,
                    text: text,
                    presetName: presetName
                )
            }
        }
    }

    // MARK: - Images section (per prompt)

    private var imagesSection: some View {
        VStack(alignment: .leading, spacing: 12) {

            Text("Images")
                .font(.subheadline)
                .fontWeight(.semibold)

            // --- Carousel ---
            if promptBinding.wrappedValue.images.isEmpty {
                Text("No images yet. Upload some!")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(promptBinding.wrappedValue.images.enumerated()), id: \.element.id) { index, img in
                            if let uiImage = UIImage(data: img.data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .onTapGesture {
                                        promptGalleryStartIndex = index
                                        showingPromptGallery = true
                                    }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            // --- Upload button BELOW the carousel ---
            Button {
                showingPromptImagePicker = true
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

//////////////////////////////////////////////////////////////
// MARK: - Gallery View
//////////////////////////////////////////////////////////////

struct GalleryView: View {
    let images: [PromptImage]
    let startIndex: Int

    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex: Int = 0

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                if images.isEmpty {
                    Text("No images")
                        .foregroundColor(.white)
                } else {
                    TabView(selection: $currentIndex) {
                        ForEach(Array(images.enumerated()), id: \.element.id) { index, promptImage in
                            if let uiImage = UIImage(data: promptImage.data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .tag(index)
                            }
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .automatic))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // 🔹 Add the global keyboard toolbar
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        KeyboardHelper.dismiss()
                    }
                }
            }
        }
        .onAppear {
            currentIndex = min(max(startIndex, 0), max(images.count - 1, 0))
        }
    }
}
