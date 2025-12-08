//
//  ScenePromptComposerTests.swift
//  ChanceryTests
//
//  Tests for scene prompt composition logic.
//

import XCTest
@testable import Chancery

final class ScenePromptComposerTests: XCTestCase {
    
    // MARK: - Helper to compose prompt (mirrors ScenePromptEditorView logic)
    
    private func composePrompt(
        prompt: ScenePrompt,
        characters: [CharacterProfile]
    ) -> String {
        var parts: [String] = []
        
        // Add each character's description
        for character in characters {
            let settings = prompt.characterSettings[character.id]
            var characterParts: [String] = []
            
            // Character name and physical description
            if let physical = settings?.physicalDescription, !physical.isEmpty {
                characterParts.append("\(character.name), \(physical)")
            } else {
                characterParts.append(character.name)
            }
            
            // Outfit
            if let outfit = settings?.outfit, !outfit.isEmpty {
                characterParts.append("wearing \(outfit)")
            }
            
            // Pose
            if let pose = settings?.pose, !pose.isEmpty {
                characterParts.append(pose)
            }
            
            // Additional info
            if let additional = settings?.additionalInfo, !additional.isEmpty {
                characterParts.append(additional)
            }
            
            if !characterParts.isEmpty {
                parts.append(characterParts.joined(separator: ", "))
            }
        }
        
        // Scene-wide settings
        if let environment = prompt.environment, !environment.isEmpty {
            parts.append(environment)
        }
        
        if let lighting = prompt.lighting, !lighting.isEmpty {
            parts.append(lighting)
        }
        
        if let style = prompt.styleModifiers, !style.isEmpty {
            parts.append(style)
        }
        
        if let technical = prompt.technicalModifiers, !technical.isEmpty {
            parts.append(technical)
        }
        
        // Additional scene info
        if let additional = prompt.additionalInfo, !additional.isEmpty {
            parts.append(additional)
        }
        
        var result = parts.joined(separator: ", ")
        
        // Add negative prompt if present
        if let negative = prompt.negativePrompt, !negative.isEmpty {
            result += " ### \(negative)"
        }
        
        return result
    }
    
    // MARK: - Empty Prompt Tests
    
    func test_composePrompt_withEmptyPrompt_returnsCharacterNames() {
        let char1 = CharacterProfile(name: "Luna")
        let char2 = CharacterProfile(name: "Aria")
        let prompt = ScenePrompt(title: "Test")
        
        let result = composePrompt(prompt: prompt, characters: [char1, char2])
        
        XCTAssertTrue(result.contains("Luna"))
        XCTAssertTrue(result.contains("Aria"))
    }
    
    func test_composePrompt_withNoCharacters_returnsSceneSettings() {
        let prompt = ScenePrompt(
            title: "Test",
            environment: "Beach",
            lighting: "Sunset"
        )
        
        let result = composePrompt(prompt: prompt, characters: [])
        
        XCTAssertEqual(result, "Beach, Sunset")
    }
    
    // MARK: - Character Settings Tests
    
    func test_composePrompt_withCharacterPhysicalDescription() {
        let char = CharacterProfile(name: "Luna")
        let settings = SceneCharacterSettings(physicalDescription: "silver hair, amber eyes")
        let prompt = ScenePrompt(
            title: "Test",
            characterSettings: [char.id: settings]
        )
        
        let result = composePrompt(prompt: prompt, characters: [char])
        
        XCTAssertTrue(result.contains("Luna, silver hair, amber eyes"))
    }
    
    func test_composePrompt_withCharacterOutfit() {
        let char = CharacterProfile(name: "Luna")
        let settings = SceneCharacterSettings(outfit: "blue dress")
        let prompt = ScenePrompt(
            title: "Test",
            characterSettings: [char.id: settings]
        )
        
        let result = composePrompt(prompt: prompt, characters: [char])
        
        XCTAssertTrue(result.contains("wearing blue dress"))
    }
    
    func test_composePrompt_withCharacterPose() {
        let char = CharacterProfile(name: "Luna")
        let settings = SceneCharacterSettings(pose: "standing confidently")
        let prompt = ScenePrompt(
            title: "Test",
            characterSettings: [char.id: settings]
        )
        
        let result = composePrompt(prompt: prompt, characters: [char])
        
        XCTAssertTrue(result.contains("standing confidently"))
    }
    
    func test_composePrompt_withFullCharacterSettings() {
        let char = CharacterProfile(name: "Luna")
        let settings = SceneCharacterSettings(
            physicalDescription: "silver hair",
            outfit: "armor",
            pose: "fighting stance",
            additionalInfo: "wielding a sword"
        )
        let prompt = ScenePrompt(
            title: "Test",
            characterSettings: [char.id: settings]
        )
        
        let result = composePrompt(prompt: prompt, characters: [char])
        
        XCTAssertTrue(result.contains("Luna, silver hair"))
        XCTAssertTrue(result.contains("wearing armor"))
        XCTAssertTrue(result.contains("fighting stance"))
        XCTAssertTrue(result.contains("wielding a sword"))
    }
    
    // MARK: - Multiple Characters Tests
    
    func test_composePrompt_withMultipleCharacters() {
        let char1 = CharacterProfile(name: "Luna")
        let char2 = CharacterProfile(name: "Aria")
        
        let settings1 = SceneCharacterSettings(physicalDescription: "silver hair")
        let settings2 = SceneCharacterSettings(physicalDescription: "dark hair")
        
        let prompt = ScenePrompt(
            title: "Test",
            characterSettings: [
                char1.id: settings1,
                char2.id: settings2
            ]
        )
        
        let result = composePrompt(prompt: prompt, characters: [char1, char2])
        
        XCTAssertTrue(result.contains("Luna, silver hair"))
        XCTAssertTrue(result.contains("Aria, dark hair"))
    }
    
    // MARK: - Scene Settings Tests
    
    func test_composePrompt_withEnvironment() {
        let prompt = ScenePrompt(
            title: "Test",
            environment: "ancient castle courtyard"
        )
        
        let result = composePrompt(prompt: prompt, characters: [])
        
        XCTAssertTrue(result.contains("ancient castle courtyard"))
    }
    
    func test_composePrompt_withLighting() {
        let prompt = ScenePrompt(
            title: "Test",
            lighting: "dramatic sunset lighting"
        )
        
        let result = composePrompt(prompt: prompt, characters: [])
        
        XCTAssertTrue(result.contains("dramatic sunset lighting"))
    }
    
    func test_composePrompt_withStyleModifiers() {
        let prompt = ScenePrompt(
            title: "Test",
            styleModifiers: "fantasy art style, detailed"
        )
        
        let result = composePrompt(prompt: prompt, characters: [])
        
        XCTAssertTrue(result.contains("fantasy art style, detailed"))
    }
    
    func test_composePrompt_withTechnicalModifiers() {
        let prompt = ScenePrompt(
            title: "Test",
            technicalModifiers: "8k resolution, highly detailed"
        )
        
        let result = composePrompt(prompt: prompt, characters: [])
        
        XCTAssertTrue(result.contains("8k resolution, highly detailed"))
    }
    
    // MARK: - Negative Prompt Tests
    
    func test_composePrompt_withNegativePrompt() {
        let prompt = ScenePrompt(
            title: "Test",
            environment: "Beach",
            negativePrompt: "blurry, low quality"
        )
        
        let result = composePrompt(prompt: prompt, characters: [])
        
        XCTAssertTrue(result.contains("Beach"))
        XCTAssertTrue(result.contains("### blurry, low quality"))
    }
    
    func test_composePrompt_negativePrompt_appearsAtEnd() {
        let prompt = ScenePrompt(
            title: "Test",
            environment: "Beach",
            lighting: "Sunset",
            negativePrompt: "blurry"
        )
        
        let result = composePrompt(prompt: prompt, characters: [])
        
        // Negative prompt should be at the end after ###
        XCTAssertTrue(result.hasSuffix("### blurry"))
    }
    
    // MARK: - Full Scene Prompt Tests
    
    func test_composePrompt_fullSceneWithMultipleCharacters() {
        let char1 = CharacterProfile(name: "Luna")
        let char2 = CharacterProfile(name: "Aria")
        
        let settings1 = SceneCharacterSettings(
            physicalDescription: "silver hair, amber eyes",
            outfit: "light armor",
            pose: "ready to fight"
        )
        let settings2 = SceneCharacterSettings(
            physicalDescription: "dark hair, green eyes",
            outfit: "flowing robes",
            pose: "casting a spell"
        )
        
        let prompt = ScenePrompt(
            title: "Epic Battle",
            environment: "ancient ruins",
            lighting: "dramatic moonlight",
            styleModifiers: "fantasy art",
            technicalModifiers: "8k, detailed",
            negativePrompt: "blurry, watermark",
            characterSettings: [
                char1.id: settings1,
                char2.id: settings2
            ]
        )
        
        let result = composePrompt(prompt: prompt, characters: [char1, char2])
        
        // Verify all parts are present
        XCTAssertTrue(result.contains("Luna"))
        XCTAssertTrue(result.contains("silver hair"))
        XCTAssertTrue(result.contains("light armor"))
        XCTAssertTrue(result.contains("Aria"))
        XCTAssertTrue(result.contains("dark hair"))
        XCTAssertTrue(result.contains("flowing robes"))
        XCTAssertTrue(result.contains("ancient ruins"))
        XCTAssertTrue(result.contains("dramatic moonlight"))
        XCTAssertTrue(result.contains("fantasy art"))
        XCTAssertTrue(result.contains("8k, detailed"))
        XCTAssertTrue(result.contains("### blurry, watermark"))
    }
    
    // MARK: - Edge Cases
    
    func test_composePrompt_withEmptyStrings_ignoresThem() {
        let char = CharacterProfile(name: "Luna")
        let settings = SceneCharacterSettings(
            physicalDescription: "",
            outfit: "",
            pose: ""
        )
        let prompt = ScenePrompt(
            title: "Test",
            environment: "",
            lighting: "",
            characterSettings: [char.id: settings]
        )
        
        let result = composePrompt(prompt: prompt, characters: [char])
        
        // Should just have the character name
        XCTAssertEqual(result, "Luna")
    }
    
    func test_composePrompt_withNilSettings_usesCharacterNameOnly() {
        let char = CharacterProfile(name: "Luna")
        let prompt = ScenePrompt(title: "Test")
        
        let result = composePrompt(prompt: prompt, characters: [char])
        
        XCTAssertEqual(result, "Luna")
    }
}
