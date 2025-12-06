import SwiftUI

/// A reusable theme picker component for settings views
struct ThemePicker: View {
    let title: String
    let selectedThemeId: String?
    let showInheritOption: Bool
    let onSelect: (String?) -> Void
    
    @EnvironmentObject var themeManager: ThemeManager
    
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
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(themeManager.resolved.textPrimary)
            
            ScrollView {
                VStack(spacing: 10) {
                    if showInheritOption {
                        inheritOptionRow
                    }
                    
                    ForEach(themeManager.availableThemes) { theme in
                        ThemePreviewCard(
                            theme: theme,
                            isSelected: selectedThemeId == theme.id,
                            action: {
                                onSelect(theme.id)
                            }
                        )
                    }
                }
            }
            .frame(maxHeight: 280) // ~4 items visible before scrolling
        }
    }
    
    private var inheritOptionRow: some View {
        Button(action: { onSelect(nil) }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Use Global Theme")
                        .font(.headline)
                        .foregroundColor(themeManager.resolved.textPrimary)
                    
                    if let globalTheme = themeManager.availableThemes.first(where: { $0.id == themeManager.globalThemeId }) {
                        Text("Currently: \(globalTheme.name)")
                            .font(.caption)
                            .foregroundColor(themeManager.resolved.textSecondary)
                    }
                }
                
                Spacer()
                
                if selectedThemeId == nil {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(themeManager.resolved.primary)
                }
            }
            .padding(12)
            .background(themeManager.resolved.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: themeManager.resolved.cornerRadiusMedium))
            .overlay(
                RoundedRectangle(cornerRadius: themeManager.resolved.cornerRadiusMedium)
                    .stroke(selectedThemeId == nil ? themeManager.resolved.primary : Color.clear, lineWidth: 2)
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
    
    var body: some View {
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
                            .foregroundColor(themeManager.resolved.textSecondary)
                        
                        Text(selectedThemeName)
                            .font(.body)
                            .foregroundColor(themeManager.resolved.textPrimary)
                    }
                    
                    Spacer()
                    
                    // Color preview dots
                    if let theme = selectedTheme {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color(hex: theme.colors.primary))
                                .frame(width: 16, height: 16)
                            Circle()
                                .fill(Color(hex: theme.colors.secondary))
                                .frame(width: 16, height: 16)
                        }
                    }
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.subheadline)
                        .foregroundColor(themeManager.resolved.textSecondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: themeManager.resolved.cornerRadiusSmall)
                        .fill(themeManager.resolved.backgroundSecondary)
                )
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                ScrollView {
                    VStack(spacing: 8) {
                        if showInheritOption {
                            themeOptionRow(theme: nil, label: "Use Global Theme", isSelected: selectedThemeId == nil)
                        }
                        
                        ForEach(themeManager.availableThemes) { theme in
                            themeOptionRow(theme: theme, label: theme.name, isSelected: selectedThemeId == theme.id)
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
    
    private func themeOptionRow(theme: AppTheme?, label: String, isSelected: Bool) -> some View {
        Button(action: {
            onSelect(theme?.id)
            withAnimation {
                isExpanded = false
            }
        }) {
            HStack {
                if let theme = theme {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color(hex: theme.colors.primary))
                            .frame(width: 14, height: 14)
                        Circle()
                            .fill(Color(hex: theme.colors.secondary))
                            .frame(width: 14, height: 14)
                    }
                } else {
                    Image(systemName: "arrow.uturn.backward.circle")
                        .foregroundColor(themeManager.resolved.textSecondary)
                }
                
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(themeManager.resolved.textPrimary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(themeManager.resolved.primary)
                        .font(.subheadline.weight(.semibold))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: themeManager.resolved.cornerRadiusSmall)
                    .fill(isSelected ? themeManager.resolved.primary.opacity(0.1) : themeManager.resolved.backgroundTertiary)
            )
        }
        .buttonStyle(.plain)
    }
}
