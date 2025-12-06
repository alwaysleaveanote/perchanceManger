//
//  PromptPresetStore.swift
//  PerchanceImageGenerator
//
//  Manages the storage and retrieval of prompt presets, global defaults,
//  and generator settings. Acts as the central data store for user preferences.
//

import Foundation
import SwiftUI
import Combine

// MARK: - PromptPresetStore

/// Central store for managing prompt presets, global defaults, and generator settings.
///
/// `PromptPresetStore` is an `ObservableObject` that provides:
/// - **Presets**: Reusable text snippets organized by prompt section
/// - **Global Defaults**: Default values applied to new prompts
/// - **Generator Settings**: The default Perchance generator to use
///
/// ## Data Persistence
/// Currently uses `UserDefaults` for the generator setting. Presets and defaults
/// are loaded from sample data on initialization (future: persist to disk).
///
/// ## Usage
/// ```swift
/// @StateObject var presetStore = PromptPresetStore()
///
/// // Get presets for a section
/// let outfitPresets = presetStore.presets(of: .outfit)
///
/// // Add a new preset
/// presetStore.addPreset(kind: .pose, name: "Action Pose", text: "dynamic action pose")
/// ```
final class PromptPresetStore: ObservableObject {
    
    // MARK: - Constants
    
    private enum StorageKeys {
        static let defaultGenerator = "defaultPerchanceGenerator"
    }
    
    private enum Defaults {
        static let generator = "ai-vibrant-image-generator"
    }
    
    // MARK: - Published Properties
    
    /// All available presets across all section types
    @Published var presets: [PromptPreset] = []
    
    /// Global default values for each prompt section
    @Published var globalDefaults: [GlobalDefaultKey: String] = [:]
    
    /// The default Perchance generator slug to use
    ///
    /// Persisted to UserDefaults automatically on change.
    @Published var defaultPerchanceGenerator: String {
        didSet {
            guard defaultPerchanceGenerator != oldValue else { return }
            Logger.info("Generator changed: '\(oldValue)' → '\(defaultPerchanceGenerator)'", category: .preset)
            UserDefaults.standard.set(defaultPerchanceGenerator, forKey: StorageKeys.defaultGenerator)
        }
    }
    
    // MARK: - Initialization
    
    /// Creates a new preset store, loading saved settings and sample data
    init() {
        // Load persisted generator setting
        self.defaultPerchanceGenerator = UserDefaults.standard.string(forKey: StorageKeys.defaultGenerator)
            ?? Defaults.generator
        
        Logger.info("Initialized with generator: '\(defaultPerchanceGenerator)'", category: .preset)
        
        // Load initial data
        loadSampleData()
    }
    
    // MARK: - Preset Access
    
    /// Returns all presets for a specific section type
    /// - Parameter kind: The section type to filter by
    /// - Returns: Array of presets matching the section type
    func presets(of kind: PromptSectionKind) -> [PromptPreset] {
        presets.filter { $0.kind == kind }
    }
    
    /// Finds a preset by its ID
    /// - Parameter id: The preset's unique identifier
    /// - Returns: The preset if found, nil otherwise
    func preset(withId id: UUID) -> PromptPreset? {
        presets.first { $0.id == id }
    }
    
    // MARK: - Preset Management
    
    /// Adds or updates a preset
    ///
    /// If a preset with the same name and kind exists (case-insensitive),
    /// its text is updated. Otherwise, a new preset is created.
    ///
    /// - Parameters:
    ///   - kind: The section type for the preset
    ///   - name: The display name for the preset
    ///   - text: The preset content
    func addPreset(kind: PromptSectionKind, name: String, text: String) {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedText.isEmpty, !trimmedName.isEmpty else {
            Logger.warning("Attempted to add preset with empty name or text", category: .preset)
            return
        }
        
        // Check for existing preset with same name and kind
        if let existingIndex = presets.firstIndex(where: {
            $0.kind == kind && $0.name.caseInsensitiveCompare(trimmedName) == .orderedSame
        }) {
            Logger.debug("Updating existing preset: '\(trimmedName)' (\(kind.displayLabel))", category: .preset)
            presets[existingIndex].text = trimmedText
        } else {
            Logger.debug("Creating new preset: '\(trimmedName)' (\(kind.displayLabel))", category: .preset)
            presets.append(PromptPreset(kind: kind, name: trimmedName, text: trimmedText))
        }
    }
    
    /// Removes a preset by its ID
    /// - Parameter id: The preset's unique identifier
    /// - Returns: True if a preset was removed, false if not found
    @discardableResult
    func removePreset(withId id: UUID) -> Bool {
        guard let index = presets.firstIndex(where: { $0.id == id }) else {
            Logger.warning("Attempted to remove non-existent preset: \(id)", category: .preset)
            return false
        }
        
        let removed = presets.remove(at: index)
        Logger.debug("Removed preset: '\(removed.name)'", category: .preset)
        return true
    }
    
    // MARK: - Global Defaults
    
    /// Gets the global default value for a section
    /// - Parameter key: The section key
    /// - Returns: The default value, or nil if not set
    func globalDefault(for key: GlobalDefaultKey) -> String? {
        globalDefaults[key]
    }
    
    /// Sets the global default value for a section
    /// - Parameters:
    ///   - value: The new default value (nil to clear)
    ///   - key: The section key
    func setGlobalDefault(_ value: String?, for key: GlobalDefaultKey) {
        if let value = value?.nonEmpty {
            globalDefaults[key] = value
            Logger.debug("Set global default for \(key.displayLabel)", category: .preset)
        } else {
            globalDefaults.removeValue(forKey: key)
            Logger.debug("Cleared global default for \(key.displayLabel)", category: .preset)
        }
    }
    
    // MARK: - Sample Data
    
    /// Loads sample presets and defaults for initial app state
    private func loadSampleData() {
        Logger.debug("Loading sample preset data", category: .preset)
        
        presets = Self.samplePresets
        globalDefaults = Self.sampleDefaults
        
        Logger.info("Loaded \(presets.count) presets and \(globalDefaults.count) defaults", category: .preset)
    }
}

// MARK: - Sample Data

extension PromptPresetStore {
    
    /// Sample presets for initial app state
    static let samplePresets: [PromptPreset] = [
        // Outfit presets
        PromptPreset(kind: .outfit, name: "Casual Outfit", text: "hoodie, jeans, sneakers, relaxed casual style"),
        PromptPreset(kind: .outfit, name: "Fantasy Armor", text: "ornate plate armor, engraved runes, flowing cape"),
        
        // Pose presets
        PromptPreset(kind: .pose, name: "Hero Pose", text: "standing tall, chest out, confident stance, looking at viewer"),
        PromptPreset(kind: .pose, name: "Relaxed Sitting", text: "sitting cross-legged, relaxed shoulders, soft expression"),
        
        // Environment presets
        PromptPreset(kind: .environment, name: "Cozy Room", text: "warm cozy bedroom, soft blankets, fairy lights, bookshelves"),
        PromptPreset(kind: .environment, name: "Sci-Fi Lab", text: "sleek futuristic lab, holographic screens, glowing consoles"),
        
        // Lighting presets
        PromptPreset(kind: .lighting, name: "Soft Studio Lighting", text: "soft even studio lighting, gentle shadows, flattering light"),
        PromptPreset(kind: .lighting, name: "Dramatic Rim Light", text: "strong rim light from behind, deep shadows, high contrast"),
        
        // Style presets
        PromptPreset(kind: .style, name: "Painterly", text: "digital painting, visible brush strokes, rich colors"),
        PromptPreset(kind: .style, name: "Anime Cel-Shaded", text: "anime style, crisp lineart, cel-shaded coloring"),
        
        // Technical presets
        PromptPreset(kind: .technical, name: "High Detail", text: "8k resolution, ultra-detailed, sharp focus"),
        PromptPreset(kind: .technical, name: "Soft Focus Portrait", text: "soft focus background, bokeh, subject in crisp focus"),
        
        // Negative presets
        PromptPreset(kind: .negative, name: "Clean Image", text: "no text, no watermark, no extra limbs, no distortions"),
        PromptPreset(kind: .negative, name: "Simple Background", text: "no cluttered background, no busy patterns")
    ]
    
    /// Sample global defaults for initial app state
    static let sampleDefaults: [GlobalDefaultKey: String] = [
        .outfit: "casual modern outfit, comfortable and practical",
        .pose: "natural relaxed pose",
        .environment: "simple neutral background",
        .lighting: "soft even lighting, no harsh shadows",
        .style: "high quality digital illustration",
        .technical: "high detail, clean lines, sharp focus",
        .negative: "no text, no watermark, no extra limbs, no distortions"
    ]
}
