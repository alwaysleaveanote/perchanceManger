//
//  StringExtensionsTests.swift
//  ChanceryTests
//
//  Unit tests for String extension functionality.
//

import XCTest
@testable import Chancery

final class StringExtensionsTests: XCTestCase {
    
    // MARK: - nonEmpty Tests
    
    func test_nonEmpty_withNonEmptyString_returnsTrimmedString() {
        let input = "  hello world  "
        
        XCTAssertEqual(input.nonEmpty, "hello world")
    }
    
    func test_nonEmpty_withEmptyString_returnsNil() {
        let input = ""
        
        XCTAssertNil(input.nonEmpty)
    }
    
    func test_nonEmpty_withWhitespaceOnly_returnsNil() {
        let input = "   \n\t  "
        
        XCTAssertNil(input.nonEmpty)
    }
    
    func test_nonEmpty_withSingleCharacter_returnsCharacter() {
        let input = "a"
        
        XCTAssertEqual(input.nonEmpty, "a")
    }
    
    func test_nonEmpty_withNewlinesAndContent_returnsTrimmedContent() {
        let input = "\n\n  content here  \n\n"
        
        XCTAssertEqual(input.nonEmpty, "content here")
    }
    
    // MARK: - isBlank Tests
    
    func test_isBlank_withEmptyString_returnsTrue() {
        let input = ""
        
        XCTAssertTrue(input.isBlank)
    }
    
    func test_isBlank_withWhitespaceOnly_returnsTrue() {
        let input = "   \t\n  "
        
        XCTAssertTrue(input.isBlank)
    }
    
    func test_isBlank_withContent_returnsFalse() {
        let input = "  hello  "
        
        XCTAssertFalse(input.isBlank)
    }
    
    func test_isBlank_withSingleCharacter_returnsFalse() {
        let input = "x"
        
        XCTAssertFalse(input.isBlank)
    }
    
    // MARK: - truncated Tests
    
    func test_truncated_withShortString_returnsOriginal() {
        let input = "hello"
        
        XCTAssertEqual(input.truncated(to: 10), "hello")
    }
    
    func test_truncated_withExactLength_returnsOriginal() {
        let input = "hello"
        
        XCTAssertEqual(input.truncated(to: 5), "hello")
    }
    
    func test_truncated_withLongString_truncatesWithEllipsis() {
        let input = "hello world"
        
        let result = input.truncated(to: 8)
        
        XCTAssertEqual(result.count, 8)
        XCTAssertTrue(result.hasSuffix("…"))
    }
    
    func test_truncated_toZero_returnsEllipsis() {
        let input = "hello"
        
        // Edge case: truncating to 0 or less
        let result = input.truncated(to: 1)
        
        XCTAssertEqual(result, "…")
    }
    
    func test_truncated_preservesUnicodeCharacters() {
        let input = "héllo wörld"
        
        let result = input.truncated(to: 6)
        
        XCTAssertEqual(result.count, 6)
        XCTAssertTrue(result.hasPrefix("héllo"))
    }
}
