//
//  PreferencesView.swift
//  MacroRecorder
//

import SwiftUI
import Carbon

struct PreferencesView: View {
    @AppStorage("defaultPlaybackSpeed") private var defaultPlaybackSpeed: Double = 1.0
    @AppStorage("defaultPlaybackMode") private var defaultPlaybackMode: String = "once"
    @AppStorage("showNotifications") private var showNotifications: Bool = true
    @AppStorage("recordMouseMoves") private var recordMouseMoves: Bool = true
    @AppStorage("mouseMoveThreshold") private var mouseMoveThreshold: Double = 0.1

    var body: some View {
        TabView {
            GeneralPreferencesView(
                defaultPlaybackSpeed: $defaultPlaybackSpeed,
                defaultPlaybackMode: $defaultPlaybackMode,
                showNotifications: $showNotifications
            )
            .tabItem {
                Label("General", systemImage: "gearshape")
            }

            RecordingPreferencesView(
                recordMouseMoves: $recordMouseMoves,
                mouseMoveThreshold: $mouseMoveThreshold
            )
            .tabItem {
                Label("Recording", systemImage: "record.circle")
            }

            HotkeyPreferencesView()
                .tabItem {
                    Label("Hotkeys", systemImage: "command")
                }

            AboutView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 500, height: 400)
    }
}

struct GeneralPreferencesView: View {
    @Binding var defaultPlaybackSpeed: Double
    @Binding var defaultPlaybackMode: String
    @Binding var showNotifications: Bool
    @AppStorage("showStatusOverlay") private var showStatusOverlay: Bool = true
    @AppStorage("overlayPosition") private var overlayPosition: String = "topRight"
    @AppStorage("useWindowScaling") private var useWindowScaling: Bool = false

    var body: some View {
        Form {
            Section("Status Overlay") {
                Toggle("Show status overlay during recording/playback", isOn: $showStatusOverlay)

                if showStatusOverlay {
                    Picker("Overlay Position", selection: $overlayPosition) {
                        Text("Top Left").tag("topLeft")
                        Text("Top Right").tag("topRight")
                        Text("Bottom Left").tag("bottomLeft")
                        Text("Bottom Right").tag("bottomRight")
                    }

                    Text("Displays recording status and playback loop count")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Section("Playback") {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Default Playback Speed")
                        .font(.subheadline)

                    HStack {
                        Slider(value: $defaultPlaybackSpeed, in: 0.1...5.0, step: 0.1)
                        Text(String(format: "%.1fx", defaultPlaybackSpeed))
                            .frame(width: 50)
                            .font(.system(.body, design: .monospaced))
                    }
                }

                Picker("Default Playback Mode", selection: $defaultPlaybackMode) {
                    Text("Once").tag("once")
                    Text("Loop").tag("loop")
                    Text("Infinite").tag("infinite")
                }

                Divider()

                Toggle("Use Window Scaling", isOn: $useWindowScaling)
                    .help("Automatically scale mouse positions to window size during playback")

                Text("When enabled, mouse positions will adapt to window size changes")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("Notifications") {
                Toggle("Show notifications for recording/playback events", isOn: $showNotifications)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

struct RecordingPreferencesView: View {
    @Binding var recordMouseMoves: Bool
    @Binding var mouseMoveThreshold: Double

    var body: some View {
        Form {
            Section("Mouse Recording") {
                Toggle("Record mouse movements", isOn: $recordMouseMoves)

                VStack(alignment: .leading, spacing: 5) {
                    Text("Mouse move threshold (seconds)")
                        .font(.subheadline)

                    HStack {
                        Slider(value: $mouseMoveThreshold, in: 0.01...1.0, step: 0.01)
                            .disabled(!recordMouseMoves)
                        Text(String(format: "%.2fs", mouseMoveThreshold))
                            .frame(width: 60)
                            .font(.system(.body, design: .monospaced))
                    }

                    Text("Minimum delay between mouse move events to reduce recording size")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Section("Optimization") {
                Text("Mouse move threshold helps reduce the number of recorded events by skipping rapid mouse movements. Increase this value for smaller macro files.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

struct HotkeyPreferencesView: View {
    @AppStorage("recordingHotkeyData") private var recordingHotkeyData: Data = {
        let defaultConfig = HotkeyConfig(keyCode: 0x2C, modifiers: UInt32(cmdKey | shiftKey))
        return (try? JSONEncoder().encode(defaultConfig)) ?? Data()
    }()

    @AppStorage("playbackHotkeyData") private var playbackHotkeyData: Data = {
        let defaultConfig = HotkeyConfig(keyCode: 0x23, modifiers: UInt32(cmdKey | shiftKey))
        return (try? JSONEncoder().encode(defaultConfig)) ?? Data()
    }()

    @State private var recordingHotkey: HotkeyConfig = HotkeyConfig(keyCode: 0x2C, modifiers: UInt32(cmdKey | shiftKey))
    @State private var playbackHotkey: HotkeyConfig = HotkeyConfig(keyCode: 0x23, modifiers: UInt32(cmdKey | shiftKey))
    @State private var showResetConfirm = false

    var body: some View {
        Form {
            Section("Global Hotkeys") {
                VStack(spacing: 15) {
                    // KeybindCaptureView temporarily disabled - displaying static text
                    HStack {
                        Text("Start/Stop Recording")
                            .frame(width: 150, alignment: .leading)
                        Text(recordingHotkey.displayString)
                            .font(.system(.body, design: .monospaced))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(6)
                    }

                    HStack {
                        Text("Play/Stop Playback")
                            .frame(width: 150, alignment: .leading)
                        Text(playbackHotkey.displayString)
                            .font(.system(.body, design: .monospaced))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(6)
                    }
                }
                .padding(.vertical, 5)

                Divider()

                HStack {
                    Button("Reset to Defaults") {
                        showResetConfirm = true
                    }
                    .buttonStyle(.borderless)

                    Spacer()

                    Text("Hotkey changes take effect immediately")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }

            Section("Instructions") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("• Click on a hotkey button to start recording")
                    Text("• Press your desired key combination (must include ⌘, ⌥, ⌃, or ⇧)")
                    Text("• The hotkey will be saved automatically")
                    Text("• Avoid using system-reserved shortcuts")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear {
            loadHotkeys()
        }
        .alert("Reset Hotkeys", isPresented: $showResetConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                resetToDefaults()
            }
        } message: {
            Text("This will reset all hotkeys to their default values.")
        }
    }

    private func loadHotkeys() {
        if let config = try? JSONDecoder().decode(HotkeyConfig.self, from: recordingHotkeyData) {
            recordingHotkey = config
        }
        if let config = try? JSONDecoder().decode(HotkeyConfig.self, from: playbackHotkeyData) {
            playbackHotkey = config
        }
    }

    private func saveRecordingHotkey(_ config: HotkeyConfig) {
        if let data = try? JSONEncoder().encode(config) {
            recordingHotkeyData = data
            // Notify that hotkeys have changed
            NotificationCenter.default.post(name: .hotkeysChanged, object: nil)
        }
    }

    private func savePlaybackHotkey(_ config: HotkeyConfig) {
        if let data = try? JSONEncoder().encode(config) {
            playbackHotkeyData = data
            // Notify that hotkeys have changed
            NotificationCenter.default.post(name: .hotkeysChanged, object: nil)
        }
    }

    private func resetToDefaults() {
        recordingHotkey = HotkeyConfig(keyCode: 0x2C, modifiers: UInt32(cmdKey | shiftKey))
        playbackHotkey = HotkeyConfig(keyCode: 0x23, modifiers: UInt32(cmdKey | shiftKey))
        saveRecordingHotkey(recordingHotkey)
        savePlaybackHotkey(playbackHotkey)
    }
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "record.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)

            Text("MacroRecorder")
                .font(.title)
                .fontWeight(.bold)

            Text("Version 1.0.3")
                .font(.subheadline)
                .foregroundColor(.secondary)

            VStack(spacing: 5) {
                Text("A powerful macro recorder for macOS")
                    .font(.body)

                Text("Record and playback mouse and keyboard events")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .multilineTextAlignment(.center)

            Divider()
                .frame(width: 200)

            VStack(spacing: 10) {
                Text("Features")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 5) {
                    FeatureRow(icon: "record.circle", text: "Record mouse clicks, drags, and key presses")
                    FeatureRow(icon: "slider.horizontal.3", text: "Adjust event delays and playback speed")
                    FeatureRow(icon: "repeat", text: "Multiple playback modes (once, loop, infinite)")
                    FeatureRow(icon: "pencil", text: "Edit and insert events")
                    FeatureRow(icon: "square.and.arrow.down", text: "Save and load macros")
                    FeatureRow(icon: "command", text: "Global hotkeys for quick access")
                }
                .font(.caption)
            }

            Spacer()

            Text("© 2025 MacroRecorder. All rights reserved.")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .frame(width: 20)
            Text(text)
            Spacer()
        }
    }
}
