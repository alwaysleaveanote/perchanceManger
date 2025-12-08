//
//  PromptComposerTests.swift
//  ChanceryTests
//
//  Unit tests for PromptComposer service functionality.
//

import XCTest
@testable import Chancery

final class PromptComposerTests: XCTestCase {
    
    // MARK: - Test Helpers
    
    private func makeEmptyCharacter(name: String = "") -> CharacterProfile {
        CharacterProfile(
            name: name,
            bio: "",
            notes: "",
            prompts: []
        )
    }
    
    private func makeEmptyPrompt() -> SavedPrompt {
        SavedPrompt(title: "Test")
    }
    
    // MARK: - Basic Composition Tests
    
    func test_composePrompt_withEmptyInputs_returnsEmptyString() {
        let character = makeEmptyCharacter()
        let prompt = makeEmptyPrompt()
        
        let result = PromptComposer.composePrompt(
            character: character,
            prompt: prompt,
            stylePreset: nil,
            globalDefaults: [:]
        )
        
        XCTAssertEqual(result, "")
    }
    
    func test_composePrompt_withCharacterName_includesNameSection() {
        let character = makeEmptyCharacter(name: "Rin")
        let prompt = makeEmptyPrompt()
        
        let result = PromptComposer.composePrompt(
            character: character,
            prompt: prompt,
            stylePreset: nil,
            globalDefaults: [:]
        )
        
        XCTAssertTrue(result.contains("Name:\nRin"))
    }
    
    func test_composePrompt_withWhitespaceOnlyName_excludesNameSection() {
        let character = makeEmptyCharacter(name: "   ")
        let prompt = makeEmptyPrompt()
        
        let result = PromptComposer.composePrompt(
            character: character,
            prompt: prompt,
            stylePreset: nil,
            globalDefaults: [:]
        )
        
        XCTAssertFalse(result.contains("Name:"))
    }
    
    // MARK: - Prompt Section Tests
    
    func test_composePrompt_withPromptPhysicalDescription_includesSection() {
        let character = makeEmptyCharacter()
        let prompt = SavedPrompt(
            title: "Test",
            physicalDescription: "tall woman with blonde hair"
        )
        
        let result = PromptComposer.composePrompt(
            character: character,
            prompt: prompt,
            stylePreset: nil,
            globalDefaults: [:]
        )
        
        XCTAssertTrue(result.contains("Physical Description:\ntall woman with blonde hair"))
    }
    
    func test_composePrompt_withAllPromptSections_includesAllSections() {
        let character = makeEmptyCharacter(name: "Test Character")
        let prompt = SavedPrompt(
            title: "Full Prompt",
            physicalDescription: "physical desc",
            outfit: "outfit desc",
            pose: "pose desc",
            environment: "environment desc",
            lighting: "lighting desc",
            styleModifiers: "style desc",
            technicalModifiers: "technical desc",
            negativePrompt: "negative desc",
            additionalInfo: "additional info"
        )
        
        let result = PromptComposer.composePrompt(
            character: character,
            prompt: prompt,
            stylePreset: nil,
            globalDefaults: [:]
        )
        
        XCTAssertTrue(result.contains("Physical Description:\nphysical desc"))
        XCTAssertTrue(result.contains("Outfit:\noutfit desc"))
        XCTAssertTrue(result.contains("Pose:\npose desc"))
        XCTAssertTrue(result.contains("Environment:\nenvironment desc"))
        XCTAssertTrue(result.contains("Lighting:\nlighting desc"))
        XCTAssertTrue(result.contains("Style Modifiers:\nstyle desc"))
        XCTAssertTrue(result.contains("Technical Modifiers:\ntechnical desc"))
        XCTAssertTrue(result.contains("Negative prompt: negative desc"))
        XCTAssertTrue(result.contains("Additional Information:\nadditional info"))
    }
    
    // MARK: - Fallback Priority Tests
    
    func test_composePrompt_promptValueTakesPrecedenceOverCharacterDefault() {
        var character = makeEmptyCharacter()
        character.characterDefaults[.physicalDescription] = "character default"
        
        let prompt = SavedPrompt(
            title: "Test",
            physicalDescription: "prompt value"
        )
        
        let result = PromptComposer.composePrompt(
            character: character,
            prompt: prompt,
            stylePreset: nil,
            globalDefaults: [.physicalDescription: "global default"]
        )
        
        XCTAssertTrue(result.contains("prompt value"))
        XCTAssertFalse(result.contains("character default"))
        XCTAssertFalse(result.contains("global default"))
    }
    
    func test_composePrompt_characterDefaultTakesPrecedenceOverGlobalDefault() {
        var character = makeEmptyCharacter()
        character.characterDefaults[.physicalDescription] = "character default"
        
        let prompt = makeEmptyPrompt()
        
        let result = PromptComposer.composePrompt(
            character: character,
            prompt: prompt,
            stylePreset: nil,
            globalDefaults: [.physicalDescription: "global default"]
        )
        
        XCTAssertTrue(result.contains("character default"))
        XCTAssertFalse(result.contains("global default"))
    }
    
    func test_composePrompt_globalDefaultUsedWhenNoOtherValues() {
        let character = makeEmptyCharacter()
        let prompt = makeEmptyPrompt()
        
        let result = PromptComposer.composePrompt(
            character: character,
            prompt: prompt,
            stylePreset: nil,
            globalDefaults: [.physicalDescription: "global default"]
        )
        
        XCTAssertTrue(result.contains("global default"))
    }
    
    func test_composePrompt_whitespaceOnlyPromptValueFallsBackToCharacterDefault() {
        var character = makeEmptyCharacter()
        character.characterDefaults[.physicalDescription] = "character default"
        
        let prompt = SavedPrompt(
            title: "Test",
            physicalDescription: "   "
        )
        
        let result = PromptComposer.composePrompt(
            character: character,
            prompt: prompt,
            stylePreset: nil,
            globalDefaults: [:]
        )
        
        XCTAssertTrue(result.contains("character default"))
    }
    
    // MARK: - Negative Prompt Tests
    
    func test_composePrompt_negativePromptWithoutPrefix_addsPrefix() {
        let character = makeEmptyCharacter()
        let prompt = SavedPrompt(
            title: "Test",
            negativePrompt: "blurry, low quality"
        )
        
        let result = PromptComposer.composePrompt(
            character: character,
            prompt: prompt,
            stylePreset: nil,
            globalDefaults: [:]
        )
        
        XCTAssertTrue(result.contains("Negative prompt: blurry, low quality"))
    }
    
    func test_composePrompt_negativePromptWithExistingPrefix_preservesPrefix() {
        let character = makeEmptyCharacter()
        let prompt = SavedPrompt(
            title: "Test",
            negativePrompt: "Negative prompt: already prefixed"
        )
        
        let result = PromptComposer.composePrompt(
            character: character,
            prompt: prompt,
            stylePreset: nil,
            globalDefaults: [:]
        )
        
        // Should not double-prefix
        XCTAssertTrue(result.contains("Negative prompt: already prefixed"))
        XCTAssertFalse(result.contains("Negative prompt: Negative prompt:"))
    }
    
    // MARK: - Section Ordering Tests
    
    func test_composePrompt_sectionsAreInCorrectOrder() {
        let character = makeEmptyCharacter(name: "Test")
        let prompt = SavedPrompt(
            title: "Test",
            physicalDescription: "1-physical",
            outfit: "2-outfit",
            pose: "3-pose",
            environment: "4-environment",
            lighting: "5-lighting",
            styleModifiers: "6-style",
            technicalModifiers: "7-technical",
            negativePrompt: "8-negative",
            additionalInfo: "9-additional"
        )
        
        let result = PromptComposer.composePrompt(
            character: character,
            prompt: prompt,
            stylePreset: nil,
            globalDefaults: [:]
        )
        
        // Verify order by checking relative positions
        let namePos = result.range(of: "Name:")?.lowerBound
        let physicalPos = result.range(of: "Physical Description:")?.lowerBound
        let outfitPos = result.range(of: "Outfit:")?.lowerBound
        let posePos = result.range(of: "Pose:")?.lowerBound
        let envPos = result.range(of: "Environment:")?.lowerBound
        let lightPos = result.range(of: "Lighting:")?.lowerBound
        let stylePos = result.range(of: "Style Modifiers:")?.lowerBound
        let techPos = result.range(of: "Technical Modifiers:")?.lowerBound
        let negPos = result.range(of: "Negative prompt:")?.lowerBound
        let addPos = result.range(of: "Additional Information:")?.lowerBound
        
        XCTAssertNotNil(namePos)
        XCTAssertNotNil(physicalPos)
        XCTAssertNotNil(outfitPos)
        XCTAssertNotNil(posePos)
        XCTAssertNotNil(envPos)
        XCTAssertNotNil(lightPos)
        XCTAssertNotNil(stylePos)
        XCTAssertNotNil(techPos)
        XCTAssertNotNil(negPos)
        XCTAssertNotNil(addPos)
        
        // Verify order
        XCTAssertTrue(namePos! < physicalPos!)
        XCTAssertTrue(physicalPos! < outfitPos!)
        XCTAssertTrue(outfitPos! < posePos!)
        XCTAssertTrue(posePos! < envPos!)
        XCTAssertTrue(envPos! < lightPos!)
        XCTAssertTrue(lightPos! < stylePos!)
        XCTAssertTrue(stylePos! < techPos!)
        XCTAssertTrue(techPos! < negPos!)
        XCTAssertTrue(negPos! < addPos!)
    }
    
    // MARK: - Section Separator Tests
    
    func test_composePrompt_sectionsAreSeparatedByDoubleNewline() {
        let character = makeEmptyCharacter(name: "Test")
        let prompt = SavedPrompt(
            title: "Test",
            physicalDescription: "physical"
        )
        
        let result = PromptComposer.composePrompt(
            character: character,
            prompt: prompt,
            stylePreset: nil,
            globalDefaults: [:]
        )
        
        XCTAssertTrue(result.contains("\n\n"))
    }
    
    // MARK: - Additional Info Tests
    
    func test_composePrompt_additionalInfoDoesNotUseDefaults() {
        var character = makeEmptyCharacter()
        // Note: There's no additionalInfo key in GlobalDefaultKey, 
        // so this tests that additionalInfo only comes from the prompt
        
        let prompt = SavedPrompt(
            title: "Test",
            additionalInfo: "prompt additional info"
        )
        
        let result = PromptComposer.composePrompt(
            character: character,
            prompt: prompt,
            stylePreset: nil,
            globalDefaults: [:]
        )
        
        XCTAssertTrue(result.contains("Additional Information:\nprompt additional info"))
    }
}
