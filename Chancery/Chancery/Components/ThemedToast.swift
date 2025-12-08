//
//  ThemedToast.swift
//  Chancery
//
//  A reusable toast notification component with themed styling.
//

import SwiftUI

// MARK: - Toast Style

/// The visual style of a toast notification
enum ToastStyle {
    case success
    case warning
    case error
    case info
    
    func backgroundColor(theme: ResolvedTheme) -> Color {
        switch self {
        case .success: return theme.success
        case .warning: return theme.warning
        case .error: return theme.error
        case .info: return theme.primary
        }
    }
    
    var defaultIcon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .info: return "info.circle.fill"
        }
    }
}

// MARK: - Themed Toast

/// A themed toast notification that appears at the top of the screen.
///
/// ## Usage
/// ```swift
/// @State private var showToast = false
///
/// .overlay(alignment: .top) {
///     if showToast {
///         ThemedToast(message: "Copied to clipboard", style: .success)
///             .transition(.move(edge: .top).combined(with: .opacity))
///     }
/// }
/// ```
struct ThemedToast: View {
    
    // MARK: - Properties
    
    let message: String
    let icon: String?
    let style: ToastStyle
    let characterThemeId: String?
    
    @EnvironmentObject var themeManager: ThemeManager
    
    // MARK: - Initialization
    
    /// Creates a themed toast notification
    /// - Parameters:
    ///   - message: The message to display
    ///   - icon: Optional SF Symbol icon (defaults to style's icon)
    ///   - style: The visual style (default: .success)
    ///   - characterThemeId: Optional character theme ID
    init(
        message: String,
        icon: String? = nil,
        style: ToastStyle = .success,
        characterThemeId: String? = nil
    ) {
        self.message = message
        self.icon = icon
        self.style = style
        self.characterThemeId = characterThemeId
    }
    
    // MARK: - Body
    
    var body: some View {
        let theme = resolvedTheme
        let displayIcon = icon ?? style.defaultIcon
        
        HStack(spacing: 8) {
            Image(systemName: displayIcon)
                .foregroundColor(theme.textOnPrimary)
            Text(message)
                .font(.subheadline.weight(.medium))
                .fontDesign(theme.fontDesign)
                .foregroundColor(theme.textOnPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(style.backgroundColor(theme: theme))
        )
        .padding(.top, 8)
    }
    
    private var resolvedTheme: ResolvedTheme {
        if let themeId = characterThemeId {
            return themeManager.resolvedTheme(forCharacterThemeId: themeId)
        }
        return themeManager.resolved
    }
}

// MARK: - Toast Modifier

/// A view modifier that shows a toast notification
struct ToastModifier: ViewModifier {
    @Binding var isPresented: Bool
    let message: String
    let icon: String?
    let style: ToastStyle
    let characterThemeId: String?
    let duration: TimeInterval
    
    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if isPresented {
                    ThemedToast(
                        message: message,
                        icon: icon,
                        style: style,
                        characterThemeId: characterThemeId
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isPresented = false
                            }
                        }
                    }
                }
            }
            .animation(.easeInOut(duration: 0.2), value: isPresented)
    }
}

extension View {
    /// Shows a toast notification
    /// - Parameters:
    ///   - isPresented: Binding to control visibility
    ///   - message: The message to display
    ///   - icon: Optional SF Symbol icon
    ///   - style: The visual style (default: .success)
    ///   - characterThemeId: Optional character theme ID
    ///   - duration: How long to show the toast (default: 2 seconds)
    func toast(
        isPresented: Binding<Bool>,
        message: String,
        icon: String? = nil,
        style: ToastStyle = .success,
        characterThemeId: String? = nil,
        duration: TimeInterval = 2.0
    ) -> some View {
        modifier(ToastModifier(
            isPresented: isPresented,
            message: message,
            icon: icon,
            style: style,
            characterThemeId: characterThemeId,
            duration: duration
        ))
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        ThemedToast(message: "Copied to clipboard", style: .success)
        ThemedToast(message: "Name is required", style: .warning)
        ThemedToast(message: "Failed to save", style: .error)
        ThemedToast(message: "Prompt loaded", style: .info)
    }
    .environmentObject(ThemeManager())
}
