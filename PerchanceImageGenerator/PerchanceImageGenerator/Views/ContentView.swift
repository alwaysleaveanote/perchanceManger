import SwiftUI
import UIKit

/// Wrapper for Safari sheet presentation
struct SafariItem: Identifiable {
    let id = UUID()
    let url: URL
}

/// Main app content with tab navigation
struct ContentView: View {
    @StateObject var presetStore = PromptPresetStore()
    @EnvironmentObject var themeManager: ThemeManager

    @State private var scratchpadPrompt: String = ""
    @State private var scratchpadSaved: [SavedPrompt] = []

    @State private var characters: [CharacterProfile] =
        CharacterProfile.sampleCharacters

    @State private var safariItem: SafariItem? = nil
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            ScratchpadView(
                scratchpadPrompt: $scratchpadPrompt,
                scratchpadSaved: $scratchpadSaved,
                characters: $characters,
                openGenerator: openGenerator
            )
            .tabItem {
                Label("Scratchpad", systemImage: themeManager.resolved.icon(for: "square.and.pencil", fallback: "square.and.pencil"))
            }
            .tag(0)

            CharactersView(
                characters: $characters,
                openGenerator: openGenerator
            )
            .tabItem {
                Label("Characters", systemImage: themeManager.resolved.icon(for: "person.3", fallback: "person.3"))
            }
            .tag(1)

            GlobalSettingsView()
                .tabItem {
                    Label("Settings", systemImage: themeManager.resolved.icon(for: "gearshape", fallback: "gearshape"))
                }
                .tag(2)
        }
        .themedTabBar()
        .tint(themeManager.resolved.primary) // Apply theme primary color to all tinted elements
        .onChange(of: selectedTab) { _, newTab in
            // Clear character theme when leaving the Characters tab
            if newTab != 1 {
                themeManager.clearCharacterTheme()
            }
        }
        .environmentObject(presetStore)
        .sheet(item: $safariItem) { item in
            SafariView(url: item.url)
        }
    }

    // MARK: - Open Perchance Generator

    private func openGenerator(_ prompt: String) {
        let slug = presetStore.defaultPerchanceGenerator.isEmpty
            ? "furry-ai"
            : presetStore.defaultPerchanceGenerator

        let urlString = "https://perchance.org/\(slug)"
        guard let url = URL(string: urlString) else { return }

        // Copy prompt for convenience
        UIPasteboard.general.string = prompt

        // Open in the Safari app
        UIApplication.shared.open(url, options: [:]) { success in
            print("[openGenerator] Opened in Safari app: \(success)")
        }
    }
}
