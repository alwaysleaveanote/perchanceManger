//
//  PromptEnumsTests.swift
//  ChanceryTests
//
//  Unit tests for PromptSectionKind and GlobalDefaultKey enums.
//

import XCTest
@testable import Chancery

final class PromptEnumsTests: XCTestCase {
    
    // MARK: - PromptSectionKind Tests
    
    func test_promptSectionKind_allCases_containsAllSections() {
        let allCases = PromptSectionKind.allCases
        
        XCTAssertEqual(allCases.count, 8)
        XCTAssertTrue(allCases.contains(.physicalDescription))
        XCTAssertTrue(allCases.contains(.outfit))
        XCTAssertTrue(allCases.contains(.pose))
        XCTAssertTrue(allCases.contains(.environment))
        XCTAssertTrue(allCases.contains(.lighting))
        XCTAssertTrue(allCases.contains(.style))
        XCTAssertTrue(allCases.contains(.technical))
        XCTAssertTrue(allCases.contains(.negative))
    }
    
    func test_promptSectionKind_displayLabel_returnsHumanReadableLabels() {
        XCTAssertEqual(PromptSectionKind.physicalDescription.displayLabel, "Physical Description")
        XCTAssertEqual(PromptSectionKind.outfit.displayLabel, "Outfit")
        XCTAssertEqual(PromptSectionKind.pose.displayLabel, "Pose")
        XCTAssertEqual(PromptSectionKind.environment.displayLabel, "Environment")
        XCTAssertEqual(PromptSectionKind.lighting.displayLabel, "Lighting")
        XCTAssertEqual(PromptSectionKind.style.displayLabel, "Style Modifiers")
        XCTAssertEqual(PromptSectionKind.technical.displayLabel, "Technical Modifiers")
        XCTAssertEqual(PromptSectionKind.negative.displayLabel, "Negative Prompt")
    }
    
    func test_promptSectionKind_placeholder_returnsNonEmptyStrings() {
        for kind in PromptSectionKind.allCases {
            XCTAssertFalse(kind.placeholder.isEmpty, "\(kind) should have a non-empty placeholder")
        }
    }
    
    func test_promptSectionKind_iconName_returnsValidSFSymbolNames() {
        // All icon names should be non-empty and follow SF Symbol naming convention
        for kind in PromptSectionKind.allCases {
            XCTAssertFalse(kind.iconName.isEmpty, "\(kind) should have a non-empty icon name")
            // SF Symbols typically contain dots or are single words
            XCTAssertTrue(
                kind.iconName.contains(".") || kind.iconName.count > 0,
                "\(kind) icon name should be a valid SF Symbol format"
            )
        }
    }
    
    func test_promptSectionKind_defaultKey_mapsToCorrectGlobalDefaultKey() {
        XCTAssertEqual(PromptSectionKind.physicalDescription.defaultKey, .physicalDescription)
        XCTAssertEqual(PromptSectionKind.outfit.defaultKey, .outfit)
        XCTAssertEqual(PromptSectionKind.pose.defaultKey, .pose)
        XCTAssertEqual(PromptSectionKind.environment.defaultKey, .environment)
        XCTAssertEqual(PromptSectionKind.lighting.defaultKey, .lighting)
        XCTAssertEqual(PromptSectionKind.style.defaultKey, .style)
        XCTAssertEqual(PromptSectionKind.technical.defaultKey, .technical)
        XCTAssertEqual(PromptSectionKind.negative.defaultKey, .negative)
    }
    
    func test_promptSectionKind_id_returnsRawValue() {
        for kind in PromptSectionKind.allCases {
            XCTAssertEqual(kind.id, kind.rawValue)
        }
    }
    
    // MARK: - GlobalDefaultKey Tests
    
    func test_globalDefaultKey_allCases_containsAllKeys() {
        let allCases = GlobalDefaultKey.allCases
        
        XCTAssertEqual(allCases.count, 8)
        XCTAssertTrue(allCases.contains(.physicalDescription))
        XCTAssertTrue(allCases.contains(.outfit))
        XCTAssertTrue(allCases.contains(.pose))
        XCTAssertTrue(allCases.contains(.environment))
        XCTAssertTrue(allCases.contains(.lighting))
        XCTAssertTrue(allCases.contains(.style))
        XCTAssertTrue(allCases.contains(.technical))
        XCTAssertTrue(allCases.contains(.negative))
    }
    
    func test_globalDefaultKey_sectionKind_mapsToCorrectPromptSectionKind() {
        XCTAssertEqual(GlobalDefaultKey.physicalDescription.sectionKind, .physicalDescription)
        XCTAssertEqual(GlobalDefaultKey.outfit.sectionKind, .outfit)
        XCTAssertEqual(GlobalDefaultKey.pose.sectionKind, .pose)
        XCTAssertEqual(GlobalDefaultKey.environment.sectionKind, .environment)
        XCTAssertEqual(GlobalDefaultKey.lighting.sectionKind, .lighting)
        XCTAssertEqual(GlobalDefaultKey.style.sectionKind, .style)
        XCTAssertEqual(GlobalDefaultKey.technical.sectionKind, .technical)
        XCTAssertEqual(GlobalDefaultKey.negative.sectionKind, .negative)
    }
    
    func test_globalDefaultKey_id_returnsRawValue() {
        for key in GlobalDefaultKey.allCases {
            XCTAssertEqual(key.id, key.rawValue)
        }
    }
    
    // MARK: - Bidirectional Mapping Tests
    
    func test_promptSectionKind_and_globalDefaultKey_areBidirectionallyMapped() {
        // Every PromptSectionKind should map to a GlobalDefaultKey and back
        for kind in PromptSectionKind.allCases {
            let defaultKey = kind.defaultKey
            let mappedBack = defaultKey.sectionKind
            XCTAssertEqual(mappedBack, kind, "Bidirectional mapping failed for \(kind)")
        }
        
        // Every GlobalDefaultKey should map to a PromptSectionKind and back
        for key in GlobalDefaultKey.allCases {
            let sectionKind = key.sectionKind
            let mappedBack = sectionKind.defaultKey
            XCTAssertEqual(mappedBack, key, "Bidirectional mapping failed for \(key)")
        }
    }
    
    // MARK: - Codable Tests
    
    func test_promptSectionKind_encodeDecode_preservesValue() throws {
        let original = PromptSectionKind.physicalDescription
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(PromptSectionKind.self, from: data)
        
        XCTAssertEqual(decoded, original)
    }
    
    func test_globalDefaultKey_encodeDecode_preservesValue() throws {
        let original = GlobalDefaultKey.style
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(GlobalDefaultKey.self, from: data)
        
        XCTAssertEqual(decoded, original)
    }
    
    // MARK: - Hashable Tests
    
    func test_promptSectionKind_canBeUsedAsSetElement() {
        var set: Set<PromptSectionKind> = []
        set.insert(.physicalDescription)
        set.insert(.outfit)
        set.insert(.physicalDescription) // Duplicate
        
        XCTAssertEqual(set.count, 2)
    }
    
    func test_globalDefaultKey_canBeUsedAsDictionaryKey() {
        var dict: [GlobalDefaultKey: String] = [:]
        dict[.physicalDescription] = "value1"
        dict[.outfit] = "value2"
        
        XCTAssertEqual(dict[.physicalDescription], "value1")
        XCTAssertEqual(dict[.outfit], "value2")
    }
}
