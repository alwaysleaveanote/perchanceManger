//
//  KeyboardHelper.swift
//  Chancery
//
//  Provides utility functions for keyboard management across the app.
//

import UIKit

// MARK: - KeyboardHelper

/// Utility for managing keyboard interactions.
///
/// Provides a centralized way to dismiss the keyboard from anywhere in the app,
/// useful when the first responder is not directly accessible.
///
/// ## Usage
/// ```swift
/// Button("Done") {
///     KeyboardHelper.dismiss()
/// }
/// ```
enum KeyboardHelper {
    
    /// Dismisses the keyboard by resigning the first responder.
    ///
    /// This method works regardless of which view currently has focus,
    /// making it ideal for toolbar buttons or navigation actions.
    static func dismiss() {
        Logger.debug("Dismissing keyboard", category: .ui)
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}
