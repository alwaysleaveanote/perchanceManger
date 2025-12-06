//
//  ThemeManager.swift
//  PerchanceImageGenerator
//
//  Central manager for app theming. Handles loading themes from bundled JSON files,
//  managing theme selection, and providing resolved theme values to the UI.
//

import SwiftUI
import Combine

// MARK: - ThemeManager

/// Central manager for application theming.
///
/// `ThemeManager` is responsible for:
/// - Loading themes from bundled JSON files and custom theme directories
/// - Managing the global theme selection (persisted to UserDefaults)
/// - Providing helper functions to resolve character-specific themes
/// - Providing a resolved global theme with computed color values for the UI
///
/// ## Theme Resolution
/// - `resolved` always returns the global theme
/// - Use `resolvedTheme(forCharacterThemeId:)` to get a character's theme
/// - Character themes are resolved locally in views, not stored globally
///
/// ## Usage
/// ```swift
/// @EnvironmentObject var themeManager: ThemeManager
///
/// // Access global theme
/// let backgroundColor = themeManager.resolved.background
///
/// // Change global theme
/// themeManager.setGlobalTheme("cyberwave")
///
/// // Get character-specific theme (resolved locally, no global state)
/// let charTheme = themeManager.resolvedTheme(forCharacterThemeId: character.characterThemeId)
/// ```
final class ThemeManager: ObservableObject {
    
    // MARK: - Constants
    
    private enum StorageKeys {
        static let globalThemeId = "globalThemeId"
    }
    
    private enum Defaults {
        static let themeId = "default"
    }
    
    /// Names of bundled theme JSON files (without extension)
    private static let bundledThemeNames = [
        "pastel", "adventure", "cyberwave",
        "fae", "paladin", "druidic", "bubblegum", "lego",
        "nerdy", "neonrave", "darkfantasy", "cottagecore",
        "ocean", "steampunk", "vaporwave", "minimalist"
    ]
    
    // MARK: - Published Properties
    
    /// All available themes (built-in + custom)
    @Published private(set) var availableThemes: [AppTheme] = []
    
    /// The globally selected theme ID (persisted to UserDefaults)
    @Published var globalThemeId: String {
        didSet {
            guard globalThemeId != oldValue else { return }
            Logger.info("Global theme changed: '\(oldValue)' → '\(globalThemeId)'", category: .theme)
            UserDefaults.standard.set(globalThemeId, forKey: StorageKeys.globalThemeId)
            updateResolvedTheme()
        }
    }
    
    /// The resolved GLOBAL theme with computed color values, ready for UI use.
    /// This always reflects the global theme - use `resolvedTheme(for:)` for character-specific themes.
    @Published private(set) var resolved: ResolvedTheme
    
    // MARK: - Computed Properties
    
    /// The raw global `AppTheme` currently in use
    var currentTheme: AppTheme {
        availableThemes.first(where: { $0.id == globalThemeId }) ?? AppTheme.defaultTheme
    }
    
    /// Alias for currentTheme for clarity
    var globalTheme: AppTheme {
        currentTheme
    }
    
    // MARK: - Initialization
    
    /// Creates a new ThemeManager, loading saved preferences and available themes
    init() {
        // Load persisted theme selection
        let savedThemeId = UserDefaults.standard.string(forKey: StorageKeys.globalThemeId) ?? Defaults.themeId
        self.globalThemeId = savedThemeId
        self.resolved = ResolvedTheme(source: AppTheme.defaultTheme)
        
        Logger.info("Initializing with saved theme: '\(savedThemeId)'", category: .theme)
        
        // Load all available themes
        loadBuiltInThemes()
        loadCustomThemes()
        updateResolvedTheme()
        
        Logger.info("Theme manager ready with \(availableThemes.count) themes", category: .theme)
    }
    
    // MARK: - Theme Loading
    
    /// Loads built-in themes bundled with the app
    private func loadBuiltInThemes() {
        Logger.debug("Loading built-in themes", category: .theme)
        
        // Always include the default theme
        var themes: [AppTheme] = [AppTheme.defaultTheme]
        
        // Load each bundled theme JSON
        for themeName in Self.bundledThemeNames {
            if let theme = loadTheme(named: themeName) {
                themes.append(theme)
            }
        }
        
        Logger.info("Loaded \(themes.count) built-in themes", category: .theme)
        availableThemes = themes
    }
    
    /// Loads a single theme from a bundled JSON file
    /// - Parameter name: The filename without extension
    /// - Returns: The loaded theme, or nil if loading failed
    private func loadTheme(named name: String) -> AppTheme? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json") else {
            Logger.warning("Theme file not found: \(name).json", category: .theme)
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            let theme = try JSONDecoder().decode(AppTheme.self, from: data)
            Logger.debug("Loaded theme: \(theme.name) (id: \(theme.id))", category: .theme)
            return theme
        } catch {
            Logger.error("Failed to load theme '\(name)': \(error.localizedDescription)", category: .theme)
            return nil
        }
    }
    
    /// Loads custom themes from the app's documents directory
    private func loadCustomThemes() {
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            Logger.warning("Could not access documents directory", category: .theme)
            return
        }
        
        let themesURL = documentsURL.appendingPathComponent("Themes", isDirectory: true)
        
        // Create themes directory if needed
        do {
            try FileManager.default.createDirectory(at: themesURL, withIntermediateDirectories: true)
        } catch {
            Logger.error("Failed to create themes directory: \(error.localizedDescription)", category: .theme)
            return
        }
        
        // Load all JSON files from the themes directory
        guard let files = try? FileManager.default.contentsOfDirectory(at: themesURL, includingPropertiesForKeys: nil) else {
            return
        }
        
        var customCount = 0
        for file in files where file.pathExtension == "json" {
            if let data = try? Data(contentsOf: file),
               let theme = try? JSONDecoder().decode(AppTheme.self, from: data) {
                // Avoid duplicates
                if !availableThemes.contains(where: { $0.id == theme.id }) {
                    availableThemes.append(theme)
                    customCount += 1
                    Logger.debug("Loaded custom theme: \(theme.name)", category: .theme)
                }
            }
        }
        
        if customCount > 0 {
            Logger.info("Loaded \(customCount) custom themes", category: .theme)
        }
    }
    
    /// Reloads all themes from disk
    ///
    /// Call this after adding new theme files to pick up changes.
    func reloadThemes() {
        Logger.info("Reloading all themes", category: .theme)
        availableThemes = []
        loadBuiltInThemes()
        loadCustomThemes()
        updateResolvedTheme()
    }
    
    // MARK: - Theme Selection
    
    /// Sets the global theme by ID
    /// - Parameter themeId: The ID of the theme to select
    /// - Returns: True if the theme was found and selected
    @discardableResult
    func setGlobalTheme(_ themeId: String) -> Bool {
        guard availableThemes.contains(where: { $0.id == themeId }) else {
            Logger.warning("Attempted to set unknown theme: '\(themeId)'", category: .theme)
            return false
        }
        globalThemeId = themeId
        return true
    }
    
    /// Resolves the theme for a specific character.
    /// If the character has a custom theme, returns that theme.
    /// Otherwise, returns the global theme.
    /// - Parameter characterThemeId: The character's theme ID (from CharacterProfile.characterThemeId)
    /// - Returns: The resolved theme for the character
    func resolvedTheme(forCharacterThemeId characterThemeId: String?) -> ResolvedTheme {
        if let themeId = characterThemeId,
           let theme = availableThemes.first(where: { $0.id == themeId }) {
            return ResolvedTheme(source: theme)
        }
        return resolved // Fall back to global theme
    }
    
    /// Convenience method to get the AppTheme for a character theme ID
    /// - Parameter characterThemeId: The character's theme ID
    /// - Returns: The AppTheme if found, otherwise the global theme
    func theme(forCharacterThemeId characterThemeId: String?) -> AppTheme {
        if let themeId = characterThemeId,
           let theme = availableThemes.first(where: { $0.id == themeId }) {
            return theme
        }
        return globalTheme
    }
    
    // MARK: - Theme Lookup
    
    /// Finds a theme by its ID
    /// - Parameter id: The theme ID to find
    /// - Returns: The theme if found, nil otherwise
    func theme(withId id: String) -> AppTheme? {
        availableThemes.first { $0.id == id }
    }
    
    // MARK: - Private Helpers
    
    /// Updates the resolved global theme based on current selection
    private func updateResolvedTheme() {
        let oldThemeId = resolved.source.id
        let newTheme = globalTheme
        resolved = ResolvedTheme(source: newTheme)
        
        if oldThemeId != newTheme.id {
            Logger.debug("Global resolved theme updated: '\(oldThemeId)' → '\(newTheme.id)'", category: .theme)
        }
    }
}

// MARK: - Environment Key

private struct ThemeManagerKey: EnvironmentKey {
    static let defaultValue: ThemeManager = ThemeManager()
}

extension EnvironmentValues {
    var themeManager: ThemeManager {
        get { self[ThemeManagerKey.self] }
        set { self[ThemeManagerKey.self] = newValue }
    }
}

// MARK: - Convenience View Extension

extension View {
    /// Apply the current theme's background
    func themedBackground() -> some View {
        modifier(ThemedBackgroundModifier())
    }
    
    /// Apply themed styling to a card/section
    func themedCard() -> some View {
        modifier(ThemedCardModifier())
    }
    
    /// Apply themed styling to a list
    func themedList() -> some View {
        modifier(ThemedListModifier())
    }
}

// MARK: - View Modifiers

struct ThemedBackgroundModifier: ViewModifier {
    @EnvironmentObject var themeManager: ThemeManager
    
    func body(content: Content) -> some View {
        content
            .background(
                ThemedBackgroundView()
                    .ignoresSafeArea()
            )
    }
}

/// A view that renders the themed background with texture support
struct ThemedBackgroundView: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        let theme = themeManager.currentTheme
        let resolved = themeManager.resolved
        
        ZStack {
            // Base layer: solid color or gradient
            if theme.effects.useGradientBackground && resolved.gradientColors.count >= 2 {
                LinearGradient(
                    colors: resolved.gradientColors,
                    startPoint: gradientStartPoint,
                    endPoint: gradientEndPoint
                )
            } else {
                resolved.background
            }
            
            // Texture overlay based on theme style
            textureOverlay(for: theme.id)
        }
    }
    
    @ViewBuilder
    private func textureOverlay(for themeId: String) -> some View {
        let resolved = themeManager.resolved
        
        switch themeId {
        case "pastel":
            // Soft, bubbly pattern for pastel theme
            PastelTextureView()
                .opacity(0.15)
            
        case "adventure":
            // Parchment-like texture for adventure theme
            ParchmentTextureView()
                .opacity(0.25)
            
        case "cyberwave":
            // Neon grid/glow effect for cyberwave
            CyberwaveTextureView(primaryColor: resolved.primary, secondaryColor: resolved.secondary)
                .opacity(0.12)
            
        default:
            // No texture for default theme
            EmptyView()
        }
    }
    
    private var gradientStartPoint: UnitPoint {
        let angle = themeManager.currentTheme.effects.gradientAngle
        return unitPoint(for: angle)
    }
    
    private var gradientEndPoint: UnitPoint {
        let angle = themeManager.currentTheme.effects.gradientAngle + 180
        return unitPoint(for: angle)
    }
    
    private func unitPoint(for angle: Double) -> UnitPoint {
        let radians = angle * .pi / 180
        let x = 0.5 + 0.5 * cos(radians)
        let y = 0.5 + 0.5 * sin(radians)
        return UnitPoint(x: x, y: y)
    }
}

// MARK: - Texture Views

/// Soft, bubbly circles for pastel theme
struct PastelTextureView: View {
    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                // Draw soft circles scattered across the view
                let circleCount = 40
                var rng = SeededRandomNumberGenerator(seed: 42)
                
                for _ in 0..<circleCount {
                    let x = CGFloat.random(in: 0...size.width, using: &rng)
                    let y = CGFloat.random(in: 0...size.height, using: &rng)
                    let radius = CGFloat.random(in: 20...80, using: &rng)
                    let opacity = Double.random(in: 0.3...0.7, using: &rng)
                    
                    let colors: [Color] = [.pink, .purple, .mint, .yellow, .orange]
                    let color = colors[Int.random(in: 0..<colors.count, using: &rng)]
                    
                    let circle = Path(ellipseIn: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2))
                    context.fill(circle, with: .color(color.opacity(opacity)))
                }
            }
        }
    }
}

/// Parchment-like texture for adventure theme
struct ParchmentTextureView: View {
    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                var rng = SeededRandomNumberGenerator(seed: 123)
                
                // Draw subtle noise/grain pattern
                let gridSize: CGFloat = 8
                let cols = Int(size.width / gridSize) + 1
                let rows = Int(size.height / gridSize) + 1
                
                for row in 0..<rows {
                    for col in 0..<cols {
                        let opacity = Double.random(in: 0.0...0.15, using: &rng)
                        let brownShade = Color(red: 0.4, green: 0.3, blue: 0.2)
                        
                        let rect = CGRect(
                            x: CGFloat(col) * gridSize,
                            y: CGFloat(row) * gridSize,
                            width: gridSize,
                            height: gridSize
                        )
                        context.fill(Path(rect), with: .color(brownShade.opacity(opacity)))
                    }
                }
                
                // Add some darker spots for aged effect
                for _ in 0..<20 {
                    let x = CGFloat.random(in: 0...size.width, using: &rng)
                    let y = CGFloat.random(in: 0...size.height, using: &rng)
                    let radius = CGFloat.random(in: 30...100, using: &rng)
                    let opacity = Double.random(in: 0.03...0.08, using: &rng)
                    
                    let circle = Path(ellipseIn: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2))
                    context.fill(circle, with: .color(Color.brown.opacity(opacity)))
                }
            }
        }
    }
}

/// Neon grid effect for cyberwave theme
struct CyberwaveTextureView: View {
    let primaryColor: Color
    let secondaryColor: Color
    
    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                // Draw horizontal scan lines
                let lineSpacing: CGFloat = 4
                let lineCount = Int(size.height / lineSpacing)
                
                for i in 0..<lineCount {
                    let y = CGFloat(i) * lineSpacing
                    let opacity = (i % 2 == 0) ? 0.15 : 0.05
                    
                    var path = Path()
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                    
                    context.stroke(path, with: .color(primaryColor.opacity(opacity)), lineWidth: 1)
                }
                
                // Draw subtle vertical grid lines
                let gridSpacing: CGFloat = 60
                let gridCols = Int(size.width / gridSpacing) + 1
                
                for col in 0..<gridCols {
                    let x = CGFloat(col) * gridSpacing
                    var path = Path()
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                    
                    context.stroke(path, with: .color(secondaryColor.opacity(0.08)), lineWidth: 1)
                }
                
                // Add glow spots
                var rng = SeededRandomNumberGenerator(seed: 77)
                for _ in 0..<8 {
                    let x = CGFloat.random(in: 0...size.width, using: &rng)
                    let y = CGFloat.random(in: 0...size.height, using: &rng)
                    let radius = CGFloat.random(in: 80...200, using: &rng)
                    
                    let colors = [primaryColor, secondaryColor]
                    let color = colors[Int.random(in: 0..<colors.count, using: &rng)]
                    
                    let circle = Path(ellipseIn: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2))
                    context.fill(circle, with: .color(color.opacity(0.08)))
                }
            }
        }
    }
}

/// Seeded random number generator for consistent texture patterns
struct SeededRandomNumberGenerator: RandomNumberGenerator {
    var state: UInt64
    
    init(seed: UInt64) {
        state = seed
    }
    
    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}

struct ThemedCardModifier: ViewModifier {
    @EnvironmentObject var themeManager: ThemeManager
    
    func body(content: Content) -> some View {
        let theme = themeManager.resolved
        let effects = themeManager.currentTheme.effects
        
        content
            .padding(theme.paddingMedium)
            .background(theme.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadiusMedium))
            .overlay(
                RoundedRectangle(cornerRadius: theme.cornerRadiusMedium)
                    .stroke(effects.cardStyle == "bordered" ? theme.border : Color.clear, lineWidth: 1)
            )
            .shadow(
                color: effects.cardStyle == "elevated" ? theme.shadow.opacity(theme.shadowOpacity) : Color.clear,
                radius: effects.cardStyle == "elevated" ? theme.shadowRadius : 0,
                x: 0,
                y: effects.cardStyle == "elevated" ? 2 : 0
            )
    }
}

struct ThemedListModifier: ViewModifier {
    @EnvironmentObject var themeManager: ThemeManager
    
    func body(content: Content) -> some View {
        let theme = themeManager.resolved
        
        content
            .scrollContentBackground(.hidden)
            .background(theme.background)
    }
}

// MARK: - Themed Text Styles

extension View {
    func themedTitle() -> some View {
        modifier(ThemedTitleModifier())
    }
    
    func themedHeadline() -> some View {
        modifier(ThemedHeadlineModifier())
    }
    
    func themedBody() -> some View {
        modifier(ThemedBodyModifier())
    }
    
    func themedCaption() -> some View {
        modifier(ThemedCaptionModifier())
    }
}

struct ThemedTitleModifier: ViewModifier {
    @EnvironmentObject var themeManager: ThemeManager
    
    func body(content: Content) -> some View {
        let theme = themeManager.resolved
        let typography = themeManager.currentTheme.typography
        
        content
            .font(.title.weight(theme.fontWeight))
            .fontDesign(theme.fontDesign)
            .foregroundColor(theme.textPrimary)
            .tracking(CGFloat(typography.letterSpacing))
            .textCase(textCase(for: typography.titleStyle))
    }
    
    private func textCase(for style: String) -> Text.Case? {
        switch style.lowercased() {
        case "uppercase": return .uppercase
        case "lowercase": return .lowercase
        default: return nil
        }
    }
}

struct ThemedHeadlineModifier: ViewModifier {
    @EnvironmentObject var themeManager: ThemeManager
    
    func body(content: Content) -> some View {
        let theme = themeManager.resolved
        
        content
            .font(.headline.weight(theme.fontWeight))
            .fontDesign(theme.fontDesign)
            .foregroundColor(theme.textPrimary)
    }
}

struct ThemedBodyModifier: ViewModifier {
    @EnvironmentObject var themeManager: ThemeManager
    
    func body(content: Content) -> some View {
        let theme = themeManager.resolved
        
        content
            .font(.body)
            .fontDesign(theme.fontDesign)
            .foregroundColor(theme.textPrimary)
    }
}

struct ThemedCaptionModifier: ViewModifier {
    @EnvironmentObject var themeManager: ThemeManager
    
    func body(content: Content) -> some View {
        let theme = themeManager.resolved
        
        content
            .font(.caption)
            .fontDesign(theme.fontDesign)
            .foregroundColor(theme.textSecondary)
    }
}
