//
//  MacroSession.swift
//  MacroRecorder
//

import Foundation
import Combine

class MacroSession: ObservableObject {
    @Published var currentMacro: Macro?
    @Published var savedMacros: [Macro] = []
    @Published var isRecording = false
    @Published var isPlaying = false
    @Published var isWindowSpecificMode = false
    @Published var targetWindow: WindowInfo?
    @Published var useWindowScaling = false
    @Published var useGhostActions = false

    let eventRecorder = EventRecorder()
    let eventPlayer = EventPlayer()

    private var cancellables = Set<AnyCancellable>()
    private let storageKey = "SavedMacros"

    init() {
        // Observe eventRecorder state
        eventRecorder.$isRecording
            .assign(to: \.isRecording, on: self)
            .store(in: &cancellables)

        // Observe eventPlayer state
        eventPlayer.$isPlaying
            .assign(to: \.isPlaying, on: self)
            .store(in: &cancellables)

        // Sync window-specific recording settings
        $isWindowSpecificMode
            .assign(to: \.isWindowSpecificMode, on: eventRecorder)
            .store(in: &cancellables)

        $targetWindow
            .assign(to: \.targetWindow, on: eventRecorder)
            .store(in: &cancellables)

        // Load window scaling preference from UserDefaults
        let savedScaling = UserDefaults.standard.bool(forKey: "useWindowScaling")
        useWindowScaling = savedScaling
        eventPlayer.useWindowScaling = savedScaling

        $useWindowScaling
            .sink { [weak self] value in
                self?.eventPlayer.useWindowScaling = value
                UserDefaults.standard.set(value, forKey: "useWindowScaling")
            }
            .store(in: &cancellables)

        $useGhostActions
            .assign(to: \.useGhostActions, on: eventPlayer)
            .store(in: &cancellables)

        // Load saved macros
        loadMacros()
    }

    // MARK: - Recording

    func startRecording() {
        guard !isRecording else { return }
        eventRecorder.startRecording()
    }

    func stopRecording() {
        guard isRecording else { return }
        eventRecorder.stopRecording()

        // Create a new macro from recorded events
        var macro = Macro(name: "Macro \(Date().formatted())", events: eventRecorder.recordedEvents)
        macro.updateDelays()
        currentMacro = macro
    }

    func clearCurrentMacro() {
        eventRecorder.clearRecording()
        currentMacro = nil
    }

    func setHotkeys(recording: (keyCode: UInt32, modifiers: UInt32), playback: (keyCode: UInt32, modifiers: UInt32)) {
        eventRecorder.recordingHotkey = recording
        eventRecorder.playbackHotkey = playback
    }

    func saveCurrentMacro(name: String? = nil) {
        guard var macro = currentMacro else { return }

        if let name = name {
            macro.name = name
        }

        macro.modifiedAt = Date()

        // Check if macro already exists and update it
        if let index = savedMacros.firstIndex(where: { $0.id == macro.id }) {
            savedMacros[index] = macro
        } else {
            savedMacros.append(macro)
        }

        saveMacros()
    }

    func deleteMacro(_ macro: Macro) {
        savedMacros.removeAll { $0.id == macro.id }
        saveMacros()
    }

    func loadMacro(_ macro: Macro) {
        currentMacro = macro
    }

    // MARK: - Playback

    func play(macro: Macro, mode: PlaybackMode = .once, speed: Double = 1.0) {
        guard !isPlaying else { return }
        eventPlayer.play(events: macro.events, mode: mode, speed: speed)
    }

    func stopPlayback() {
        eventPlayer.stop()
    }

    // MARK: - Event Editing

    func updateEventDelay(eventId: UUID, newDelay: TimeInterval) {
        guard var macro = currentMacro else { return }

        if let index = macro.events.firstIndex(where: { $0.id == eventId }) {
            macro.events[index].delay = newDelay
            currentMacro = macro
        }
    }

    func insertEvent(_ event: MacroEvent, at index: Int) {
        guard var macro = currentMacro else { return }

        if index >= 0 && index <= macro.events.count {
            macro.events.insert(event, at: index)
            currentMacro = macro
        }
    }

    func removeEvent(eventId: UUID) {
        guard var macro = currentMacro else { return }

        macro.events.removeAll { $0.id == eventId }
        currentMacro = macro
    }

    func updateEvent(_ event: MacroEvent) {
        guard var macro = currentMacro else { return }

        if let index = macro.events.firstIndex(where: { $0.id == event.id }) {
            macro.events[index] = event
            currentMacro = macro
        }
    }

    func moveEvent(from sourceIndex: Int, to destinationIndex: Int) {
        guard var macro = currentMacro else { return }
        guard sourceIndex >= 0 && sourceIndex < macro.events.count else { return }
        guard destinationIndex >= 0 && destinationIndex <= macro.events.count else { return }

        let event = macro.events.remove(at: sourceIndex)
        let adjustedDestination = sourceIndex < destinationIndex ? destinationIndex - 1 : destinationIndex
        macro.events.insert(event, at: adjustedDestination)

        // Recalculate delays after reordering
        macro.updateDelays()
        currentMacro = macro
    }

    // MARK: - Persistence

    private func saveMacros() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(savedMacros)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("Failed to save macros: \(error)")
        }
    }

    private func loadMacros() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            savedMacros = try decoder.decode([Macro].self, from: data)
        } catch {
            print("Failed to load macros: \(error)")
        }
    }

    // MARK: - Import/Export

    func exportMacro(_ macro: Macro, to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(macro)
        try data.write(to: url)
    }

    func importMacro(from url: URL) throws -> Macro {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Macro.self, from: data)
    }
}
