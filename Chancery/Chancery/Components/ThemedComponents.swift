import SwiftUI

// MARK: - Keyboard Dismiss Button

/// A subtle X button for keyboard toolbar that blends with the keyboard
struct KeyboardDismissButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
                .frame(width: 32, height: 32)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Themed Button

/// A button that automatically applies theme styling
struct ThemedButton: View {
    let title: String
    let icon: String?
    let style: ButtonStyleType
    let action: () -> Void
    
    @EnvironmentObject var themeManager: ThemeManager
    
    enum ButtonStyleType {
        case primary
        case secondary
        case destructive
        case plain
    }
    
    init(_ title: String, icon: String? = nil, style: ButtonStyleType = .primary, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.style = style
        self.action = action
    }
    
    var body: some View {
        let theme = themeManager.resolved
        
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: theme.icon(for: icon, fallback: icon))
                        .fontWeight(theme.iconWeight)
                        .font(.system(size: 14))
                }
                Text(title)
            }
            .font(.subheadline.weight(.semibold))
            .fontDesign(theme.fontDesign)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .foregroundColor(foregroundColor)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadiusMedium))
            .overlay(
                RoundedRectangle(cornerRadius: theme.cornerRadiusMedium)
                    .stroke(borderColor, lineWidth: needsBorder ? 1.5 : 0)
            )
            .shadow(
                color: shadowColor,
                radius: style == .primary ? 4 : 2,
                x: 0,
                y: style == .primary ? 2 : 1
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    private var foregroundColor: Color {
        let theme = themeManager.resolved
        switch style {
        case .primary:
            return themeManager.currentTheme.effects.buttonStyle == "outlined" ? theme.primary : theme.textOnPrimary
        case .secondary:
            return theme.secondary
        case .destructive:
            return themeManager.currentTheme.effects.buttonStyle == "outlined" ? theme.error : theme.textOnPrimary
        case .plain:
            return theme.textPrimary
        }
    }
    
    private var backgroundColor: Color {
        let theme = themeManager.resolved
        let buttonStyle = themeManager.currentTheme.effects.buttonStyle
        
        switch style {
        case .primary:
            switch buttonStyle {
            case "outlined": return Color.clear
            case "soft": return theme.primary.opacity(0.15)
            default: return theme.primary
            }
        case .secondary:
            switch buttonStyle {
            case "outlined": return Color.clear
            case "soft": return theme.secondary.opacity(0.15)
            default: return theme.backgroundSecondary
            }
        case .destructive:
            switch buttonStyle {
            case "outlined": return Color.clear
            case "soft": return theme.error.opacity(0.15)
            default: return theme.error
            }
        case .plain:
            return Color.clear
        }
    }
    
    private var borderColor: Color {
        let theme = themeManager.resolved
        switch style {
        case .primary: return theme.primary
        case .secondary: return theme.secondary
        case .destructive: return theme.error
        case .plain: return Color.clear
        }
    }
    
    private var needsBorder: Bool {
        themeManager.currentTheme.effects.buttonStyle == "outlined"
    }
    
    private var shadowColor: Color {
        let theme = themeManager.resolved
        switch style {
        case .primary: return theme.primary.opacity(0.3)
        case .secondary: return theme.shadow.opacity(0.15)
        case .destructive: return theme.error.opacity(0.3)
        case .plain: return Color.clear
        }
    }
}

// MARK: - Scale Button Style

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Themed Icon

/// An icon that automatically applies theme styling
struct ThemedIcon: View {
    let systemName: String
    let size: IconSize
    let color: IconColor
    
    @EnvironmentObject var themeManager: ThemeManager
    
    enum IconSize {
        case small, medium, large, custom(CGFloat)
        
        var fontSize: CGFloat {
            switch self {
            case .small: return 14
            case .medium: return 18
            case .large: return 24
            case .custom(let size): return size
            }
        }
    }
    
    enum IconColor {
        case primary, secondary, accent, custom(Color)
    }
    
    init(_ systemName: String, size: IconSize = .medium, color: IconColor = .primary) {
        self.systemName = systemName
        self.size = size
        self.color = color
    }
    
    var body: some View {
        let theme = themeManager.resolved
        let resolvedName = theme.icon(for: systemName, fallback: systemName)
        
        Image(systemName: resolvedName)
            .font(.system(size: size.fontSize, weight: theme.iconWeight))
            .foregroundColor(resolvedColor)
    }
    
    private var resolvedColor: Color {
        let theme = themeManager.resolved
        switch color {
        case .primary: return theme.textPrimary
        case .secondary: return theme.textSecondary
        case .accent: return theme.primary
        case .custom(let color): return color
        }
    }
}

// MARK: - Themed Section Header

struct ThemedSectionHeader: View {
    let title: String
    let icon: String?
    
    @EnvironmentObject var themeManager: ThemeManager
    
    init(_ title: String, icon: String? = nil) {
        self.title = title
        self.icon = icon
    }
    
    var body: some View {
        let theme = themeManager.resolved
        let typography = themeManager.currentTheme.typography
        
        HStack(spacing: 8) {
            if let icon = icon {
                ThemedIcon(icon, size: .medium, color: .accent)
            }
            
            Text(title)
                .font(.headline.weight(theme.fontWeight))
                .fontDesign(theme.fontDesign)
                .foregroundColor(theme.textPrimary)
                .tracking(CGFloat(typography.letterSpacing))
        }
    }
}

// MARK: - Themed Divider

struct ThemedDivider: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Rectangle()
            .fill(themeManager.resolved.divider)
            .frame(height: 1)
    }
}

// MARK: - Themed Text Field

struct ThemedTextField: View {
    let placeholder: String
    @Binding var text: String
    var characterThemeId: String? = nil
    var showClearButton: Bool = true
    
    @EnvironmentObject var themeManager: ThemeManager
    @FocusState private var isFocused: Bool
    
    private var theme: ResolvedTheme {
        themeManager.resolvedTheme(forCharacterThemeId: characterThemeId)
    }
    
    var body: some View {
        HStack(spacing: 8) {
            TextField(placeholder, text: $text)
                .font(.subheadline)
                .fontDesign(theme.fontDesign)
                .foregroundColor(theme.textPrimary)
            
            if showClearButton && !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(theme.textSecondary.opacity(0.6))
                        .font(.system(size: 16))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: theme.cornerRadiusMedium)
                .fill(theme.backgroundTertiary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: theme.cornerRadiusMedium)
                .stroke(isFocused ? theme.primary : theme.border.opacity(0.5), lineWidth: isFocused ? 2 : 1)
        )
        .shadow(color: theme.shadow.opacity(0.05), radius: 2, x: 0, y: 1)
        .focused($isFocused)
        .animation(.easeInOut(duration: 0.15), value: isFocused)
    }
}

// MARK: - Themed Card

struct ThemedCard<Content: View>: View {
    let content: Content
    
    @EnvironmentObject var themeManager: ThemeManager
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .themedCard()
    }
}

// MARK: - Themed Navigation Title

struct ThemedNavigationTitle: ViewModifier {
    @EnvironmentObject var themeManager: ThemeManager
    
    func body(content: Content) -> some View {
        let _ = print("[ThemedNavigationTitle] body - resolved theme id: \(themeManager.resolved.source.id)")
        return content
            .toolbarColorScheme(colorScheme, for: .navigationBar)
            .toolbarBackground(themeManager.resolved.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .tint(themeManager.resolved.primary)
            .onAppear {
                print("[ThemedNavigationTitle] onAppear - theme: \(themeManager.resolved.source.id)")
                updateNavigationBarAppearance()
            }
            .onChange(of: themeManager.resolved.source.id) { oldValue, newValue in
                print("[ThemedNavigationTitle] onChange resolved theme: \(oldValue) -> \(newValue)")
                updateNavigationBarAppearance()
            }
    }
    
    private func updateNavigationBarAppearance() {
        let theme = themeManager.resolved
        let themeData = themeManager.currentTheme
        print("[ThemedNavigationTitle] updateNavigationBarAppearance - theme: \(theme.source.id)")
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(theme.background)
        
        // Get the appropriate font for the theme
        let titleFont: UIFont
        switch themeData.typography.fontFamily {
        case "serif":
            titleFont = UIFont(descriptor: UIFontDescriptor.preferredFontDescriptor(withTextStyle: .headline).withDesign(.serif)!, size: 20)
        case "rounded":
            titleFont = UIFont(descriptor: UIFontDescriptor.preferredFontDescriptor(withTextStyle: .headline).withDesign(.rounded)!, size: 20)
        case "monospaced":
            titleFont = UIFont(descriptor: UIFontDescriptor.preferredFontDescriptor(withTextStyle: .headline).withDesign(.monospaced)!, size: 20)
        default:
            titleFont = UIFont(descriptor: UIFontDescriptor.preferredFontDescriptor(withTextStyle: .headline).withDesign(.default)!, size: 20)
        }
        
        // Title text attributes - use primary color and theme font
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor(theme.primary),
            .font: titleFont
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(theme.primary),
            .font: UIFont(descriptor: titleFont.fontDescriptor, size: 34)
        ]
        
        // Button appearance
        let buttonAppearance = UIBarButtonItemAppearance()
        buttonAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(theme.primary)
        ]
        appearance.buttonAppearance = buttonAppearance
        appearance.doneButtonAppearance = buttonAppearance
        
        // Apply the appearance globally
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
    
    private var colorScheme: ColorScheme {
        let bgHex = themeManager.currentTheme.colors.background
        return isLightColor(hex: bgHex) ? .light : .dark
    }
    
    private func isLightColor(hex: String) -> Bool {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255.0
        let g = Double((int >> 8) & 0xFF) / 255.0
        let b = Double(int & 0xFF) / 255.0
        let luminance = 0.299 * r + 0.587 * g + 0.114 * b
        return luminance > 0.5
    }
}

extension View {
    func themedNavigationBar() -> some View {
        modifier(ThemedNavigationTitle())
    }
    
    /// Use this for views that should always use the global theme, ignoring character overrides
    func globalThemedNavigationBar() -> some View {
        modifier(GlobalThemedNavigationTitle())
    }
    
    /// Use this for character pages that should use the character's theme
    func characterThemedNavigationBar(characterThemeId: String?) -> some View {
        modifier(CharacterThemedNavigationTitle(characterThemeId: characterThemeId))
    }
}

// MARK: - Character Themed Navigation Title

/// A navigation bar modifier that uses the character's theme (or global if none set)
struct CharacterThemedNavigationTitle: ViewModifier {
    let characterThemeId: String?
    
    @EnvironmentObject var themeManager: ThemeManager
    
    private var theme: ResolvedTheme {
        themeManager.resolvedTheme(forCharacterThemeId: characterThemeId)
    }
    
    private var themeData: AppTheme {
        themeManager.theme(forCharacterThemeId: characterThemeId)
    }
    
    func body(content: Content) -> some View {
        content
            .toolbarColorScheme(colorScheme, for: .navigationBar)
            .toolbarBackground(theme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .tint(theme.primary)
            .onAppear {
                updateNavigationBarAppearance()
            }
            .onChange(of: characterThemeId) { _, _ in
                updateNavigationBarAppearance()
            }
    }
    
    private func updateNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(theme.background)
        
        // Get the appropriate font for the theme
        let titleFont: UIFont
        switch themeData.typography.fontFamily {
        case "serif":
            titleFont = UIFont(descriptor: UIFontDescriptor.preferredFontDescriptor(withTextStyle: .headline).withDesign(.serif)!, size: 20)
        case "rounded":
            titleFont = UIFont(descriptor: UIFontDescriptor.preferredFontDescriptor(withTextStyle: .headline).withDesign(.rounded)!, size: 20)
        case "monospaced":
            titleFont = UIFont(descriptor: UIFontDescriptor.preferredFontDescriptor(withTextStyle: .headline).withDesign(.monospaced)!, size: 20)
        default:
            titleFont = UIFont(descriptor: UIFontDescriptor.preferredFontDescriptor(withTextStyle: .headline).withDesign(.default)!, size: 20)
        }
        
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor(theme.primary),
            .font: titleFont
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(theme.primary),
            .font: UIFont(descriptor: titleFont.fontDescriptor, size: 34)
        ]
        
        let buttonAppearance = UIBarButtonItemAppearance()
        buttonAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(theme.primary)
        ]
        appearance.buttonAppearance = buttonAppearance
        appearance.doneButtonAppearance = buttonAppearance
        
        // Apply the appearance globally
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
    
    private var colorScheme: ColorScheme {
        let bgHex = themeData.colors.background
        return isLightColor(hex: bgHex) ? .light : .dark
    }
    
    private func isLightColor(hex: String) -> Bool {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255.0
        let g = Double((int >> 8) & 0xFF) / 255.0
        let b = Double(int & 0xFF) / 255.0
        let luminance = 0.299 * r + 0.587 * g + 0.114 * b
        return luminance > 0.5
    }
}

// MARK: - Global Themed Navigation Title

/// A navigation bar modifier that always uses the global theme, ignoring character theme overrides
struct GlobalThemedNavigationTitle: ViewModifier {
    @EnvironmentObject var themeManager: ThemeManager
    
    private var globalTheme: ResolvedTheme {
        if let theme = themeManager.availableThemes.first(where: { $0.id == themeManager.globalThemeId }) {
            return ResolvedTheme(source: theme)
        }
        return themeManager.resolved
    }
    
    private var globalThemeData: AppTheme {
        themeManager.availableThemes.first(where: { $0.id == themeManager.globalThemeId }) ?? themeManager.currentTheme
    }
    
    func body(content: Content) -> some View {
        let _ = print("[GlobalThemedNavigationTitle] body - globalTheme id: \(globalTheme.source.id)")
        return content
            .toolbarColorScheme(colorScheme, for: .navigationBar)
            .toolbarBackground(globalTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .tint(globalTheme.primary)
            .onAppear {
                print("[GlobalThemedNavigationTitle] onAppear - updating nav bar to global theme: \(globalTheme.source.id)")
                updateNavigationBarAppearance()
            }
            .onChange(of: themeManager.globalThemeId) { _, _ in
                print("[GlobalThemedNavigationTitle] onChange globalThemeId - updating nav bar")
                updateNavigationBarAppearance()
            }
    }
    
    private func updateNavigationBarAppearance() {
        let theme = globalTheme
        let themeData = globalThemeData
        print("[GlobalThemedNavigationTitle] updateNavigationBarAppearance - theme: \(theme.source.id)")
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(theme.background)
        
        // Get the appropriate font for the theme
        let titleFont: UIFont
        switch themeData.typography.fontFamily {
        case "serif":
            titleFont = UIFont(descriptor: UIFontDescriptor.preferredFontDescriptor(withTextStyle: .headline).withDesign(.serif)!, size: 20)
        case "rounded":
            titleFont = UIFont(descriptor: UIFontDescriptor.preferredFontDescriptor(withTextStyle: .headline).withDesign(.rounded)!, size: 20)
        case "monospaced":
            titleFont = UIFont(descriptor: UIFontDescriptor.preferredFontDescriptor(withTextStyle: .headline).withDesign(.monospaced)!, size: 20)
        default:
            titleFont = UIFont(descriptor: UIFontDescriptor.preferredFontDescriptor(withTextStyle: .headline).withDesign(.default)!, size: 20)
        }
        
        // Title text attributes - use primary color and theme font
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor(theme.primary),
            .font: titleFont
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(theme.primary),
            .font: UIFont(descriptor: titleFont.fontDescriptor, size: 34)
        ]
        
        // Button appearance
        let buttonAppearance = UIBarButtonItemAppearance()
        buttonAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(theme.primary)
        ]
        appearance.buttonAppearance = buttonAppearance
        appearance.doneButtonAppearance = buttonAppearance
        
        // Apply to all navigation bars in the app
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
        // Force existing navigation bars to update
        DispatchQueue.main.async {
            for window in UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).flatMap({ $0.windows }) {
                for navBar in window.subviews(ofType: UINavigationBar.self) {
                    navBar.standardAppearance = appearance
                    navBar.compactAppearance = appearance
                    navBar.scrollEdgeAppearance = appearance
                    navBar.setNeedsLayout()
                }
            }
        }
    }
    
    private var colorScheme: ColorScheme {
        let bgHex = globalThemeData.colors.background
        return isLightColor(hex: bgHex) ? .light : .dark
    }
    
    private func isLightColor(hex: String) -> Bool {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255.0
        let g = Double((int >> 8) & 0xFF) / 255.0
        let b = Double(int & 0xFF) / 255.0
        let luminance = 0.299 * r + 0.587 * g + 0.114 * b
        return luminance > 0.5
    }
}

// MARK: - Themed Tab Bar Appearance

struct ThemedTabBar: ViewModifier {
    @EnvironmentObject var themeManager: ThemeManager
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                updateTabBarAppearance()
            }
            .onChange(of: themeManager.globalThemeId) { _, _ in
                // Update tab bar appearance when global theme changes
                // Do NOT recreate the view - this breaks keyboard toolbars
                updateTabBarAppearance()
            }
    }
    
    private func updateTabBarAppearance() {
        let theme = themeManager.resolved
        
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(theme.tabBarBackground)
        
        // Selected state
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(theme.tabBarSelected)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(theme.tabBarSelected)
        ]
        
        // Normal state
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(theme.tabBarUnselected)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(theme.tabBarUnselected)
        ]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        
        // Force existing tab bars to update
        for window in UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).flatMap({ $0.windows }) {
            for tabBar in window.subviews(ofType: UITabBar.self) {
                tabBar.standardAppearance = appearance
                tabBar.scrollEdgeAppearance = appearance
            }
        }
    }
}

// Helper extension to find subviews of a specific type
extension UIView {
    func subviews<T: UIView>(ofType type: T.Type) -> [T] {
        var result: [T] = []
        for subview in subviews {
            if let typed = subview as? T {
                result.append(typed)
            }
            result.append(contentsOf: subview.subviews(ofType: type))
        }
        return result
    }
}

extension View {
    func themedTabBar() -> some View {
        modifier(ThemedTabBar())
    }
}

// MARK: - Theme Preview Card

/// A card showing a preview of a theme for selection
struct ThemePreviewCard: View {
    let theme: AppTheme
    let isSelected: Bool
    let action: () -> Void
    /// Optional styling theme - if nil, uses the theme being previewed for styling
    var stylingTheme: ResolvedTheme? = nil
    
    @EnvironmentObject var themeManager: ThemeManager
    
    /// The theme to use for card styling (text colors, backgrounds, etc.)
    private var cardTheme: ResolvedTheme {
        stylingTheme ?? themeManager.resolved
    }
    
    /// Get the icon for a theme based on its id
    private var themeIcon: String {
        if let icon = theme.icon {
            return icon
        }
        // Fallback icons based on theme id
        switch theme.id {
        case "default": return "circle.grid.2x2"
        case "pastel": return "cloud.fill"
        case "darkfantasy": return "moon.stars.fill"
        case "cottagecore": return "leaf.fill"
        case "vaporwave": return "waveform"
        case "minimalist": return "square"
        case "neonrave": return "sparkles"
        case "fae": return "sparkle"
        case "druidic": return "tree.fill"
        case "ocean": return "water.waves"
        case "adventure": return "map.fill"
        case "lego": return "building.2.fill"
        case "nerdy": return "book.fill"
        default: return "paintpalette.fill"
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Theme icon - uses the theme being previewed
                Image(systemName: themeIcon)
                    .font(.system(size: 24))
                    .foregroundColor(Color(hex: theme.colors.primary))
                    .frame(width: 40, height: 40)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(hex: theme.colors.background))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(hex: theme.colors.primary).opacity(0.3), lineWidth: 1)
                            )
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(theme.name)
                        .font(.headline)
                        .foregroundColor(cardTheme.textPrimary)
                    
                    Text(theme.description)
                        .font(.caption)
                        .foregroundColor(cardTheme.textSecondary)
                        .lineLimit(isSelected ? nil : 2)
                        .animation(.easeInOut(duration: 0.2), value: isSelected)
                }
                
                Spacer()
                
                // Color preview dots - uses the theme being previewed
                HStack(spacing: 3) {
                    Circle()
                        .fill(Color(hex: theme.colors.primary))
                        .frame(width: 12, height: 12)
                    Circle()
                        .fill(Color(hex: theme.colors.secondary))
                        .frame(width: 12, height: 12)
                }
            }
            .padding(12)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardTheme.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: cardTheme.cornerRadiusMedium))
        .overlay(
            RoundedRectangle(cornerRadius: cardTheme.cornerRadiusMedium)
                .stroke(isSelected ? cardTheme.primary : Color.clear, lineWidth: 2)
        )
    }
}
