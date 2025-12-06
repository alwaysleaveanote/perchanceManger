//
//  DismissKeyboardOnDrag.swift
//  PerchanceImageGenerator
//
//  Provides a view modifier for dismissing the keyboard when the user drags.
//  Useful for scroll views and forms where tapping outside isn't sufficient.
//

import SwiftUI

// MARK: - DismissKeyboardOnDrag

/// A view modifier that dismisses the keyboard when the user performs a drag gesture.
///
/// This is particularly useful for:
/// - Scroll views where the user might want to dismiss the keyboard while scrolling
/// - Forms with multiple text fields
/// - Any view where tapping outside the keyboard doesn't naturally dismiss it
///
/// ## Usage
/// ```swift
/// ScrollView {
///     // content
/// }
/// .dismissKeyboardOnDrag()
/// ```
struct DismissKeyboardOnDrag: ViewModifier {
    
    func body(content: Content) -> some View {
        content.gesture(
            DragGesture()
                .onChanged { _ in
                    KeyboardHelper.dismiss()
                }
        )
    }
}

// MARK: - View Extension

extension View {
    
    /// Adds a gesture that dismisses the keyboard when the user drags.
    ///
    /// Apply this modifier to scroll views or forms to allow users to
    /// dismiss the keyboard by dragging/scrolling.
    ///
    /// - Returns: A view with the keyboard dismissal gesture attached
    func dismissKeyboardOnDrag() -> some View {
        modifier(DismissKeyboardOnDrag())
    }
}
