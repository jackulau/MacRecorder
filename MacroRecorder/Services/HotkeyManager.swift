//
//  HotkeyManager.swift
//  MacroRecorder
//

import Foundation
import Carbon
import AppKit

// HotkeyConfig is now defined in Models/HotkeyConfig.swift

class HotkeyManager: ObservableObject {
    @Published var recordingHotkey: (keyCode: UInt32, modifiers: UInt32)
    @Published var playbackHotkey: (keyCode: UInt32, modifiers: UInt32)

    private var recordingEventHandler: EventHotKeyRef?
    private var playbackEventHandler: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?

    var onRecordingTriggered: (() -> Void)?
    var onPlaybackTriggered: (() -> Void)?

    init() {
        // Load custom hotkeys from UserDefaults or use defaults
        if let data = UserDefaults.standard.data(forKey: "recordingHotkeyData"),
           let config = try? JSONDecoder().decode(HotkeyConfig.self, from: data) {
            self.recordingHotkey = (keyCode: config.keyCode, modifiers: config.modifiers)
        } else {
            let defaultConfig = HotkeyConfig.defaultRecording
            self.recordingHotkey = (keyCode: defaultConfig.keyCode, modifiers: defaultConfig.modifiers)
        }

        if let data = UserDefaults.standard.data(forKey: "playbackHotkeyData"),
           let config = try? JSONDecoder().decode(HotkeyConfig.self, from: data) {
            self.playbackHotkey = (keyCode: config.keyCode, modifiers: config.modifiers)
        } else {
            let defaultConfig = HotkeyConfig.defaultPlayback
            self.playbackHotkey = (keyCode: defaultConfig.keyCode, modifiers: defaultConfig.modifiers)
        }
    }

    func registerHotkeys() {
        // Install event handler
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        let handler: EventHandlerUPP = { (nextHandler, theEvent, userData) -> OSStatus in
            guard let userData = userData else { return OSStatus(eventNotHandledErr) }

            var hotKeyID = EventHotKeyID()
            let status = GetEventParameter(
                theEvent,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hotKeyID
            )

            guard status == noErr else { return status }

            let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()

            if hotKeyID.id == 1 {
                DispatchQueue.main.async {
                    manager.onRecordingTriggered?()
                }
            } else if hotKeyID.id == 2 {
                DispatchQueue.main.async {
                    manager.onPlaybackTriggered?()
                }
            }

            return noErr
        }

        let selfPointer = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(GetApplicationEventTarget(), handler, 1, &eventType, selfPointer, &eventHandler)

        // Register recording hotkey
        let recordingID = EventHotKeyID(signature: OSType(0x52454344), id: 1) // 'RECD'
        RegisterEventHotKey(
            recordingHotkey.keyCode,
            recordingHotkey.modifiers,
            recordingID,
            GetApplicationEventTarget(),
            0,
            &recordingEventHandler
        )

        // Register playback hotkey
        let playbackID = EventHotKeyID(signature: OSType(0x504C4159), id: 2) // 'PLAY'
        RegisterEventHotKey(
            playbackHotkey.keyCode,
            playbackHotkey.modifiers,
            playbackID,
            GetApplicationEventTarget(),
            0,
            &playbackEventHandler
        )
    }

    func unregisterHotkeys() {
        if let handler = recordingEventHandler {
            UnregisterEventHotKey(handler)
            recordingEventHandler = nil
        }

        if let handler = playbackEventHandler {
            UnregisterEventHotKey(handler)
            playbackEventHandler = nil
        }

        if let handler = eventHandler {
            RemoveEventHandler(handler)
            eventHandler = nil
        }
    }

    func reloadHotkeys() {
        // Unregister existing hotkeys
        unregisterHotkeys()

        // Reload from UserDefaults
        if let data = UserDefaults.standard.data(forKey: "recordingHotkeyData"),
           let config = try? JSONDecoder().decode(HotkeyConfig.self, from: data) {
            self.recordingHotkey = (keyCode: config.keyCode, modifiers: config.modifiers)
        }

        if let data = UserDefaults.standard.data(forKey: "playbackHotkeyData"),
           let config = try? JSONDecoder().decode(HotkeyConfig.self, from: data) {
            self.playbackHotkey = (keyCode: config.keyCode, modifiers: config.modifiers)
        }

        // Re-register with new hotkeys
        registerHotkeys()
    }

    deinit {
        unregisterHotkeys()
    }
}

// Helper to convert key code and modifiers to string representation
extension HotkeyManager {
    func hotkeyString(keyCode: UInt32, modifiers: UInt32) -> String {
        let config = HotkeyConfig(keyCode: keyCode, modifiers: modifiers)
        return config.displayString
    }
}
