//
//  HotkeyManager.swift
//  MacroRecorder
//

import Foundation
import Carbon
import AppKit

struct HotkeyConfig: Codable, Equatable {
    var keyCode: UInt32
    var modifiers: UInt32

    var displayString: String {
        var parts: [String] = []

        if modifiers & UInt32(cmdKey) != 0 {
            parts.append("⌘")
        }
        if modifiers & UInt32(shiftKey) != 0 {
            parts.append("⇧")
        }
        if modifiers & UInt32(optionKey) != 0 {
            parts.append("⌥")
        }
        if modifiers & UInt32(controlKey) != 0 {
            parts.append("⌃")
        }

        parts.append(keyCodeToString(keyCode: UInt16(keyCode)))
        return parts.joined()
    }

    private func keyCodeToString(keyCode: UInt16) -> String {
        let keyCodes: [UInt16: String] = [
            0x00: "A", 0x01: "S", 0x02: "D", 0x03: "F", 0x04: "H", 0x05: "G",
            0x06: "Z", 0x07: "X", 0x08: "C", 0x09: "V", 0x0B: "B", 0x0C: "Q",
            0x0D: "W", 0x0E: "E", 0x0F: "R", 0x10: "Y", 0x11: "T", 0x12: "1",
            0x13: "2", 0x14: "3", 0x15: "4", 0x16: "6", 0x17: "5", 0x18: "=",
            0x19: "9", 0x1A: "7", 0x1B: "-", 0x1C: "8", 0x1D: "0", 0x1E: "]",
            0x1F: "O", 0x20: "U", 0x21: "[", 0x22: "I", 0x23: "P", 0x25: "L",
            0x26: "J", 0x27: "'", 0x28: "K", 0x29: ";", 0x2A: "\\", 0x2B: ",",
            0x2C: "/", 0x2D: "N", 0x2E: "M", 0x2F: ".", 0x32: "`",
            0x24: "↩", 0x30: "⇥", 0x31: "␣", 0x33: "⌫", 0x35: "⎋",
            0x7A: "F1", 0x78: "F2", 0x63: "F3", 0x76: "F4", 0x60: "F5",
            0x61: "F6", 0x62: "F7", 0x64: "F8", 0x65: "F9", 0x6D: "F10",
            0x67: "F11", 0x6F: "F12"
        ]

        return keyCodes[keyCode] ?? "?"
    }
}

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
            self.recordingHotkey = (keyCode: 0x2C, modifiers: UInt32(cmdKey | shiftKey))
        }

        if let data = UserDefaults.standard.data(forKey: "playbackHotkeyData"),
           let config = try? JSONDecoder().decode(HotkeyConfig.self, from: data) {
            self.playbackHotkey = (keyCode: config.keyCode, modifiers: config.modifiers)
        } else {
            self.playbackHotkey = (keyCode: 0x23, modifiers: UInt32(cmdKey | shiftKey))
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
        var parts: [String] = []

        if modifiers & UInt32(cmdKey) != 0 {
            parts.append("⌘")
        }
        if modifiers & UInt32(shiftKey) != 0 {
            parts.append("⇧")
        }
        if modifiers & UInt32(optionKey) != 0 {
            parts.append("⌥")
        }
        if modifiers & UInt32(controlKey) != 0 {
            parts.append("⌃")
        }

        // Get key name from keycode (simplified)
        let keyName = keyCodeToString(keyCode: UInt16(keyCode))
        parts.append(keyName)

        return parts.joined()
    }

    private func keyCodeToString(keyCode: UInt16) -> String {
        let keyCodes: [UInt16: String] = [
            0x00: "A", 0x01: "S", 0x02: "D", 0x03: "F", 0x04: "H", 0x05: "G",
            0x06: "Z", 0x07: "X", 0x08: "C", 0x09: "V", 0x0B: "B", 0x0C: "Q",
            0x0D: "W", 0x0E: "E", 0x0F: "R", 0x10: "Y", 0x11: "T", 0x12: "1",
            0x13: "2", 0x14: "3", 0x15: "4", 0x16: "6", 0x17: "5", 0x18: "=",
            0x19: "9", 0x1A: "7", 0x1B: "-", 0x1C: "8", 0x1D: "0", 0x1E: "]",
            0x1F: "O", 0x20: "U", 0x21: "[", 0x22: "I", 0x23: "P", 0x25: "L",
            0x26: "J", 0x27: "'", 0x28: "K", 0x29: ";", 0x2A: "\\", 0x2B: ",",
            0x2C: "/", 0x2D: "N", 0x2E: "M", 0x2F: ".", 0x32: "`",
            0x24: "↩", 0x30: "⇥", 0x31: "␣", 0x33: "⌫", 0x35: "⎋"
        ]

        return keyCodes[keyCode] ?? "?"
    }
}
