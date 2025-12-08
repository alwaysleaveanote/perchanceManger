//
//  CharacterProfileTests.swift
//  ChanceryTests
//
//  Unit tests for CharacterProfile model functionality.
//

import XCTest
@testable import Chancery

final class CharacterProfileTests: XCTestCase {
    
    // MARK: - Initialization Tests
    
    func test_init_withDefaultValues_createsCharacterWithEmptyFields() {
        let character = CharacterProfile(name: "Test Character")
        
        XCTAssertFalse(character.id.uuidString.isEmpty)
        XCTAssertEqual(character.name, "Test Character")
        XCTAssertEqual(character.bio, "")
        XCTAssertEqual(character.notes, "")
        XCTAssertTrue(character.prompts.isEmpty)
        XCTAssertNil(character.profileImageData)
        XCTAssertTrue(character.links.isEmpty)
        XCTAssertTrue(character.characterDefaults.isEmpty)
        XCTAssertNil(character.characterDefaultPerchanceGenerator)
        XCTAssertNil(character.characterThemeId)
    }
    
    func test_init_withAllFields_createsCharacterWithAllValues() {
        let id = UUID()
        let prompt = SavedPrompt(title: "Test Prompt")
        let link = RelatedLink(title: "Test Link", urlString: "https://example.com")
        let imageData = Data([0x00, 0x01, 0x02])
        
        let character = CharacterProfile(
            id: id,
            name: "Full Character",
            bio: "A test biography",
            notes: "Some notes",
            prompts: [prompt],
            profileImageData: imageData,
            links: [link],
            characterDefaults: [.physicalDescription: "default physical"],
            characterDefaultPerchanceGenerator: "custom-generator",
            characterThemeId: "custom-theme"
        )
        
        XCTAssertEqual(character.id, id)
        XCTAssertEqual(character.name, "Full Character")
        XCTAssertEqual(character.bio, "A test biography")
        XCTAssertEqual(character.notes, "Some notes")
        XCTAssertEqual(character.prompts.count, 1)
        XCTAssertEqual(character.profileImageData, imageData)
        XCTAssertEqual(character.links.count, 1)
        XCTAssertEqual(character.characterDefaults[.physicalDescription], "default physical")
        XCTAssertEqual(character.characterDefaultPerchanceGenerator, "custom-generator")
        XCTAssertEqual(character.characterThemeId, "custom-theme")
    }
    
    // MARK: - hasProfileImage Tests
    
    func test_hasProfileImage_withNoImage_returnsFalse() {
        let character = CharacterProfile(name: "Test")
        
        XCTAssertFalse(character.hasProfileImage)
    }
    
    func test_hasProfileImage_withImage_returnsTrue() {
        let character = CharacterProfile(
            name: "Test",
            profileImageData: Data([0x00])
        )
        
        XCTAssertTrue(character.hasProfileImage)
    }
    
    // MARK: - promptCount Tests
    
    func test_promptCount_withNoPrompts_returnsZero() {
        let character = CharacterProfile(name: "Test")
        
        XCTAssertEqual(character.promptCount, 0)
    }
    
    func test_promptCount_withPrompts_returnsCorrectCount() {
        let prompts = [
            SavedPrompt(title: "Prompt 1"),
            SavedPrompt(title: "Prompt 2"),
            SavedPrompt(title: "Prompt 3")
        ]
        let character = CharacterProfile(name: "Test", prompts: prompts)
        
        XCTAssertEqual(character.promptCount, 3)
    }
    
    // MARK: - totalImageCount Tests
    
    func test_totalImageCount_withNoImages_returnsZero() {
        let character = CharacterProfile(name: "Test")
        
        XCTAssertEqual(character.totalImageCount, 0)
    }
    
    func test_totalImageCount_withImagesAcrossPrompts_returnsTotalCount() {
        let image1 = PromptImage(id: UUID(), data: Data())
        let image2 = PromptImage(id: UUID(), data: Data())
        let image3 = PromptImage(id: UUID(), data: Data())
        
        let prompts = [
            SavedPrompt(title: "Prompt 1", images: [image1, image2]),
            SavedPrompt(title: "Prompt 2", images: [image3])
        ]
        let character = CharacterProfile(name: "Test", prompts: prompts)
        
        XCTAssertEqual(character.totalImageCount, 3)
    }
    
    // MARK: - hasCustomDefaults Tests
    
    func test_hasCustomDefaults_withNoDefaults_returnsFalse() {
        let character = CharacterProfile(name: "Test")
        
        XCTAssertFalse(character.hasCustomDefaults)
    }
    
    func test_hasCustomDefaults_withDefaults_returnsTrue() {
        let character = CharacterProfile(
            name: "Test",
            characterDefaults: [.physicalDescription: "default"]
        )
        
        XCTAssertTrue(character.hasCustomDefaults)
    }
    
    // MARK: - hasCustomTheme Tests
    
    func test_hasCustomTheme_withNoTheme_returnsFalse() {
        let character = CharacterProfile(name: "Test")
        
        XCTAssertFalse(character.hasCustomTheme)
    }
    
    func test_hasCustomTheme_withTheme_returnsTrue() {
        let character = CharacterProfile(
            name: "Test",
            characterThemeId: "custom-theme"
        )
        
        XCTAssertTrue(character.hasCustomTheme)
    }
    
    // MARK: - hasCustomGenerator Tests
    
    func test_hasCustomGenerator_withNoGenerator_returnsFalse() {
        let character = CharacterProfile(name: "Test")
        
        XCTAssertFalse(character.hasCustomGenerator)
    }
    
    func test_hasCustomGenerator_withGenerator_returnsTrue() {
        let character = CharacterProfile(
            name: "Test",
            characterDefaultPerchanceGenerator: "custom-gen"
        )
        
        XCTAssertTrue(character.hasCustomGenerator)
    }
    
    // MARK: - effectiveDefault Tests
    
    func test_effectiveDefault_withCharacterDefault_returnsCharacterDefault() {
        let character = CharacterProfile(
            name: "Test",
            characterDefaults: [.physicalDescription: "character default"]
        )
        let globalDefaults: [GlobalDefaultKey: String] = [.physicalDescription: "global default"]
        
        let result = character.effectiveDefault(for: .physicalDescription, globalDefaults: globalDefaults)
        
        XCTAssertEqual(result, "character default")
    }
    
    func test_effectiveDefault_withNoCharacterDefault_returnsGlobalDefault() {
        let character = CharacterProfile(name: "Test")
        let globalDefaults: [GlobalDefaultKey: String] = [.physicalDescription: "global default"]
        
        let result = character.effectiveDefault(for: .physicalDescription, globalDefaults: globalDefaults)
        
        XCTAssertEqual(result, "global default")
    }
    
    func test_effectiveDefault_withNoDefaults_returnsNil() {
        let character = CharacterProfile(name: "Test")
        let globalDefaults: [GlobalDefaultKey: String] = [:]
        
        let result = character.effectiveDefault(for: .physicalDescription, globalDefaults: globalDefaults)
        
        XCTAssertNil(result)
    }
    
    // MARK: - Equatable Tests
    
    func test_equality_withSameId_returnsTrue() {
        let id = UUID()
        let char1 = CharacterProfile(id: id, name: "Test 1")
        let char2 = CharacterProfile(id: id, name: "Test 1")
        
        XCTAssertEqual(char1, char2)
    }
    
    func test_equality_withDifferentId_returnsFalse() {
        let char1 = CharacterProfile(name: "Test")
        let char2 = CharacterProfile(name: "Test")
        
        XCTAssertNotEqual(char1, char2)
    }
    
    // MARK: - Codable Tests
    
    func test_encodeDecode_preservesAllFields() throws {
        let original = CharacterProfile(
            name: "Codable Test",
            bio: "Test bio",
            notes: "Test notes",
            characterDefaults: [.physicalDescription: "default"],
            characterDefaultPerchanceGenerator: "test-gen",
            characterThemeId: "test-theme"
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(CharacterProfile.self, from: data)
        
        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.name, original.name)
        XCTAssertEqual(decoded.bio, original.bio)
        XCTAssertEqual(decoded.notes, original.notes)
        XCTAssertEqual(decoded.characterDefaults, original.characterDefaults)
        XCTAssertEqual(decoded.characterDefaultPerchanceGenerator, original.characterDefaultPerchanceGenerator)
        XCTAssertEqual(decoded.characterThemeId, original.characterThemeId)
    }
    
    // MARK: - Static Data Tests
    
    func test_starterCharacter_hasValidData() {
        let starter = CharacterProfile.starterCharacter
        
        XCTAssertEqual(starter.name, "Luna")
        XCTAssertFalse(starter.bio.isEmpty)
        XCTAssertFalse(starter.notes.isEmpty)
        XCTAssertEqual(starter.prompts.count, 2)
        XCTAssertEqual(starter.links.count, 2)
        XCTAssertTrue(starter.hasCustomDefaults)
    }
}
