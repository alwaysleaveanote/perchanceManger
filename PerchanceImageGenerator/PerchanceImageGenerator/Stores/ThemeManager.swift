import SwiftUI
import Combine

/// Manages theme loading, selection, and provides the current resolved theme
/// Supports both global themes and character-specific theme overrides
final class ThemeManager: ObservableObject {
    
    // MARK: - Published Properties
    
    /// All available themes loaded from JSON files
    @Published private(set) var availableThemes: [AppTheme] = []
    
    /// The globally selected theme ID
    @Published var globalThemeId: String {
        didSet {
            UserDefaults.standard.set(globalThemeId, forKey: "globalThemeId")
            updateResolvedTheme()
        }
    }
    
    /// Currently active character's theme override (nil = use global)
    @Published var activeCharacterThemeId: String? = nil {
        didSet {
            updateResolvedTheme()
        }
    }
    
    /// The resolved theme ready for use in views
    @Published private(set) var resolved: ResolvedTheme
    
    /// The raw theme currently in use
    var currentTheme: AppTheme {
        if let charThemeId = activeCharacterThemeId,
           let theme = availableThemes.first(where: { $0.id == charThemeId }) {
            return theme
        }
        return availableThemes.first(where: { $0.id == globalThemeId }) ?? AppTheme.defaultTheme
    }
    
    // MARK: - Initialization
    
    init() {
        let savedThemeId = UserDefaults.standard.string(forKey: "globalThemeId") ?? "default"
        self.globalThemeId = savedThemeId
        self.resolved = ResolvedTheme(source: AppTheme.defaultTheme)
        
        loadBuiltInThemes()
        loadCustomThemes()
        updateResolvedTheme()
    }
    
    // MARK: - Theme Loading
    
    /// Load built-in themes bundled with the app
    private func loadBuiltInThemes() {
        // Always include the default theme
        var themes: [AppTheme] = [AppTheme.defaultTheme]
        
        // Load bundled JSON theme files
        let bundledThemeNames = [
            "pastel", "adventure", "cyberwave",
            "fae", "paladin", "druidic", "bubblegum", "kidcore",
            "nerdy", "neonrave", "darkfantasy", "cottagecore",
            "ocean", "steampunk", "vaporwave", "minimalist"
        ]
         
        for themeName in bundledThemeNames {
            if let url = Bundle.main.url(forResource: themeName, withExtension: "json") {
                do {
                    let data = try Data(contentsOf: url)
                    let theme = try JSONDecoder().decode(AppTheme.self, from: data)
                    themes.append(theme)
                    print("[ThemeManager] Loaded theme: \(theme.name) (id: \(theme.id))")
                } catch {
                    print("[ThemeManager] Failed to load theme '\(themeName)': \(error)")
                }
            } else {
                print("[ThemeManager] Theme file not found: \(themeName).json")
            }
        }
        
        print("[ThemeManager] Total themes loaded: \(themes.count)")
        availableThemes = themes
    }
    
    /// Load custom themes from the app's documents directory
    private func loadCustomThemes() {
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        let themesURL = documentsURL.appendingPathComponent("Themes", isDirectory: true)
        
        // Create themes directory if it doesn't exist
        try? FileManager.default.createDirectory(at: themesURL, withIntermediateDirectories: true)
        
        // Load all JSON files from the themes directory
        guard let files = try? FileManager.default.contentsOfDirectory(at: themesURL, includingPropertiesForKeys: nil) else {
            return
        }
        
        for file in files where file.pathExtension == "json" {
            if let data = try? Data(contentsOf: file),
               let theme = try? JSONDecoder().decode(AppTheme.self, from: data) {
                // Avoid duplicates
                if !availableThemes.contains(where: { $0.id == theme.id }) {
                    availableThemes.append(theme)
                }
            }
        }
    }
    
    /// Reload all themes (useful after adding new theme files)
    func reloadThemes() {
        availableThemes = []
        loadBuiltInThemes()
        loadCustomThemes()
        updateResolvedTheme()
    }
    
    // MARK: - Theme Selection
    
    /// Set the global theme by ID
    func setGlobalTheme(_ themeId: String) {
        guard availableThemes.contains(where: { $0.id == themeId }) else { return }
        globalThemeId = themeId
    }
    
    /// Set a character-specific theme override
    func setCharacterTheme(_ themeId: String?) { 
        print("[ThemeManager] setCharacterTheme called with themeId: \(themeId ?? "nil")")
        print("[ThemeManager] Previous activeCharacterThemeId: \(activeCharacterThemeId ?? "nil")")
        activeCharacterThemeId = themeId
        print("[ThemeManager] New activeCharacterThemeId: \(activeCharacterThemeId ?? "nil")")
        print("[ThemeManager] Current resolved theme: \(resolved.source.id)")
    }
    
    /// Clear the character theme override (revert to global)
    func clearCharacterTheme() {
        print("[ThemeManager] clearCharacterTheme called")
        print("[ThemeManager] Previous activeCharacterThemeId: \(activeCharacterThemeId ?? "nil")")
        activeCharacterThemeId = nil
        print("[ThemeManager] Cleared - now using global theme: \(globalThemeId)")
        print("[ThemeManager] Current resolved theme: \(resolved.source.id)")
    }
    
    // MARK: - Private Helpers
    
    private func updateResolvedTheme() {
        let oldThemeId = resolved.source.id
        resolved = ResolvedTheme(source: currentTheme)
        print("[ThemeManager] updateResolvedTheme: \(oldThemeId) -> \(resolved.source.id)")
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
