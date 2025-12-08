//
//  SceneGalleryTests.swift
//  ChanceryTests
//
//  Tests for scene images appearing in gallery and related functionality.
//  These are regression tests to ensure scene images are properly included.
//

import XCTest
@testable import Chancery

final class SceneGalleryTests: XCTestCase {
    
    // MARK: - Test Data Helpers
    
    private func createTestImage() -> Data {
        // Create a simple 1x1 pixel image
        let size = CGSize(width: 1, height: 1)
        UIGraphicsBeginImageContext(size)
        UIColor.red.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image?.jpegData(compressionQuality: 0.5) ?? Data()
    }
    
    private func createCharacter(name: String, promptCount: Int = 0, imageCount: Int = 0) -> CharacterProfile {
        var character = CharacterProfile(name: name)
        for i in 0..<promptCount {
            var prompt = SavedPrompt(title: "Prompt \(i)")
            for _ in 0..<imageCount {
                prompt.images.append(PromptImage(data: createTestImage()))
            }
            character.prompts.append(prompt)
        }
        return character
    }
    
    private func createScene(name: String, characterIds: [UUID], promptCount: Int = 0, imageCount: Int = 0) -> CharacterScene {
        var scene = CharacterScene(name: name, characterIds: characterIds)
        for i in 0..<promptCount {
            var prompt = ScenePrompt(title: "Scene Prompt \(i)")
            for _ in 0..<imageCount {
                prompt.images.append(PromptImage(data: createTestImage()))
            }
            scene.prompts.append(prompt)
        }
        return scene
    }
    
    // MARK: - Scene allImages Tests
    
    func test_sceneAllImages_withPromptImages_includesAllImages() {
        // Given
        var scene = CharacterScene(name: "Test Scene", characterIds: [UUID()])
        var prompt = ScenePrompt(title: "Test Prompt")
        prompt.images = [
            PromptImage(data: createTestImage()),
            PromptImage(data: createTestImage())
        ]
        scene.prompts.append(prompt)
        
        // Then
        XCTAssertEqual(scene.allImages.count, 2)
    }
    
    func test_sceneAllImages_withStandaloneImages_includesStandaloneImages() {
        // Given
        var scene = CharacterScene(name: "Test Scene", characterIds: [UUID()])
        scene.standaloneImages = [
            PromptImage(data: createTestImage()),
            PromptImage(data: createTestImage()),
            PromptImage(data: createTestImage())
        ]
        
        // Then
        XCTAssertEqual(scene.allImages.count, 3)
    }
    
    func test_sceneAllImages_withBothPromptAndStandalone_includesAll() {
        // Given
        var scene = CharacterScene(name: "Test Scene", characterIds: [UUID()])
        var prompt = ScenePrompt(title: "Test Prompt")
        prompt.images = [PromptImage(data: createTestImage())]
        scene.prompts.append(prompt)
        scene.standaloneImages = [PromptImage(data: createTestImage())]
        
        // Then
        XCTAssertEqual(scene.allImages.count, 2)
    }
    
    func test_sceneAllImages_empty_returnsEmptyArray() {
        // Given
        let scene = CharacterScene(name: "Empty Scene", characterIds: [UUID()])
        
        // Then
        XCTAssertTrue(scene.allImages.isEmpty)
    }
    
    func test_sceneAllImages_multiplePrompts_includesAllPromptImages() {
        // Given
        var scene = CharacterScene(name: "Test Scene", characterIds: [UUID()])
        for i in 0..<3 {
            var prompt = ScenePrompt(title: "Prompt \(i)")
            prompt.images = [PromptImage(data: createTestImage())]
            scene.prompts.append(prompt)
        }
        
        // Then
        XCTAssertEqual(scene.allImages.count, 3)
    }
    
    // MARK: - Scene totalImageCount Tests
    
    func test_sceneTotalImageCount_withPromptImages_returnsCorrectCount() {
        // Given
        var scene = CharacterScene(name: "Test Scene", characterIds: [UUID()])
        var prompt = ScenePrompt(title: "Test Prompt")
        prompt.images = [
            PromptImage(data: createTestImage()),
            PromptImage(data: createTestImage())
        ]
        scene.prompts.append(prompt)
        
        // Then
        XCTAssertEqual(scene.totalImageCount, 2)
    }
    
    func test_sceneTotalImageCount_withStandaloneImages_includesStandalone() {
        // Given
        var scene = CharacterScene(name: "Test Scene", characterIds: [UUID()])
        scene.standaloneImages = [
            PromptImage(data: createTestImage()),
            PromptImage(data: createTestImage())
        ]
        
        // Then
        XCTAssertEqual(scene.totalImageCount, 2)
    }
    
    func test_sceneTotalImageCount_withBoth_returnsCombinedCount() {
        // Given
        var scene = CharacterScene(name: "Test Scene", characterIds: [UUID()])
        var prompt = ScenePrompt(title: "Test Prompt")
        prompt.images = [PromptImage(data: createTestImage())]
        scene.prompts.append(prompt)
        scene.standaloneImages = [PromptImage(data: createTestImage())]
        
        // Then
        XCTAssertEqual(scene.totalImageCount, 2)
    }
    
    // MARK: - Scene Profile Image Tests
    
    func test_sceneProfileImageData_initiallyNil() {
        // Given
        let scene = CharacterScene(name: "Test Scene", characterIds: [UUID()])
        
        // Then
        XCTAssertNil(scene.profileImageData)
    }
    
    func test_sceneProfileImageData_canBeSet() {
        // Given
        var scene = CharacterScene(name: "Test Scene", characterIds: [UUID()])
        let imageData = createTestImage()
        
        // When
        scene.profileImageData = imageData
        
        // Then
        XCTAssertNotNil(scene.profileImageData)
        XCTAssertEqual(scene.profileImageData, imageData)
    }
    
    func test_sceneProfileImageData_encodesAndDecodes() throws {
        // Given
        var scene = CharacterScene(name: "Test Scene", characterIds: [UUID()])
        scene.profileImageData = createTestImage()
        
        // When
        let encoded = try JSONEncoder().encode(scene)
        let decoded = try JSONDecoder().decode(CharacterScene.self, from: encoded)
        
        // Then
        XCTAssertNotNil(decoded.profileImageData)
        XCTAssertEqual(decoded.profileImageData, scene.profileImageData)
    }
    
    // MARK: - Scene Links Tests
    
    func test_sceneLinks_initiallyEmpty() {
        // Given
        let scene = CharacterScene(name: "Test Scene", characterIds: [UUID()])
        
        // Then
        XCTAssertTrue(scene.links.isEmpty)
    }
    
    func test_sceneLinks_canAddLinks() {
        // Given
        var scene = CharacterScene(name: "Test Scene", characterIds: [UUID()])
        let link = RelatedLink(title: "Test Link", urlString: "https://example.com")
        
        // When
        scene.links.append(link)
        
        // Then
        XCTAssertEqual(scene.links.count, 1)
        XCTAssertEqual(scene.links[0].title, "Test Link")
    }
    
    func test_sceneLinks_encodesAndDecodes() throws {
        // Given
        var scene = CharacterScene(name: "Test Scene", characterIds: [UUID()])
        scene.links = [
            RelatedLink(title: "Link 1", urlString: "https://example1.com"),
            RelatedLink(title: "Link 2", urlString: "https://example2.com")
        ]
        
        // When
        let encoded = try JSONEncoder().encode(scene)
        let decoded = try JSONDecoder().decode(CharacterScene.self, from: encoded)
        
        // Then
        XCTAssertEqual(decoded.links.count, 2)
        XCTAssertEqual(decoded.links[0].title, "Link 1")
        XCTAssertEqual(decoded.links[1].title, "Link 2")
    }
    
    func test_sceneLinks_multipleLinks_maintainsOrder() {
        // Given
        var scene = CharacterScene(name: "Test Scene", characterIds: [UUID()])
        
        // When
        for i in 0..<5 {
            scene.links.append(RelatedLink(title: "Link \(i)", urlString: "https://example\(i).com"))
        }
        
        // Then
        XCTAssertEqual(scene.links.count, 5)
        for i in 0..<5 {
            XCTAssertEqual(scene.links[i].title, "Link \(i)")
        }
    }
    
    // MARK: - Scene Standalone Images Tests
    
    func test_sceneStandaloneImages_initiallyEmpty() {
        // Given
        let scene = CharacterScene(name: "Test Scene", characterIds: [UUID()])
        
        // Then
        XCTAssertTrue(scene.standaloneImages.isEmpty)
    }
    
    func test_sceneStandaloneImages_canAddImages() {
        // Given
        var scene = CharacterScene(name: "Test Scene", characterIds: [UUID()])
        
        // When
        scene.standaloneImages.append(PromptImage(data: createTestImage()))
        scene.standaloneImages.append(PromptImage(data: createTestImage()))
        
        // Then
        XCTAssertEqual(scene.standaloneImages.count, 2)
    }
    
    func test_sceneStandaloneImages_encodesAndDecodes() throws {
        // Given
        var scene = CharacterScene(name: "Test Scene", characterIds: [UUID()])
        scene.standaloneImages = [
            PromptImage(data: createTestImage()),
            PromptImage(data: createTestImage())
        ]
        
        // When
        let encoded = try JSONEncoder().encode(scene)
        let decoded = try JSONDecoder().decode(CharacterScene.self, from: encoded)
        
        // Then
        XCTAssertEqual(decoded.standaloneImages.count, 2)
    }
    
    // MARK: - Scene Prompt Images Tests
    
    func test_scenePromptImages_canAddToPrompt() {
        // Given
        var prompt = ScenePrompt(title: "Test Prompt")
        
        // When
        prompt.images.append(PromptImage(data: createTestImage()))
        
        // Then
        XCTAssertEqual(prompt.images.count, 1)
    }
    
    func test_scenePromptImages_encodesAndDecodes() throws {
        // Given
        var prompt = ScenePrompt(title: "Test Prompt")
        prompt.images = [
            PromptImage(data: createTestImage()),
            PromptImage(data: createTestImage())
        ]
        
        // When
        let encoded = try JSONEncoder().encode(prompt)
        let decoded = try JSONDecoder().decode(ScenePrompt.self, from: encoded)
        
        // Then
        XCTAssertEqual(decoded.images.count, 2)
    }
    
    // MARK: - Edge Cases
    
    func test_sceneWithEmptyName_stillWorks() {
        // Given
        let scene = CharacterScene(name: "", characterIds: [UUID()])
        
        // Then
        XCTAssertEqual(scene.name, "")
        XCTAssertTrue(scene.allImages.isEmpty)
    }
    
    func test_sceneWithNoCharacters_stillWorks() {
        // Given
        let scene = CharacterScene(name: "Test Scene", characterIds: [])
        
        // Then
        XCTAssertEqual(scene.characterCount, 0)
        XCTAssertTrue(scene.characterIds.isEmpty)
    }
    
    func test_sceneWithManyImages_handlesCorrectly() {
        // Given
        var scene = CharacterScene(name: "Test Scene", characterIds: [UUID()])
        for _ in 0..<100 {
            scene.standaloneImages.append(PromptImage(data: createTestImage()))
        }
        
        // Then
        XCTAssertEqual(scene.standaloneImages.count, 100)
        XCTAssertEqual(scene.totalImageCount, 100)
        XCTAssertEqual(scene.allImages.count, 100)
    }
}
