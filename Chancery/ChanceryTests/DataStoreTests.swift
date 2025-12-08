//
//  DataStoreTests.swift
//  ChanceryTests
//
//  Tests for DataStore-related functionality.
//  Note: DataStore is a singleton with CloudKit integration, so these tests
//  focus on the data structures and helper types it uses.
//

import XCTest
@testable import Chancery

final class DataStoreTests: XCTestCase {
    
    // MARK: - CloudKitSyncStatus Tests
    
    func test_cloudKitSyncStatus_idle_canBeCreated() {
        let status = CloudKitSyncStatus.idle
        // Verify the status can be created and compared
        XCTAssertEqual(status, .idle)
    }
    
    func test_cloudKitSyncStatus_syncing_canBeCreated() {
        let status = CloudKitSyncStatus.syncing
        XCTAssertEqual(status, .syncing)
    }
    
    func test_cloudKitSyncStatus_error_containsMessage() {
        let errorMessage = "Network unavailable"
        let status = CloudKitSyncStatus.error(errorMessage)
        
        if case .error(let message) = status {
            XCTAssertEqual(message, errorMessage)
        } else {
            XCTFail("Status should be error case")
        }
    }
    
    func test_cloudKitSyncStatus_equality_sameIdle_returnsTrue() {
        XCTAssertEqual(CloudKitSyncStatus.idle, CloudKitSyncStatus.idle)
    }
    
    func test_cloudKitSyncStatus_equality_sameSyncing_returnsTrue() {
        XCTAssertEqual(CloudKitSyncStatus.syncing, CloudKitSyncStatus.syncing)
    }
    
    func test_cloudKitSyncStatus_equality_sameError_returnsTrue() {
        let error1 = CloudKitSyncStatus.error("test")
        let error2 = CloudKitSyncStatus.error("test")
        XCTAssertEqual(error1, error2)
    }
    
    func test_cloudKitSyncStatus_equality_differentError_returnsFalse() {
        let error1 = CloudKitSyncStatus.error("error1")
        let error2 = CloudKitSyncStatus.error("error2")
        XCTAssertNotEqual(error1, error2)
    }
    
    func test_cloudKitSyncStatus_equality_differentTypes_returnsFalse() {
        XCTAssertNotEqual(CloudKitSyncStatus.idle, CloudKitSyncStatus.syncing)
        XCTAssertNotEqual(CloudKitSyncStatus.idle, CloudKitSyncStatus.error("test"))
        XCTAssertNotEqual(CloudKitSyncStatus.syncing, CloudKitSyncStatus.error("test"))
    }
    
    func test_cloudKitSyncStatus_error_withEmptyMessage() {
        let status = CloudKitSyncStatus.error("")
        if case .error(let message) = status {
            XCTAssertTrue(message.isEmpty)
        } else {
            XCTFail("Status should be error case")
        }
    }
    
    func test_cloudKitSyncStatus_error_withLongMessage() {
        let longMessage = String(repeating: "error ", count: 100)
        let status = CloudKitSyncStatus.error(longMessage)
        if case .error(let message) = status {
            XCTAssertEqual(message, longMessage)
        } else {
            XCTFail("Status should be error case")
        }
    }
}

// MARK: - Character Profile Integration Tests

extension DataStoreTests {
    
    func test_starterCharacter_isValid() {
        let starter = CharacterProfile.starterCharacter
        
        XCTAssertFalse(starter.name.isEmpty, "Starter character should have a name")
        XCTAssertNotNil(starter.id)
    }
    
    func test_starterCharacter_hasWelcomePrompt() {
        let starter = CharacterProfile.starterCharacter
        
        // Starter should have at least one prompt to guide new users
        XCTAssertFalse(starter.prompts.isEmpty, "Starter character should have prompts")
    }
}

// MARK: - GlobalDefaultKey Dictionary Tests

extension DataStoreTests {
    
    func test_globalDefaultsDictionary_canStoreAllKeys() {
        var defaults: [GlobalDefaultKey: String] = [:]
        
        for key in GlobalDefaultKey.allCases {
            defaults[key] = "test value for \(key.rawValue)"
        }
        
        XCTAssertEqual(defaults.count, GlobalDefaultKey.allCases.count)
    }
    
    func test_globalDefaultsDictionary_codable_preservesAllKeys() throws {
        var original: [GlobalDefaultKey: String] = [:]
        for key in GlobalDefaultKey.allCases {
            original[key] = "value-\(key.rawValue)"
        }
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode([GlobalDefaultKey: String].self, from: data)
        
        XCTAssertEqual(decoded.count, original.count)
        for key in GlobalDefaultKey.allCases {
            XCTAssertEqual(decoded[key], original[key])
        }
    }
}

// MARK: - Scene Data Structure Tests

extension DataStoreTests {
    
    func test_sceneArray_canBeEncoded() throws {
        let scene1 = CharacterScene(name: "Beach Day", characterIds: [UUID(), UUID()])
        let scene2 = CharacterScene(name: "Adventure", characterIds: [UUID()])
        let scenes = [scene1, scene2]
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(scenes)
        
        XCTAssertFalse(data.isEmpty)
    }
    
    func test_sceneArray_canBeDecoded() throws {
        let scene1 = CharacterScene(name: "Beach Day", characterIds: [UUID(), UUID()])
        let scene2 = CharacterScene(name: "Adventure", characterIds: [UUID()])
        let original = [scene1, scene2]
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode([CharacterScene].self, from: data)
        
        XCTAssertEqual(decoded.count, 2)
        XCTAssertEqual(decoded[0].name, "Beach Day")
        XCTAssertEqual(decoded[1].name, "Adventure")
    }
    
    func test_sceneWithPrompts_canBeEncodedAndDecoded() throws {
        var scene = CharacterScene(name: "Test Scene", characterIds: [UUID()])
        
        let characterId = UUID()
        let settings = SceneCharacterSettings(
            physicalDescription: "Tall",
            outfit: "Armor",
            pose: "Standing"
        )
        
        var prompt = ScenePrompt(
            title: "Battle",
            environment: "Castle",
            lighting: "Dramatic",
            characterSettings: [characterId: settings]
        )
        prompt.images.append(PromptImage(data: Data([0x00, 0x01])))
        scene.prompts.append(prompt)
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(scene)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(CharacterScene.self, from: data)
        
        XCTAssertEqual(decoded.name, "Test Scene")
        XCTAssertEqual(decoded.prompts.count, 1)
        XCTAssertEqual(decoded.prompts[0].title, "Battle")
        XCTAssertEqual(decoded.prompts[0].environment, "Castle")
        XCTAssertEqual(decoded.prompts[0].characterSettings[characterId]?.physicalDescription, "Tall")
        XCTAssertEqual(decoded.prompts[0].images.count, 1)
    }
    
    @MainActor
    func test_sceneIndex_returnsCorrectIndex() {
        let dataStore = DataStore.shared
        
        // Note: This test uses the shared DataStore, so we're testing the index lookup logic
        // In a real scenario, we'd use dependency injection for better isolation
        
        let scene = CharacterScene(name: "Test Scene \(UUID().uuidString)")
        dataStore.addScene(scene)
        
        let index = dataStore.sceneIndex(for: scene.id)
        XCTAssertNotNil(index)
        XCTAssertEqual(index, 0) // New scenes are inserted at the beginning
        
        // Cleanup
        dataStore.deleteScene(scene)
    }
    
    @MainActor
    func test_charactersForScene_returnsMatchingCharacters() {
        let dataStore = DataStore.shared
        
        // Get existing characters or use their IDs
        let existingCharacters = dataStore.characters
        guard existingCharacters.count >= 2 else {
            // Skip test if not enough characters
            return
        }
        
        let char1 = existingCharacters[0]
        let char2 = existingCharacters[1]
        
        let scene = CharacterScene(
            name: "Test Scene",
            characterIds: [char1.id, char2.id]
        )
        
        let sceneCharacters = dataStore.characters(for: scene)
        XCTAssertEqual(sceneCharacters.count, 2)
        XCTAssertTrue(sceneCharacters.contains { $0.id == char1.id })
        XCTAssertTrue(sceneCharacters.contains { $0.id == char2.id })
    }
}
