//
//  SceneTests.swift
//  ChanceryTests
//
//  Tests for CharacterScene, ScenePrompt, and SceneCharacterSettings models.
//

import XCTest
@testable import Chancery

final class SceneTests: XCTestCase {
    
    // MARK: - CharacterScene Initialization Tests
    
    func test_characterScene_init_withDefaults() {
        let scene = CharacterScene(name: "Beach Day")
        
        XCTAssertFalse(scene.id.uuidString.isEmpty)
        XCTAssertEqual(scene.name, "Beach Day")
        XCTAssertEqual(scene.description, "")
        XCTAssertEqual(scene.notes, "")
        XCTAssertTrue(scene.characterIds.isEmpty)
        XCTAssertTrue(scene.prompts.isEmpty)
        XCTAssertTrue(scene.standaloneImages.isEmpty)
        XCTAssertNil(scene.sceneThemeId)
        XCTAssertNil(scene.sceneDefaultPerchanceGenerator)
    }
    
    func test_characterScene_init_withAllParameters() {
        let id = UUID()
        let characterId1 = UUID()
        let characterId2 = UUID()
        let prompt = ScenePrompt(title: "Test Prompt")
        let image = PromptImage(data: Data([0x00, 0x01]))
        
        let scene = CharacterScene(
            id: id,
            name: "Adventure",
            description: "An epic adventure",
            notes: "Private notes",
            characterIds: [characterId1, characterId2],
            prompts: [prompt],
            standaloneImages: [image],
            sceneThemeId: "dark",
            sceneDefaultPerchanceGenerator: "custom-gen"
        )
        
        XCTAssertEqual(scene.id, id)
        XCTAssertEqual(scene.name, "Adventure")
        XCTAssertEqual(scene.description, "An epic adventure")
        XCTAssertEqual(scene.notes, "Private notes")
        XCTAssertEqual(scene.characterIds.count, 2)
        XCTAssertEqual(scene.prompts.count, 1)
        XCTAssertEqual(scene.standaloneImages.count, 1)
        XCTAssertEqual(scene.sceneThemeId, "dark")
        XCTAssertEqual(scene.sceneDefaultPerchanceGenerator, "custom-gen")
    }
    
    // MARK: - CharacterScene Computed Properties Tests
    
    func test_characterScene_promptCount() {
        var scene = CharacterScene(name: "Test")
        XCTAssertEqual(scene.promptCount, 0)
        
        scene.prompts.append(ScenePrompt(title: "Prompt 1"))
        XCTAssertEqual(scene.promptCount, 1)
        
        scene.prompts.append(ScenePrompt(title: "Prompt 2"))
        XCTAssertEqual(scene.promptCount, 2)
    }
    
    func test_characterScene_totalImageCount() {
        var scene = CharacterScene(name: "Test")
        XCTAssertEqual(scene.totalImageCount, 0)
        
        // Add standalone image
        scene.standaloneImages.append(PromptImage(data: Data([0x00])))
        XCTAssertEqual(scene.totalImageCount, 1)
        
        // Add prompt with images
        var prompt = ScenePrompt(title: "Test")
        prompt.images.append(PromptImage(data: Data([0x01])))
        prompt.images.append(PromptImage(data: Data([0x02])))
        scene.prompts.append(prompt)
        XCTAssertEqual(scene.totalImageCount, 3)
    }
    
    func test_characterScene_allImages() {
        var scene = CharacterScene(name: "Test")
        XCTAssertTrue(scene.allImages.isEmpty)
        
        let standaloneImage = PromptImage(data: Data([0x00]))
        scene.standaloneImages.append(standaloneImage)
        
        var prompt = ScenePrompt(title: "Test")
        let promptImage = PromptImage(data: Data([0x01]))
        prompt.images.append(promptImage)
        scene.prompts.append(prompt)
        
        XCTAssertEqual(scene.allImages.count, 2)
    }
    
    func test_characterScene_characterCount() {
        var scene = CharacterScene(name: "Test")
        XCTAssertEqual(scene.characterCount, 0)
        
        scene.characterIds = [UUID(), UUID(), UUID()]
        XCTAssertEqual(scene.characterCount, 3)
    }
    
    // MARK: - CharacterScene Profile Image Tests
    
    func test_characterScene_profileImageData_defaultsToNil() {
        let scene = CharacterScene(name: "Test")
        XCTAssertNil(scene.profileImageData)
    }
    
    func test_characterScene_profileImageData_canBeSet() {
        var scene = CharacterScene(name: "Test")
        let imageData = Data([0x00, 0x01, 0x02])
        scene.profileImageData = imageData
        XCTAssertEqual(scene.profileImageData, imageData)
    }
    
    // MARK: - CharacterScene Links Tests
    
    func test_characterScene_links_defaultsToEmpty() {
        let scene = CharacterScene(name: "Test")
        XCTAssertTrue(scene.links.isEmpty)
    }
    
    func test_characterScene_links_canBeModified() {
        var scene = CharacterScene(name: "Test")
        let link = RelatedLink(title: "Reference", urlString: "https://example.com")
        scene.links.append(link)
        XCTAssertEqual(scene.links.count, 1)
        XCTAssertEqual(scene.links.first?.title, "Reference")
    }
    
    func test_characterScene_links_encodeDecode() throws {
        var scene = CharacterScene(name: "Test")
        scene.links = [
            RelatedLink(title: "Link 1", urlString: "https://example1.com"),
            RelatedLink(title: "Link 2", urlString: "https://example2.com")
        ]
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(scene)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(CharacterScene.self, from: data)
        
        XCTAssertEqual(decoded.links.count, 2)
        XCTAssertEqual(decoded.links[0].title, "Link 1")
        XCTAssertEqual(decoded.links[1].title, "Link 2")
    }
    
    // MARK: - CharacterScene Codable Tests
    
    func test_characterScene_encodeDecode() throws {
        let characterId1 = UUID()
        let characterId2 = UUID()
        let original = CharacterScene(
            name: "Test Scene",
            description: "A test",
            notes: "Notes",
            characterIds: [characterId1, characterId2],
            sceneThemeId: "ocean"
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(CharacterScene.self, from: data)
        
        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.name, original.name)
        XCTAssertEqual(decoded.description, original.description)
        XCTAssertEqual(decoded.notes, original.notes)
        XCTAssertEqual(decoded.characterIds, original.characterIds)
        XCTAssertEqual(decoded.sceneThemeId, original.sceneThemeId)
    }
    
    // MARK: - CharacterScene Equatable Tests
    
    func test_characterScene_equatable() {
        let id = UUID()
        let scene1 = CharacterScene(id: id, name: "Test")
        let scene2 = CharacterScene(id: id, name: "Test")
        let scene3 = CharacterScene(name: "Test") // Different ID
        
        XCTAssertEqual(scene1, scene2)
        XCTAssertNotEqual(scene1, scene3)
    }
}

// MARK: - ScenePrompt Tests

final class ScenePromptTests: XCTestCase {
    
    func test_scenePrompt_init_withDefaults() {
        let prompt = ScenePrompt()
        
        XCTAssertFalse(prompt.id.uuidString.isEmpty)
        XCTAssertEqual(prompt.title, "")
        XCTAssertNil(prompt.environment)
        XCTAssertNil(prompt.lighting)
        XCTAssertNil(prompt.styleModifiers)
        XCTAssertNil(prompt.technicalModifiers)
        XCTAssertNil(prompt.negativePrompt)
        XCTAssertNil(prompt.additionalInfo)
        XCTAssertTrue(prompt.characterSettings.isEmpty)
        XCTAssertTrue(prompt.images.isEmpty)
    }
    
    func test_scenePrompt_init_withAllParameters() {
        let id = UUID()
        let characterId = UUID()
        let settings = SceneCharacterSettings(physicalDescription: "Tall")
        let image = PromptImage(data: Data([0x00]))
        
        let prompt = ScenePrompt(
            id: id,
            title: "Epic Battle",
            environment: "Castle courtyard",
            lighting: "Dramatic sunset",
            styleModifiers: "Fantasy art",
            technicalModifiers: "8k, detailed",
            negativePrompt: "blurry",
            additionalInfo: "Extra info",
            characterSettings: [characterId: settings],
            images: [image]
        )
        
        XCTAssertEqual(prompt.id, id)
        XCTAssertEqual(prompt.title, "Epic Battle")
        XCTAssertEqual(prompt.environment, "Castle courtyard")
        XCTAssertEqual(prompt.lighting, "Dramatic sunset")
        XCTAssertEqual(prompt.styleModifiers, "Fantasy art")
        XCTAssertEqual(prompt.technicalModifiers, "8k, detailed")
        XCTAssertEqual(prompt.negativePrompt, "blurry")
        XCTAssertEqual(prompt.additionalInfo, "Extra info")
        XCTAssertEqual(prompt.characterSettings.count, 1)
        XCTAssertEqual(prompt.images.count, 1)
    }
    
    func test_scenePrompt_imageCount() {
        var prompt = ScenePrompt(title: "Test")
        XCTAssertEqual(prompt.imageCount, 0)
        
        prompt.images.append(PromptImage(data: Data([0x00])))
        prompt.images.append(PromptImage(data: Data([0x01])))
        XCTAssertEqual(prompt.imageCount, 2)
    }
    
    func test_scenePrompt_hasContent_whenEmpty() {
        let prompt = ScenePrompt(title: "Test")
        XCTAssertFalse(prompt.hasContent)
    }
    
    func test_scenePrompt_hasContent_withEnvironment() {
        let prompt = ScenePrompt(title: "Test", environment: "Forest")
        XCTAssertTrue(prompt.hasContent)
    }
    
    func test_scenePrompt_hasContent_withCharacterSettings() {
        let characterId = UUID()
        let settings = SceneCharacterSettings(physicalDescription: "Tall")
        let prompt = ScenePrompt(title: "Test", characterSettings: [characterId: settings])
        XCTAssertTrue(prompt.hasContent)
    }
    
    func test_scenePrompt_encodeDecode() throws {
        let characterId = UUID()
        let settings = SceneCharacterSettings(physicalDescription: "Tall", outfit: "Armor")
        let original = ScenePrompt(
            title: "Battle",
            environment: "Castle",
            lighting: "Sunset",
            characterSettings: [characterId: settings]
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ScenePrompt.self, from: data)
        
        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.title, original.title)
        XCTAssertEqual(decoded.environment, original.environment)
        XCTAssertEqual(decoded.lighting, original.lighting)
        XCTAssertEqual(decoded.characterSettings[characterId]?.physicalDescription, "Tall")
        XCTAssertEqual(decoded.characterSettings[characterId]?.outfit, "Armor")
    }
}

// MARK: - SceneCharacterSettings Tests

final class SceneCharacterSettingsTests: XCTestCase {
    
    func test_sceneCharacterSettings_init_withDefaults() {
        let settings = SceneCharacterSettings()
        
        XCTAssertNil(settings.physicalDescription)
        XCTAssertNil(settings.outfit)
        XCTAssertNil(settings.pose)
        XCTAssertNil(settings.additionalInfo)
        XCTAssertNil(settings.sourcePromptId)
    }
    
    func test_sceneCharacterSettings_init_withAllParameters() {
        let sourceId = UUID()
        let settings = SceneCharacterSettings(
            physicalDescription: "Tall with silver hair",
            outfit: "Blue dress",
            pose: "Standing confidently",
            additionalInfo: "Extra details",
            sourcePromptId: sourceId
        )
        
        XCTAssertEqual(settings.physicalDescription, "Tall with silver hair")
        XCTAssertEqual(settings.outfit, "Blue dress")
        XCTAssertEqual(settings.pose, "Standing confidently")
        XCTAssertEqual(settings.additionalInfo, "Extra details")
        XCTAssertEqual(settings.sourcePromptId, sourceId)
    }
    
    func test_sceneCharacterSettings_encodeDecode() throws {
        let sourceId = UUID()
        let original = SceneCharacterSettings(
            physicalDescription: "Short",
            outfit: "Casual",
            pose: "Sitting",
            sourcePromptId: sourceId
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(SceneCharacterSettings.self, from: data)
        
        XCTAssertEqual(decoded.physicalDescription, original.physicalDescription)
        XCTAssertEqual(decoded.outfit, original.outfit)
        XCTAssertEqual(decoded.pose, original.pose)
        XCTAssertEqual(decoded.sourcePromptId, original.sourcePromptId)
    }
    
    func test_sceneCharacterSettings_equatable() {
        let settings1 = SceneCharacterSettings(physicalDescription: "Tall")
        let settings2 = SceneCharacterSettings(physicalDescription: "Tall")
        let settings3 = SceneCharacterSettings(physicalDescription: "Short")
        
        XCTAssertEqual(settings1, settings2)
        XCTAssertNotEqual(settings1, settings3)
    }
}

// MARK: - Scene with Characters Integration Tests

final class SceneCharacterIntegrationTests: XCTestCase {
    
    func test_scene_withMultipleCharacters() {
        let character1 = CharacterProfile(name: "Luna")
        let character2 = CharacterProfile(name: "Aria")
        
        let scene = CharacterScene(
            name: "Beach Day",
            characterIds: [character1.id, character2.id]
        )
        
        XCTAssertEqual(scene.characterCount, 2)
        XCTAssertTrue(scene.characterIds.contains(character1.id))
        XCTAssertTrue(scene.characterIds.contains(character2.id))
    }
    
    func test_scenePrompt_withMultipleCharacterSettings() {
        let character1Id = UUID()
        let character2Id = UUID()
        
        let settings1 = SceneCharacterSettings(
            physicalDescription: "Silver hair, amber eyes",
            outfit: "Light armor"
        )
        let settings2 = SceneCharacterSettings(
            physicalDescription: "Dark hair, green eyes",
            outfit: "Flowing robes"
        )
        
        let prompt = ScenePrompt(
            title: "Battle Scene",
            environment: "Ancient ruins",
            lighting: "Dramatic",
            characterSettings: [
                character1Id: settings1,
                character2Id: settings2
            ]
        )
        
        XCTAssertEqual(prompt.characterSettings.count, 2)
        XCTAssertEqual(prompt.characterSettings[character1Id]?.physicalDescription, "Silver hair, amber eyes")
        XCTAssertEqual(prompt.characterSettings[character2Id]?.outfit, "Flowing robes")
    }
    
    func test_scene_addingAndRemovingPrompts() {
        var scene = CharacterScene(name: "Test Scene")
        XCTAssertEqual(scene.promptCount, 0)
        
        // Add prompts
        scene.prompts.append(ScenePrompt(title: "Prompt 1"))
        scene.prompts.append(ScenePrompt(title: "Prompt 2"))
        XCTAssertEqual(scene.promptCount, 2)
        
        // Remove prompt
        scene.prompts.removeFirst()
        XCTAssertEqual(scene.promptCount, 1)
        XCTAssertEqual(scene.prompts.first?.title, "Prompt 2")
    }
    
    func test_scene_addingAndRemovingCharacters() {
        var scene = CharacterScene(name: "Test Scene")
        let char1 = UUID()
        let char2 = UUID()
        let char3 = UUID()
        
        scene.characterIds = [char1, char2, char3]
        XCTAssertEqual(scene.characterCount, 3)
        
        // Remove a character
        scene.characterIds.removeAll { $0 == char2 }
        XCTAssertEqual(scene.characterCount, 2)
        XCTAssertFalse(scene.characterIds.contains(char2))
    }
}
