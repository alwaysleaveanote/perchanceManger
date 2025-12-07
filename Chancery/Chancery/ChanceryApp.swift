//
//  ChanceryApp.swift
//  Chancery
//
//  The main entry point for the Chancery app.
//  This app helps users create and manage prompts for AI image generation
//  using Perchance generators.
//
//  Created by Alex Gingras on 12/5/25.
//

import SwiftUI

// MARK: - App Entry Point

/// The main application entry point.
///
/// `ChanceryApp` is responsible for:
/// - Initializing the app's global state (ThemeManager)
/// - Setting up the root view hierarchy
/// - Injecting environment objects into the view tree
///
/// ## Architecture Overview
/// The app uses a combination of:
/// - **Environment Objects**: For shared state (ThemeManager, PromptPresetStore)
/// - **Binding**: For parent-child data flow
/// - **MVVM-lite**: Views observe published properties from stores
///
/// ## Key Components
/// - `ThemeManager`: Manages app-wide theming and per-character theme overrides
/// - `PromptPresetStore`: Manages presets, defaults, and generator settings
/// - `ContentView`: The root tab-based navigation container
@main
struct ChanceryApp: App {
    
    // MARK: - State
    
    /// The app-wide theme manager, injected as an environment object
    @StateObject private var themeManager = ThemeManager()
    
    // MARK: - Initialization
    
    init() {
        Logger.info("App launching", category: .app)
        configureAppearance()
    }
    
    // MARK: - Body
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(themeManager)
                .onAppear {
                    Logger.info("Root view appeared", category: .app)
                }
        }
    }
    
    // MARK: - Configuration
    
    /// Configures global UIKit appearance settings
    private func configureAppearance() {
        Logger.debug("Configuring global appearance", category: .app)
        
        // Configure any global UIKit appearance settings here
        // Note: Most theming is handled by SwiftUI modifiers in ThemedComponents
    }
}
