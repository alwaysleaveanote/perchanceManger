import SwiftUI
import SafariServices

/// A UIViewControllerRepresentable wrapper for SFSafariViewController
struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        print("[SafariView] makeUIViewController with URL = \(url.absoluteString)")

        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false

        let vc = SFSafariViewController(url: url, configuration: config)
        vc.modalPresentationStyle = .fullScreen
        vc.preferredBarTintColor = nil
        vc.preferredControlTintColor = .label

        return vc
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // No updates needed for now
    }
}
