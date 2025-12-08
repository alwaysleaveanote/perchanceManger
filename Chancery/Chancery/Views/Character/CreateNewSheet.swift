//
//  CreateNewSheet.swift
//  Chancery
//
//  Sheet for creating a new character or scene.
//

import SwiftUI

struct CreateNewSheet: View {
    let characters: [CharacterProfile]
    let onCreateCharacter: (String) -> Void
    let onCreateScene: (String, [UUID]) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var selectedType: CreateType = .character
    @State private var name: String = ""
    @State private var selectedCharacterIds: Set<UUID> = []
    
    enum CreateType: String, CaseIterable {
        case character = "Character"
        case scene = "Scene"
    }
    
    var body: some View {
        let theme = themeManager.resolved
        
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Type selector
                    typeSelector
                    
                    // Name input
                    VStack(alignment: .leading, spacing: 8) {
                        Text(selectedType == .character ? "Character Name" : "Scene Name")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(theme.textPrimary)
                        
                        TextField(selectedType == .character ? "Enter character name" : "Enter scene name", text: $name)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    // Character selection (for scenes)
                    if selectedType == .scene {
                        characterSelection
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .themedBackground()
            .navigationTitle(selectedType == .character ? "New Character" : "New Scene")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        create()
                    }
                    .disabled(!canCreate)
                }
            }
        }
    }
    
    // MARK: - Type Selector
    
    private var typeSelector: some View {
        let theme = themeManager.resolved
        
        return VStack(alignment: .leading, spacing: 12) {
            Text("What would you like to create?")
                .font(.subheadline.weight(.medium))
                .foregroundColor(theme.textPrimary)
            
            HStack(spacing: 12) {
                typeButton(.character, icon: "person.fill", theme: theme)
                typeButton(.scene, icon: "person.3.fill", theme: theme)
            }
        }
    }
    
    private func typeButton(_ type: CreateType, icon: String, theme: ResolvedTheme) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedType = type
                if type == .character {
                    selectedCharacterIds.removeAll()
                }
            }
        } label: {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(selectedType == type ? theme.primary : theme.primary.opacity(0.12))
                        .frame(width: 48, height: 48)
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(selectedType == type ? theme.textOnPrimary : theme.primary)
                }
                
                Text(type.rawValue)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(selectedType == type ? theme.textPrimary : theme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: theme.cornerRadiusMedium)
                    .fill(selectedType == type ? theme.primary.opacity(0.08) : theme.backgroundTertiary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: theme.cornerRadiusMedium)
                    .stroke(selectedType == type ? theme.primary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Character Selection
    
    private var characterSelection: some View {
        let theme = themeManager.resolved
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Select Characters")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(theme.textPrimary)
                
                Spacer()
                
                Text("\(selectedCharacterIds.count) selected")
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
            }
            
            if characters.isEmpty {
                Text("Create some characters first to add them to a scene.")
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: theme.cornerRadiusSmall)
                            .fill(theme.backgroundTertiary)
                    )
            } else {
                VStack(spacing: 8) {
                    ForEach(characters) { character in
                        characterSelectionRow(character, theme: theme)
                    }
                }
            }
            
            if selectedCharacterIds.count < 2 && !characters.isEmpty {
                Text("Select at least 2 characters for a scene")
                    .font(.caption)
                    .foregroundColor(theme.warning)
            }
        }
    }
    
    private func characterSelectionRow(_ character: CharacterProfile, theme: ResolvedTheme) -> some View {
        let isSelected = selectedCharacterIds.contains(character.id)
        
        return Button {
            if isSelected {
                selectedCharacterIds.remove(character.id)
            } else {
                selectedCharacterIds.insert(character.id)
            }
        } label: {
            HStack(spacing: 12) {
                // Avatar
                Group {
                    if let imageData = character.profileImageData,
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                    } else {
                        ZStack {
                            Circle()
                                .fill(theme.primary.opacity(0.2))
                            Text(String(character.name.prefix(1)).uppercased())
                                .font(.caption.weight(.bold))
                                .foregroundColor(theme.primary)
                        }
                    }
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                
                // Name
                Text(character.name)
                    .font(.subheadline)
                    .foregroundColor(theme.textPrimary)
                
                Spacer()
                
                // Checkbox
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isSelected ? theme.primary : theme.textSecondary)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: theme.cornerRadiusSmall)
                    .fill(isSelected ? theme.primary.opacity(0.08) : theme.backgroundTertiary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: theme.cornerRadiusSmall)
                    .stroke(isSelected ? theme.primary.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Validation
    
    private var canCreate: Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if selectedType == .character {
            return !trimmedName.isEmpty
        } else {
            return !trimmedName.isEmpty && selectedCharacterIds.count >= 2
        }
    }
    
    // MARK: - Actions
    
    private func create() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if selectedType == .character {
            onCreateCharacter(trimmedName)
        } else {
            onCreateScene(trimmedName, Array(selectedCharacterIds))
        }
        
        dismiss()
    }
}
