//
//  PromptPresetStoreTests.swift
//  ChanceryTests
//
//  Tests for PromptPresetStore functionality including preset filtering,
//  lookup, and sample data validation.
//

import XCTest
@testable import Chancery

final class PromptPresetStoreTests: XCTestCase {
    
    // MARK: - Sample Data Tests
    
    func test_samplePresets_isNotEmpty() {
        XCTAssertFalse(PromptPresetStore.samplePresets.isEmpty)
    }
    
    func test_samplePresets_containsCommonSectionKinds() {
        // Sample presets should cover the most commonly used section kinds
        let kindsInSamples = Set(PromptPresetStore.samplePresets.map { $0.kind })
        
        // These are the kinds that have sample presets defined
        let expectedKinds: [PromptSectionKind] = [
            .outfit, .pose, .environment, .lighting, .style, .technical, .negative
        ]
        
        for kind in expectedKinds {
            XCTAssertTrue(kindsInSamples.contains(kind), "Sample presets should include \(kind)")
        }
    }
    
    func test_samplePresets_haveNonEmptyNames() {
        for preset in PromptPresetStore.samplePresets {
            XCTAssertFalse(preset.name.isEmpty, "Preset should have a name")
        }
    }
    
    func test_samplePresets_haveNonEmptyText() {
        for preset in PromptPresetStore.samplePresets {
            XCTAssertFalse(preset.text.isEmpty, "Preset \(preset.name) should have text")
        }
    }
    
    func test_samplePresets_haveUniqueIds() {
        let ids = PromptPresetStore.samplePresets.map { $0.id }
        let uniqueIds = Set(ids)
        
        XCTAssertEqual(ids.count, uniqueIds.count, "All sample presets should have unique IDs")
    }
    
    // MARK: - Sample Defaults Tests
    
    func test_sampleDefaults_isNotEmpty() {
        XCTAssertFalse(PromptPresetStore.sampleDefaults.isEmpty)
    }
    
    func test_sampleDefaults_containsExpectedKeys() {
        // Should have defaults for common sections
        let expectedKeys: [GlobalDefaultKey] = [.lighting, .style, .technical, .negative]
        
        for key in expectedKeys {
            XCTAssertNotNil(PromptPresetStore.sampleDefaults[key], "Should have default for \(key)")
        }
    }
    
    // MARK: - Preset Filtering Tests (using sample data)
    
    func test_filterPresetsByKind_returnsCorrectPresets() {
        // Given sample presets
        let presets = PromptPresetStore.samplePresets
        
        // When filtering by kind
        let outfitPresets = presets.filter { $0.kind == .outfit }
        
        // Then all returned presets should be of that kind
        for preset in outfitPresets {
            XCTAssertEqual(preset.kind, .outfit)
        }
        XCTAssertFalse(outfitPresets.isEmpty, "Should have outfit presets in samples")
    }
    
    func test_filterPresetsByKind_lightingHasMultiplePresets() {
        // Lighting should have comprehensive presets
        let lightingPresets = PromptPresetStore.samplePresets.filter { $0.kind == .lighting }
        
        XCTAssertGreaterThan(lightingPresets.count, 5, "Should have multiple lighting presets")
    }
    
    func test_filterPresetsByKind_styleHasMultiplePresets() {
        // Style should have comprehensive presets
        let stylePresets = PromptPresetStore.samplePresets.filter { $0.kind == .style }
        
        XCTAssertGreaterThan(stylePresets.count, 5, "Should have multiple style presets")
    }
    
    func test_filterPresetsByKind_negativeHasMultiplePresets() {
        // Negative should have comprehensive presets
        let negativePresets = PromptPresetStore.samplePresets.filter { $0.kind == .negative }
        
        XCTAssertGreaterThan(negativePresets.count, 3, "Should have multiple negative presets")
    }
    
    // MARK: - Preset Lookup Tests (using sample data)
    
    func test_findPresetById_existingPreset_returnsPreset() {
        // Given a known preset
        guard let knownPreset = PromptPresetStore.samplePresets.first else {
            XCTFail("Should have at least one sample preset")
            return
        }
        
        // When looking up by ID
        let found = PromptPresetStore.samplePresets.first { $0.id == knownPreset.id }
        
        // Then should find it
        XCTAssertNotNil(found)
        XCTAssertEqual(found?.name, knownPreset.name)
    }
    
    func test_findPresetById_nonexistentId_returnsNil() {
        // Given a random UUID
        let randomId = UUID()
        
        // When looking up by ID
        let found = PromptPresetStore.samplePresets.first { $0.id == randomId }
        
        // Then should not find it
        XCTAssertNil(found)
    }
    
    // MARK: - Preset Content Quality Tests
    
    func test_lightingPresets_containDescriptiveText() {
        // Lighting presets should have detailed descriptions
        let lightingPresets = PromptPresetStore.samplePresets.filter { $0.kind == .lighting }
        
        for preset in lightingPresets {
            XCTAssertGreaterThan(preset.text.count, 20, "Lighting preset '\(preset.name)' should have detailed text")
        }
    }
    
    func test_stylePresets_containDescriptiveText() {
        // Style presets should have detailed descriptions
        let stylePresets = PromptPresetStore.samplePresets.filter { $0.kind == .style }
        
        for preset in stylePresets {
            XCTAssertGreaterThan(preset.text.count, 20, "Style preset '\(preset.name)' should have detailed text")
        }
    }
    
    func test_negativePresets_containCommonTerms() {
        // Negative presets should contain common quality issues
        let negativePresets = PromptPresetStore.samplePresets.filter { $0.kind == .negative }
        
        // At least one should mention "blurry" or "low quality"
        let hasQualityTerms = negativePresets.contains { preset in
            preset.text.lowercased().contains("blurry") ||
            preset.text.lowercased().contains("low quality")
        }
        
        XCTAssertTrue(hasQualityTerms, "Negative presets should include quality-related terms")
    }
    
    func test_technicalPresets_containCameraTerms() {
        // Technical presets should contain camera/photography terms
        let technicalPresets = PromptPresetStore.samplePresets.filter { $0.kind == .technical }
        
        let hasCameraTerms = technicalPresets.contains { preset in
            let text = preset.text.lowercased()
            return text.contains("focus") ||
                   text.contains("resolution") ||
                   text.contains("lens") ||
                   text.contains("aperture")
        }
        
        XCTAssertTrue(hasCameraTerms, "Technical presets should include camera-related terms")
    }
}

// MARK: - PromptPreset Model Tests

extension PromptPresetStoreTests {
    
    func test_promptPreset_init_setsAllProperties() {
        // Given
        let kind = PromptSectionKind.outfit
        let name = "Test Preset"
        let text = "test preset text"
        
        // When
        let preset = PromptPreset(kind: kind, name: name, text: text)
        
        // Then
        XCTAssertEqual(preset.kind, kind)
        XCTAssertEqual(preset.name, name)
        XCTAssertEqual(preset.text, text)
        XCTAssertNotNil(preset.id)
    }
    
    func test_promptPreset_equality_withSameValues_returnsTrue() {
        let id = UUID()
        let preset1 = PromptPreset(id: id, kind: .pose, name: "Test", text: "text")
        let preset2 = PromptPreset(id: id, kind: .pose, name: "Test", text: "text")
        
        XCTAssertEqual(preset1, preset2)
    }
    
    func test_promptPreset_equality_withDifferentId_returnsFalse() {
        let preset1 = PromptPreset(kind: .pose, name: "Test", text: "text")
        let preset2 = PromptPreset(kind: .pose, name: "Test", text: "text")
        
        XCTAssertNotEqual(preset1, preset2)
    }
    
    func test_promptPreset_hashable_canBeUsedInSet() {
        let preset1 = PromptPreset(kind: .outfit, name: "A", text: "a")
        let preset2 = PromptPreset(kind: .pose, name: "B", text: "b")
        let preset3 = PromptPreset(kind: .lighting, name: "C", text: "c")
        
        let set: Set<PromptPreset> = [preset1, preset2, preset3]
        
        XCTAssertEqual(set.count, 3)
        XCTAssertTrue(set.contains(preset1))
    }
}
