//
//  CloudKitConvertible.swift
//  Chancery
//
//  Extensions for converting models to and from CloudKit records.
//

import Foundation
import CloudKit

// MARK: - CharacterProfile + CloudKit

extension CharacterProfile {
    
    /// Converts this character to a CKRecord
    func toCKRecord(zoneID: CKRecordZone.ID) -> CKRecord {
        let recordID = CKRecord.ID(
            recordName: "\(CloudKitRecordType.character.rawValue)_\(id.uuidString)",
            zoneID: zoneID
        )
        let record = CKRecord(recordType: CloudKitRecordType.character.rawValue, recordID: recordID)
        
        // Basic fields
        record["uuid"] = id.uuidString
        record["name"] = name
        record["bio"] = bio
        record["notes"] = notes
        
        // Customization
        record["characterDefaultPerchanceGenerator"] = characterDefaultPerchanceGenerator
        record["characterThemeId"] = characterThemeId
        
        // Encode character defaults as JSON
        let encoder = JSONEncoder()
        if let defaultsData = try? encoder.encode(characterDefaults),
           let defaultsString = String(data: defaultsData, encoding: .utf8) {
            record["characterDefaults"] = defaultsString
        }
        
        // Encode prompts as JSON
        if let promptsData = try? encoder.encode(prompts),
           let promptsString = String(data: promptsData, encoding: .utf8) {
            record["prompts"] = promptsString
        }
        
        // Encode links as JSON
        if let linksData = try? encoder.encode(links),
           let linksString = String(data: linksData, encoding: .utf8) {
            record["links"] = linksString
        }
        
        // Profile image as asset
        if let imageData = profileImageData {
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("jpg")
            
            do {
                try imageData.write(to: tempURL)
                record["profileImage"] = CKAsset(fileURL: tempURL)
            } catch {
                Logger.warning("Failed to write profile image for CloudKit: \(error)", category: .data)
            }
        }
        
        return record
    }
    
    /// Creates a CharacterProfile from a CKRecord
    init?(from record: CKRecord) {
        guard record.recordType == CloudKitRecordType.character.rawValue,
              let uuidString = record["uuid"] as? String,
              let uuid = UUID(uuidString: uuidString),
              let name = record["name"] as? String else {
            return nil
        }
        
        let decoder = JSONDecoder()
        
        // Decode character defaults
        var characterDefaults: [GlobalDefaultKey: String] = [:]
        if let defaultsString = record["characterDefaults"] as? String,
           let defaultsData = defaultsString.data(using: .utf8) {
            characterDefaults = (try? decoder.decode([GlobalDefaultKey: String].self, from: defaultsData)) ?? [:]
        }
        
        // Decode prompts
        var prompts: [SavedPrompt] = []
        if let promptsString = record["prompts"] as? String,
           let promptsData = promptsString.data(using: .utf8) {
            prompts = (try? decoder.decode([SavedPrompt].self, from: promptsData)) ?? []
        }
        
        // Decode links
        var links: [RelatedLink] = []
        if let linksString = record["links"] as? String,
           let linksData = linksString.data(using: .utf8) {
            links = (try? decoder.decode([RelatedLink].self, from: linksData)) ?? []
        }
        
        // Load profile image from asset
        var profileImageData: Data? = nil
        if let asset = record["profileImage"] as? CKAsset,
           let fileURL = asset.fileURL {
            profileImageData = try? Data(contentsOf: fileURL)
        }
        
        self.init(
            id: uuid,
            name: name,
            bio: record["bio"] as? String ?? "",
            notes: record["notes"] as? String ?? "",
            prompts: prompts,
            profileImageData: profileImageData,
            links: links,
            characterDefaults: characterDefaults,
            characterDefaultPerchanceGenerator: record["characterDefaultPerchanceGenerator"] as? String,
            characterThemeId: record["characterThemeId"] as? String
        )
    }
}

// MARK: - PromptPreset + CloudKit

extension PromptPreset {
    
    /// Converts this preset to a CKRecord
    func toCKRecord(zoneID: CKRecordZone.ID) -> CKRecord {
        let recordID = CKRecord.ID(
            recordName: "\(CloudKitRecordType.promptPreset.rawValue)_\(id.uuidString)",
            zoneID: zoneID
        )
        let record = CKRecord(recordType: CloudKitRecordType.promptPreset.rawValue, recordID: recordID)
        
        record["uuid"] = id.uuidString
        record["kind"] = kind.rawValue
        record["name"] = name
        record["text"] = text
        
        return record
    }
    
    /// Creates a PromptPreset from a CKRecord
    init?(from record: CKRecord) {
        guard record.recordType == CloudKitRecordType.promptPreset.rawValue,
              let uuidString = record["uuid"] as? String,
              let uuid = UUID(uuidString: uuidString),
              let kindString = record["kind"] as? String,
              let kind = PromptSectionKind(rawValue: kindString),
              let name = record["name"] as? String,
              let text = record["text"] as? String else {
            return nil
        }
        
        self.init(id: uuid, kind: kind, name: name, text: text)
    }
}

// MARK: - SavedPrompt + CloudKit

extension SavedPrompt {
    
    /// Converts this prompt to a CKRecord (for standalone storage if needed)
    func toCKRecord(zoneID: CKRecordZone.ID, characterID: UUID) -> CKRecord {
        let recordID = CKRecord.ID(
            recordName: "\(CloudKitRecordType.savedPrompt.rawValue)_\(id.uuidString)",
            zoneID: zoneID
        )
        let record = CKRecord(recordType: CloudKitRecordType.savedPrompt.rawValue, recordID: recordID)
        
        record["uuid"] = id.uuidString
        record["characterID"] = characterID.uuidString
        record["title"] = title
        record["text"] = text
        
        // Prompt sections
        record["physicalDescription"] = physicalDescription
        record["outfit"] = outfit
        record["pose"] = pose
        record["environment"] = environment
        record["lighting"] = lighting
        record["styleModifiers"] = styleModifiers
        record["technicalModifiers"] = technicalModifiers
        record["negativePrompt"] = negativePrompt
        record["additionalInfo"] = additionalInfo
        
        // Preset names
        record["physicalDescriptionPresetName"] = physicalDescriptionPresetName
        record["outfitPresetName"] = outfitPresetName
        record["posePresetName"] = posePresetName
        record["environmentPresetName"] = environmentPresetName
        record["lightingPresetName"] = lightingPresetName
        record["stylePresetName"] = stylePresetName
        record["technicalPresetName"] = technicalPresetName
        record["negativePresetName"] = negativePresetName
        
        // Encode images as JSON (image data stored separately as assets)
        let encoder = JSONEncoder()
        if let imagesData = try? encoder.encode(images),
           let imagesString = String(data: imagesData, encoding: .utf8) {
            record["images"] = imagesString
        }
        
        return record
    }
}

// MARK: - PromptImage + CloudKit

extension PromptImage {
    
    /// Converts this image to a CKRecord
    func toCKRecord(zoneID: CKRecordZone.ID, promptID: UUID) -> CKRecord {
        let recordID = CKRecord.ID(
            recordName: "\(CloudKitRecordType.promptImage.rawValue)_\(id.uuidString)",
            zoneID: zoneID
        )
        let record = CKRecord(recordType: CloudKitRecordType.promptImage.rawValue, recordID: recordID)
        
        record["uuid"] = id.uuidString
        record["promptID"] = promptID.uuidString
        
        // Store image data as asset
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("jpg")
        
        do {
            try data.write(to: tempURL)
            record["imageAsset"] = CKAsset(fileURL: tempURL)
        } catch {
            Logger.warning("Failed to write image for CloudKit: \(error)", category: .data)
        }
        
        return record
    }
    
    /// Creates a PromptImage from a CKRecord
    init?(from record: CKRecord) {
        guard record.recordType == CloudKitRecordType.promptImage.rawValue,
              let uuidString = record["uuid"] as? String,
              let uuid = UUID(uuidString: uuidString),
              let asset = record["imageAsset"] as? CKAsset,
              let fileURL = asset.fileURL,
              let data = try? Data(contentsOf: fileURL) else {
            return nil
        }
        
        self.init(id: uuid, data: data)
    }
}

// MARK: - RelatedLink + CloudKit

extension RelatedLink {
    
    /// Converts this link to a CKRecord
    func toCKRecord(zoneID: CKRecordZone.ID, characterID: UUID) -> CKRecord {
        let recordID = CKRecord.ID(
            recordName: "\(CloudKitRecordType.relatedLink.rawValue)_\(id.uuidString)",
            zoneID: zoneID
        )
        let record = CKRecord(recordType: CloudKitRecordType.relatedLink.rawValue, recordID: recordID)
        
        record["uuid"] = id.uuidString
        record["characterID"] = characterID.uuidString
        record["title"] = title
        record["urlString"] = urlString
        
        return record
    }
    
    /// Creates a RelatedLink from a CKRecord
    init?(from record: CKRecord) {
        guard record.recordType == CloudKitRecordType.relatedLink.rawValue,
              let uuidString = record["uuid"] as? String,
              let uuid = UUID(uuidString: uuidString),
              let title = record["title"] as? String,
              let urlString = record["urlString"] as? String else {
            return nil
        }
        
        self.init(id: uuid, title: title, urlString: urlString)
    }
}
