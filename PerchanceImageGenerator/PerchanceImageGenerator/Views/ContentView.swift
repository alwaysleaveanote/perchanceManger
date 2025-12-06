//
//  ContentView.swift
//  PerchanceImageGenerator
//
//  The root view containing the main tab navigation structure.
//

import SwiftUI
import UIKit

// MARK: - SafariItem

/// A wrapper for presenting Safari sheets with a specific URL.
///
/// Conforms to `Identifiable` for use with SwiftUI's `sheet(item:)` modifier.
struct SafariItem: Identifiable {
    let id = UUID()
    let url: URL
}

// MARK: - Tab

/// Represents the available tabs in the main navigation.
private enum Tab: Int, CaseIterable {
    case scratchpad = 0
    case characters = 1
    case settings = 2
    
    /// The display title for the tab
    var title: String {
        switch self {
        case .scratchpad: return "Scratchpad"
        case .characters: return "Characters"
        case .settings: return "Settings"
        }
    }
    
    /// The SF Symbol icon key for the tab
    var iconKey: String {
        switch self {
        case .scratchpad: return "square.and.pencil"
        case .characters: return "person.3"
        case .settings: return "gearshape"
        }
    }
}

// MARK: - ContentView

/// The root view of the application containing tab-based navigation.
///
/// `ContentView` manages:
/// - Tab navigation between Scratchpad, Characters, and Settings
/// - The `PromptPresetStore` environment object
/// - Opening the Perchance generator in Safari
/// - Clearing character themes when navigating away from Characters tab
///
/// ## Data Flow
/// - `scratchpadPrompt` and `scratchpadSaved`: Managed locally, passed to ScratchpadView
/// - `characters`: Managed locally, passed to both ScratchpadView and CharactersView
/// - `presetStore`: Created here and injected as environment object
struct ContentView: View {
    
    // MARK: - State
    
    /// Store for managing presets and global defaults
    @StateObject private var presetStore = PromptPresetStore()
    
    /// The current scratchpad prompt text (legacy)
    @State private var scratchpadPrompt: String = ""
    
    /// Saved scratchpad prompts
    @State private var scratchpadSaved: [SavedPrompt] = []
    
    /// All character profiles
    @State private var characters: [CharacterProfile] = CharacterProfile.sampleCharacters
    
    /// Currently selected tab
    @State private var selectedTab: Tab = .scratchpad
    
    /// Safari sheet presentation item
    @State private var safariItem: SafariItem? = nil
    
    // MARK: - Environment
    
    @EnvironmentObject var themeManager: ThemeManager
    
    // MARK: - Body
    
    var body: some View {
        TabView(selection: $selectedTab) {
            scratchpadTab
            charactersTab
            settingsTab
        }
        .themedTabBar()
        .tint(themeManager.resolved.primary)
        .onChange(of: selectedTab) { _, newTab in
            handleTabChange(to: newTab)
        }
        .environmentObject(presetStore)
        .sheet(item: $safariItem) { item in
            SafariView(url: item.url)
        }
    }
    
    // MARK: - Tab Views
    
    /// Scratchpad tab content
    private var scratchpadTab: some View {
        ScratchpadView(
            scratchpadPrompt: $scratchpadPrompt,
            scratchpadSaved: $scratchpadSaved,
            characters: $characters,
            openGenerator: openGenerator
        )
        .tabItem {
            Label(Tab.scratchpad.title, systemImage: tabIcon(for: .scratchpad))
        }
        .tag(Tab.scratchpad)
    }
    
    /// Characters tab content
    private var charactersTab: some View {
        CharactersView(
            characters: $characters,
            openGenerator: openGenerator
        )
        .tabItem {
            Label(Tab.characters.title, systemImage: tabIcon(for: .characters))
        }
        .tag(Tab.characters)
    }
    
    /// Settings tab content
    private var settingsTab: some View {
        GlobalSettingsView()
            .tabItem {
                Label(Tab.settings.title, systemImage: tabIcon(for: .settings))
            }
            .tag(Tab.settings)
    }
    
    // MARK: - Helpers
    
    /// Gets the themed icon for a tab
    private func tabIcon(for tab: Tab) -> String {
        themeManager.resolved.icon(for: tab.iconKey, fallback: tab.iconKey)
    }
    
    /// Handles tab change events
    private func handleTabChange(to newTab: Tab) {
        Logger.debug("Tab changed to: \(newTab.title)", category: .navigation)
        // Character themes are now resolved locally per-view, no global state to clear
    }
    
    // MARK: - Actions
    
    /// Opens the Perchance generator in Safari with the given prompt
    /// - Parameter prompt: The prompt text to copy to clipboard
    private func openGenerator(_ prompt: String) {
        let slug = presetStore.defaultPerchanceGenerator.isEmpty
            ? "ai-artgen"
            : presetStore.defaultPerchanceGenerator
        
        let urlString = "https://perchance.org/\(slug)"
        
        guard let url = URL(string: urlString) else {
            Logger.error("Invalid generator URL: \(urlString)", category: .navigation)
            return
        }
        
        // Copy prompt to clipboard for easy pasting
        UIPasteboard.general.string = prompt
        Logger.info("Opening generator '\(slug)' with prompt copied to clipboard", category: .navigation)
        
        // Open in Safari app
        UIApplication.shared.open(url, options: [:]) { success in
            if success {
                Logger.debug("Successfully opened Safari", category: .navigation)
            } else {
                Logger.warning("Failed to open Safari", category: .navigation)
            }
        }
    }
}
