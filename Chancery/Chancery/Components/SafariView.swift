//
//  SafariView.swift
//  Chancery
//
//  A SwiftUI wrapper for SFSafariViewController, enabling in-app web browsing.
//

import SwiftUI
import SafariServices

// MARK: - SafariView

/// A SwiftUI wrapper for `SFSafariViewController`.
///
/// Use this view to present web content within the app using Safari's
/// rendering engine, complete with navigation controls and sharing options.
///
/// ## Usage
/// ```swift
/// .sheet(item: $safariItem) { item in
///     SafariView(url: item.url)
/// }
/// ```
struct SafariView: UIViewControllerRepresentable {
    
    // MARK: - Properties
    
    /// The URL to display in the Safari view
    let url: URL
    
    // MARK: - UIViewControllerRepresentable
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        Logger.debug("Opening Safari view: \(url.absoluteString)", category: .navigation)
        
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false
        
        let viewController = SFSafariViewController(url: url, configuration: config)
        viewController.modalPresentationStyle = .fullScreen
        viewController.preferredBarTintColor = nil
        viewController.preferredControlTintColor = .label
        
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // Safari view doesn't support URL updates after creation
    }
}
