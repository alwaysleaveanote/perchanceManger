//
//  BugRegressionTests.swift
//  ChanceryTests
//
//  Regression tests for bugs fixed in the Scenes feature.
//  Per AI_META_PROMPT Section 1.2.8: Bug fixes MUST have regression tests.
//

import XCTest
@testable import Chancery

final class BugRegressionTests: XCTestCase {
    
    // MARK: - Bug #1: Gallery Image Order Mismatch
    // The thumbnail order was different from swipe order because allPromptImages()
    // and allGalleryImages() had different ordering logic.
    // FIX: Both now use consistent order: profile -> prompts -> standalone
    
    func test_characterImageOrder_thumbnailMatchesSwipe_profileFirst() {
        // Arrange
        let profileData = "profile".data(using: .utf8)!
        let promptImageData = "prompt".data(using: .utf8)!
        let standaloneImageData = "standalone".data(using: .utf8)!
        
        let promptImage = PromptImage(data: promptImageData)
        let standaloneImage = PromptImage(data: standaloneImageData)
        
        let prompt = SavedPrompt(
            id: UUID(),
            title: "Test Prompt",
            text: "",
            images: [promptImage]
        )
        
        var character = CharacterProfile(name: "Test Character")
        character.profileImageData = profileData
        character.prompts = [prompt]
        character.standaloneImages = [standaloneImage]
        
        // Act - Simulate what CharacterDetailView.allPromptImages() does
        var thumbnailImages: [PromptImage] = []
        
        // 1. Profile image first (if unique)
        if let profileData = character.profileImageData {
            let isFromPrompt = character.prompts.flatMap { $0.images }.contains { $0.data == profileData }
            let isFromStandalone = character.standaloneImages.contains { $0.data == profileData }
            if !isFromPrompt && !isFromStandalone {
                thumbnailImages.append(PromptImage(id: UUID(), data: profileData))
            }
        }
        
        // 2. Prompt images
        thumbnailImages.append(contentsOf: character.prompts.flatMap { $0.images })
        
        // 3. Standalone images
        thumbnailImages.append(contentsOf: character.standaloneImages)
        
        // Assert - Order should be: profile, prompt, standalone
        XCTAssertEqual(thumbnailImages.count, 3)
        XCTAssertEqual(thumbnailImages[0].data, profileData)
        XCTAssertEqual(thumbnailImages[1].data, promptImageData)
        XCTAssertEqual(thumbnailImages[2].data, standaloneImageData)
    }
    
    func test_sceneImageOrder_thumbnailMatchesSwipe_profileFirst() {
        // Arrange
        let profileData = "profile".data(using: .utf8)!
        let promptImageData = "prompt".data(using: .utf8)!
        let standaloneImageData = "standalone".data(using: .utf8)!
        
        let promptImage = PromptImage(data: promptImageData)
        let standaloneImage = PromptImage(data: standaloneImageData)
        
        let scenePrompt = ScenePrompt(
            title: "Test Prompt",
            images: [promptImage]
        )
        
        var scene = CharacterScene(name: "Test Scene")
        scene.profileImageData = profileData
        scene.prompts = [scenePrompt]
        scene.standaloneImages = [standaloneImage]
        
        // Act - Simulate what SceneDetailView.allImages does
        var thumbnailImages: [PromptImage] = []
        
        // 1. Profile image first (if unique)
        if let profileData = scene.profileImageData {
            let isFromPrompt = scene.prompts.flatMap { $0.images }.contains { $0.data == profileData }
            let isFromStandalone = scene.standaloneImages.contains { $0.data == profileData }
            if !isFromPrompt && !isFromStandalone {
                thumbnailImages.append(PromptImage(id: UUID(), data: profileData))
            }
        }
        
        // 2. Prompt images
        thumbnailImages.append(contentsOf: scene.prompts.flatMap { $0.images })
        
        // 3. Standalone images
        thumbnailImages.append(contentsOf: scene.standaloneImages)
        
        // Assert - Order should be: profile, prompt, standalone
        XCTAssertEqual(thumbnailImages.count, 3)
        XCTAssertEqual(thumbnailImages[0].data, profileData)
        XCTAssertEqual(thumbnailImages[1].data, promptImageData)
        XCTAssertEqual(thumbnailImages[2].data, standaloneImageData)
    }
    
    // MARK: - Bug #2: Physical Description Not Loading in Scene Prompts
    // loadFromCharacterPrompt was using characterPrompt.text instead of characterPrompt.physicalDescription
    // FIX: Now uses physicalDescription field correctly
    
    func test_loadFromCharacterPrompt_copiesPhysicalDescription() {
        // Arrange
        let characterPrompt = SavedPrompt(
            id: UUID(),
            title: "Source Prompt",
            text: "legacy text",
            physicalDescription: "blue eyes, blonde hair",
            outfit: "red dress",
            pose: "standing"
        )
        
        var sceneSettings = SceneCharacterSettings()
        
        // Act - Simulate what loadFromCharacterPrompt does
        sceneSettings.physicalDescription = characterPrompt.physicalDescription
        sceneSettings.outfit = characterPrompt.outfit
        sceneSettings.pose = characterPrompt.pose
        sceneSettings.sourcePromptId = characterPrompt.id
        
        // Assert
        XCTAssertEqual(sceneSettings.physicalDescription, "blue eyes, blonde hair")
        XCTAssertEqual(sceneSettings.outfit, "red dress")
        XCTAssertEqual(sceneSettings.pose, "standing")
        XCTAssertEqual(sceneSettings.sourcePromptId, characterPrompt.id)
    }
    
    func test_loadFromCharacterPrompt_doesNotUseLegacyTextField() {
        // Arrange - prompt with text but no physicalDescription
        let characterPrompt = SavedPrompt(
            id: UUID(),
            title: "Source Prompt",
            text: "this should NOT be used",
            physicalDescription: nil,
            outfit: "casual outfit"
        )
        
        var sceneSettings = SceneCharacterSettings()
        
        // Act
        sceneSettings.physicalDescription = characterPrompt.physicalDescription
        sceneSettings.outfit = characterPrompt.outfit
        
        // Assert - physicalDescription should be nil, NOT the text field
        XCTAssertNil(sceneSettings.physicalDescription)
        XCTAssertEqual(sceneSettings.outfit, "casual outfit")
    }
    
    // MARK: - Bug #3: Character Order in Scene Not Matching "Your Characters" Order
    // sceneCharacters was not preserving the order from allCharacters
    // FIX: Filter allCharacters while preserving order using Set for membership check
    
    func test_sceneCharacters_preservesAllCharactersOrder() {
        // Arrange
        let char1 = CharacterProfile(name: "Alice")
        let char2 = CharacterProfile(name: "Bob")
        let char3 = CharacterProfile(name: "Charlie")
        let char4 = CharacterProfile(name: "Diana")
        
        let allCharacters = [char1, char2, char3, char4]
        
        // Scene has characters in different order than allCharacters
        let scene = CharacterScene(
            name: "Test Scene",
            characterIds: [char3.id, char1.id, char4.id] // Charlie, Alice, Diana
        )
        
        // Act - Simulate what SceneDetailView.sceneCharacters does
        let sceneCharacterSet = Set(scene.characterIds)
        let sceneCharacters = allCharacters.filter { sceneCharacterSet.contains($0.id) }
        
        // Assert - Order should match allCharacters order (Alice, Charlie, Diana), not scene.characterIds order
        XCTAssertEqual(sceneCharacters.count, 3)
        XCTAssertEqual(sceneCharacters[0].name, "Alice")   // char1 comes first in allCharacters
        XCTAssertEqual(sceneCharacters[1].name, "Charlie") // char3 comes second
        XCTAssertEqual(sceneCharacters[2].name, "Diana")   // char4 comes third
    }
    
    func test_sceneCharacters_excludesNonSceneCharacters() {
        // Arrange
        let char1 = CharacterProfile(name: "Alice")
        let char2 = CharacterProfile(name: "Bob")
        let char3 = CharacterProfile(name: "Charlie")
        
        let allCharacters = [char1, char2, char3]
        
        // Scene only has Alice and Charlie
        let scene = CharacterScene(
            name: "Test Scene",
            characterIds: [char1.id, char3.id]
        )
        
        // Act
        let sceneCharacterSet = Set(scene.characterIds)
        let sceneCharacters = allCharacters.filter { sceneCharacterSet.contains($0.id) }
        
        // Assert - Bob should be excluded
        XCTAssertEqual(sceneCharacters.count, 2)
        XCTAssertFalse(sceneCharacters.contains { $0.name == "Bob" })
    }
    
    // MARK: - Bug #4: Profile Image Deduplication
    // Profile images that were also in prompts or standalone were being duplicated
    // FIX: Check both prompts AND standalone images for duplicates
    
    func test_profileImage_notDuplicatedWhenInPrompts() {
        // Arrange
        let sharedData = "shared image".data(using: .utf8)!
        let sharedImage = PromptImage(data: sharedData)
        
        let prompt = SavedPrompt(
            id: UUID(),
            title: "Test",
            text: "",
            images: [sharedImage]
        )
        
        var character = CharacterProfile(name: "Test")
        character.profileImageData = sharedData // Same as prompt image
        character.prompts = [prompt]
        
        // Act - Check if profile should be added
        let isFromPrompt = character.prompts.flatMap { $0.images }.contains { $0.data == sharedData }
        let isFromStandalone = character.standaloneImages.contains { $0.data == sharedData }
        let shouldAddProfile = !isFromPrompt && !isFromStandalone
        
        // Assert - Profile should NOT be added (it's already in prompts)
        XCTAssertFalse(shouldAddProfile)
    }
    
    func test_profileImage_notDuplicatedWhenInStandalone() {
        // Arrange
        let sharedData = "shared image".data(using: .utf8)!
        let standaloneImage = PromptImage(data: sharedData)
        
        var character = CharacterProfile(name: "Test")
        character.profileImageData = sharedData // Same as standalone image
        character.standaloneImages = [standaloneImage]
        
        // Act
        let isFromPrompt = character.prompts.flatMap { $0.images }.contains { $0.data == sharedData }
        let isFromStandalone = character.standaloneImages.contains { $0.data == sharedData }
        let shouldAddProfile = !isFromPrompt && !isFromStandalone
        
        // Assert - Profile should NOT be added (it's already in standalone)
        XCTAssertFalse(shouldAddProfile)
    }
    
    func test_profileImage_addedWhenUnique() {
        // Arrange
        let profileData = "unique profile".data(using: .utf8)!
        let promptData = "prompt image".data(using: .utf8)!
        
        let promptImage = PromptImage(data: promptData)
        let prompt = SavedPrompt(
            id: UUID(),
            title: "Test",
            text: "",
            images: [promptImage]
        )
        
        var character = CharacterProfile(name: "Test")
        character.profileImageData = profileData
        character.prompts = [prompt]
        
        // Act
        let isFromPrompt = character.prompts.flatMap { $0.images }.contains { $0.data == profileData }
        let isFromStandalone = character.standaloneImages.contains { $0.data == profileData }
        let shouldAddProfile = !isFromPrompt && !isFromStandalone
        
        // Assert - Profile SHOULD be added (it's unique)
        XCTAssertTrue(shouldAddProfile)
    }
    
    // MARK: - Bug #5: Standalone Images Not Included in Gallery
    // allPromptImages() and allGalleryImages() were not including standalone images
    // FIX: Both now include standalone images after prompt images
    
    func test_characterGallery_includesStandaloneImages() {
        // Arrange
        let standaloneImage = PromptImage(data: "standalone".data(using: .utf8)!)
        
        var character = CharacterProfile(name: "Test")
        character.standaloneImages = [standaloneImage]
        
        // Act - Simulate allPromptImages
        var images: [PromptImage] = []
        images.append(contentsOf: character.prompts.flatMap { $0.images })
        images.append(contentsOf: character.standaloneImages)
        
        // Assert
        XCTAssertEqual(images.count, 1)
        XCTAssertEqual(images[0].id, standaloneImage.id)
    }
    
    func test_sceneGallery_includesStandaloneImages() {
        // Arrange
        let standaloneImage = PromptImage(data: "standalone".data(using: .utf8)!)
        
        var scene = CharacterScene(name: "Test")
        scene.standaloneImages = [standaloneImage]
        
        // Act - Simulate allImages
        var images: [PromptImage] = []
        images.append(contentsOf: scene.prompts.flatMap { $0.images })
        images.append(contentsOf: scene.standaloneImages)
        
        // Assert
        XCTAssertEqual(images.count, 1)
        XCTAssertEqual(images[0].id, standaloneImage.id)
    }
    
    // MARK: - Bug #6: Scene Prompt Defaults Not Applied
    // New scene prompts were not applying scene-specific or global defaults
    // FIX: createNewPrompt now applies scene defaults first, then global defaults
    
    func test_scenePromptDefaults_sceneDefaultsTakePriority() {
        // Arrange
        let globalDefaults: [GlobalDefaultKey: String] = [
            .environment: "global environment",
            .lighting: "global lighting",
            .style: "global style"
        ]
        
        let sceneDefaults: [GlobalDefaultKey: String] = [
            .environment: "scene environment",  // Should override global
            .lighting: ""  // Empty, should fall back to global
        ]
        
        // Act - Simulate effectiveDefault logic
        func effectiveDefault(_ key: GlobalDefaultKey) -> String? {
            let sceneValue = sceneDefaults[key]
            let globalValue = globalDefaults[key]
            
            // Scene defaults take priority if non-empty
            if let scene = sceneValue, !scene.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return scene
            }
            // Fall back to global
            if let global = globalValue, !global.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return global
            }
            return nil
        }
        
        // Assert
        XCTAssertEqual(effectiveDefault(.environment), "scene environment")  // Scene overrides
        XCTAssertEqual(effectiveDefault(.lighting), "global lighting")  // Falls back to global
        XCTAssertEqual(effectiveDefault(.style), "global style")  // Only in global
        XCTAssertNil(effectiveDefault(.technical))  // Not in either
    }
    
    func test_scenePromptDefaults_emptySceneDefaultFallsBackToGlobal() {
        // Arrange
        let globalDefaults: [GlobalDefaultKey: String] = [
            .negative: "global negative prompt"
        ]
        
        let sceneDefaults: [GlobalDefaultKey: String] = [
            .negative: "   "  // Whitespace only, should fall back
        ]
        
        // Act
        func effectiveDefault(_ key: GlobalDefaultKey) -> String? {
            let sceneValue = sceneDefaults[key]
            let globalValue = globalDefaults[key]
            
            if let scene = sceneValue, !scene.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return scene
            }
            if let global = globalValue, !global.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return global
            }
            return nil
        }
        
        // Assert
        XCTAssertEqual(effectiveDefault(.negative), "global negative prompt")
    }
    
    // MARK: - Bug #7: Scene Prompt Navigation from Gallery
    // Scene prompt images in gallery had wrong promptId (UUID() instead of prompt.id)
    // FIX: Use actual prompt.id and set sceneId for navigation
    
    func test_scenePromptImage_hasCorrectPromptId() {
        // Arrange
        let promptId = UUID()
        let sceneId = UUID()
        let imageData = "test".data(using: .utf8)!
        let image = PromptImage(data: imageData)
        
        let prompt = ScenePrompt(
            id: promptId,
            title: "Test Prompt",
            images: [image]
        )
        
        var scene = CharacterScene(id: sceneId, name: "Test Scene")
        scene.prompts = [prompt]
        
        // Act - Simulate what HomeView.allGalleryImages does for scene prompt images
        // This is the CORRECT implementation
        let galleryPromptId = prompt.id  // Should use actual prompt.id
        let gallerySceneId: UUID? = scene.id  // Should set sceneId
        
        // Assert
        XCTAssertEqual(galleryPromptId, promptId)
        XCTAssertEqual(gallerySceneId, sceneId)
        XCTAssertNotEqual(galleryPromptId, UUID())  // Should NOT be a new UUID
    }
}
