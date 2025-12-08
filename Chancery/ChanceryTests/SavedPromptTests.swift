//
//  SavedPromptTests.swift
//  ChanceryTests
//
//  Unit tests for SavedPrompt model functionality.
//

import XCTest
@testable import Chancery

final class SavedPromptTests: XCTestCase {
    
    // MARK: - Initialization Tests
    
    func test_init_withDefaultValues_createsPromptWithEmptyFields() {
        let prompt = SavedPrompt(title: "Test Prompt")
        
        XCTAssertFalse(prompt.id.uuidString.isEmpty)
        XCTAssertEqual(prompt.title, "Test Prompt")
        XCTAssertEqual(prompt.text, "")
        XCTAssertNil(prompt.physicalDescription)
        XCTAssertNil(prompt.outfit)
        XCTAssertNil(prompt.pose)
        XCTAssertNil(prompt.environment)
        XCTAssertNil(prompt.lighting)
        XCTAssertNil(prompt.styleModifiers)
        XCTAssertNil(prompt.technicalModifiers)
        XCTAssertNil(prompt.negativePrompt)
        XCTAssertNil(prompt.additionalInfo)
        XCTAssertTrue(prompt.images.isEmpty)
    }
    
    func test_init_withAllFields_createsPromptWithAllValues() {
        let id = UUID()
        let prompt = SavedPrompt(
            id: id,
            title: "Full Prompt",
            text: "legacy text",
            physicalDescription: "tall, blonde hair",
            outfit: "red dress",
            pose: "standing",
            environment: "forest",
            lighting: "golden hour",
            styleModifiers: "anime style",
            technicalModifiers: "4k, detailed",
            negativePrompt: "blurry, low quality",
            additionalInfo: "extra notes"
        )
        
        XCTAssertEqual(prompt.id, id)
        XCTAssertEqual(prompt.title, "Full Prompt")
        XCTAssertEqual(prompt.text, "legacy text")
        XCTAssertEqual(prompt.physicalDescription, "tall, blonde hair")
        XCTAssertEqual(prompt.outfit, "red dress")
        XCTAssertEqual(prompt.pose, "standing")
        XCTAssertEqual(prompt.environment, "forest")
        XCTAssertEqual(prompt.lighting, "golden hour")
        XCTAssertEqual(prompt.styleModifiers, "anime style")
        XCTAssertEqual(prompt.technicalModifiers, "4k, detailed")
        XCTAssertEqual(prompt.negativePrompt, "blurry, low quality")
        XCTAssertEqual(prompt.additionalInfo, "extra notes")
    }
    
    // MARK: - composedPrompt Tests
    
    func test_composedPrompt_withNoSections_returnsEmptyString() {
        let prompt = SavedPrompt(title: "Empty")
        
        XCTAssertEqual(prompt.composedPrompt, "")
    }
    
    func test_composedPrompt_withSingleSection_returnsSectionContent() {
        let prompt = SavedPrompt(
            title: "Single",
            physicalDescription: "tall woman"
        )
        
        XCTAssertEqual(prompt.composedPrompt, "tall woman")
    }
    
    func test_composedPrompt_withMultipleSections_joinsWithComma() {
        let prompt = SavedPrompt(
            title: "Multiple",
            physicalDescription: "tall woman",
            outfit: "red dress",
            pose: "standing"
        )
        
        XCTAssertEqual(prompt.composedPrompt, "tall woman, red dress, standing")
    }
    
    func test_composedPrompt_withNegativePrompt_appendsWithPipe() {
        let prompt = SavedPrompt(
            title: "With Negative",
            physicalDescription: "tall woman",
            negativePrompt: "blurry"
        )
        
        XCTAssertEqual(prompt.composedPrompt, "tall woman | blurry")
    }
    
    func test_composedPrompt_withOnlyNegativePrompt_startsWithPipe() {
        let prompt = SavedPrompt(
            title: "Only Negative",
            negativePrompt: "blurry"
        )
        
        XCTAssertEqual(prompt.composedPrompt, "| blurry")
    }
    
    func test_composedPrompt_withWhitespaceOnlySections_ignoresWhitespace() {
        let prompt = SavedPrompt(
            title: "Whitespace",
            physicalDescription: "   ",
            outfit: "red dress",
            pose: "  \n  "
        )
        
        XCTAssertEqual(prompt.composedPrompt, "red dress")
    }
    
    func test_composedPrompt_includesAllSectionsInOrder() {
        let prompt = SavedPrompt(
            title: "All Sections",
            physicalDescription: "physical",
            outfit: "outfit",
            pose: "pose",
            environment: "environment",
            lighting: "lighting",
            styleModifiers: "style",
            technicalModifiers: "technical",
            additionalInfo: "additional"
        )
        
        XCTAssertEqual(
            prompt.composedPrompt,
            "physical, outfit, pose, environment, lighting, style, technical, additional"
        )
    }
    
    // MARK: - hasContent Tests
    
    func test_hasContent_withNoSections_returnsFalse() {
        let prompt = SavedPrompt(title: "Empty")
        
        XCTAssertFalse(prompt.hasContent)
    }
    
    func test_hasContent_withOnlyWhitespaceSections_returnsFalse() {
        let prompt = SavedPrompt(
            title: "Whitespace",
            physicalDescription: "   ",
            outfit: "\n\t"
        )
        
        XCTAssertFalse(prompt.hasContent)
    }
    
    func test_hasContent_withAnySectionFilled_returnsTrue() {
        let prompt = SavedPrompt(
            title: "Has Content",
            environment: "forest"
        )
        
        XCTAssertTrue(prompt.hasContent)
    }
    
    func test_hasContent_withOnlyNegativePrompt_returnsTrue() {
        let prompt = SavedPrompt(
            title: "Only Negative",
            negativePrompt: "blurry"
        )
        
        XCTAssertTrue(prompt.hasContent)
    }
    
    // MARK: - imageCount Tests
    
    func test_imageCount_withNoImages_returnsZero() {
        let prompt = SavedPrompt(title: "No Images")
        
        XCTAssertEqual(prompt.imageCount, 0)
    }
    
    func test_imageCount_withImages_returnsCorrectCount() {
        let images = [
            PromptImage(id: UUID(), data: Data()),
            PromptImage(id: UUID(), data: Data())
        ]
        let prompt = SavedPrompt(title: "With Images", images: images)
        
        XCTAssertEqual(prompt.imageCount, 2)
    }
    
    // MARK: - autoSummary Tests
    
    func test_autoSummary_withNoContent_returnsUntitledPrompt() {
        let prompt = SavedPrompt(title: "Empty")
        
        XCTAssertEqual(prompt.autoSummary, "Untitled Prompt")
    }
    
    func test_autoSummary_withPhysicalDescription_usesPhysicalDescription() {
        let prompt = SavedPrompt(
            title: "Test",
            physicalDescription: "tall woman with blonde hair"
        )
        
        XCTAssertEqual(prompt.autoSummary, "tall woman with blonde hair")
    }
    
    func test_autoSummary_withMultipleParts_combinesTwoParts() {
        let prompt = SavedPrompt(
            title: "Test",
            physicalDescription: "tall woman",
            environment: "forest"
        )
        
        XCTAssertEqual(prompt.autoSummary, "tall woman, forest")
    }
    
    func test_autoSummary_withLongContent_truncatesAt80Chars() {
        let longDescription = String(repeating: "a", count: 100)
        let prompt = SavedPrompt(
            title: "Test",
            physicalDescription: longDescription
        )
        
        XCTAssertTrue(prompt.autoSummary.count <= 80)
        XCTAssertTrue(prompt.autoSummary.hasSuffix("..."))
    }
    
    // MARK: - Section Access Tests
    
    func test_content_forKind_returnsCorrectSection() {
        let prompt = SavedPrompt(
            title: "Test",
            physicalDescription: "physical",
            outfit: "outfit",
            pose: "pose",
            environment: "environment",
            lighting: "lighting",
            styleModifiers: "style",
            technicalModifiers: "technical",
            negativePrompt: "negative"
        )
        
        XCTAssertEqual(prompt.content(for: .physicalDescription), "physical")
        XCTAssertEqual(prompt.content(for: .outfit), "outfit")
        XCTAssertEqual(prompt.content(for: .pose), "pose")
        XCTAssertEqual(prompt.content(for: .environment), "environment")
        XCTAssertEqual(prompt.content(for: .lighting), "lighting")
        XCTAssertEqual(prompt.content(for: .style), "style")
        XCTAssertEqual(prompt.content(for: .technical), "technical")
        XCTAssertEqual(prompt.content(for: .negative), "negative")
    }
    
    func test_setContent_forKind_updatesCorrectSection() {
        var prompt = SavedPrompt(title: "Test")
        
        prompt.setContent("new physical", for: .physicalDescription)
        prompt.setContent("new outfit", for: .outfit)
        
        XCTAssertEqual(prompt.physicalDescription, "new physical")
        XCTAssertEqual(prompt.outfit, "new outfit")
    }
    
    func test_presetName_forKind_returnsCorrectPresetName() {
        let prompt = SavedPrompt(
            title: "Test",
            physicalDescriptionPresetName: "preset1",
            outfitPresetName: "preset2"
        )
        
        XCTAssertEqual(prompt.presetName(for: .physicalDescription), "preset1")
        XCTAssertEqual(prompt.presetName(for: .outfit), "preset2")
        XCTAssertNil(prompt.presetName(for: .pose))
    }
    
    func test_setPresetName_forKind_updatesCorrectPresetName() {
        var prompt = SavedPrompt(title: "Test")
        
        prompt.setPresetName("new preset", for: .physicalDescription)
        
        XCTAssertEqual(prompt.physicalDescriptionPresetName, "new preset")
    }
    
    // MARK: - Equatable Tests
    
    func test_equality_withSameId_returnsTrue() {
        let id = UUID()
        let prompt1 = SavedPrompt(id: id, title: "Test 1")
        let prompt2 = SavedPrompt(id: id, title: "Test 1")
        
        XCTAssertEqual(prompt1, prompt2)
    }
    
    func test_equality_withDifferentId_returnsFalse() {
        let prompt1 = SavedPrompt(title: "Test")
        let prompt2 = SavedPrompt(title: "Test")
        
        XCTAssertNotEqual(prompt1, prompt2)
    }
    
    // MARK: - Codable Tests
    
    func test_encodeDecode_preservesAllFields() throws {
        let original = SavedPrompt(
            title: "Codable Test",
            physicalDescription: "physical",
            outfit: "outfit",
            negativePrompt: "negative",
            physicalDescriptionPresetName: "preset"
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(SavedPrompt.self, from: data)
        
        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.title, original.title)
        XCTAssertEqual(decoded.physicalDescription, original.physicalDescription)
        XCTAssertEqual(decoded.outfit, original.outfit)
        XCTAssertEqual(decoded.negativePrompt, original.negativePrompt)
        XCTAssertEqual(decoded.physicalDescriptionPresetName, original.physicalDescriptionPresetName)
    }
}
