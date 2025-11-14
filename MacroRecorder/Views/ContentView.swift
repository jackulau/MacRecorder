//
//  ContentView.swift
//  MacroRecorder
//

import SwiftUI

struct ContentView: View {
    @StateObject private var session = MacroSession()
    @StateObject private var hotkeyManager = HotkeyManager()

    @State private var playbackSpeed: Double = 1.0
    @State private var playbackMode: PlaybackMode = .once
    @State private var loopCount: Int = 1
    @State private var selectedMacro: Macro?
    @State private var showingSaveDialog = false
    @State private var macroName = ""
    @State private var showingImportExport = false
    // @State private var statusOverlayWindow: StatusOverlayWindow?

    // @AppStorage("showStatusOverlay") private var showStatusOverlay: Bool = true

    var body: some View {
        HSplitView {
            // Left sidebar - Saved macros
            MacroListView(
                macros: session.savedMacros,
                selectedMacro: $selectedMacro,
                onLoad: { macro in
                    session.loadMacro(macro)
                },
                onDelete: { macro in
                    session.deleteMacro(macro)
                },
                onExport: { macro in
                    exportMacro(macro)
                },
                onImport: {
                    importMacro()
                }
            )
            .frame(minWidth: 200, maxWidth: 300)

            // Main content area
            VStack(spacing: 0) {
                // Top controls
                ControlsView(
                    session: session,
                    playbackSpeed: $playbackSpeed,
                    playbackMode: $playbackMode,
                    loopCount: $loopCount,
                    onSave: {
                        showingSaveDialog = true
                    }
                )
                .padding()
                .background(Color(NSColor.controlBackgroundColor))

                Divider()

                // Event list
                if let macro = session.currentMacro {
                    EventListView(
                        macro: macro,
                        session: session,
                        currentEventIndex: session.player.currentEventIndex
                    )
                } else {
                    EmptyStateView()
                }

                Divider()

                // Status bar
                StatusBarView(session: session)
                    .frame(height: 30)
                    .background(Color(NSColor.controlBackgroundColor))
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .sheet(isPresented: $showingSaveDialog) {
            SaveMacroDialog(
                macroName: $macroName,
                onSave: {
                    session.saveCurrentMacro(name: macroName)
                    showingSaveDialog = false
                    macroName = ""
                },
                onCancel: {
                    showingSaveDialog = false
                    macroName = ""
                }
            )
        }
        .onAppear {
            setupHotkeys()
            // setupOverlayWindow()
        }
        .onReceive(NotificationCenter.default.publisher(for: .hotkeysChanged)) { _ in
            hotkeyManager.reloadHotkeys()
            // Update session with new hotkeys
            session.setHotkeys(
                recording: hotkeyManager.recordingHotkey,
                playback: hotkeyManager.playbackHotkey
            )
        }
        // .onChange(of: session.isRecording) { isRecording in
        //     updateOverlayVisibility()
        // }
        // .onChange(of: session.isPlaying) { isPlaying in
        //     updateOverlayVisibility()
        // }
        // .onChange(of: showStatusOverlay) { _ in
        //     updateOverlayVisibility()
        // }
        // .onChange(of: UserDefaults.standard.string(forKey: "overlayPosition")) { _ in
        //     statusOverlayWindow?.positionWindow()
        // }
    }

    // private func setupOverlayWindow() {
    //     statusOverlayWindow = StatusOverlayWindow(session: session, player: session.player)
    //     updateOverlayVisibility()
    // }

    // private func updateOverlayVisibility() {
    //     guard let window = statusOverlayWindow else { return }

    //     if showStatusOverlay && (session.isRecording || session.isPlaying) {
    //         window.showOverlay()
    //     } else {
    //         window.hideOverlay()
    //     }
    // }

    private func setupHotkeys() {
        // Pass hotkeys to session so recorder can filter them out
        session.setHotkeys(
            recording: hotkeyManager.recordingHotkey,
            playback: hotkeyManager.playbackHotkey
        )

        hotkeyManager.onRecordingTriggered = {
            if session.isRecording {
                session.stopRecording()
            } else {
                session.startRecording()
            }
        }

        hotkeyManager.onPlaybackTriggered = {
            if session.isPlaying {
                session.stopPlayback()
            } else if let macro = session.currentMacro {
                session.play(macro: macro, mode: playbackMode, speed: playbackSpeed)
            }
        }

        hotkeyManager.registerHotkeys()
    }

    private func exportMacro(_ macro: Macro) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "\(macro.name).json"

        panel.begin { response in
            if response == .OK, let url = panel.url {
                do {
                    try session.exportMacro(macro, to: url)
                } catch {
                    print("Export failed: \(error)")
                }
            }
        }
    }

    private func importMacro() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false

        panel.begin { response in
            if response == .OK, let url = panel.url {
                do {
                    let macro = try session.importMacro(from: url)
                    session.loadMacro(macro)
                    session.saveCurrentMacro()
                } catch {
                    print("Import failed: \(error)")
                }
            }
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "record.circle")
                .font(.system(size: 64))
                .foregroundColor(.secondary)

            Text("No Macro Loaded")
                .font(.title)
                .foregroundColor(.secondary)

            Text("Press the Record button or ⌘⇧/ to start recording a new macro")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct SaveMacroDialog: View {
    @Binding var macroName: String
    let onSave: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Save Macro")
                .font(.headline)

            TextField("Macro Name", text: $macroName)
                .textFieldStyle(.roundedBorder)
                .frame(width: 300)

            HStack(spacing: 10) {
                Button("Cancel") {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)

                Button("Save") {
                    onSave()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(macroName.isEmpty)
            }
        }
        .padding()
        .frame(width: 400, height: 150)
    }
}
