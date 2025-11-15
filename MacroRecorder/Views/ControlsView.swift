//
//  ControlsView.swift
//  MacroRecorder
//

import SwiftUI

struct ControlsView: View {
    @ObservedObject var session: MacroSession
    @Binding var playbackSpeed: Double
    @Binding var playbackMode: PlaybackMode
    @Binding var loopCount: Int

    let onSave: () -> Void

    @State private var showWindowPicker = false
    @State private var selectedWindowTitle: String = "All Windows"

    var body: some View {
        VStack(spacing: 15) {
            // Window-specific recording controls
            HStack(alignment: .center, spacing: 15) {
                Toggle("Window-Specific Recording", isOn: $session.isWindowSpecificMode)
                    .toggleStyle(.switch)
                    .disabled(session.isRecording)

                if session.isWindowSpecificMode {
                    Divider()
                        .frame(height: 20)

                    HStack(spacing: 10) {
                        Label("Target:", systemImage: "macwindow")
                            .foregroundColor(.secondary)
                            .font(.system(size: 12))

                        Button(action: {
                            showWindowPicker = true
                        }) {
                            HStack(spacing: 4) {
                                Text(selectedWindowTitle)
                                    .lineLimit(1)
                                    .frame(maxWidth: 200)
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 10))
                            }
                        }
                        .buttonStyle(.bordered)
                        .disabled(session.isRecording)

                        if session.targetWindow != nil {
                            Button(action: {
                                session.targetWindow = nil
                                selectedWindowTitle = "All Windows"
                            }) {
                                Image(systemName: "xmark.circle.fill")
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(.secondary)
                            .help("Clear window selection")
                        }
                    }

                    Divider()
                        .frame(height: 20)

                    Toggle("Ghost Actions", isOn: $session.useGhostActions)
                        .toggleStyle(.switch)
                        .help("Send events to windows without focusing them")
                }

                Spacer()
            }

            .sheet(isPresented: $showWindowPicker) {
                WindowPickerView(
                    selectedWindow: $session.targetWindow,
                    selectedTitle: $selectedWindowTitle
                )
            }

            Divider()

            // Recording controls
            HStack(spacing: 15) {
                Button(action: {
                    if session.isRecording {
                        session.stopRecording()
                    } else {
                        session.startRecording()
                    }
                }) {
                    HStack {
                        Image(systemName: session.isRecording ? "stop.circle.fill" : "record.circle")
                            .font(.title2)
                        Text(session.isRecording ? "Stop Recording" : "Start Recording")
                    }
                    .frame(width: 180)
                }
                .buttonStyle(.borderedProminent)
                .tint(session.isRecording ? .red : .blue)
                .disabled(session.isPlaying)
                .keyboardShortcut("r", modifiers: [.command])

                Button(action: {
                    session.clearCurrentMacro()
                }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Clear")
                    }
                }
                .disabled(session.isRecording || session.currentMacro?.events.isEmpty ?? true)

                Spacer()

                Button(action: onSave) {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                        Text("Save Macro")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(session.currentMacro?.events.isEmpty != false)
                .keyboardShortcut("s", modifiers: [.command])

                Button(action: {
                    if #available(macOS 14, *) {
                        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                    } else if #available(macOS 13, *) {
                        NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
                    }
                }) {
                    Image(systemName: "gearshape")
                }
                .help("Open Settings")
                .keyboardShortcut(",", modifiers: [.command])
            }

            Divider()

            // Playback controls
            HStack(spacing: 15) {
                Button(action: {
                    if session.isPlaying {
                        session.stopPlayback()
                    } else if let macro = session.currentMacro {
                        session.play(macro: macro, mode: playbackMode, speed: playbackSpeed)
                    }
                }) {
                    HStack {
                        Image(systemName: session.isPlaying ? "stop.fill" : "play.fill")
                            .font(.title2)
                        Text(session.isPlaying ? "Stop Playback" : "Play Macro")
                    }
                    .frame(width: 180)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .disabled(session.isRecording || session.currentMacro?.events.isEmpty != false)
                .keyboardShortcut("p", modifiers: [.command])

                VStack(alignment: .leading, spacing: 5) {
                    Text("Speed: \(String(format: "%.1fx", playbackSpeed))")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Slider(value: $playbackSpeed, in: 0.1...5.0, step: 0.1)
                        .frame(width: 150)
                        .disabled(session.isPlaying)
                }

                Divider()
                    .frame(height: 40)

                VStack(alignment: .leading, spacing: 5) {
                    Text("Playback Mode")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Picker("", selection: $playbackMode) {
                        Text("Once").tag(PlaybackMode.once)
                        Text("Loop").tag(PlaybackMode.count(loopCount))
                        Text("Infinite").tag(PlaybackMode.infinite)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 200)
                    .disabled(session.isPlaying)
                }

                if case .count = playbackMode {
                    Stepper("Count: \(loopCount)", value: $loopCount, in: 1...1000)
                        .frame(width: 150)
                        .disabled(session.isPlaying)
                        .onChange(of: loopCount) { newValue in
                            playbackMode = .count(newValue)
                        }
                }

                Spacer()
            }
        }
    }
}

// Helper to make PlaybackMode conform to Hashable for Picker
extension PlaybackMode: Hashable {
    func hash(into hasher: inout Hasher) {
        switch self {
        case .once:
            hasher.combine(0)
        case .count(let count):
            hasher.combine(1)
            hasher.combine(count)
        case .infinite:
            hasher.combine(2)
        }
    }

    static func == (lhs: PlaybackMode, rhs: PlaybackMode) -> Bool {
        switch (lhs, rhs) {
        case (.once, .once):
            return true
        case (.count(let a), .count(let b)):
            return a == b
        case (.infinite, .infinite):
            return true
        default:
            return false
        }
    }
}
