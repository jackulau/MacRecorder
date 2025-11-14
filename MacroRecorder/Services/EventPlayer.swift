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

    var playbackSpeed: Double = 1.0

    private var playbackTask: Task<Void, Never>?
    private var events: [MacroEvent] = []

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
            if event.delay > 0 {
                let adjustedDelay = event.delay / playbackSpeed
                try? await Task.sleep(nanoseconds: UInt64(adjustedDelay * 1_000_000_000))
            }

            // Post the event
            if let cgEvent = event.toCGEvent() {
                cgEvent.post(tap: .cghidEventTap)
            }
        }

        // Update progress to 100%
        await MainActor.run {
            playbackProgress = 1.0
        }
    }
}
