//
//  CloudSyncService.swift
//  MacroRecorder
//
//  Service for syncing macros to iCloud using CloudKit
//

import Foundation
import CloudKit

class CloudSyncService: ObservableObject {
    static let shared = CloudSyncService()

    @Published var isEnabled = false
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncError: String?
    @Published private(set) var cloudMacros: [CloudMacro] = []

    private let container: CKContainer
    private let privateDatabase: CKDatabase
    private let zoneID: CKRecordZone.ID
    private let zoneName = "MacroRecorderZone"

    private let enabledKey = "macrorecorder.cloudSync.enabled"
    private let lastSyncKey = "macrorecorder.cloudSync.lastSync"

    private init() {
        container = CKContainer(identifier: "iCloud.com.macrorecorder")
        privateDatabase = container.privateCloudDatabase
        zoneID = CKRecordZone.ID(zoneName: zoneName, ownerName: CKCurrentUserDefaultName)

        isEnabled = UserDefaults.standard.bool(forKey: enabledKey)
        lastSyncDate = UserDefaults.standard.object(forKey: lastSyncKey) as? Date
    }

    // MARK: - Setup

    func setup() async throws {
        // Check iCloud account status
        let status = try await container.accountStatus()

        guard status == .available else {
            throw CloudSyncError.noAccount
        }

        // Create custom zone if needed
        try await createZoneIfNeeded()
    }

    private func createZoneIfNeeded() async throws {
        let zone = CKRecordZone(zoneID: zoneID)

        do {
            _ = try await privateDatabase.save(zone)
        } catch let error as CKError where error.code == .serverRecordChanged {
            // Zone already exists, that's fine
        }
    }

    // MARK: - Sync Control

    func enableSync() async throws {
        try await setup()
        isEnabled = true
        UserDefaults.standard.set(true, forKey: enabledKey)
        await sync()
    }

    func disableSync() {
        isEnabled = false
        UserDefaults.standard.set(false, forKey: enabledKey)
    }

    // MARK: - Sync Operations

    @MainActor
    func sync() async {
        guard isEnabled else { return }

        isSyncing = true
        syncError = nil

        do {
            // Fetch all cloud records
            let cloudRecords = try await fetchAllRecords()

            // Convert to CloudMacros
            cloudMacros = cloudRecords.compactMap { CloudMacro.from(record: $0) }

            lastSyncDate = Date()
            UserDefaults.standard.set(lastSyncDate, forKey: lastSyncKey)
        } catch {
            syncError = error.localizedDescription
        }

        isSyncing = false
    }

    func uploadMacro(_ macro: Macro) async throws {
        guard isEnabled else { return }

        let cloudMacro = CloudMacro(macro: macro, syncStatus: .pendingUpload)
        let record = cloudMacro.toRecord(zoneID: zoneID)

        _ = try await privateDatabase.save(record)

        await sync()
    }

    func deleteMacro(_ macroId: UUID) async throws {
        guard isEnabled else { return }

        guard let cloudMacro = cloudMacros.first(where: { $0.id == macroId }),
              let recordName = cloudMacro.cloudRecordId else {
            return
        }

        let recordID = CKRecord.ID(recordName: recordName, zoneID: zoneID)
        try await privateDatabase.deleteRecord(withID: recordID)

        await sync()
    }

    // MARK: - Fetch Operations

    private func fetchAllRecords() async throws -> [CKRecord] {
        var records: [CKRecord] = []

        let query = CKQuery(recordType: CloudMacro.recordType, predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "modificationDate", ascending: false)]

        let (matchResults, _) = try await privateDatabase.records(
            matching: query,
            inZoneWith: zoneID,
            desiredKeys: nil,
            resultsLimit: CKQueryOperation.maximumResults
        )

        for (_, result) in matchResults {
            if case .success(let record) = result {
                records.append(record)
            }
        }

        return records
    }

    func fetchMacro(_ macroId: UUID) async throws -> CloudMacro? {
        guard let cloudMacro = cloudMacros.first(where: { $0.id == macroId }),
              let recordName = cloudMacro.cloudRecordId else {
            return nil
        }

        let recordID = CKRecord.ID(recordName: recordName, zoneID: zoneID)
        let record = try await privateDatabase.record(for: recordID)

        return CloudMacro.from(record: record)
    }

    // MARK: - Subscriptions

    func setupSubscription() async throws {
        let subscription = CKQuerySubscription(
            recordType: CloudMacro.recordType,
            predicate: NSPredicate(value: true),
            subscriptionID: "macro-changes",
            options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion]
        )

        let notification = CKSubscription.NotificationInfo()
        notification.shouldSendContentAvailable = true
        subscription.notificationInfo = notification

        _ = try await privateDatabase.save(subscription)
    }

    // MARK: - Conflict Resolution

    func resolveConflict(
        macroId: UUID,
        resolution: CloudMacro.ConflictResolution,
        localMacro: Macro
    ) async throws -> Macro {
        guard let cloudMacro = cloudMacros.first(where: { $0.id == macroId }) else {
            return localMacro
        }

        switch resolution {
        case .keepLocal:
            try await uploadMacro(localMacro)
            return localMacro

        case .keepCloud:
            return cloudMacro.macro

        case .keepBoth:
            // Create a copy with new ID
            var copy = localMacro
            copy = Macro(id: UUID(), name: "\(localMacro.name) (Local Copy)", events: localMacro.events)
            try await uploadMacro(copy)
            return cloudMacro.macro
        }
    }
}

// MARK: - Error Types

enum CloudSyncError: LocalizedError {
    case noAccount
    case notEnabled
    case networkError(String)
    case quotaExceeded
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case .noAccount: return "iCloud account not available"
        case .notEnabled: return "Cloud sync is not enabled"
        case .networkError(let msg): return "Network error: \(msg)"
        case .quotaExceeded: return "iCloud storage quota exceeded"
        case .permissionDenied: return "Permission denied"
        }
    }
}
