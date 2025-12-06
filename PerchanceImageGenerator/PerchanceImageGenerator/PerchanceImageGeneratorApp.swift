//
//  PerchanceImageGeneratorApp.swift
//  PerchanceImageGenerator
//
//  Created by Alex Gingras on 12/5/25.
//

import SwiftUI

@main
struct PerchanceImageGeneratorApp: App {
    @StateObject private var themeManager = ThemeManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(themeManager)
        }
    }
}

// Note: ContentView is now located at Views/ContentView.swift
