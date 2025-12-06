import SwiftUI

/// Represents a complete visual theme for the app
/// Designed to be loaded from JSON for easy extensibility
struct AppTheme: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    var description: String
    var icon: String?  // SF Symbol name for theme icon
    
    // MARK: - Colors (stored as hex strings for JSON compatibility)
    var colors: ThemeColors
    
    // MARK: - Typography
    var typography: ThemeTypography
    
    // MARK: - Iconography
    var iconography: ThemeIconography
    
    // MARK: - Spacing & Corners
    var spacing: ThemeSpacing
    
    // MARK: - Effects
    var effects: ThemeEffects
}

// MARK: - Theme Colors

struct ThemeColors: Codable, Equatable {
    // Primary palette
    var primary: String           // Main accent color
    var primaryVariant: String    // Lighter/darker variant
    var secondary: String         // Secondary accent
    var secondaryVariant: String
    
    // Backgrounds
    var background: String        // Main background
    var backgroundSecondary: String // Cards, sections
    var backgroundTertiary: String  // Nested elements
    
    // Text
    var textPrimary: String
    var textSecondary: String
    var textAccent: String
    var textOnPrimary: String     // Text on primary color buttons
    
    // UI Elements
    var border: String
    var divider: String
    var shadow: String
    
    // Semantic colors
    var success: String
    var warning: String
    var error: String
    
    // Tab bar
    var tabBarBackground: String
    var tabBarSelected: String
    var tabBarUnselected: String
}

// MARK: - Theme Typography

struct ThemeTypography: Codable, Equatable {
    var fontFamily: String        // "system", "rounded", or custom font name
    var fontWeight: String        // "regular", "medium", "semibold", "bold"
    var titleStyle: String        // "uppercase", "lowercase", "capitalize", "none"
    var letterSpacing: Double     // Additional letter spacing
    var lineHeightMultiplier: Double
}

// MARK: - Theme Iconography

struct ThemeIconography: Codable, Equatable {
    var style: String             // "sf-symbols", "custom"
    var weight: String            // "ultraLight", "thin", "light", "regular", "medium", "semibold", "bold", "heavy", "black"
    
    // Icon overrides (SF Symbol name mappings)
    var icons: [String: String]   // e.g., "settings" -> "sparkle.magnifyingglass"
}

// MARK: - Theme Spacing

struct ThemeSpacing: Codable, Equatable {
    var cornerRadiusSmall: Double
    var cornerRadiusMedium: Double
    var cornerRadiusLarge: Double
    var paddingSmall: Double
    var paddingMedium: Double
    var paddingLarge: Double
    var itemSpacing: Double
    var sectionSpacing: Double
}

// MARK: - Theme Effects

struct ThemeEffects: Codable, Equatable {
    var shadowRadius: Double
    var shadowOpacity: Double
    var blurRadius: Double
    var useGradientBackground: Bool
    var gradientColors: [String]  // Array of hex colors for gradient
    var gradientAngle: Double     // Degrees
    var buttonStyle: String       // "filled", "outlined", "soft"
    var cardStyle: String         // "flat", "elevated", "bordered"
}

// MARK: - Color Extension for Hex Support

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Resolved Theme (SwiftUI-ready colors)

/// A resolved version of AppTheme with actual SwiftUI Color values
struct ResolvedTheme {
    let source: AppTheme
    
    // Colors
    var primary: Color { Color(hex: source.colors.primary) }
    var primaryVariant: Color { Color(hex: source.colors.primaryVariant) }
    var secondary: Color { Color(hex: source.colors.secondary) }
    var secondaryVariant: Color { Color(hex: source.colors.secondaryVariant) }
    
    var background: Color { Color(hex: source.colors.background) }
    var backgroundSecondary: Color { Color(hex: source.colors.backgroundSecondary) }
    var backgroundTertiary: Color { Color(hex: source.colors.backgroundTertiary) }
    
    var textPrimary: Color { Color(hex: source.colors.textPrimary) }
    var textSecondary: Color { Color(hex: source.colors.textSecondary) }
    var textAccent: Color { Color(hex: source.colors.textAccent) }
    var textOnPrimary: Color { Color(hex: source.colors.textOnPrimary) }
    
    var border: Color { Color(hex: source.colors.border) }
    var divider: Color { Color(hex: source.colors.divider) }
    var shadow: Color { Color(hex: source.colors.shadow) }
    
    var success: Color { Color(hex: source.colors.success) }
    var warning: Color { Color(hex: source.colors.warning) }
    var error: Color { Color(hex: source.colors.error) }
    
    var tabBarBackground: Color { Color(hex: source.colors.tabBarBackground) }
    var tabBarSelected: Color { Color(hex: source.colors.tabBarSelected) }
    var tabBarUnselected: Color { Color(hex: source.colors.tabBarUnselected) }
    
    // Gradient
    var gradientColors: [Color] {
        source.effects.gradientColors.map { Color(hex: $0) }
    }
    
    // Typography
    var fontDesign: Font.Design {
        switch source.typography.fontFamily.lowercased() {
        case "rounded": return .rounded
        case "serif": return .serif
        case "monospaced": return .monospaced
        default: return .default
        }
    }
    
    var fontWeight: Font.Weight {
        switch source.typography.fontWeight.lowercased() {
        case "ultralight": return .ultraLight
        case "thin": return .thin
        case "light": return .light
        case "medium": return .medium
        case "semibold": return .semibold
        case "bold": return .bold
        case "heavy": return .heavy
        case "black": return .black
        default: return .regular
        }
    }
    
    var iconWeight: Font.Weight {
        switch source.iconography.weight.lowercased() {
        case "ultralight": return .ultraLight
        case "thin": return .thin
        case "light": return .light
        case "medium": return .medium
        case "semibold": return .semibold
        case "bold": return .bold
        case "heavy": return .heavy
        case "black": return .black
        default: return .regular
        }
    }
    
    // Spacing
    var cornerRadiusSmall: CGFloat { CGFloat(source.spacing.cornerRadiusSmall) }
    var cornerRadiusMedium: CGFloat { CGFloat(source.spacing.cornerRadiusMedium) }
    var cornerRadiusLarge: CGFloat { CGFloat(source.spacing.cornerRadiusLarge) }
    var paddingSmall: CGFloat { CGFloat(source.spacing.paddingSmall) }
    var paddingMedium: CGFloat { CGFloat(source.spacing.paddingMedium) }
    var paddingLarge: CGFloat { CGFloat(source.spacing.paddingLarge) }
    var itemSpacing: CGFloat { CGFloat(source.spacing.itemSpacing) }
    var sectionSpacing: CGFloat { CGFloat(source.spacing.sectionSpacing) }
    
    // Effects
    var shadowRadius: CGFloat { CGFloat(source.effects.shadowRadius) }
    var shadowOpacity: Double { source.effects.shadowOpacity }
    var blurRadius: CGFloat { CGFloat(source.effects.blurRadius) }
    
    // Icon lookup
    func icon(for key: String, fallback: String) -> String {
        source.iconography.icons[key] ?? fallback
    }
}

// MARK: - Default Theme

extension AppTheme {
    /// The default system theme that matches iOS styling
    static let defaultTheme = AppTheme(
        id: "default",
        name: "Default",
        description: "Clean system styling that follows iOS conventions",
        icon: "circle.grid.2x2",
        colors: ThemeColors(
            primary: "#007AFF",
            primaryVariant: "#0051D4",
            secondary: "#5856D6",
            secondaryVariant: "#3634A3",
            background: "#FFFFFF",
            backgroundSecondary: "#F2F2F7",
            backgroundTertiary: "#E5E5EA",
            textPrimary: "#000000",
            textSecondary: "#8E8E93",
            textAccent: "#007AFF",
            textOnPrimary: "#FFFFFF",
            border: "#C6C6C8",
            divider: "#C6C6C8",
            shadow: "#000000",
            success: "#34C759",
            warning: "#FF9500",
            error: "#FF3B30",
            tabBarBackground: "#F8F8F8",
            tabBarSelected: "#007AFF",
            tabBarUnselected: "#8E8E93"
        ),
        typography: ThemeTypography(
            fontFamily: "system",
            fontWeight: "regular",
            titleStyle: "none",
            letterSpacing: 0,
            lineHeightMultiplier: 1.0
        ),
        iconography: ThemeIconography(
            style: "sf-symbols",
            weight: "regular",
            icons: [:]
        ),
        spacing: ThemeSpacing(
            cornerRadiusSmall: 6,
            cornerRadiusMedium: 10,
            cornerRadiusLarge: 16,
            paddingSmall: 8,
            paddingMedium: 12,
            paddingLarge: 16,
            itemSpacing: 8,
            sectionSpacing: 16
        ),
        effects: ThemeEffects(
            shadowRadius: 4,
            shadowOpacity: 0.1,
            blurRadius: 0,
            useGradientBackground: false,
            gradientColors: [],
            gradientAngle: 0,
            buttonStyle: "filled",
            cardStyle: "flat"
        )
    )
}
