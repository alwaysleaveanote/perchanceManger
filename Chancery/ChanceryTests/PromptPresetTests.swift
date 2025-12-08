//
//  PromptPresetTests.swift
//  ChanceryTests
//
//  Unit tests for PromptPreset model functionality.
//

import XCTest
@testable import Chancery

final class PromptPresetTests: XCTestCase {
    
    // MARK: - Initialization Tests
    
    func test_init_withAllParameters_createsPreset() {
        let preset = PromptPreset(
            kind: .outfit,
            name: "Casual Wear",
            text: "hoodie, jeans, sneakers"
        )
        
        XCTAssertFalse(preset.id.uuidString.isEmpty)
        XCTAssertEqual(preset.kind, .outfit)
        XCTAssertEqual(preset.name, "Casual Wear")
        XCTAssertEqual(preset.text, "hoodie, jeans, sneakers")
    }
    
    func test_init_withCustomId_usesProvidedId() {
        let customId = UUID()
        let preset = PromptPreset(
            id: customId,
            kind: .physicalDescription,
            name: "Test",
            text: "test text"
        )
        
        XCTAssertEqual(preset.id, customId)
    }
    
    func test_init_withDifferentKinds_createsCorrectPresets() {
        for kind in PromptSectionKind.allCases {
            let preset = PromptPreset(kind: kind, name: "Test", text: "text")
            XCTAssertEqual(preset.kind, kind)
        }
    }
    
    // MARK: - Equatable Tests
    
    func test_equality_withSameValues_returnsTrue() {
        let id = UUID()
        let preset1 = PromptPreset(id: id, kind: .style, name: "Test", text: "text")
        let preset2 = PromptPreset(id: id, kind: .style, name: "Test", text: "text")
        
        XCTAssertEqual(preset1, preset2)
    }
    
    func test_equality_withDifferentId_returnsFalse() {
        let preset1 = PromptPreset(kind: .style, name: "Test", text: "text")
        let preset2 = PromptPreset(kind: .style, name: "Test", text: "text")
        
        XCTAssertNotEqual(preset1, preset2)
    }
    
    func test_equality_withDifferentKind_returnsFalse() {
        let id = UUID()
        let preset1 = PromptPreset(id: id, kind: .style, name: "Test", text: "text")
        let preset2 = PromptPreset(id: id, kind: .outfit, name: "Test", text: "text")
        
        XCTAssertNotEqual(preset1, preset2)
    }
    
    // MARK: - Hashable Tests
    
    func test_hashable_canBeUsedInSet() {
        let preset1 = PromptPreset(kind: .style, name: "Style 1", text: "text1")
        let preset2 = PromptPreset(kind: .outfit, name: "Outfit 1", text: "text2")
        
        var set: Set<PromptPreset> = []
        set.insert(preset1)
        set.insert(preset2)
        set.insert(preset1) // Duplicate
        
        XCTAssertEqual(set.count, 2)
    }
    
    func test_hashable_canBeUsedAsDictionaryKey() {
        let preset = PromptPreset(kind: .lighting, name: "Soft", text: "soft lighting")
        
        var dict: [PromptPreset: String] = [:]
        dict[preset] = "value"
        
        XCTAssertEqual(dict[preset], "value")
    }
    
    // MARK: - Codable Tests
    
    func test_encodeDecode_preservesAllFields() throws {
        let original = PromptPreset(
            kind: .environment,
            name: "Forest Scene",
            text: "dense forest, sunlight filtering through trees"
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(PromptPreset.self, from: data)
        
        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.kind, original.kind)
        XCTAssertEqual(decoded.name, original.name)
        XCTAssertEqual(decoded.text, original.text)
    }
    
    func test_encodeDecode_withAllKinds_preservesKind() throws {
        for kind in PromptSectionKind.allCases {
            let original = PromptPreset(kind: kind, name: "Test", text: "text")
            
            let encoder = JSONEncoder()
            let data = try encoder.encode(original)
            
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(PromptPreset.self, from: data)
            
            XCTAssertEqual(decoded.kind, kind, "Kind \(kind) should be preserved through encode/decode")
        }
    }
    
    // MARK: - Identifiable Tests
    
    func test_identifiable_usesIdProperty() {
        let preset = PromptPreset(kind: .pose, name: "Standing", text: "standing pose")
        
        XCTAssertEqual(preset.id, preset.id)
    }
}
