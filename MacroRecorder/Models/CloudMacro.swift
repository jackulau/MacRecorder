//
//  CloudMacro.swift
//  MacroRecorder
//
//  Model for cloud-synced macros with metadata
//

import Foundation
import CloudKit

/// Sync status for a macro
enum SyncStatus: String, Codable {
    case synced          // Fully synced with cloud
    case pendingUpload   // Local changes need upload
    case pendingDownload // Cloud has newer version
    case conflict        // Both local and cloud have changes
    case error           // Sync error occurred
    case localOnly       // Not synced to cloud

    var displayName: String {
        switch self {
        case .synced: return "Synced"
        case .pendingUpload: return "Uploading..."
        case .pendingDownload: return "Downloading..."
        case .conflict: return "Conflict"
        case .error: return "Sync Error"
        case .localOnly: return "Local Only"
        }
    }

    var iconName: String {
        switch self {
        case .synced: return "checkmark.icloud"
        case .pendingUpload: return "arrow.up.icloud"
        case .pendingDownload: return "arrow.down.icloud"
        case .conflict: return "exclamationmark.icloud"
        case .error: return "xmark.icloud"
        case .localOnly: return "icloud.slash"
        }
    }
}

/// Wrapper for Macro with sync metadata
struct CloudMacro: Codable, Identifiable {
    let id: UUID
    var macro: Macro
    var syncStatus: SyncStatus
    var cloudRecordId: String?       // CKRecord.ID name
    var lastSyncedAt: Date?
    var cloudModifiedAt: Date?       // Server modification date
    var localModifiedAt: Date        // Local modification date
    var deviceId: String             // Device that last modified

    init(
        macro: Macro,
        syncStatus: SyncStatus = .localOnly,
        cloudRecordId: String? = nil,
        deviceId: String? = nil
    ) {
        self.id = macro.id
        self.macro = macro
        self.syncStatus = syncStatus
        self.cloudRecordId = cloudRecordId
        self.lastSyncedAt = nil
        self.cloudModifiedAt = nil
        self.localModifiedAt = Date()
        self.deviceId = deviceId ?? Self.currentDeviceId
    }

    static var currentDeviceId: String {
        if let deviceId = UserDefaults.standard.string(forKey: "macrorecorder.deviceId") {
            return deviceId
        }
        let newId = UUID().uuidString
        UserDefaults.standard.set(newId, forKey: "macrorecorder.deviceId")
        return newId
    }

    // MARK: - CloudKit Conversion

    static let recordType = "Macro"

    func toRecord(zoneID: CKRecordZone.ID) -> CKRecord {
        let recordID = CKRecord.ID(
            recordName: cloudRecordId ?? id.uuidString,
            zoneID: zoneID
        )
        let record = CKRecord(recordType: Self.recordType, recordID: recordID)

        record["macroId"] = id.uuidString
        record["name"] = macro.name
        record["deviceId"] = deviceId
        record["localModifiedAt"] = localModifiedAt

        // Encode macro as JSON data
        if let macroData = try? JSONEncoder().encode(macro) {
            record["macroData"] = macroData
        }

        return record
    }

    static func from(record: CKRecord) -> CloudMacro? {
        guard let macroData = record["macroData"] as? Data,
              let macro = try? JSONDecoder().decode(Macro.self, from: macroData) else {
            return nil
        }

        let deviceId = record["deviceId"] as? String ?? "unknown"
        let localModifiedAt = record["localModifiedAt"] as? Date ?? record.modificationDate ?? Date()

        var cloudMacro = CloudMacro(
            macro: macro,
            syncStatus: .synced,
            cloudRecordId: record.recordID.recordName,
            deviceId: deviceId
        )
        cloudMacro.lastSyncedAt = Date()
        cloudMacro.cloudModifiedAt = record.modificationDate
        cloudMacro.localModifiedAt = localModifiedAt

        return cloudMacro
    }

    // MARK: - Conflict Resolution

    enum ConflictResolution {
        case keepLocal
        case keepCloud
        case keepBoth  // Creates a copy
    }

    func needsSync(comparedTo cloudVersion: CloudMacro?) -> Bool {
        guard let cloud = cloudVersion else {
            return syncStatus != .localOnly
        }

        return localModifiedAt > (cloud.cloudModifiedAt ?? Date.distantPast)
    }

    func hasConflict(with cloudVersion: CloudMacro) -> Bool {
        guard let cloudModified = cloudVersion.cloudModifiedAt,
              let lastSync = lastSyncedAt else {
            return false
        }

        // Conflict if both local and cloud modified after last sync
        return localModifiedAt > lastSync && cloudModified > lastSync
    }
}
