//
//  StandaloneImagesTests.swift
//  ChanceryTests
//
//  Tests for standalone images functionality in CharacterProfile.
//

import XCTest
@testable import Chancery

final class StandaloneImagesTests: XCTestCase {
    
    // MARK: - CharacterProfile Standalone Images Tests
    
    func test_characterProfile_standaloneImages_defaultsToEmpty() {
        let character = CharacterProfile(name: "Test")
        XCTAssertTrue(character.standaloneImages.isEmpty)
    }
    
    func test_characterProfile_standaloneImages_canBeInitialized() {
        let image1 = PromptImage(data: Data([0x00, 0x01]))
        let image2 = PromptImage(data: Data([0x02, 0x03]))
        
        let character = CharacterProfile(
            name: "Test",
            standaloneImages: [image1, image2]
        )
        
        XCTAssertEqual(character.standaloneImages.count, 2)
    }
    
    func test_characterProfile_standaloneImages_canBeModified() {
        var character = CharacterProfile(name: "Test")
        XCTAssertTrue(character.standaloneImages.isEmpty)
        
        let image = PromptImage(data: Data([0x00]))
        character.standaloneImages.append(image)
        
        XCTAssertEqual(character.standaloneImages.count, 1)
        XCTAssertEqual(character.standaloneImages.first?.id, image.id)
    }
    
    func test_characterProfile_totalImageCount_includesStandaloneImages() {
        var character = CharacterProfile(name: "Test")
        
        // Add a prompt with images
        var prompt = SavedPrompt(title: "Test Prompt")
        prompt.images.append(PromptImage(data: Data([0x00])))
        prompt.images.append(PromptImage(data: Data([0x01])))
        character.prompts.append(prompt)
        
        XCTAssertEqual(character.totalImageCount, 2)
        
        // Add standalone images
        character.standaloneImages.append(PromptImage(data: Data([0x02])))
        character.standaloneImages.append(PromptImage(data: Data([0x03])))
        character.standaloneImages.append(PromptImage(data: Data([0x04])))
        
        XCTAssertEqual(character.totalImageCount, 5)
    }
    
    func test_characterProfile_allImages_includesStandaloneImages() {
        var character = CharacterProfile(name: "Test")
        
        // Add a prompt with images
        var prompt = SavedPrompt(title: "Test Prompt")
        let promptImage = PromptImage(data: Data([0x00]))
        prompt.images.append(promptImage)
        character.prompts.append(prompt)
        
        // Add standalone image
        let standaloneImage = PromptImage(data: Data([0x01]))
        character.standaloneImages.append(standaloneImage)
        
        let allImages = character.allImages
        XCTAssertEqual(allImages.count, 2)
        XCTAssertTrue(allImages.contains { $0.id == promptImage.id })
        XCTAssertTrue(allImages.contains { $0.id == standaloneImage.id })
    }
    
    func test_characterProfile_standaloneImages_encodeDecode() throws {
        let image = PromptImage(data: Data([0x00, 0x01, 0x02]))
        let original = CharacterProfile(
            name: "Test",
            standaloneImages: [image]
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(CharacterProfile.self, from: data)
        
        XCTAssertEqual(decoded.standaloneImages.count, 1)
        XCTAssertEqual(decoded.standaloneImages.first?.data, image.data)
    }
    
    func test_characterProfile_standaloneImages_removingImage() {
        var character = CharacterProfile(name: "Test")
        let image1 = PromptImage(data: Data([0x00]))
        let image2 = PromptImage(data: Data([0x01]))
        let image3 = PromptImage(data: Data([0x02]))
        
        character.standaloneImages = [image1, image2, image3]
        XCTAssertEqual(character.standaloneImages.count, 3)
        
        // Remove middle image
        character.standaloneImages.removeAll { $0.id == image2.id }
        XCTAssertEqual(character.standaloneImages.count, 2)
        XCTAssertFalse(character.standaloneImages.contains { $0.id == image2.id })
    }
}

// MARK: - Scene Standalone Images Tests

final class SceneStandaloneImagesTests: XCTestCase {
    
    func test_scene_standaloneImages_defaultsToEmpty() {
        let scene = CharacterScene(name: "Test")
        XCTAssertTrue(scene.standaloneImages.isEmpty)
    }
    
    func test_scene_standaloneImages_canBeInitialized() {
        let image = PromptImage(data: Data([0x00]))
        let scene = CharacterScene(
            name: "Test",
            standaloneImages: [image]
        )
        
        XCTAssertEqual(scene.standaloneImages.count, 1)
    }
    
    func test_scene_totalImageCount_includesStandaloneImages() {
        var scene = CharacterScene(name: "Test")
        
        // Add prompt with images
        var prompt = ScenePrompt(title: "Test")
        prompt.images.append(PromptImage(data: Data([0x00])))
        scene.prompts.append(prompt)
        
        XCTAssertEqual(scene.totalImageCount, 1)
        
        // Add standalone images
        scene.standaloneImages.append(PromptImage(data: Data([0x01])))
        scene.standaloneImages.append(PromptImage(data: Data([0x02])))
        
        XCTAssertEqual(scene.totalImageCount, 3)
    }
    
    func test_scene_allImages_includesStandaloneImages() {
        var scene = CharacterScene(name: "Test")
        
        // Add prompt with image
        var prompt = ScenePrompt(title: "Test")
        let promptImage = PromptImage(data: Data([0x00]))
        prompt.images.append(promptImage)
        scene.prompts.append(prompt)
        
        // Add standalone image
        let standaloneImage = PromptImage(data: Data([0x01]))
        scene.standaloneImages.append(standaloneImage)
        
        let allImages = scene.allImages
        XCTAssertEqual(allImages.count, 2)
    }
}
