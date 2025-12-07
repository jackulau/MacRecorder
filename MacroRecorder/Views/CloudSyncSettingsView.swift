//
//  CloudSyncSettingsView.swift
//  MacroRecorder
//
//  View for managing cloud sync settings
//

import SwiftUI

struct CloudSyncSettingsView: View {
    @StateObject private var syncService = CloudSyncService.shared

    @State private var showingEnableConfirm = false
    @State private var showingDisableConfirm = false
    @State private var error: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "icloud")
                    .font(.title2)
                Text("iCloud Sync")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()

                // Status indicator
                if syncService.isSyncing {
                    HStack(spacing: 4) {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text("Syncing...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else if syncService.isEnabled {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.icloud.fill")
                            .foregroundColor(.green)
                        Text("Connected")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Divider()

            // Enable/Disable toggle
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Sync Macros to iCloud")
                                .font(.headline)
                            Text("Keep your macros synchronized across all your devices")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { syncService.isEnabled },
                            set: { newValue in
                                if newValue {
                                    showingEnableConfirm = true
                                } else {
                                    showingDisableConfirm = true
                                }
                            }
                        ))
                        .toggleStyle(.switch)
                    }
                }
            }

            // Sync status
            if syncService.isEnabled {
                GroupBox("Sync Status") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Last synced:")
                            Spacer()
                            if let date = syncService.lastSyncDate {
                                Text(date.formatted(date: .abbreviated, time: .shortened))
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Never")
                                    .foregroundColor(.secondary)
                            }
                        }

                        HStack {
                            Text("Cloud macros:")
                            Spacer()
                            Text("\(syncService.cloudMacros.count)")
                                .foregroundColor(.secondary)
                        }

                        Divider()

                        HStack {
                            Button(action: syncNow) {
                                HStack {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                    Text("Sync Now")
                                }
                            }
                            .disabled(syncService.isSyncing)

                            Spacer()
                        }
                    }
                    .padding(4)
                }
            }

            // Error display
            if let error = syncService.syncError ?? error {
                GroupBox {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                        Spacer()
                    }
                }
            }

            // Info
            GroupBox("About iCloud Sync") {
                VStack(alignment: .leading, spacing: 8) {
                    InfoRow(icon: "lock.shield", text: "Your macros are encrypted and stored securely in your iCloud account")
                    InfoRow(icon: "arrow.triangle.2.circlepath", text: "Changes sync automatically when connected to the internet")
                    InfoRow(icon: "macbook.and.iphone", text: "Access your macros from any Mac signed into your iCloud account")
                }
                .padding(4)
            }

            Spacer()
        }
        .padding()
        .alert("Enable iCloud Sync?", isPresented: $showingEnableConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Enable") {
                enableSync()
            }
        } message: {
            Text("Your macros will be uploaded to iCloud and synced across your devices.")
        }
        .alert("Disable iCloud Sync?", isPresented: $showingDisableConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Disable", role: .destructive) {
                syncService.disableSync()
            }
        } message: {
            Text("Your macros will no longer sync. Existing macros on this device will be kept.")
        }
    }

    private func enableSync() {
        Task {
            do {
                try await syncService.enableSync()
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                }
            }
        }
    }

    private func syncNow() {
        Task {
            await syncService.sync()
        }
    }
}

struct InfoRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .frame(width: 20)
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Sync Status Indicator (for MenuBar)

struct SyncStatusIndicator: View {
    @StateObject private var syncService = CloudSyncService.shared

    var body: some View {
        if syncService.isEnabled {
            Group {
                if syncService.isSyncing {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundColor(.blue)
                } else if syncService.syncError != nil {
                    Image(systemName: "exclamationmark.icloud")
                        .foregroundColor(.red)
                } else {
                    Image(systemName: "checkmark.icloud")
                        .foregroundColor(.green)
                }
            }
            .help(syncStatusText)
        }
    }

    private var syncStatusText: String {
        if syncService.isSyncing {
            return "Syncing..."
        } else if let error = syncService.syncError {
            return "Sync error: \(error)"
        } else if let date = syncService.lastSyncDate {
            return "Last synced: \(date.formatted())"
        } else {
            return "iCloud sync enabled"
        }
    }
}
