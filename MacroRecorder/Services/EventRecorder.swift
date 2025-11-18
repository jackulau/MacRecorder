//
//  EventRecorder.swift
//  MacroRecorder
//

import Foundation
import CoreGraphics
import Combine
import ApplicationServices
import Carbon
import AppKit

class EventRecorder: ObservableObject {
    @Published var isRecording = false
    @Published var recordedEvents: [MacroEvent] = []
    @Published var isWindowSpecificMode = false  // Toggle for window-specific recording
    @Published var targetWindow: WindowInfo?      // The window to record in

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var lastEventTime: TimeInterval = 0
    private var startTime: TimeInterval = 0
    private var windowDetector = WindowDetector.shared

    // Store hotkeys to filter them out during recording
    var recordingHotkey: (keyCode: UInt32, modifiers: UInt32)?
    var playbackHotkey: (keyCode: UInt32, modifiers: UInt32)?

    // Event masks for what we want to capture
    private var eventMask: CGEventMask {
        let mask1 = CGEventMask(1 << CGEventType.leftMouseDown.rawValue)
        let mask2 = CGEventMask(1 << CGEventType.leftMouseUp.rawValue)
        let mask3 = CGEventMask(1 << CGEventType.rightMouseDown.rawValue)
        let mask4 = CGEventMask(1 << CGEventType.rightMouseUp.rawValue)
        let mask5 = CGEventMask(1 << CGEventType.mouseMoved.rawValue)
        let mask6 = CGEventMask(1 << CGEventType.leftMouseDragged.rawValue)
        let mask7 = CGEventMask(1 << CGEventType.rightMouseDragged.rawValue)
        let mask8 = CGEventMask(1 << CGEventType.keyDown.rawValue)
        let mask9 = CGEventMask(1 << CGEventType.keyUp.rawValue)
        let mask10 = CGEventMask(1 << CGEventType.scrollWheel.rawValue)

        var result = mask1
        result |= mask2
        result |= mask3
        result |= mask4
        result |= mask5
        result |= mask6
        result |= mask7
        result |= mask8
        result |= mask9
        result |= mask10
        return result
    }

    func startRecording() {
        guard !isRecording else { return }

        // Check for accessibility permissions
        guard checkAccessibilityPermissions() else {
            NSLog("MacroRecorder: Accessibility permissions not granted")
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "Accessibility Permission Required"
                alert.informativeText = "Please grant MacroRecorder accessibility permission in System Settings > Privacy & Security > Accessibility, then restart the app."
                alert.alertStyle = .warning
                alert.addButton(withTitle: "Open System Settings")
                alert.addButton(withTitle: "OK")

                if alert.runModal() == .alertFirstButtonReturn {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
            return
        }

        recordedEvents.removeAll()
        startTime = Date().timeIntervalSince1970
        lastEventTime = startTime

        // Create event tap callback
        let callback: CGEventTapCallBack = { proxy, type, event, refcon in
            guard let refcon = refcon else { return Unmanaged.passUnretained(event) }

            let recorder = Unmanaged<EventRecorder>.fromOpaque(refcon).takeUnretainedValue()
            recorder.handleEvent(event: event, type: type)

            return Unmanaged.passUnretained(event)
        }

        // Create event tap
        let selfPointer = Unmanaged.passUnretained(self).toOpaque()
        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: eventMask,
            callback: callback,
            userInfo: selfPointer
        )

        guard let eventTap = eventTap else {
            NSLog("MacroRecorder: Failed to create event tap")
            return
        }

        // Create run loop source
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)

        guard let runLoopSource = runLoopSource else {
            NSLog("MacroRecorder: Failed to create run loop source")
            return
        }

        // Add to run loop
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)

        isRecording = true
    }

    func stopRecording() {
        guard isRecording else { return }

        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
        }

        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        }

        eventTap = nil
        runLoopSource = nil
        isRecording = false
    }

    private func handleEvent(event: CGEvent, type: CGEventType) {
        let currentTime = Date().timeIntervalSince1970
        let delay = recordedEvents.isEmpty ? 0 : currentTime - lastEventTime

        // Filter out hotkey events to prevent recording our own hotkeys
        if type == .keyDown || type == .keyUp {
            let keyCode = UInt32(event.getIntegerValueField(.keyboardEventKeycode))
            let flags = event.flags

            // Extract modifier flags
            let cmdPressed = flags.contains(.maskCommand)
            let shiftPressed = flags.contains(.maskShift)
            let optPressed = flags.contains(.maskAlternate)
            let ctrlPressed = flags.contains(.maskControl)

            // Check if this matches our recording hotkey
            if let recordingHotkey = recordingHotkey {
                if keyCode == recordingHotkey.keyCode {
                    let expectedCmd = (recordingHotkey.modifiers & UInt32(cmdKey)) != 0
                    let expectedShift = (recordingHotkey.modifiers & UInt32(shiftKey)) != 0
                    let expectedOpt = (recordingHotkey.modifiers & UInt32(optionKey)) != 0
                    let expectedCtrl = (recordingHotkey.modifiers & UInt32(controlKey)) != 0

                    if cmdPressed == expectedCmd && shiftPressed == expectedShift &&
                       optPressed == expectedOpt && ctrlPressed == expectedCtrl {
                        return // Filtered out recording hotkey
                    }
                }
            }

            // Check if this matches our playback hotkey
            if let playbackHotkey = playbackHotkey {
                if keyCode == playbackHotkey.keyCode {
                    let expectedCmd = (playbackHotkey.modifiers & UInt32(cmdKey)) != 0
                    let expectedShift = (playbackHotkey.modifiers & UInt32(shiftKey)) != 0
                    let expectedOpt = (playbackHotkey.modifiers & UInt32(optionKey)) != 0
                    let expectedCtrl = (playbackHotkey.modifiers & UInt32(controlKey)) != 0

                    if cmdPressed == expectedCmd && shiftPressed == expectedShift &&
                       optPressed == expectedOpt && ctrlPressed == expectedCtrl {
                        return // Filtered out playback hotkey
                    }
                }
            }
        }

        // Performance optimization: filter out excessive events
        if type == .mouseMoved {
            // Only record mouse moves if there's a significant delay
            if delay < 0.05 { // Reduced from 0.1 for smoother recording
                // Also check distance from last position if we have one
                if let lastEvent = recordedEvents.last,
                   let lastPos = lastEvent.position {
                    let currentPos = event.location
                    let distance = sqrt(pow(currentPos.x - lastPos.x, 2) + pow(currentPos.y - lastPos.y, 2))
                    if distance < 10 { // Skip if mouse moved less than 10 pixels
                        return
                    }
                } else {
                    return
                }
            }
        }

        // Limit total events for performance (optional safety limit)
        if recordedEvents.count >= 10000 {
            NSLog("MacroRecorder: Maximum event limit reached (10,000)")
            return
        }

        if var macroEvent = MacroEvent.from(cgEvent: event, delay: delay) {
            // If window-specific mode is enabled, capture window information
            if isWindowSpecificMode {
                if let position = macroEvent.position {
                    // Get window info at the event position
                    if let windowInfo = windowDetector.getWindowInfo(at: position) {
                        // If we have a target window, only record events in that window
                        if let target = targetWindow {
                            // Check if the event is in the target window
                            if windowInfo.processID != target.processID {
                                return // Skip events not in target window
                            }
                        }

                        // Calculate relative position within the window
                        let relativePos = windowInfo.relativePosition(from: position)

                        // Create new event with window information
                        macroEvent = MacroEvent(
                            id: macroEvent.id,
                            type: macroEvent.type,
                            timestamp: macroEvent.timestamp,
                            position: macroEvent.position,
                            keyCode: macroEvent.keyCode,
                            flags: macroEvent.flags,
                            scrollDeltaX: macroEvent.scrollDeltaX,
                            scrollDeltaY: macroEvent.scrollDeltaY,
                            delay: macroEvent.delay,
                            windowInfo: windowInfo,
                            relativePosition: relativePos
                        )

                        // Add window focus event if window changed
                        if let lastEvent = recordedEvents.last,
                           let lastWindow = lastEvent.windowInfo,
                           lastWindow.processID != windowInfo.processID {
                            // Insert a window focus event
                            let focusEvent = MacroEvent(
                                type: .windowFocus,
                                timestamp: currentTime,
                                delay: 0,
                                windowInfo: windowInfo,
                                relativePosition: nil
                            )
                            recordedEvents.append(focusEvent)
                        }
                    }
                } else if macroEvent.type == .keyDown || macroEvent.type == .keyUp {
                    // For keyboard events, get the frontmost window info
                    if let windowInfo = windowDetector.getFrontmostWindowInfo() {
                        // If we have a target window, only record events when it's focused
                        if let target = targetWindow {
                            if windowInfo.processID != target.processID {
                                return // Skip keyboard events when target window isn't focused
                            }
                        }

                        macroEvent = MacroEvent(
                            id: macroEvent.id,
                            type: macroEvent.type,
                            timestamp: macroEvent.timestamp,
                            position: macroEvent.position,
                            keyCode: macroEvent.keyCode,
                            flags: macroEvent.flags,
                            scrollDeltaX: macroEvent.scrollDeltaX,
                            scrollDeltaY: macroEvent.scrollDeltaY,
                            delay: macroEvent.delay,
                            windowInfo: windowInfo,
                            relativePosition: nil
                        )
                    }
                }
            }

            recordedEvents.append(macroEvent)
            lastEventTime = currentTime
        }
    }

    func checkAccessibilityPermissions() -> Bool {
        // Check without prompting - just return the status
        // The app will handle showing prompts at launch
        return AXIsProcessTrusted()
    }

    func clearRecording() {
        recordedEvents.removeAll()
    }
}
