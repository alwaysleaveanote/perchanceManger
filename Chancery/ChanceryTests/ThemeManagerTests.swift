//
//  ThemeManagerTests.swift
//  ChanceryTests
//
//  Tests for ThemeManager functionality including theme loading,
//  selection, and resolution.
//

import XCTest
@testable import Chancery

@MainActor
final class ThemeManagerTests: XCTestCase {
    
    var themeManager: ThemeManager!
    
    override func setUp() async throws {
        try await super.setUp()
        themeManager = ThemeManager()
    }
    
    override func tearDown() async throws {
        themeManager = nil
        try await super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func test_init_loadsAvailableThemes() {
        // ThemeManager should load built-in themes on init
        XCTAssertFalse(themeManager.availableThemes.isEmpty, "Should have loaded themes")
    }
    
    func test_init_includesDefaultTheme() {
        // Default theme should always be available
        let hasDefault = themeManager.availableThemes.contains { $0.id == "default" }
        XCTAssertTrue(hasDefault, "Should include default theme")
    }
    
    func test_init_resolvedThemeIsNotNil() {
        // Resolved theme should be set after init
        XCTAssertNotNil(themeManager.resolved)
    }
    
    // MARK: - Theme Selection Tests
    
    func test_setGlobalTheme_withValidId_returnsTrue() {
        // Given a valid theme ID
        let validId = "default"
        
        // When setting the theme
        let result = themeManager.setGlobalTheme(validId)
        
        // Then it should succeed
        XCTAssertTrue(result)
        XCTAssertEqual(themeManager.globalThemeId, validId)
    }
    
    func test_setGlobalTheme_withInvalidId_returnsFalse() {
        // Given an invalid theme ID
        let invalidId = "nonexistent-theme-id-12345"
        let originalId = themeManager.globalThemeId
        
        // When setting the theme
        let result = themeManager.setGlobalTheme(invalidId)
        
        // Then it should fail and not change the theme
        XCTAssertFalse(result)
        XCTAssertEqual(themeManager.globalThemeId, originalId)
    }
    
    func test_setGlobalTheme_updatesResolvedTheme() {
        // Given a different valid theme
        guard let differentTheme = themeManager.availableThemes.first(where: { $0.id != themeManager.globalThemeId }) else {
            XCTSkip("Need at least 2 themes to test theme switching")
            return
        }
        
        // When setting the theme
        themeManager.setGlobalTheme(differentTheme.id)
        
        // Then resolved theme should update
        XCTAssertEqual(themeManager.resolved.source.id, differentTheme.id)
    }
    
    // MARK: - Theme Lookup Tests
    
    func test_themeWithId_existingTheme_returnsTheme() {
        // Given a known theme ID
        let themeId = "default"
        
        // When looking up the theme
        let theme = themeManager.theme(withId: themeId)
        
        // Then it should return the theme
        XCTAssertNotNil(theme)
        XCTAssertEqual(theme?.id, themeId)
    }
    
    func test_themeWithId_nonexistentTheme_returnsNil() {
        // Given an unknown theme ID
        let themeId = "nonexistent-theme"
        
        // When looking up the theme
        let theme = themeManager.theme(withId: themeId)
        
        // Then it should return nil
        XCTAssertNil(theme)
    }
    
    // MARK: - Character Theme Resolution Tests
    
    func test_resolvedThemeForCharacter_withNilThemeId_returnsGlobalTheme() {
        // Given a nil character theme ID
        let characterThemeId: String? = nil
        
        // When resolving the theme
        let resolved = themeManager.resolvedTheme(forCharacterThemeId: characterThemeId)
        
        // Then it should return the global theme
        XCTAssertEqual(resolved.source.id, themeManager.globalThemeId)
    }
    
    func test_resolvedThemeForCharacter_withValidThemeId_returnsCharacterTheme() {
        // Given a valid character theme ID different from global
        guard let characterTheme = themeManager.availableThemes.first(where: { $0.id != themeManager.globalThemeId }) else {
            XCTSkip("Need at least 2 themes to test character theme resolution")
            return
        }
        
        // When resolving the theme
        let resolved = themeManager.resolvedTheme(forCharacterThemeId: characterTheme.id)
        
        // Then it should return the character's theme
        XCTAssertEqual(resolved.source.id, characterTheme.id)
    }
    
    func test_resolvedThemeForCharacter_withInvalidThemeId_returnsGlobalTheme() {
        // Given an invalid character theme ID
        let invalidThemeId = "nonexistent-theme"
        
        // When resolving the theme
        let resolved = themeManager.resolvedTheme(forCharacterThemeId: invalidThemeId)
        
        // Then it should fall back to global theme
        XCTAssertEqual(resolved.source.id, themeManager.globalThemeId)
    }
    
    func test_themeForCharacterThemeId_withNil_returnsGlobalTheme() {
        // Given nil character theme ID
        let result = themeManager.theme(forCharacterThemeId: nil)
        
        // Then should return global theme
        XCTAssertEqual(result.id, themeManager.globalTheme.id)
    }
    
    func test_themeForCharacterThemeId_withValid_returnsMatchingTheme() {
        // Given a valid theme ID
        guard let theme = themeManager.availableThemes.first else {
            XCTFail("Should have at least one theme")
            return
        }
        
        // When getting theme for character
        let result = themeManager.theme(forCharacterThemeId: theme.id)
        
        // Then should return matching theme
        XCTAssertEqual(result.id, theme.id)
    }
    
    // MARK: - Computed Properties Tests
    
    func test_currentTheme_matchesGlobalThemeId() {
        // The currentTheme should match the globalThemeId
        XCTAssertEqual(themeManager.currentTheme.id, themeManager.globalThemeId)
    }
    
    func test_globalTheme_isAliasForCurrentTheme() {
        // globalTheme should be the same as currentTheme
        XCTAssertEqual(themeManager.globalTheme.id, themeManager.currentTheme.id)
    }
    
    // MARK: - Theme Reload Tests
    
    func test_reloadThemes_maintainsThemeSelection() {
        // Given a selected theme
        let selectedId = themeManager.globalThemeId
        
        // When reloading themes
        themeManager.reloadThemes()
        
        // Then selection should be maintained (if theme still exists)
        if themeManager.availableThemes.contains(where: { $0.id == selectedId }) {
            XCTAssertEqual(themeManager.globalThemeId, selectedId)
        }
    }
    
    func test_reloadThemes_reloadsAvailableThemes() {
        // When reloading themes
        themeManager.reloadThemes()
        
        // Then themes should still be loaded
        XCTAssertFalse(themeManager.availableThemes.isEmpty)
    }
}

// MARK: - Bundled Theme Tests

extension ThemeManagerTests {
    
    func test_bundledThemes_haveUniqueIds() {
        // All themes should have unique IDs
        let ids = themeManager.availableThemes.map { $0.id }
        let uniqueIds = Set(ids)
        
        XCTAssertEqual(ids.count, uniqueIds.count, "Theme IDs should be unique")
    }
    
    func test_bundledThemes_haveNonEmptyNames() {
        // All themes should have names
        for theme in themeManager.availableThemes {
            XCTAssertFalse(theme.name.isEmpty, "Theme \(theme.id) should have a name")
        }
    }
    
    func test_bundledThemes_haveValidColors() {
        // All themes should have valid color definitions
        for theme in themeManager.availableThemes {
            XCTAssertFalse(theme.colors.primary.isEmpty, "Theme \(theme.id) should have primary color")
            XCTAssertFalse(theme.colors.background.isEmpty, "Theme \(theme.id) should have background color")
            XCTAssertFalse(theme.colors.textPrimary.isEmpty, "Theme \(theme.id) should have text color")
        }
    }
}
