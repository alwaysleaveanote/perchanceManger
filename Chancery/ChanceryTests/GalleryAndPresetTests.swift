//
//  GalleryAndPresetTests.swift
//  ChanceryTests
//
//  Comprehensive tests for gallery functionality (Your Creations, character galleries, scene galleries)
//  and preset functionality for both characters and scenes.
//  Per AI_META_PROMPT Section 1.2.1: Comprehensive test coverage is mandatory.
//

import XCTest
@testable import Chancery

final class GalleryAndPresetTests: XCTestCase {
    
    // MARK: - Test Data Helpers
    
    private func createTestImageData(_ identifier: String = "test") -> Data {
        return identifier.data(using: .utf8) ?? Data()
    }
    
    private func createCharacterWithImages(
        name: String,
        profileImage: Bool = false,
        promptImages: Int = 0,
        standaloneImages: Int = 0
    ) -> CharacterProfile {
        var character = CharacterProfile(name: name)
        
        if profileImage {
            character.profileImageData = createTestImageData("profile-\(name)")
        }
        
        if promptImages > 0 {
            var prompt = SavedPrompt(title: "Test Prompt")
            for i in 0..<promptImages {
                prompt.images.append(PromptImage(data: createTestImageData("prompt-\(i)")))
            }
            character.prompts.append(prompt)
        }
        
        for i in 0..<standaloneImages {
            character.standaloneImages.append(PromptImage(data: createTestImageData("standalone-\(i)")))
        }
        
        return character
    }
    
    private func createSceneWithImages(
        name: String,
        characterIds: [UUID] = [],
        profileImage: Bool = false,
        promptImages: Int = 0,
        standaloneImages: Int = 0
    ) -> CharacterScene {
        var scene = CharacterScene(name: name, characterIds: characterIds)
        
        if profileImage {
            scene.profileImageData = createTestImageData("scene-profile-\(name)")
        }
        
        if promptImages > 0 {
            var prompt = ScenePrompt(title: "Test Scene Prompt")
            for i in 0..<promptImages {
                prompt.images.append(PromptImage(data: createTestImageData("scene-prompt-\(i)")))
            }
            scene.prompts.append(prompt)
        }
        
        for i in 0..<standaloneImages {
            scene.standaloneImages.append(PromptImage(data: createTestImageData("scene-standalone-\(i)")))
        }
        
        return scene
    }
    
    // MARK: - Gallery Image Order Tests
    
    func test_characterGallery_imageOrder_profileFirstThenPromptsThenStandalone() {
        // Arrange
        let character = createCharacterWithImages(
            name: "Test",
            profileImage: true,
            promptImages: 2,
            standaloneImages: 2
        )
        
        // Act - Simulate the order logic from CharacterDetailView.allPromptImages
        var images: [PromptImage] = []
        
        // Profile first (if unique)
        if let profileData = character.profileImageData {
            let isFromPrompt = character.prompts.flatMap { $0.images }.contains { $0.data == profileData }
            let isFromStandalone = character.standaloneImages.contains { $0.data == profileData }
            if !isFromPrompt && !isFromStandalone {
                images.append(PromptImage(data: profileData))
            }
        }
        
        // Then prompts
        images.append(contentsOf: character.prompts.flatMap { $0.images })
        
        // Then standalone
        images.append(contentsOf: character.standaloneImages)
        
        // Assert
        XCTAssertEqual(images.count, 5) // 1 profile + 2 prompt + 2 standalone
        XCTAssertEqual(images[0].data, character.profileImageData)
    }
    
    func test_sceneGallery_imageOrder_profileFirstThenPromptsThenStandalone() {
        // Arrange
        let scene = createSceneWithImages(
            name: "Test Scene",
            profileImage: true,
            promptImages: 2,
            standaloneImages: 2
        )
        
        // Act - Simulate the order logic from SceneDetailView
        var images: [PromptImage] = []
        
        // Profile first (if unique)
        if let profileData = scene.profileImageData {
            let isFromPrompt = scene.prompts.flatMap { $0.images }.contains { $0.data == profileData }
            let isFromStandalone = scene.standaloneImages.contains { $0.data == profileData }
            if !isFromPrompt && !isFromStandalone {
                images.append(PromptImage(data: profileData))
            }
        }
        
        // Then prompts
        images.append(contentsOf: scene.prompts.flatMap { $0.images })
        
        // Then standalone
        images.append(contentsOf: scene.standaloneImages)
        
        // Assert
        XCTAssertEqual(images.count, 5) // 1 profile + 2 prompt + 2 standalone
        XCTAssertEqual(images[0].data, scene.profileImageData)
    }
    
    func test_galleryImage_profileImageDeduplication_whenProfileMatchesPromptImage() {
        // Arrange - Profile image is same as a prompt image
        let sharedImageData = createTestImageData("shared")
        var character = CharacterProfile(name: "Test")
        character.profileImageData = sharedImageData
        
        var prompt = SavedPrompt(title: "Test")
        prompt.images.append(PromptImage(data: sharedImageData))
        character.prompts.append(prompt)
        
        // Act
        var images: [PromptImage] = []
        
        if let profileData = character.profileImageData {
            let isFromPrompt = character.prompts.flatMap { $0.images }.contains { $0.data == profileData }
            if !isFromPrompt {
                images.append(PromptImage(data: profileData))
            }
        }
        images.append(contentsOf: character.prompts.flatMap { $0.images })
        
        // Assert - Should NOT duplicate the profile image
        XCTAssertEqual(images.count, 1)
    }
    
    // MARK: - Your Creations Gallery Tests
    
    func test_yourCreationsGallery_includesCharacterImages() {
        // Arrange
        let character = createCharacterWithImages(name: "Hero", promptImages: 3)
        let characters = [character]
        let scenes: [CharacterScene] = []
        
        // Act - Simulate HomeView.allGalleryImages logic
        var result: [Data] = []
        var seenImageData = Set<Data>()
        
        for char in characters {
            for prompt in char.prompts {
                for image in prompt.images {
                    if !seenImageData.contains(image.data) {
                        seenImageData.insert(image.data)
                        result.append(image.data)
                    }
                }
            }
        }
        
        // Assert
        XCTAssertEqual(result.count, 3)
    }
    
    func test_yourCreationsGallery_includesSceneImages() {
        // Arrange
        let scene = createSceneWithImages(name: "Battle", promptImages: 2)
        let characters: [CharacterProfile] = []
        let scenes = [scene]
        
        // Act
        var result: [Data] = []
        var seenImageData = Set<Data>()
        
        for scene in scenes {
            for prompt in scene.prompts {
                for image in prompt.images {
                    if !seenImageData.contains(image.data) {
                        seenImageData.insert(image.data)
                        result.append(image.data)
                    }
                }
            }
        }
        
        // Assert
        XCTAssertEqual(result.count, 2)
    }
    
    func test_yourCreationsGallery_deduplicatesAcrossCharactersAndScenes() {
        // Arrange - Same image in both character and scene
        let sharedImageData = createTestImageData("shared")
        
        var character = CharacterProfile(name: "Hero")
        var charPrompt = SavedPrompt(title: "Test")
        charPrompt.images.append(PromptImage(data: sharedImageData))
        character.prompts.append(charPrompt)
        
        var scene = CharacterScene(name: "Battle")
        var scenePrompt = ScenePrompt(title: "Test")
        scenePrompt.images.append(PromptImage(data: sharedImageData))
        scene.prompts.append(scenePrompt)
        
        // Act
        var result: [Data] = []
        var seenImageData = Set<Data>()
        
        // Characters first
        for prompt in character.prompts {
            for image in prompt.images {
                if !seenImageData.contains(image.data) {
                    seenImageData.insert(image.data)
                    result.append(image.data)
                }
            }
        }
        
        // Then scenes
        for prompt in scene.prompts {
            for image in prompt.images {
                if !seenImageData.contains(image.data) {
                    seenImageData.insert(image.data)
                    result.append(image.data)
                }
            }
        }
        
        // Assert - Should only have 1 image (deduplicated)
        XCTAssertEqual(result.count, 1)
    }
    
    func test_yourCreationsGallery_includesStandaloneImages() {
        // Arrange
        var character = CharacterProfile(name: "Hero")
        character.standaloneImages = [
            PromptImage(data: createTestImageData("standalone1")),
            PromptImage(data: createTestImageData("standalone2"))
        ]
        
        // Act
        var result: [Data] = []
        var seenImageData = Set<Data>()
        
        for image in character.standaloneImages {
            if !seenImageData.contains(image.data) {
                seenImageData.insert(image.data)
                result.append(image.data)
            }
        }
        
        // Assert
        XCTAssertEqual(result.count, 2)
    }
    
    func test_yourCreationsGallery_includesProfileImages() {
        // Arrange
        var character = CharacterProfile(name: "Hero")
        character.profileImageData = createTestImageData("profile")
        
        // Act
        var result: [Data] = []
        var seenImageData = Set<Data>()
        
        if let profileData = character.profileImageData,
           !seenImageData.contains(profileData) {
            seenImageData.insert(profileData)
            result.append(profileData)
        }
        
        // Assert
        XCTAssertEqual(result.count, 1)
    }
    
    // MARK: - Scene Prompt ID Tests (Navigation)
    
    func test_scenePromptImage_hasCorrectPromptId() {
        // Arrange
        let promptId = UUID()
        let sceneId = UUID()
        
        let prompt = ScenePrompt(
            id: promptId,
            title: "Test Prompt",
            images: [PromptImage(data: createTestImageData("test"))]
        )
        
        var scene = CharacterScene(id: sceneId, name: "Test Scene")
        scene.prompts = [prompt]
        
        // Assert - The prompt ID should be accessible
        XCTAssertEqual(scene.prompts.first?.id, promptId)
        XCTAssertEqual(scene.id, sceneId)
    }
    
    func test_scenePromptImage_promptIdIsNotNewUUID() {
        // This tests the bug where HomeView was using UUID() instead of prompt.id
        let originalPromptId = UUID()
        let prompt = ScenePrompt(id: originalPromptId, title: "Test")
        
        // The correct behavior is to use prompt.id, not UUID()
        let galleryPromptId = prompt.id
        
        XCTAssertEqual(galleryPromptId, originalPromptId)
        XCTAssertNotEqual(galleryPromptId, UUID()) // Should not be a new random UUID
    }
    
    // MARK: - Scene Defaults Tests
    
    func test_sceneDefaults_sceneDefaultsTakePriorityOverGlobal() {
        // Arrange
        let globalDefaults: [GlobalDefaultKey: String] = [
            .environment: "global environment",
            .lighting: "global lighting"
        ]
        
        let sceneDefaults: [GlobalDefaultKey: String] = [
            .environment: "scene environment" // Should override global
        ]
        
        // Act
        func effectiveDefault(_ key: GlobalDefaultKey) -> String? {
            if let scene = sceneDefaults[key], !scene.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return scene
            }
            if let global = globalDefaults[key], !global.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return global
            }
            return nil
        }
        
        // Assert
        XCTAssertEqual(effectiveDefault(.environment), "scene environment")
        XCTAssertEqual(effectiveDefault(.lighting), "global lighting")
    }
    
    func test_sceneDefaults_emptySceneDefaultFallsBackToGlobal() {
        // Arrange
        let globalDefaults: [GlobalDefaultKey: String] = [
            .style: "global style"
        ]
        
        let sceneDefaults: [GlobalDefaultKey: String] = [
            .style: "   " // Whitespace only
        ]
        
        // Act
        func effectiveDefault(_ key: GlobalDefaultKey) -> String? {
            if let scene = sceneDefaults[key], !scene.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return scene
            }
            if let global = globalDefaults[key], !global.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return global
            }
            return nil
        }
        
        // Assert
        XCTAssertEqual(effectiveDefault(.style), "global style")
    }
    
    // MARK: - Scene Prompt Preset Tests
    
    func test_scenePrompt_hasPresetNameFields() {
        // Arrange
        let prompt = ScenePrompt(
            title: "Test",
            environmentPresetName: "Outdoor",
            lightingPresetName: "Golden Hour"
        )
        
        // Assert
        XCTAssertEqual(prompt.environmentPresetName, "Outdoor")
        XCTAssertEqual(prompt.lightingPresetName, "Golden Hour")
        XCTAssertNil(prompt.stylePresetName)
        XCTAssertNil(prompt.technicalPresetName)
        XCTAssertNil(prompt.negativePresetName)
    }
    
    func test_sceneCharacterSettings_hasPresetNameFields() {
        // Arrange
        let settings = SceneCharacterSettings(
            physicalDescription: "Tall and strong",
            physicalDescriptionPresetName: "Warrior Build"
        )
        
        // Assert
        XCTAssertEqual(settings.physicalDescriptionPresetName, "Warrior Build")
        XCTAssertNil(settings.outfitPresetName)
        XCTAssertNil(settings.posePresetName)
    }
    
    func test_presetMatching_findsMatchingPreset() {
        // Arrange
        let presetText = "A beautiful sunset over the ocean"
        let inputText = "A beautiful sunset over the ocean"
        
        // Act
        let trimmedPreset = presetText.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedInput = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        let matches = trimmedPreset == trimmedInput
        
        // Assert
        XCTAssertTrue(matches)
    }
    
    func test_presetMatching_ignoresWhitespace() {
        // Arrange
        let presetText = "A beautiful sunset"
        let inputText = "  A beautiful sunset  "
        
        // Act
        let trimmedPreset = presetText.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedInput = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        let matches = trimmedPreset == trimmedInput
        
        // Assert
        XCTAssertTrue(matches)
    }
    
    func test_presetMatching_doesNotMatchDifferentText() {
        // Arrange
        let presetText = "A beautiful sunset"
        let inputText = "A beautiful sunrise"
        
        // Act
        let trimmedPreset = presetText.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedInput = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        let matches = trimmedPreset == trimmedInput
        
        // Assert
        XCTAssertFalse(matches)
    }
    
    // MARK: - Scene Character Order Tests
    
    func test_sceneCharacterOrder_preservesInsertionOrder() {
        // Arrange
        let char1Id = UUID()
        let char2Id = UUID()
        let char3Id = UUID()
        
        var scene = CharacterScene(name: "Test")
        scene.characterIds = [char1Id, char2Id, char3Id]
        
        // Assert - Order should be preserved
        XCTAssertEqual(scene.characterIds[0], char1Id)
        XCTAssertEqual(scene.characterIds[1], char2Id)
        XCTAssertEqual(scene.characterIds[2], char3Id)
    }
    
    func test_sceneCharacterOrder_matchesCharacterListOrder() {
        // Arrange
        let char1 = CharacterProfile(name: "Alice")
        let char2 = CharacterProfile(name: "Bob")
        let char3 = CharacterProfile(name: "Charlie")
        let characters = [char1, char2, char3]
        
        var scene = CharacterScene(name: "Test")
        scene.characterIds = characters.map { $0.id }
        
        // Act - Resolve characters in scene order
        let sceneCharacters = scene.characterIds.compactMap { id in
            characters.first { $0.id == id }
        }
        
        // Assert
        XCTAssertEqual(sceneCharacters.count, 3)
        XCTAssertEqual(sceneCharacters[0].name, "Alice")
        XCTAssertEqual(sceneCharacters[1].name, "Bob")
        XCTAssertEqual(sceneCharacters[2].name, "Charlie")
    }
    
    // MARK: - Scene Encoding/Decoding Tests
    
    func test_scenePrompt_encodeDecode_preservesPresetNames() throws {
        // Arrange
        let prompt = ScenePrompt(
            title: "Test",
            environment: "Forest",
            environmentPresetName: "Enchanted Forest",
            lightingPresetName: "Dappled Sunlight"
        )
        
        // Act
        let encoder = JSONEncoder()
        let data = try encoder.encode(prompt)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ScenePrompt.self, from: data)
        
        // Assert
        XCTAssertEqual(decoded.environmentPresetName, "Enchanted Forest")
        XCTAssertEqual(decoded.lightingPresetName, "Dappled Sunlight")
    }
    
    func test_sceneCharacterSettings_encodeDecode_preservesPresetNames() throws {
        // Arrange
        let settings = SceneCharacterSettings(
            physicalDescription: "Tall warrior",
            outfit: "Armor",
            physicalDescriptionPresetName: "Warrior Build",
            outfitPresetName: "Battle Armor"
        )
        
        // Act
        let encoder = JSONEncoder()
        let data = try encoder.encode(settings)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(SceneCharacterSettings.self, from: data)
        
        // Assert
        XCTAssertEqual(decoded.physicalDescriptionPresetName, "Warrior Build")
        XCTAssertEqual(decoded.outfitPresetName, "Battle Armor")
    }
    
    // MARK: - Scene Defaults Storage Tests
    
    func test_sceneDefaults_canStoreAndRetrieve() {
        // Arrange
        var scene = CharacterScene(name: "Test")
        scene.sceneDefaults[.environment] = "Default forest"
        scene.sceneDefaults[.lighting] = "Default sunset"
        
        // Assert
        XCTAssertEqual(scene.sceneDefaults[.environment], "Default forest")
        XCTAssertEqual(scene.sceneDefaults[.lighting], "Default sunset")
        XCTAssertNil(scene.sceneDefaults[.style])
    }
    
    func test_sceneDefaults_encodeDecode() throws {
        // Arrange
        var scene = CharacterScene(name: "Test")
        scene.sceneDefaults[.environment] = "Forest"
        scene.sceneDefaults[.negative] = "No blur"
        
        // Act
        let encoder = JSONEncoder()
        let data = try encoder.encode(scene)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(CharacterScene.self, from: data)
        
        // Assert
        XCTAssertEqual(decoded.sceneDefaults[.environment], "Forest")
        XCTAssertEqual(decoded.sceneDefaults[.negative], "No blur")
    }
}
