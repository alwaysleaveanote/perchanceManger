// ContentView.swift

import SwiftUI

struct ContentView: View {
    @StateObject private var presetStore = PromptPresetStore()

    @State private var characters: [CharacterProfile] = CharacterProfile.sampleCharacters
    @State private var scratchpadPrompt: String = ""
    @State private var scratchpadSaved: [SavedPrompt] = []

    @State private var safariURL: URL?
    @State private var showingSafari: Bool = false

    var body: some View {
        TabView {
            // Scratchpad tab
            ScratchpadView(
                scratchpadPrompt: $scratchpadPrompt,
                scratchpadSaved: $scratchpadSaved,
                openGenerator: openGenerator
            )
            .tabItem {
                Label("Scratchpad", systemImage: "square.and.pencil")
            }

            // Characters tab
            CharactersView(
                characters: $characters,
                openGenerator: openGenerator
            )
            .tabItem {
                Label("Characters", systemImage: "person.3")
            }

            // Global settings tab
            GlobalSettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .environmentObject(presetStore)
        .sheet(isPresented: $showingSafari) {
            if let url = safariURL {
                SafariView(url: url)
            }
        }
    }

    // MARK: - Open furry generator in SafariViewController

    private func openGenerator(_ prompt: String) {
        var components = URLComponents(string: "https://perchance.org/furry-ai")
        components?.queryItems = [
            URLQueryItem(name: "prompt", value: prompt)
        ]

        let url = components?.url ?? URL(string: "https://perchance.org/furry-ai")!
        safariURL = url
        showingSafari = true
    }
}
