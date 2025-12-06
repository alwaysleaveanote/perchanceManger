import SwiftUI

/// A reusable theme picker component for settings views
struct ThemePicker: View {
    let title: String
    let selectedThemeId: String?
    let showInheritOption: Bool
    let onSelect: (String?) -> Void
    
    @EnvironmentObject var themeManager: ThemeManager
    
    /// The theme to use for styling this picker - based on selected theme for preview
    private var previewTheme: ResolvedTheme {
        if let themeId = selectedThemeId,
           let theme = themeManager.availableThemes.first(where: { $0.id == themeId }) {
            return ResolvedTheme(source: theme)
        }
        // Fall back to global theme
        return themeManager.resolved
    }
    
    init(
        title: String = "Theme",
        selectedThemeId: String?,
        showInheritOption: Bool = false,
        onSelect: @escaping (String?) -> Void
    ) {
        self.title = title
        self.selectedThemeId = selectedThemeId
        self.showInheritOption = showInheritOption
        self.onSelect = onSelect
    }
    
    var body: some View {
        let theme = previewTheme
        
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(theme.textPrimary)
            
            ScrollView {
                VStack(spacing: 10) {
                    if showInheritOption {
                        inheritOptionRow(theme: theme)
                    }
                    
                    ForEach(themeManager.availableThemes) { availableTheme in
                        ThemePreviewCard(
                            theme: availableTheme,
                            isSelected: selectedThemeId == availableTheme.id,
                            action: {
                                onSelect(availableTheme.id)
                            }
                        )
                    }
                }
            }
            .frame(maxHeight: 280) // ~4 items visible before scrolling
        }
    }
    
    private func inheritOptionRow(theme: ResolvedTheme) -> some View {
        Button(action: { onSelect(nil) }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Use Global Theme")
                        .font(.headline)
                        .foregroundColor(theme.textPrimary)
                    
                    if let globalTheme = themeManager.availableThemes.first(where: { $0.id == themeManager.globalThemeId }) {
                        Text("Currently: \(globalTheme.name)")
                            .font(.caption)
                            .foregroundColor(theme.textSecondary)
                    }
                }
                
                Spacer()
                
                if selectedThemeId == nil {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(theme.primary)
                }
            }
            .padding(12)
            .background(theme.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadiusMedium))
            .overlay(
                RoundedRectangle(cornerRadius: theme.cornerRadiusMedium)
                    .stroke(selectedThemeId == nil ? theme.primary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Compact Theme Picker (for inline use)

struct CompactThemePicker: View {
    let selectedThemeId: String?
    let showInheritOption: Bool
    let onSelect: (String?) -> Void
    
    @EnvironmentObject var themeManager: ThemeManager
    @State private var isExpanded: Bool = false
    
    /// The theme to use for styling - based on selected theme for preview
    private var previewTheme: ResolvedTheme {
        if let themeId = selectedThemeId,
           let theme = themeManager.availableThemes.first(where: { $0.id == themeId }) {
            return ResolvedTheme(source: theme)
        }
        return themeManager.resolved
    }
    
    var body: some View {
        let theme = previewTheme
        
        VStack(alignment: .leading, spacing: 8) {
            Button(action: {
                withAnimation {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Theme")
                            .font(.subheadline)
                            .foregroundColor(theme.textSecondary)
                        
                        Text(selectedThemeName)
                            .font(.body)
                            .foregroundColor(theme.textPrimary)
                    }
                    
                    Spacer()
                    
                    // Color preview dots
                    if let selectedAppTheme = selectedTheme {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color(hex: selectedAppTheme.colors.primary))
                                .frame(width: 16, height: 16)
                            Circle()
                                .fill(Color(hex: selectedAppTheme.colors.secondary))
                                .frame(width: 16, height: 16)
                        }
                    }
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.subheadline)
                        .foregroundColor(theme.textSecondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: theme.cornerRadiusSmall)
                        .fill(theme.backgroundSecondary)
                )
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                ScrollView {
                    VStack(spacing: 8) {
                        if showInheritOption {
                            themeOptionRow(appTheme: nil, label: "Use Global Theme", isSelected: selectedThemeId == nil, currentTheme: theme)
                        }
                        
                        ForEach(themeManager.availableThemes) { appTheme in
                            themeOptionRow(appTheme: appTheme, label: appTheme.name, isSelected: selectedThemeId == appTheme.id, currentTheme: theme)
                        }
                    }
                }
                .frame(maxHeight: 200) // ~4 items visible before scrolling
                .padding(.top, 4)
            }
        }
    }
    
    private var selectedThemeName: String {
        if showInheritOption && selectedThemeId == nil {
            return "Global (\(themeManager.availableThemes.first(where: { $0.id == themeManager.globalThemeId })?.name ?? "Default"))"
        }
        return selectedTheme?.name ?? "Default"
    }
    
    private var selectedTheme: AppTheme? {
        if let id = selectedThemeId {
            return themeManager.availableThemes.first(where: { $0.id == id })
        } else if showInheritOption {
            return themeManager.availableThemes.first(where: { $0.id == themeManager.globalThemeId })
        }
        return themeManager.availableThemes.first(where: { $0.id == themeManager.globalThemeId })
    }
    
    private func themeOptionRow(appTheme: AppTheme?, label: String, isSelected: Bool, currentTheme: ResolvedTheme) -> some View {
        Button(action: {
            onSelect(appTheme?.id)
            withAnimation {
                isExpanded = false
            }
        }) {
            HStack {
                if let appTheme = appTheme {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color(hex: appTheme.colors.primary))
                            .frame(width: 14, height: 14)
                        Circle()
                            .fill(Color(hex: appTheme.colors.secondary))
                            .frame(width: 14, height: 14)
                    }
                } else {
                    Image(systemName: "arrow.uturn.backward.circle")
                        .foregroundColor(currentTheme.textSecondary)
                }
                
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(currentTheme.textPrimary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(currentTheme.primary)
                        .font(.subheadline.weight(.semibold))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: currentTheme.cornerRadiusSmall)
                    .fill(isSelected ? currentTheme.primary.opacity(0.1) : currentTheme.backgroundTertiary)
            )
        }
        .buttonStyle(.plain)
    }
}
