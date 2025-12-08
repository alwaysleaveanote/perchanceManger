//
//  PromptImageTests.swift
//  ChanceryTests
//
//  Unit tests for PromptImage model functionality.
//

import XCTest
import UIKit
@testable import Chancery

final class PromptImageTests: XCTestCase {
    
    // MARK: - Initialization Tests
    
    func test_init_withData_createsImage() {
        let testData = Data([0x00, 0x01, 0x02, 0x03])
        let image = PromptImage(id: UUID(), data: testData)
        
        XCTAssertFalse(image.id.uuidString.isEmpty)
        XCTAssertEqual(image.data, testData)
    }
    
    func test_init_withDefaultId_generatesUniqueId() {
        let image1 = PromptImage(data: Data())
        let image2 = PromptImage(data: Data())
        
        XCTAssertNotEqual(image1.id, image2.id)
    }
    
    // MARK: - dataSize Tests
    
    func test_dataSize_returnsCorrectByteCount() {
        let testData = Data([0x00, 0x01, 0x02, 0x03, 0x04])
        let image = PromptImage(data: testData)
        
        XCTAssertEqual(image.dataSize, 5)
    }
    
    func test_dataSize_withEmptyData_returnsZero() {
        let image = PromptImage(data: Data())
        
        XCTAssertEqual(image.dataSize, 0)
    }
    
    // MARK: - Equatable Tests
    
    func test_equality_withSameIdAndData_returnsTrue() {
        let id = UUID()
        let data = Data([0x00, 0x01])
        let image1 = PromptImage(id: id, data: data)
        let image2 = PromptImage(id: id, data: data)
        
        XCTAssertEqual(image1, image2)
    }
    
    func test_equality_withDifferentId_returnsFalse() {
        let data = Data([0x00, 0x01])
        let image1 = PromptImage(data: data)
        let image2 = PromptImage(data: data)
        
        XCTAssertNotEqual(image1, image2)
    }
    
    // MARK: - Hashable Tests
    
    func test_hashable_canBeUsedInSet() {
        let image1 = PromptImage(data: Data([0x00]))
        let image2 = PromptImage(data: Data([0x01]))
        
        var set: Set<PromptImage> = []
        set.insert(image1)
        set.insert(image2)
        set.insert(image1) // Duplicate
        
        XCTAssertEqual(set.count, 2)
    }
    
    // MARK: - Codable Tests
    
    func test_encodeDecode_preservesAllFields() throws {
        let original = PromptImage(data: Data([0x00, 0x01, 0x02]))
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(PromptImage.self, from: data)
        
        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.data, original.data)
    }
    
    // MARK: - UIImage Conversion Tests
    
    func test_uiImage_withValidImageData_returnsUIImage() {
        // Create a simple 1x1 red PNG
        let size = CGSize(width: 1, height: 1)
        UIGraphicsBeginImageContext(size)
        UIColor.red.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let uiImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        let imageData = uiImage.pngData()!
        let promptImage = PromptImage(data: imageData)
        
        XCTAssertNotNil(promptImage.uiImage)
    }
    
    func test_uiImage_withInvalidData_returnsNil() {
        let invalidData = Data([0x00, 0x01, 0x02])
        let promptImage = PromptImage(data: invalidData)
        
        XCTAssertNil(promptImage.uiImage)
    }
    
    func test_initFromUIImage_createsPromptImage() {
        // Create a simple 1x1 red image
        let size = CGSize(width: 1, height: 1)
        UIGraphicsBeginImageContext(size)
        UIColor.red.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let uiImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        let promptImage = PromptImage(uiImage: uiImage)
        
        XCTAssertNotNil(promptImage)
        XCTAssertFalse(promptImage!.data.isEmpty)
    }
}
