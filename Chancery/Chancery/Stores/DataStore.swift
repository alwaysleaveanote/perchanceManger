//
//  DataStore.swift
//  Chancery
//
//  Central data store managing local persistence and CloudKit synchronization.
//  Handles characters, presets, and global settings.
//

import Foundation
import Combine

// MARK: - DataStore

/// Central store for all persistent user data with CloudKit sync.
///
/// `DataStore` manages:
/// - **Characters**: All character profiles with their prompts and images
/// - **Presets**: Reusable prompt snippets
/// - **Global Settings**: Default values and generator preferences
///
/// ## Persistence Strategy
/// - Local: JSON files in the app's documents directory
/// - Cloud: CloudKit private database for cross-device sync
///
/// ## Usage
/// ```swift
/// @StateObject var dataStore = DataStore.shared
///
/// // Access characters
/// ForEach(dataStore.characters) { character in ... }
///
/// // Save changes
/// dataStore.saveCharacter(character)
/// ```
@MainActor
final class DataStore: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = DataStore()
    
    // MARK: - Published Properties
    
    /// All character profiles
    @Published var characters: [CharacterProfile] = []
    
    /// All prompt presets
    @Published var presets: [PromptPreset] = []
    
    /// Global default values for prompt sections
    @Published var globalDefaults: [GlobalDefaultKey: String] = [:]
    
    /// Default Perchance generator
    @Published var defaultPerchanceGenerator: String = "ai-vibrant-image-generator"
    
    /// Current sync status
    @Published private(set) var syncStatus: CloudKitSyncStatus = .idle
    
    /// Whether initial data has been loaded
    @Published private(set) var isLoaded: Bool = false
    
    /// Last sync date
    @Published private(set) var lastSyncDate: Date?
    
    // MARK: - Private Properties
    
    private let cloudKit = CloudKitManager.shared
    private var cancellables = Set<AnyCancellable>()
    private var saveDebouncer: Task<Void, Never>?
    
    // File URLs for local persistence
    private var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private var charactersFileURL: URL {
        documentsDirectory.appendingPathComponent("characters.json")
    }
    
    private var presetsFileURL: URL {
        documentsDirectory.appendingPathComponent("presets.json")
    }
    
    private var settingsFileURL: URL {
        documentsDirectory.appendingPathComponent("settings.json")
    }
    
    // MARK: - Initialization
    
    private init() {
        Logger.info("DataStore initializing", category: .data)
        
        // Observe CloudKit sync status
        cloudKit.$syncStatus
            .receive(on: DispatchQueue.main)
            .assign(to: &$syncStatus)
        
        // Load local data first, then sync with cloud
        Task {
            await loadLocalData()
            await syncWithCloud()
        }
    }
    
    // MARK: - Local Persistence
    
    /// Loads all data from local storage
    private func loadLocalData() async {
        Logger.debug("Loading local data", category: .data)
        
        let decoder = JSONDecoder()
        
        // Load characters
        if let data = try? Data(contentsOf: charactersFileURL),
           let loaded = try? decoder.decode([CharacterProfile].self, from: data) {
            characters = loaded
            Logger.info("Loaded \(loaded.count) characters from local storage", category: .data)
        }
        
        // Load presets
        if let data = try? Data(contentsOf: presetsFileURL),
           let loaded = try? decoder.decode([PromptPreset].self, from: data) {
            presets = loaded
            Logger.info("Loaded \(loaded.count) presets from local storage", category: .data)
        } else {
            // Use sample presets if none saved
            presets = PromptPresetStore.samplePresets
            Logger.debug("Using sample presets", category: .data)
        }
        
        // Load settings
        if let data = try? Data(contentsOf: settingsFileURL),
           let loaded = try? decoder.decode(SettingsData.self, from: data) {
            globalDefaults = loaded.globalDefaults
            defaultPerchanceGenerator = loaded.defaultGenerator
            Logger.debug("Loaded settings from local storage", category: .data)
        } else {
            // Use sample defaults if none saved
            globalDefaults = PromptPresetStore.sampleDefaults
            Logger.debug("Using sample defaults", category: .data)
        }
        
        isLoaded = true
    }
    
    /// Saves all data to local storage
    private func saveLocalData() {
        Logger.debug("Saving local data", category: .data)
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        // Save characters
        if let data = try? encoder.encode(characters) {
            try? data.write(to: charactersFileURL)
        }
        
        // Save presets
        if let data = try? encoder.encode(presets) {
            try? data.write(to: presetsFileURL)
        }
        
        // Save settings
        let settings = SettingsData(
            globalDefaults: globalDefaults,
            defaultGenerator: defaultPerchanceGenerator
        )
        if let data = try? encoder.encode(settings) {
            try? data.write(to: settingsFileURL)
        }
    }
    
    /// Debounced save to avoid excessive writes
    private func scheduleSave() {
        saveDebouncer?.cancel()
        saveDebouncer = Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            guard !Task.isCancelled else { return }
            saveLocalData()
        }
    }
    
    // MARK: - CloudKit Sync
    
    /// Syncs data with CloudKit
    func syncWithCloud() async {
        guard cloudKit.isAvailable else {
            Logger.debug("CloudKit not available, skipping sync", category: .data)
            return
        }
        
        Logger.info("Starting CloudKit sync", category: .data)
        
        do {
            // Fetch from cloud
            let (cloudCharacters, cloudPresets, _) = try await cloudKit.fetchChanges()
            
            // Merge cloud data with local (cloud wins for now - simple strategy)
            if !cloudCharacters.isEmpty {
                mergeCharacters(cloudCharacters)
            }
            
            if !cloudPresets.isEmpty {
                mergePresets(cloudPresets)
            }
            
            // Fetch global settings
            if let settings = try await cloudKit.fetchGlobalSettings() {
                globalDefaults = settings.defaults
                defaultPerchanceGenerator = settings.generator
            }
            
            // Save merged data locally
            saveLocalData()
            
            lastSyncDate = Date()
            Logger.info("CloudKit sync completed", category: .data)
            
        } catch {
            Logger.error("CloudKit sync failed: \(error)", category: .data)
        }
    }
    
    /// Merges cloud characters with local, preferring cloud versions
    private func mergeCharacters(_ cloudCharacters: [CharacterProfile]) {
        var merged = characters
        
        for cloudChar in cloudCharacters {
            if let index = merged.firstIndex(where: { $0.id == cloudChar.id }) {
                // Update existing
                merged[index] = cloudChar
            } else {
                // Add new
                merged.append(cloudChar)
            }
        }
        
        characters = merged
    }
    
    /// Merges cloud presets with local, preferring cloud versions
    private func mergePresets(_ cloudPresets: [PromptPreset]) {
        var merged = presets
        
        for cloudPreset in cloudPresets {
            if let index = merged.firstIndex(where: { $0.id == cloudPreset.id }) {
                // Update existing
                merged[index] = cloudPreset
            } else {
                // Add new
                merged.append(cloudPreset)
            }
        }
        
        presets = merged
    }
    
    // MARK: - Character Operations
    
    /// Adds a new character
    func addCharacter(_ character: CharacterProfile) {
        characters.insert(character, at: 0)
        scheduleSave()
        
        Task {
            try? await cloudKit.saveCharacter(character)
        }
        
        Logger.info("Added character: \(character.name)", category: .data)
    }
    
    /// Updates an existing character
    func updateCharacter(_ character: CharacterProfile) {
        guard let index = characters.firstIndex(where: { $0.id == character.id }) else {
            Logger.warning("Character not found for update: \(character.id)", category: .data)
            return
        }
        
        characters[index] = character
        scheduleSave()
        
        Task {
            try? await cloudKit.saveCharacter(character)
        }
        
        Logger.debug("Updated character: \(character.name)", category: .data)
    }
    
    /// Deletes a character
    func deleteCharacter(_ character: CharacterProfile) {
        characters.removeAll { $0.id == character.id }
        scheduleSave()
        
        Task {
            try? await cloudKit.deleteCharacter(character)
        }
        
        Logger.info("Deleted character: \(character.name)", category: .data)
    }
    
    /// Gets a binding-compatible index for a character
    func characterIndex(for id: UUID) -> Int? {
        characters.firstIndex { $0.id == id }
    }
    
    // MARK: - Preset Operations
    
    /// Adds or updates a preset
    func savePreset(_ preset: PromptPreset) {
        if let index = presets.firstIndex(where: { $0.id == preset.id }) {
            presets[index] = preset
        } else {
            presets.append(preset)
        }
        scheduleSave()
        
        Task {
            try? await cloudKit.savePreset(preset)
        }
        
        Logger.debug("Saved preset: \(preset.name)", category: .data)
    }
    
    /// Adds a new preset by values
    func addPreset(kind: PromptSectionKind, name: String, text: String) {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedText.isEmpty, !trimmedName.isEmpty else { return }
        
        // Check for existing preset with same name and kind
        if let existingIndex = presets.firstIndex(where: {
            $0.kind == kind && $0.name.caseInsensitiveCompare(trimmedName) == .orderedSame
        }) {
            presets[existingIndex].text = trimmedText
            scheduleSave()
            
            Task {
                try? await cloudKit.savePreset(presets[existingIndex])
            }
        } else {
            let preset = PromptPreset(kind: kind, name: trimmedName, text: trimmedText)
            presets.append(preset)
            scheduleSave()
            
            Task {
                try? await cloudKit.savePreset(preset)
            }
        }
    }
    
    /// Deletes a preset
    func deletePreset(_ preset: PromptPreset) {
        presets.removeAll { $0.id == preset.id }
        scheduleSave()
        
        Task {
            try? await cloudKit.deletePreset(preset)
        }
        
        Logger.debug("Deleted preset: \(preset.name)", category: .data)
    }
    
    /// Gets presets for a specific section kind
    func presets(of kind: PromptSectionKind) -> [PromptPreset] {
        presets.filter { $0.kind == kind }
    }
    
    // MARK: - Settings Operations
    
    /// Updates a global default value
    func setGlobalDefault(_ value: String?, for key: GlobalDefaultKey) {
        if let value = value?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty {
            globalDefaults[key] = value
        } else {
            globalDefaults.removeValue(forKey: key)
        }
        scheduleSave()
        
        Task {
            try? await cloudKit.saveGlobalSettings(
                defaults: globalDefaults,
                generator: defaultPerchanceGenerator
            )
        }
    }
    
    /// Updates the default generator
    func setDefaultGenerator(_ generator: String) {
        let trimmed = generator.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != defaultPerchanceGenerator else { return }
        
        defaultPerchanceGenerator = trimmed
        scheduleSave()
        
        Task {
            try? await cloudKit.saveGlobalSettings(
                defaults: globalDefaults,
                generator: defaultPerchanceGenerator
            )
        }
        
        Logger.info("Generator changed to: \(trimmed)", category: .data)
    }
    
    // MARK: - Force Sync
    
    /// Forces a full sync with CloudKit
    func forceSync() async {
        guard cloudKit.isAvailable else { return }
        
        Logger.info("Force syncing all data to CloudKit", category: .data)
        
        do {
            // Upload all local data
            try await cloudKit.saveCharacters(characters)
            try await cloudKit.savePresets(presets)
            try await cloudKit.saveGlobalSettings(
                defaults: globalDefaults,
                generator: defaultPerchanceGenerator
            )
            
            lastSyncDate = Date()
            Logger.info("Force sync completed", category: .data)
            
        } catch {
            Logger.error("Force sync failed: \(error)", category: .data)
        }
    }
}

// MARK: - Settings Data

/// Container for serializing settings
private struct SettingsData: Codable {
    let globalDefaults: [GlobalDefaultKey: String]
    let defaultGenerator: String
}

