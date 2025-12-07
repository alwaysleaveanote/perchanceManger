//
//  CloudKitManager.swift
//  Chancery
//
//  Manages CloudKit sync operations for user data including characters,
//  prompts, images, presets, and settings.
//

import Foundation
import CloudKit
import Combine

// MARK: - CloudKit Record Types

/// Record type identifiers for CloudKit
enum CloudKitRecordType: String {
    case character = "Character"
    case savedPrompt = "SavedPrompt"
    case promptImage = "PromptImage"
    case promptPreset = "PromptPreset"
    case relatedLink = "RelatedLink"
    case globalSettings = "GlobalSettings"
}

// MARK: - CloudKit Error

/// Errors that can occur during CloudKit operations
enum CloudKitError: LocalizedError {
    case notAuthenticated
    case networkUnavailable
    case quotaExceeded
    case recordNotFound
    case conflictDetected(serverRecord: CKRecord)
    case assetTooLarge
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Not signed into iCloud"
        case .networkUnavailable:
            return "Network unavailable"
        case .quotaExceeded:
            return "iCloud storage quota exceeded"
        case .recordNotFound:
            return "Record not found in iCloud"
        case .conflictDetected:
            return "Conflict detected with server record"
        case .assetTooLarge:
            return "Image file too large for iCloud"
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}

// MARK: - CloudKit Sync Status

/// Represents the current sync status
enum CloudKitSyncStatus: Equatable {
    case idle
    case syncing
    case error(String)
    case disabled
}

// MARK: - CloudKitManager

/// Manages all CloudKit operations for syncing user data.
///
/// `CloudKitManager` handles:
/// - Saving and fetching records from the private CloudKit database
/// - Subscribing to remote changes
/// - Handling sync conflicts
/// - Managing image assets
///
/// ## Usage
/// ```swift
/// let manager = CloudKitManager.shared
/// try await manager.saveCharacter(character)
/// let characters = try await manager.fetchAllCharacters()
/// ```
@MainActor
final class CloudKitManager: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = CloudKitManager()
    
    // MARK: - Properties
    
    /// The CloudKit container for this app (nil when CloudKit is disabled)
    private var container: CKContainer?
    
    /// The private database for user data
    private var privateDatabase: CKDatabase? {
        container?.privateCloudDatabase
    }
    
    /// Current sync status
    @Published private(set) var syncStatus: CloudKitSyncStatus = .idle
    
    /// Whether CloudKit is available
    @Published private(set) var isAvailable: Bool = false
    
    /// Zone ID for custom zone
    private var zoneID: CKRecordZone.ID?
    
    /// Subscription ID for change notifications
    private let subscriptionID = "chancery-changes"
    
    // MARK: - Initialization
    
    private init() {
        // Check feature flag FIRST before touching any CloudKit APIs
        guard FeatureFlags.isCloudKitEnabled else {
            Logger.info("CloudKitManager initialized (CloudKit DISABLED by feature flag)", category: .data)
            self.container = nil
            self.zoneID = nil
            isAvailable = false
            syncStatus = .disabled
            return
        }
        
        // Only initialize CloudKit when enabled
        self.container = CKContainer.default()
        self.zoneID = CKRecordZone.ID(zoneName: "ChanceryZone", ownerName: CKCurrentUserDefaultName)
        
        Logger.info("CloudKitManager initialized", category: .data)
        
        Task {
            await checkAccountStatus()
            await setupZoneAndSubscription()
        }
    }
    
    // MARK: - Account Status
    
    /// Checks if the user is signed into iCloud
    func checkAccountStatus() async {
        // Check feature flag first
        guard FeatureFlags.isCloudKitEnabled, let container = container else {
            isAvailable = false
            syncStatus = .disabled
            return
        }
        do {
            let status = try await container.accountStatus()
            
            switch status {
            case .available:
                isAvailable = true
                syncStatus = .idle
                Logger.info("iCloud account available", category: .data)
                
            case .noAccount:
                isAvailable = false
                syncStatus = .disabled
                Logger.warning("No iCloud account", category: .data)
                
            case .restricted:
                isAvailable = false
                syncStatus = .disabled
                Logger.warning("iCloud account restricted", category: .data)
                
            case .couldNotDetermine:
                isAvailable = false
                syncStatus = .error("Could not determine iCloud status")
                Logger.error("Could not determine iCloud status", category: .data)
                
            case .temporarilyUnavailable:
                isAvailable = false
                syncStatus = .error("iCloud temporarily unavailable")
                Logger.warning("iCloud temporarily unavailable", category: .data)
                
            @unknown default:
                isAvailable = false
                syncStatus = .error("Unknown iCloud status")
                Logger.error("Unknown iCloud account status", category: .data)
            }
        } catch {
            isAvailable = false
            syncStatus = .error(error.localizedDescription)
            Logger.error("Failed to check iCloud status: \(error)", category: .data)
        }
    }
    
    // MARK: - Zone & Subscription Setup
    
    /// Creates the custom zone and subscription for change notifications
    private func setupZoneAndSubscription() async {
        guard isAvailable, let zoneID = zoneID, let privateDatabase = privateDatabase else { return }
        
        do {
            // Create custom zone
            let zone = CKRecordZone(zoneID: zoneID)
            _ = try await privateDatabase.modifyRecordZones(saving: [zone], deleting: [])
            Logger.debug("Custom zone created/verified", category: .data)
            
            // Create subscription for changes
            let subscription = CKDatabaseSubscription(subscriptionID: subscriptionID)
            let notificationInfo = CKSubscription.NotificationInfo()
            notificationInfo.shouldSendContentAvailable = true
            subscription.notificationInfo = notificationInfo
            
            _ = try await privateDatabase.modifySubscriptions(saving: [subscription], deleting: [])
            Logger.debug("Subscription created/verified", category: .data)
            
        } catch {
            // Zone/subscription might already exist, which is fine
            Logger.debug("Zone/subscription setup: \(error.localizedDescription)", category: .data)
        }
    }
    
    // MARK: - Record ID Helpers
    
    /// Creates a CKRecord.ID for a given UUID and record type
    private func recordID(for uuid: UUID, type: CloudKitRecordType) -> CKRecord.ID? {
        guard let zoneID = zoneID else { return nil }
        return CKRecord.ID(recordName: "\(type.rawValue)_\(uuid.uuidString)", zoneID: zoneID)
    }
    
    // MARK: - Character Operations
    
    /// Saves a character to CloudKit
    func saveCharacter(_ character: CharacterProfile) async throws {
        guard isAvailable, let zoneID = zoneID, let privateDatabase = privateDatabase else {
            throw CloudKitError.notAuthenticated
        }
        
        syncStatus = .syncing
        defer { syncStatus = .idle }
        
        let record = character.toCKRecord(zoneID: zoneID)
        
        do {
            _ = try await privateDatabase.save(record)
            Logger.info("Saved character: \(character.name)", category: .data)
        } catch let error as CKError {
            throw mapCKError(error)
        }
    }
    
    /// Fetches all characters from CloudKit
    func fetchAllCharacters() async throws -> [CharacterProfile] {
        guard isAvailable, let zoneID = zoneID, let privateDatabase = privateDatabase else {
            throw CloudKitError.notAuthenticated
        }
        
        syncStatus = .syncing
        defer { syncStatus = .idle }
        
        let query = CKQuery(recordType: CloudKitRecordType.character.rawValue, predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        do {
            let (results, _) = try await privateDatabase.records(matching: query, inZoneWith: zoneID)
            
            var characters: [CharacterProfile] = []
            for (_, result) in results {
                switch result {
                case .success(let record):
                    if let character = CharacterProfile(from: record) {
                        characters.append(character)
                    }
                case .failure(let error):
                    Logger.warning("Failed to fetch character record: \(error)", category: .data)
                }
            }
            
            Logger.info("Fetched \(characters.count) characters", category: .data)
            return characters
            
        } catch let error as CKError {
            throw mapCKError(error)
        }
    }
    
    /// Deletes a character from CloudKit
    func deleteCharacter(_ character: CharacterProfile) async throws {
        guard isAvailable, let privateDatabase = privateDatabase, let recordID = recordID(for: character.id, type: .character) else {
            throw CloudKitError.notAuthenticated
        }
        
        syncStatus = .syncing
        defer { syncStatus = .idle }
        
        do {
            try await privateDatabase.deleteRecord(withID: recordID)
            Logger.info("Deleted character: \(character.name)", category: .data)
        } catch let error as CKError {
            throw mapCKError(error)
        }
    }
    
    // MARK: - Preset Operations
    
    /// Saves a preset to CloudKit
    func savePreset(_ preset: PromptPreset) async throws {
        guard isAvailable, let zoneID = zoneID, let privateDatabase = privateDatabase else {
            throw CloudKitError.notAuthenticated
        }
        
        let record = preset.toCKRecord(zoneID: zoneID)
        
        do {
            _ = try await privateDatabase.save(record)
            Logger.debug("Saved preset: \(preset.name)", category: .data)
        } catch let error as CKError {
            throw mapCKError(error)
        }
    }
    
    /// Fetches all presets from CloudKit
    func fetchAllPresets() async throws -> [PromptPreset] {
        guard isAvailable, let zoneID = zoneID, let privateDatabase = privateDatabase else {
            throw CloudKitError.notAuthenticated
        }
        
        let query = CKQuery(recordType: CloudKitRecordType.promptPreset.rawValue, predicate: NSPredicate(value: true))
        
        do {
            let (results, _) = try await privateDatabase.records(matching: query, inZoneWith: zoneID)
            
            var presets: [PromptPreset] = []
            for (_, result) in results {
                switch result {
                case .success(let record):
                    if let preset = PromptPreset(from: record) {
                        presets.append(preset)
                    }
                case .failure(let error):
                    Logger.warning("Failed to fetch preset record: \(error)", category: .data)
                }
            }
            
            Logger.info("Fetched \(presets.count) presets", category: .data)
            return presets
            
        } catch let error as CKError {
            throw mapCKError(error)
        }
    }
    
    /// Deletes a preset from CloudKit
    func deletePreset(_ preset: PromptPreset) async throws {
        guard isAvailable, let privateDatabase = privateDatabase, let recordID = recordID(for: preset.id, type: .promptPreset) else {
            throw CloudKitError.notAuthenticated
        }
        
        do {
            try await privateDatabase.deleteRecord(withID: recordID)
            Logger.debug("Deleted preset: \(preset.name)", category: .data)
        } catch let error as CKError {
            throw mapCKError(error)
        }
    }
    
    // MARK: - Global Settings Operations
    
    /// Saves global settings to CloudKit
    func saveGlobalSettings(defaults: [GlobalDefaultKey: String], generator: String) async throws {
        guard isAvailable, let zoneID = zoneID, let privateDatabase = privateDatabase else {
            throw CloudKitError.notAuthenticated
        }
        
        let recordID = CKRecord.ID(recordName: "GlobalSettings_singleton", zoneID: zoneID)
        let record = CKRecord(recordType: CloudKitRecordType.globalSettings.rawValue, recordID: recordID)
        
        // Encode defaults as JSON
        let encoder = JSONEncoder()
        if let defaultsData = try? encoder.encode(defaults) {
            record["defaults"] = String(data: defaultsData, encoding: .utf8)
        }
        record["defaultGenerator"] = generator
        
        do {
            _ = try await privateDatabase.save(record)
            Logger.debug("Saved global settings", category: .data)
        } catch let error as CKError {
            throw mapCKError(error)
        }
    }
    
    /// Fetches global settings from CloudKit
    func fetchGlobalSettings() async throws -> (defaults: [GlobalDefaultKey: String], generator: String)? {
        guard isAvailable, let zoneID = zoneID, let privateDatabase = privateDatabase else {
            throw CloudKitError.notAuthenticated
        }
        
        let recordID = CKRecord.ID(recordName: "GlobalSettings_singleton", zoneID: zoneID)
        
        do {
            let record = try await privateDatabase.record(for: recordID)
            
            var defaults: [GlobalDefaultKey: String] = [:]
            if let defaultsString = record["defaults"] as? String,
               let defaultsData = defaultsString.data(using: .utf8) {
                let decoder = JSONDecoder()
                defaults = (try? decoder.decode([GlobalDefaultKey: String].self, from: defaultsData)) ?? [:]
            }
            
            let generator = record["defaultGenerator"] as? String ?? "ai-vibrant-image-generator"
            
            Logger.debug("Fetched global settings", category: .data)
            return (defaults, generator)
            
        } catch let error as CKError where error.code == .unknownItem {
            // No settings saved yet
            return nil
        } catch let error as CKError {
            throw mapCKError(error)
        }
    }
    
    // MARK: - Batch Operations
    
    /// Saves multiple characters in a batch
    func saveCharacters(_ characters: [CharacterProfile]) async throws {
        guard isAvailable, let zoneID = zoneID, let privateDatabase = privateDatabase else {
            throw CloudKitError.notAuthenticated
        }
        
        syncStatus = .syncing
        defer { syncStatus = .idle }
        
        let records = characters.map { $0.toCKRecord(zoneID: zoneID) }
        
        do {
            let (saveResults, _) = try await privateDatabase.modifyRecords(saving: records, deleting: [])
            
            var successCount = 0
            for (_, result) in saveResults {
                if case .success = result {
                    successCount += 1
                }
            }
            
            Logger.info("Batch saved \(successCount)/\(characters.count) characters", category: .data)
        } catch let error as CKError {
            throw mapCKError(error)
        }
    }
    
    /// Saves multiple presets in a batch
    func savePresets(_ presets: [PromptPreset]) async throws {
        guard isAvailable, let zoneID = zoneID, let privateDatabase = privateDatabase else {
            throw CloudKitError.notAuthenticated
        }
        
        let records = presets.map { $0.toCKRecord(zoneID: zoneID) }
        
        do {
            let (saveResults, _) = try await privateDatabase.modifyRecords(saving: records, deleting: [])
            
            var successCount = 0
            for (_, result) in saveResults {
                if case .success = result {
                    successCount += 1
                }
            }
            
            Logger.info("Batch saved \(successCount)/\(presets.count) presets", category: .data)
        } catch let error as CKError {
            throw mapCKError(error)
        }
    }
    
    // MARK: - Change Fetching
    
    /// Fetches changes since the last sync
    func fetchChanges() async throws -> (
        characters: [CharacterProfile],
        presets: [PromptPreset],
        deletedRecordIDs: [CKRecord.ID]
    ) {
        guard isAvailable else {
            throw CloudKitError.notAuthenticated
        }
        
        syncStatus = .syncing
        defer { syncStatus = .idle }
        
        // For now, just fetch all records
        // In a production app, you'd use CKFetchRecordZoneChangesOperation
        // with a stored change token for incremental sync
        
        let characters = try await fetchAllCharacters()
        let presets = try await fetchAllPresets()
        
        return (characters, presets, [])
    }
    
    // MARK: - Error Mapping
    
    /// Maps CKError to CloudKitError
    private func mapCKError(_ error: CKError) -> CloudKitError {
        switch error.code {
        case .notAuthenticated:
            return .notAuthenticated
        case .networkUnavailable, .networkFailure:
            return .networkUnavailable
        case .quotaExceeded:
            return .quotaExceeded
        case .unknownItem:
            return .recordNotFound
        case .serverRecordChanged:
            if let serverRecord = error.userInfo[CKRecordChangedErrorServerRecordKey] as? CKRecord {
                return .conflictDetected(serverRecord: serverRecord)
            }
            return .unknown(error)
        case .assetFileModified, .assetNotAvailable:
            return .assetTooLarge
        default:
            return .unknown(error)
        }
    }
}

