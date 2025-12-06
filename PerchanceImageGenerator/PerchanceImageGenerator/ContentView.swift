import SwiftUI

// Small wrapper so we can use .sheet(item:)
struct SafariItem: Identifiable {
    let id = UUID()
    let url: URL
}

struct ContentView: View {
    @StateObject var presetStore = PromptPresetStore()

    @State private var scratchpadPrompt: String = ""
    @State private var scratchpadSaved: [SavedPrompt] = []

    @State private var characters: [CharacterProfile] =
        CharacterProfile.sampleCharacters

    // Instead of Bool + URL?, we use a single optional item
    @State private var safariItem: SafariItem? = nil

    var body: some View {
        TabView {
            ScratchpadView(
                scratchpadPrompt: $scratchpadPrompt,
                scratchpadSaved: $scratchpadSaved,
                openGenerator: openGenerator
            )
            .tabItem {
                Label("Scratchpad", systemImage: "square.and.pencil")
            }

            CharactersView(
                characters: $characters,
                openGenerator: openGenerator
            )
            .tabItem {
                Label("Characters", systemImage: "person.3")
            }

            GlobalSettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .environmentObject(presetStore)
        // Sheet now appears ONLY when safariItem is non-nil
        .sheet(item: $safariItem) { item in
            SafariView(url: item.url)
        }
    }

    // MARK: - Open Perchance generator

    private func openGenerator(_ prompt: String) {
        let slug = presetStore.defaultPerchanceGenerator.isEmpty
            ? "furry-ai"
            : presetStore.defaultPerchanceGenerator

        let urlString = "https://perchance.org/\(slug)"
        guard let url = URL(string: urlString) else { return }

        // Copy prompt for convenience
        UIPasteboard.general.string = prompt

        // Open in the Safari app instead of in-app SafariView
        UIApplication.shared.open(url, options: [:]) { success in
            print("[openGenerator] Opened in Safari app: \(success)")
        }
    }
}
