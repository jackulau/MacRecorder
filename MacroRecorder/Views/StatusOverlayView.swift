//
//  StatusOverlayView.swift
//  MacroRecorder
//

import SwiftUI
import AppKit

struct StatusOverlayView: View {
    @ObservedObject var session: MacroSession
    @ObservedObject var player: EventPlayer
    @AppStorage("overlayPosition") private var overlayPosition: String = "topRight"

    var body: some View {
        VStack(spacing: 8) {
            if session.isRecording {
                // Recording indicator
                HStack(spacing: 10) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .fill(Color.red)
                                .frame(width: 12, height: 12)
                                .scaleEffect(1.5)
                                .opacity(0.5)
                                .animation(Animation.easeInOut(duration: 1).repeatForever(autoreverses: true), value: session.isRecording)
                        )

                    Text("RECORDING")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)

                    if let macro = session.currentMacro {
                        Text("\(macro.events.count) events")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.red.opacity(0.9))
                )
            } else if session.isPlaying {
                // Playback indicator
                HStack(spacing: 10) {
                    Image(systemName: "play.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 12))

                    Text("PLAYING")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)

                    // Show loop count for non-infinite playback
                    if player.mode != .infinite {
                        switch player.mode {
                        case .once:
                            Text("Once")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.8))
                        case .count(let total):
                            Text("Loop \(player.currentLoop)/\(total)")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.8))
                        case .infinite:
                            EmptyView()
                        }
                    } else {
                        // Show total loops for infinite mode
                        Text("Loop \(player.currentLoop)")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.8))
                    }

                    // Progress indicator
                    if let macro = session.currentMacro {
                        Text("[\(player.currentEventIndex + 1)/\(macro.events.count)]")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.green.opacity(0.9))
                )
            }
        }
        .padding(20)
        .allowsHitTesting(false)  // Make overlay non-interactive
    }
}

class StatusOverlayWindow: NSWindow {
    init(session: MacroSession, player: EventPlayer) {
        let view = StatusOverlayView(session: session, player: player)

        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 100),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        self.contentView = NSHostingView(rootView: view)
        self.isOpaque = false
        self.backgroundColor = .clear
        self.level = .statusBar
        self.isReleasedWhenClosed = false
        self.ignoresMouseEvents = true
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]

        positionWindow()
    }

    func positionWindow() {
        guard let screen = NSScreen.main else { return }

        let position = UserDefaults.standard.string(forKey: "overlayPosition") ?? "topRight"
        let padding: CGFloat = 20

        switch position {
        case "topLeft":
            self.setFrameOrigin(NSPoint(
                x: screen.frame.minX + padding,
                y: screen.frame.maxY - self.frame.height - padding
            ))
        case "topRight":
            self.setFrameOrigin(NSPoint(
                x: screen.frame.maxX - self.frame.width - padding,
                y: screen.frame.maxY - self.frame.height - padding
            ))
        case "bottomLeft":
            self.setFrameOrigin(NSPoint(
                x: screen.frame.minX + padding,
                y: screen.frame.minY + padding
            ))
        case "bottomRight":
            self.setFrameOrigin(NSPoint(
                x: screen.frame.maxX - self.frame.width - padding,
                y: screen.frame.minY + padding
            ))
        default:
            // Default to top right
            self.setFrameOrigin(NSPoint(
                x: screen.frame.maxX - self.frame.width - padding,
                y: screen.frame.maxY - self.frame.height - padding
            ))
        }
    }

    func showOverlay() {
        self.orderFrontRegardless()
    }

    func hideOverlay() {
        self.orderOut(nil)
    }
}