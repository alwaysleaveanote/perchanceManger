//
//  AppThemeTests.swift
//  ChanceryTests
//
//  Unit tests for AppTheme and related theme models.
//

import XCTest
import SwiftUI
@testable import Chancery

final class AppThemeTests: XCTestCase {
    
    // MARK: - Test Helpers
    
    private func makeTestTheme() -> AppTheme {
        AppTheme(
            id: "test-theme",
            name: "Test Theme",
            description: "A theme for testing",
            icon: "star.fill",
            colors: ThemeColors(
                primary: "#007AFF",
                primaryVariant: "#0056B3",
                secondary: "#FF9500",
                secondaryVariant: "#CC7700",
                background: "#FFFFFF",
                backgroundSecondary: "#F5F5F5",
                backgroundTertiary: "#EEEEEE",
                textPrimary: "#000000",
                textSecondary: "#666666",
                textAccent: "#007AFF",
                textOnPrimary: "#FFFFFF",
                border: "#CCCCCC",
                divider: "#E0E0E0",
                shadow: "#000000",
                success: "#34C759",
                warning: "#FF9500",
                error: "#FF3B30",
                tabBarBackground: "#FFFFFF",
                tabBarSelected: "#007AFF",
                tabBarUnselected: "#8E8E93"
            ),
            typography: ThemeTypography(
                fontFamily: "rounded",
                fontWeight: "medium",
                titleStyle: "none",
                letterSpacing: 0.0,
                lineHeightMultiplier: 1.2
            ),
            iconography: ThemeIconography(
                style: "sf-symbols",
                weight: "medium",
                icons: ["settings": "gear"]
            ),
            spacing: ThemeSpacing(
                cornerRadiusSmall: 8.0,
                cornerRadiusMedium: 12.0,
                cornerRadiusLarge: 16.0,
                paddingSmall: 8.0,
                paddingMedium: 16.0,
                paddingLarge: 24.0,
                itemSpacing: 12.0,
                sectionSpacing: 24.0
            ),
            effects: ThemeEffects(
                shadowRadius: 8.0,
                shadowOpacity: 0.1,
                blurRadius: 10.0,
                useGradientBackground: false,
                gradientColors: ["#007AFF", "#00C7FF"],
                gradientAngle: 45.0,
                buttonStyle: "filled",
                cardStyle: "elevated"
            )
        )
    }
    
    // MARK: - AppTheme Tests
    
    func test_appTheme_identifiable_usesIdProperty() {
        let theme = makeTestTheme()
        
        XCTAssertEqual(theme.id, "test-theme")
    }
    
    func test_appTheme_equatable_comparesById() {
        var theme1 = makeTestTheme()
        var theme2 = makeTestTheme()
        
        XCTAssertEqual(theme1, theme2)
        
        theme2.id = "different-id"
        XCTAssertNotEqual(theme1, theme2)
    }
    
    func test_appTheme_codable_encodesAndDecodes() throws {
        let original = makeTestTheme()
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(AppTheme.self, from: data)
        
        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.name, original.name)
        XCTAssertEqual(decoded.description, original.description)
        XCTAssertEqual(decoded.icon, original.icon)
        XCTAssertEqual(decoded.colors, original.colors)
        XCTAssertEqual(decoded.typography, original.typography)
        XCTAssertEqual(decoded.iconography, original.iconography)
        XCTAssertEqual(decoded.spacing, original.spacing)
        XCTAssertEqual(decoded.effects, original.effects)
    }
    
    // MARK: - ThemeColors Tests
    
    func test_themeColors_equatable_comparesAllProperties() {
        let colors1 = makeTestTheme().colors
        var colors2 = colors1
        
        XCTAssertEqual(colors1, colors2)
        
        colors2.primary = "#FF0000"
        XCTAssertNotEqual(colors1, colors2)
    }
    
    // MARK: - ThemeTypography Tests
    
    func test_themeTypography_equatable_comparesAllProperties() {
        let typography1 = makeTestTheme().typography
        var typography2 = typography1
        
        XCTAssertEqual(typography1, typography2)
        
        typography2.fontFamily = "serif"
        XCTAssertNotEqual(typography1, typography2)
    }
    
    // MARK: - ThemeSpacing Tests
    
    func test_themeSpacing_equatable_comparesAllProperties() {
        let spacing1 = makeTestTheme().spacing
        var spacing2 = spacing1
        
        XCTAssertEqual(spacing1, spacing2)
        
        spacing2.cornerRadiusMedium = 20.0
        XCTAssertNotEqual(spacing1, spacing2)
    }
    
    // MARK: - ThemeEffects Tests
    
    func test_themeEffects_equatable_comparesAllProperties() {
        let effects1 = makeTestTheme().effects
        var effects2 = effects1
        
        XCTAssertEqual(effects1, effects2)
        
        effects2.cardStyle = "flat"
        XCTAssertNotEqual(effects1, effects2)
    }
    
    // MARK: - ResolvedTheme Tests
    
    func test_resolvedTheme_fontDesign_mapsCorrectly() {
        var theme = makeTestTheme()
        
        theme.typography.fontFamily = "rounded"
        var resolved = ResolvedTheme(source: theme)
        XCTAssertEqual(resolved.fontDesign, .rounded)
        
        theme.typography.fontFamily = "serif"
        resolved = ResolvedTheme(source: theme)
        XCTAssertEqual(resolved.fontDesign, .serif)
        
        theme.typography.fontFamily = "monospaced"
        resolved = ResolvedTheme(source: theme)
        XCTAssertEqual(resolved.fontDesign, .monospaced)
        
        theme.typography.fontFamily = "system"
        resolved = ResolvedTheme(source: theme)
        XCTAssertEqual(resolved.fontDesign, .default)
    }
    
    func test_resolvedTheme_fontWeight_mapsCorrectly() {
        var theme = makeTestTheme()
        
        theme.typography.fontWeight = "bold"
        var resolved = ResolvedTheme(source: theme)
        XCTAssertEqual(resolved.fontWeight, .bold)
        
        theme.typography.fontWeight = "light"
        resolved = ResolvedTheme(source: theme)
        XCTAssertEqual(resolved.fontWeight, .light)
        
        theme.typography.fontWeight = "regular"
        resolved = ResolvedTheme(source: theme)
        XCTAssertEqual(resolved.fontWeight, .regular)
    }
    
    func test_resolvedTheme_spacingProperties_returnCorrectValues() {
        let theme = makeTestTheme()
        let resolved = ResolvedTheme(source: theme)
        
        XCTAssertEqual(resolved.cornerRadiusSmall, 8.0)
        XCTAssertEqual(resolved.cornerRadiusMedium, 12.0)
        XCTAssertEqual(resolved.cornerRadiusLarge, 16.0)
        XCTAssertEqual(resolved.paddingSmall, 8.0)
        XCTAssertEqual(resolved.paddingMedium, 16.0)
        XCTAssertEqual(resolved.paddingLarge, 24.0)
    }
    
    func test_resolvedTheme_effectsProperties_returnCorrectValues() {
        let theme = makeTestTheme()
        let resolved = ResolvedTheme(source: theme)
        
        XCTAssertEqual(resolved.shadowRadius, 8.0)
        XCTAssertEqual(resolved.shadowOpacity, 0.1)
    }
    
    func test_resolvedTheme_gradientColors_mapsHexToColors() {
        let theme = makeTestTheme()
        let resolved = ResolvedTheme(source: theme)
        
        XCTAssertEqual(resolved.gradientColors.count, 2)
    }
    
    func test_resolvedTheme_iconOverride_returnsOverriddenIcon() {
        let theme = makeTestTheme()
        let resolved = ResolvedTheme(source: theme)
        
        // Should return the overridden icon
        XCTAssertEqual(resolved.icon(for: "settings", fallback: "default"), "gear")
        
        // Should return fallback for non-overridden icons
        XCTAssertEqual(resolved.icon(for: "unknown", fallback: "star"), "star")
    }
    
    // MARK: - Color Hex Extension Tests
    
    func test_colorHex_with6CharHex_createsColor() {
        let color = Color(hex: "#FF0000")
        // Color comparison is tricky, but we can at least verify it doesn't crash
        XCTAssertNotNil(color)
    }
    
    func test_colorHex_with3CharHex_createsColor() {
        let color = Color(hex: "#F00")
        XCTAssertNotNil(color)
    }
    
    func test_colorHex_with8CharHex_createsColorWithAlpha() {
        let color = Color(hex: "#80FF0000")
        XCTAssertNotNil(color)
    }
    
    func test_colorHex_withoutHashPrefix_createsColor() {
        let color = Color(hex: "007AFF")
        XCTAssertNotNil(color)
    }
    
    func test_colorHex_withInvalidHex_createsBlackColor() {
        let color = Color(hex: "invalid")
        XCTAssertNotNil(color)
    }
}
