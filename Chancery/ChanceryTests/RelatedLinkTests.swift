//
//  RelatedLinkTests.swift
//  ChanceryTests
//
//  Unit tests for RelatedLink model functionality.
//

import XCTest
@testable import Chancery

final class RelatedLinkTests: XCTestCase {
    
    // MARK: - Initialization Tests
    
    func test_init_withValidURL_createsLink() {
        let link = RelatedLink(
            title: "Test Link",
            urlString: "https://example.com"
        )
        
        XCTAssertFalse(link.id.uuidString.isEmpty)
        XCTAssertEqual(link.title, "Test Link")
        XCTAssertEqual(link.urlString, "https://example.com")
    }
    
    func test_init_withCustomId_usesProvidedId() {
        let customId = UUID()
        let link = RelatedLink(
            id: customId,
            title: "Test",
            urlString: "https://example.com"
        )
        
        XCTAssertEqual(link.id, customId)
    }
    
    // MARK: - url Tests
    
    func test_url_withValidURL_returnsURL() {
        let link = RelatedLink(
            title: "Test",
            urlString: "https://example.com/path?query=value"
        )
        
        XCTAssertNotNil(link.url)
        XCTAssertEqual(link.url?.absoluteString, "https://example.com/path?query=value")
    }
    
    func test_url_withInvalidURL_returnsNil() {
        // URL with malformed bracket that URL(string:) rejects
        let link = RelatedLink(
            title: "Test",
            urlString: "http://[invalid"
        )
        
        XCTAssertNil(link.url)
    }
    
    func test_url_withEmptyString_returnsNil() {
        let link = RelatedLink(
            title: "Test",
            urlString: ""
        )
        
        XCTAssertNil(link.url)
    }
    
    // MARK: - isValid Tests
    
    func test_isValid_withValidURL_returnsTrue() {
        let link = RelatedLink(
            title: "Test",
            urlString: "https://example.com"
        )
        
        XCTAssertTrue(link.isValid)
    }
    
    func test_isValid_withInvalidURL_returnsFalse() {
        // URL with malformed bracket that URL(string:) rejects
        let link = RelatedLink(
            title: "Test",
            urlString: "http://[invalid"
        )
        
        XCTAssertFalse(link.isValid)
    }
    
    // MARK: - host Tests
    
    func test_host_withValidURL_returnsHost() {
        let link = RelatedLink(
            title: "Test",
            urlString: "https://www.example.com/path"
        )
        
        XCTAssertEqual(link.host, "www.example.com")
    }
    
    func test_host_withInvalidURL_returnsNil() {
        let link = RelatedLink(
            title: "Test",
            urlString: "invalid"
        )
        
        XCTAssertNil(link.host)
    }
    
    // MARK: - Equatable Tests
    
    func test_equality_withSameValues_returnsTrue() {
        let id = UUID()
        let link1 = RelatedLink(id: id, title: "Test", urlString: "https://example.com")
        let link2 = RelatedLink(id: id, title: "Test", urlString: "https://example.com")
        
        XCTAssertEqual(link1, link2)
    }
    
    func test_equality_withDifferentId_returnsFalse() {
        let link1 = RelatedLink(title: "Test", urlString: "https://example.com")
        let link2 = RelatedLink(title: "Test", urlString: "https://example.com")
        
        XCTAssertNotEqual(link1, link2)
    }
    
    // MARK: - Hashable Tests
    
    func test_hashable_canBeUsedInSet() {
        let link1 = RelatedLink(title: "Link 1", urlString: "https://example1.com")
        let link2 = RelatedLink(title: "Link 2", urlString: "https://example2.com")
        
        var set: Set<RelatedLink> = []
        set.insert(link1)
        set.insert(link2)
        set.insert(link1) // Duplicate
        
        XCTAssertEqual(set.count, 2)
    }
    
    // MARK: - Codable Tests
    
    func test_encodeDecode_preservesAllFields() throws {
        let original = RelatedLink(
            title: "Codable Test",
            urlString: "https://example.com/test"
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(RelatedLink.self, from: data)
        
        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.title, original.title)
        XCTAssertEqual(decoded.urlString, original.urlString)
    }
}
