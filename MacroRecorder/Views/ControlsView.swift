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

    var body: some View {
        VStack(spacing: 15) {
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
