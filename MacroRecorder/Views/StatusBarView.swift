//
//  StatusBarView.swift
//  MacroRecorder
//

import SwiftUI

struct StatusBarView: View {
    @ObservedObject var session: MacroSession

    var body: some View {
        HStack {
            // Status indicator
            HStack(spacing: 8) {
                if session.isRecording {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                    Text("Recording...")
                        .foregroundColor(.red)
                } else if session.isPlaying {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text("Playing...")
                        .foregroundColor(.green)
                } else {
                    Circle()
                        .fill(Color.secondary)
                        .frame(width: 8, height: 8)
                    Text("Ready")
                        .foregroundColor(.secondary)
                }
            }
            .font(.caption)

            Spacer()

            // Event count
            if let macro = session.currentMacro {
                Text("\(macro.events.count) events")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Divider()
                    .frame(height: 15)
            }

            // Playback progress
            if session.isPlaying {
                HStack(spacing: 5) {
                    if case .count(let max) = session.player.mode {
                        Text("Loop \(session.player.currentLoop)/\(max)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if case .infinite = session.player.mode {
                        Text("Loop \(session.player.currentLoop)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    ProgressView(value: session.player.playbackProgress)
                        .frame(width: 100)
                }

                Divider()
                    .frame(height: 15)
            }

            // Hotkey hints
            HStack(spacing: 15) {
                HStack(spacing: 3) {
                    Text("⌘⇧/")
                        .font(.caption.monospaced())
                        .foregroundColor(.secondary)
                    Text("Record")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 3) {
                    Text("⌘⇧P")
                        .font(.caption.monospaced())
                        .foregroundColor(.secondary)
                    Text("Play")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal)
    }
}
