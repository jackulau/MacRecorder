//
//  EventPlayer.swift
//  MacroRecorder
//

import Foundation
import CoreGraphics
import Combine

enum PlaybackMode {
    case once
    case count(Int)
    case infinite
}

class EventPlayer: ObservableObject {
    @Published var isPlaying = false
    @Published var currentEventIndex: Int = 0
    @Published var playbackProgress: Double = 0.0
    @Published var currentLoop: Int = 0
    @Published var mode: PlaybackMode = .once
    @Published var useWindowScaling = false  // Enable window-aware playback
    @Published var useGhostActions = false   // Send events without focusing window

    var playbackSpeed: Double = 1.0

    private var playbackTask: Task<Void, Never>?
    private var events: [MacroEvent] = []
    private let windowDetector = WindowDetector.shared
    private let variableManager = VariableManager.shared

    func play(events: [MacroEvent], mode: PlaybackMode = .once, speed: Double = 1.0) {
        guard !isPlaying, !events.isEmpty else { return }

        self.events = events
        self.mode = mode
        self.playbackSpeed = speed
        self.currentEventIndex = 0
        self.currentLoop = 0
        self.isPlaying = true

        playbackTask = Task {
            await performPlayback()
        }
    }

    func stop() {
        playbackTask?.cancel()
        playbackTask = nil
        isPlaying = false
        currentEventIndex = 0
        playbackProgress = 0.0
        currentLoop = 0
    }

    func pause() {
        // For future implementation
    }

    private func performPlayback() async {
        switch mode {
        case .once:
            await playOnce()
        case .count(let count):
            for loop in 0..<count {
                guard !Task.isCancelled else { break }
                currentLoop = loop + 1
                await playOnce()
            }
        case .infinite:
            while !Task.isCancelled {
                currentLoop += 1
                await playOnce()
            }
        }

        await MainActor.run {
            isPlaying = false
            currentEventIndex = 0
            playbackProgress = 0.0
        }
    }

    private func playOnce() async {
        guard !events.isEmpty else { return }

        for (index, event) in events.enumerated() {
            guard !Task.isCancelled else { break }

            // Update progress
            await MainActor.run {
                currentEventIndex = index
                playbackProgress = Double(index) / Double(events.count)
            }

            // Wait for the delay (adjusted by playback speed)
            // Use delayConfig for variable/random delays, fallback to fixed delay
            let resolvedDelay: TimeInterval
            if let config = event.delayConfig {
                resolvedDelay = variableManager.resolveDelay(config)
            } else {
                resolvedDelay = event.delay
            }

            if resolvedDelay > 0 {
                let adjustedDelay = resolvedDelay / playbackSpeed
                try? await Task.sleep(nanoseconds: UInt64(adjustedDelay * 1_000_000_000))
            }

            // Handle window focus events
            if event.type == .windowFocus {
                if let windowInfo = event.windowInfo {
                    // Try to focus the window
                    _ = windowDetector.focusWindow(with: windowInfo)
                    // Give the window time to focus
                    try? await Task.sleep(nanoseconds: 200_000_000) // 200ms
                }
                continue
            }

            // Create the CGEvent
            var cgEvent: CGEvent?

            // If window scaling is enabled and we have window info
            if useWindowScaling,
               let windowInfo = event.windowInfo,
               let relativePos = event.relativePosition {

                // Try to find the current window
                let currentWindow = windowDetector.getWindowInfo(for: windowInfo.processID,
                                                                matchingBounds: windowInfo.windowBounds)

                if let currentWindow = currentWindow {
                    // Calculate the scaled position based on current window size
                    let scaledPosition = windowInfo.absolutePosition(from: relativePos,
                                                                    currentBounds: currentWindow.windowBounds)

                    // If not using ghost actions and window is not active, focus it first
                    if !useGhostActions && !currentWindow.isActive {
                        _ = windowDetector.focusWindow(with: currentWindow)
                        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms to let window focus
                    }

                    // Create event with scaled position
                    switch event.type {
                    case .mouseLeftDown, .mouseLeftUp, .mouseRightDown, .mouseRightUp, .mouseMove, .mouseDrag:
                        let mouseButton: CGMouseButton = event.type == .mouseRightDown || event.type == .mouseRightUp ? .right : .left
                        let eventType: CGEventType = {
                            switch event.type {
                            case .mouseLeftDown: return .leftMouseDown
                            case .mouseLeftUp: return .leftMouseUp
                            case .mouseRightDown: return .rightMouseDown
                            case .mouseRightUp: return .rightMouseUp
                            case .mouseMove: return .mouseMoved
                            case .mouseDrag: return .leftMouseDragged
                            default: return .null
                            }
                        }()
                        cgEvent = CGEvent(mouseEventSource: nil,
                                        mouseType: eventType,
                                        mouseCursorPosition: scaledPosition,
                                        mouseButton: mouseButton)

                        // If using ghost actions, set the target process
                        if useGhostActions && cgEvent != nil {
                            cgEvent?.setTargetProcessID(windowInfo.processID)
                        }
                    default:
                        // For non-mouse events, use the original event
                        cgEvent = event.toCGEvent()

                        // For keyboard events with ghost actions, set target process
                        if useGhostActions && (event.type == .keyDown || event.type == .keyUp) {
                            cgEvent?.setTargetProcessID(windowInfo.processID)
                        }
                    }
                } else {
                    // Window not found, use original position
                    cgEvent = event.toCGEvent()
                }
            } else {
                // Use original event without scaling
                cgEvent = event.toCGEvent()
            }

            // Post the event
            if let cgEvent = cgEvent {
                if useGhostActions,
                   let windowInfo = event.windowInfo {
                    // Post directly to the process for ghost actions
                    cgEvent.postToPid(windowInfo.processID)
                } else {
                    // Regular posting
                    cgEvent.post(tap: .cghidEventTap)
                }
            }
        }

        // Update progress to 100%
        await MainActor.run {
            playbackProgress = 1.0
        }
    }
}
