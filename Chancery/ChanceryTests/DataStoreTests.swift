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
