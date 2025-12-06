//
//  DynamicGrowingTextEditor.swift
//  PerchanceImageGenerator
//
//  A text editor that dynamically grows based on content, with placeholder support.
//

import SwiftUI

// MARK: - DynamicGrowingTextEditor

/// A text editor that dynamically adjusts its height based on content.
///
/// Features:
/// - **Dynamic Height**: Grows from `minLines` to `maxLines` based on content
/// - **Placeholder**: Shows placeholder text when empty
/// - **Theme Support**: Automatically applies the current app theme
/// - **Line Wrapping**: Properly wraps long lines
///
/// ## Height Behavior
/// - Starts at minimum height based on `minLines`
/// - Grows as content is added
/// - Stops growing at maximum height based on `maxLines`
/// - Becomes scrollable when content exceeds maximum height
///
/// ## Usage
/// ```swift
/// DynamicGrowingTextEditor(
///     text: $description,
///     placeholder: "Enter a description...",
///     minLines: 2,
///     maxLines: 8
/// )
/// ```
struct DynamicGrowingTextEditor: View {
    
    // MARK: - Properties
    
    /// Binding to the text content
    @Binding var text: String
    
    /// Placeholder text shown when editor is empty
    let placeholder: String
    
    /// Minimum number of visible lines
    let minLines: Int
    
    /// Maximum number of visible lines before scrolling
    let maxLines: Int
    
    /// Font size for the text
    let fontSize: CGFloat
    
    // MARK: - Environment & State
    
    @EnvironmentObject var themeManager: ThemeManager
    
    /// Measured height of the current content
    @State private var measuredHeight: CGFloat = 0
    
    // MARK: - Computed Properties
    
    /// Line height based on system font
    private var lineHeight: CGFloat {
        UIFont.systemFont(ofSize: fontSize).lineHeight
    }
    
    /// Font to use for the text editor
    private var textFont: Font {
        .system(size: fontSize)
    }
    
    /// Minimum height based on minLines
    private var minHeight: CGFloat {
        CGFloat(max(minLines, 1)) * lineHeight + Constants.verticalPadding
    }
    
    /// Maximum height based on maxLines
    private var maxHeight: CGFloat {
        CGFloat(max(maxLines, minLines)) * lineHeight + Constants.verticalPadding
    }
    
    /// Whether the text field is effectively empty
    private var isEmpty: Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Constants
    
    private enum Constants {
        static let verticalPadding: CGFloat = 16
        static let placeholderPadding: CGFloat = 8
        static let borderOpacity: CGFloat = 0.5
    }
    
    // MARK: - Initialization
    
    /// Creates a new dynamic growing text editor
    /// - Parameters:
    ///   - text: Binding to the text content
    ///   - placeholder: Placeholder text shown when empty
    ///   - minLines: Minimum visible lines (default: 1)
    ///   - maxLines: Maximum visible lines before scrolling (default: 10)
    ///   - fontSize: Font size (default: 16)
    init(
        text: Binding<String>,
        placeholder: String,
        minLines: Int = 1,
        maxLines: Int = 10,
        fontSize: CGFloat = 16
    ) {
        self._text = text
        self.placeholder = placeholder
        self.minLines = minLines
        self.maxLines = maxLines
        self.fontSize = fontSize
    }
    
    // MARK: - Body
    
    var body: some View {
        let theme = themeManager.resolved
        
        ZStack(alignment: .topLeading) {
            textEditorView(theme: theme)
            placeholderView(theme: theme)
        }
        .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadiusSmall))
        .overlay(
            RoundedRectangle(cornerRadius: theme.cornerRadiusSmall)
                .stroke(theme.border.opacity(Constants.borderOpacity), lineWidth: 1)
        )
    }
    
    // MARK: - Subviews
    
    /// The main text editor
    private func textEditorView(theme: ResolvedTheme) -> some View {
        TextEditor(text: $text)
            .font(textFont)
            .fontDesign(theme.fontDesign)
            .foregroundColor(theme.textPrimary)
            .scrollContentBackground(.hidden)
            .frame(
                minHeight: minHeight,
                maxHeight: min(max(measuredHeight, minHeight), maxHeight)
            )
            .background(theme.backgroundTertiary)
            .background(
                HeightMeasurementView(text: text, height: $measuredHeight)
            )
    }
    
    /// Placeholder text overlay
    @ViewBuilder
    private func placeholderView(theme: ResolvedTheme) -> some View {
        if isEmpty && !placeholder.isEmpty {
            Text(placeholder)
                .font(textFont)
                .fontDesign(theme.fontDesign)
                .foregroundColor(theme.textSecondary.opacity(0.6))
                .padding(.horizontal, Constants.placeholderPadding)
                .padding(.vertical, Constants.placeholderPadding)
                .allowsHitTesting(false) // Allow taps to pass through to TextEditor
        }
    }
}

// MARK: - HeightMeasurementView

/// A helper view that measures the height of text content.
///
/// This view renders the text invisibly and reports its measured height,
/// allowing the parent to adjust its frame accordingly.
private struct HeightMeasurementView: View {
    
    // MARK: - Properties
    
    /// The text to measure
    let text: String
    
    /// Binding to report the measured height
    @Binding var height: CGFloat
    
    // MARK: - Constants
    
    private enum Constants {
        static let horizontalPadding: CGFloat = 4
        static let verticalPadding: CGFloat = 4
        static let heightThreshold: CGFloat = 0.5
    }
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { _ in
            Text(text.isEmpty ? " " : text)
                .font(.body)
                .padding(.horizontal, Constants.horizontalPadding)
                .padding(.vertical, Constants.verticalPadding)
                .fixedSize(horizontal: false, vertical: true)
                .background(heightReporter)
                .opacity(0) // Invisible - only used for measurement
        }
    }
    
    // MARK: - Height Reporter
    
    /// Reports height changes to the binding
    private var heightReporter: some View {
        GeometryReader { geometry in
            Color.clear
                .onAppear {
                    updateHeight(from: geometry)
                }
                .onChange(of: geometry.size.height) { _, _ in
                    updateHeight(from: geometry)
                }
        }
    }
    
    /// Updates the height binding if the change is significant
    private func updateHeight(from geometry: GeometryProxy) {
        let newHeight = geometry.size.height
        
        // Only update if change is significant (avoids layout loops)
        guard abs(newHeight - height) > Constants.heightThreshold else { return }
        
        DispatchQueue.main.async {
            height = newHeight
        }
    }
}
