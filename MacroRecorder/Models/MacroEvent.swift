//
//  MacroEvent.swift
//  MacroRecorder
//

import Foundation
import CoreGraphics

enum EventType: String, Codable {
    case mouseLeftDown
    case mouseLeftUp
    case mouseRightDown
    case mouseRightUp
    case mouseMove
    case mouseDrag
    case keyDown
    case keyUp
    case scroll
    case windowFocus  // New event type for window focus

    // AppleScript events
    case appleScript       // Execute inline AppleScript
    case appleScriptFile   // Execute AppleScript from file

    // Conditional/control flow events
    case conditionStart    // If condition begins
    case conditionElse     // Else branch
    case conditionEnd      // End of conditional block
    case loopStart         // Loop begins
    case loopEnd           // Loop ends
    case breakLoop         // Break out of loop
    case continueLoop      // Continue to next iteration

    // Image-based events
    case clickImage        // Click on found image
    case waitForImage      // Wait for image to appear
    case dragToImage       // Drag to image location

    var displayName: String {
        switch self {
        case .mouseLeftDown: return "Left Click Down"
        case .mouseLeftUp: return "Left Click Up"
        case .mouseRightDown: return "Right Click Down"
        case .mouseRightUp: return "Right Click Up"
        case .mouseMove: return "Mouse Move"
        case .mouseDrag: return "Mouse Drag"
        case .keyDown: return "Key Down"
        case .keyUp: return "Key Up"
        case .scroll: return "Scroll"
        case .windowFocus: return "Window Focus"
        case .appleScript: return "AppleScript"
        case .appleScriptFile: return "AppleScript File"
        case .conditionStart: return "If Condition"
        case .conditionElse: return "Else"
        case .conditionEnd: return "End If"
        case .loopStart: return "Loop Start"
        case .loopEnd: return "Loop End"
        case .breakLoop: return "Break"
        case .continueLoop: return "Continue"
        case .clickImage: return "Click Image"
        case .waitForImage: return "Wait For Image"
        case .dragToImage: return "Drag To Image"
        }
    }

    var isControlFlow: Bool {
        switch self {
        case .conditionStart, .conditionElse, .conditionEnd,
             .loopStart, .loopEnd, .breakLoop, .continueLoop:
            return true
        default:
            return false
        }
    }
}

// Window information for window-specific recording
struct WindowInfo: Codable {
    let processID: Int32
    let bundleIdentifier: String?
    let windowTitle: String?
    let windowBounds: CGRect  // Window frame at recording time
    let isActive: Bool  // Whether window was focused
    let windowID: CGWindowID?  // Window ID for capturing snapshots

    // Calculate relative position within window
    func relativePosition(from absolutePosition: CGPoint) -> CGPoint {
        return CGPoint(
            x: (absolutePosition.x - windowBounds.origin.x) / windowBounds.width,
            y: (absolutePosition.y - windowBounds.origin.y) / windowBounds.height
        )
    }

    // Convert relative position back to absolute based on current window size
    func absolutePosition(from relativePosition: CGPoint, currentBounds: CGRect) -> CGPoint {
        return CGPoint(
            x: currentBounds.origin.x + (relativePosition.x * currentBounds.width),
            y: currentBounds.origin.y + (relativePosition.y * currentBounds.height)
        )
    }
}

struct MacroEvent: Codable, Identifiable {
    let id: UUID
    let type: EventType
    let timestamp: TimeInterval
    let position: CGPoint?
    let keyCode: UInt16?
    let flags: UInt64?
    let scrollDeltaX: Double?
    let scrollDeltaY: Double?

    // Legacy delay field - kept for backward compatibility
    private var _delay: TimeInterval

    // New delay configuration - supports fixed, random, variable, expression
    var delayConfig: DelayConfig?

    /// Computed delay property for backward compatibility
    /// Gets: returns fixed value from delayConfig, or legacy _delay
    /// Sets: updates both _delay and delayConfig
    var delay: TimeInterval {
        get {
            if let config = delayConfig {
                return config.fixedValue ?? _delay
            }
            return _delay
        }
        set {
            _delay = newValue
            delayConfig = .fixed(newValue)
        }
    }

    // Window-specific recording fields
    let windowInfo: WindowInfo?  // Window information at time of recording
    let relativePosition: CGPoint?  // Position relative to window (0-1 range)

    // AppleScript fields
    var scriptContent: String?          // Inline AppleScript code
    var scriptPath: String?             // Path to AppleScript file
    var scriptTimeout: TimeInterval?    // Max execution time
    var captureScriptOutput: Bool?      // Whether to capture output
    var outputVariableName: String?     // Variable to store output

    // Control flow fields
    var controlFlowConfig: ControlFlowConfig?  // Condition/loop configuration

    // Image-based event fields
    var imageEventConfig: ImageEventConfig?    // Image template configuration

    // Custom coding keys to handle the private _delay field
    enum CodingKeys: String, CodingKey {
        case id, type, timestamp, position, keyCode, flags
        case scrollDeltaX, scrollDeltaY
        case _delay = "delay"  // Map _delay to "delay" in JSON
        case delayConfig
        case windowInfo, relativePosition
        case scriptContent, scriptPath, scriptTimeout, captureScriptOutput, outputVariableName
        case controlFlowConfig, imageEventConfig
    }

    init(
        id: UUID = UUID(),
        type: EventType,
        timestamp: TimeInterval,
        position: CGPoint? = nil,
        keyCode: UInt16? = nil,
        flags: UInt64? = nil,
        scrollDeltaX: Double? = nil,
        scrollDeltaY: Double? = nil,
        delay: TimeInterval = 0,
        delayConfig: DelayConfig? = nil,
        windowInfo: WindowInfo? = nil,
        relativePosition: CGPoint? = nil,
        scriptContent: String? = nil,
        scriptPath: String? = nil,
        scriptTimeout: TimeInterval? = nil,
        captureScriptOutput: Bool? = nil,
        outputVariableName: String? = nil,
        controlFlowConfig: ControlFlowConfig? = nil,
        imageEventConfig: ImageEventConfig? = nil
    ) {
        self.id = id
        self.type = type
        self.timestamp = timestamp
        self.position = position
        self.keyCode = keyCode
        self.flags = flags
        self.scrollDeltaX = scrollDeltaX
        self.scrollDeltaY = scrollDeltaY
        self._delay = delay
        self.delayConfig = delayConfig ?? .fixed(delay)
        self.windowInfo = windowInfo
        self.relativePosition = relativePosition
        self.scriptContent = scriptContent
        self.scriptPath = scriptPath
        self.scriptTimeout = scriptTimeout
        self.captureScriptOutput = captureScriptOutput
        self.outputVariableName = outputVariableName
        self.controlFlowConfig = controlFlowConfig
        self.imageEventConfig = imageEventConfig
    }

    // Custom decoder to handle legacy macros without new fields
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        type = try container.decode(EventType.self, forKey: .type)
        timestamp = try container.decode(TimeInterval.self, forKey: .timestamp)
        position = try container.decodeIfPresent(CGPoint.self, forKey: .position)
        keyCode = try container.decodeIfPresent(UInt16.self, forKey: .keyCode)
        flags = try container.decodeIfPresent(UInt64.self, forKey: .flags)
        scrollDeltaX = try container.decodeIfPresent(Double.self, forKey: .scrollDeltaX)
        scrollDeltaY = try container.decodeIfPresent(Double.self, forKey: .scrollDeltaY)
        _delay = try container.decode(TimeInterval.self, forKey: ._delay)
        windowInfo = try container.decodeIfPresent(WindowInfo.self, forKey: .windowInfo)
        relativePosition = try container.decodeIfPresent(CGPoint.self, forKey: .relativePosition)

        // Try to decode delayConfig, fallback to creating from legacy delay
        if let config = try container.decodeIfPresent(DelayConfig.self, forKey: .delayConfig) {
            delayConfig = config
        } else {
            delayConfig = .fixed(_delay)
        }

        // Decode new optional fields (nil for legacy macros)
        scriptContent = try container.decodeIfPresent(String.self, forKey: .scriptContent)
        scriptPath = try container.decodeIfPresent(String.self, forKey: .scriptPath)
        scriptTimeout = try container.decodeIfPresent(TimeInterval.self, forKey: .scriptTimeout)
        captureScriptOutput = try container.decodeIfPresent(Bool.self, forKey: .captureScriptOutput)
        outputVariableName = try container.decodeIfPresent(String.self, forKey: .outputVariableName)
        controlFlowConfig = try container.decodeIfPresent(ControlFlowConfig.self, forKey: .controlFlowConfig)
        imageEventConfig = try container.decodeIfPresent(ImageEventConfig.self, forKey: .imageEventConfig)
    }

    // Create from CGEvent
    static func from(cgEvent: CGEvent, delay: TimeInterval = 0) -> MacroEvent? {
        let timestamp = Date().timeIntervalSince1970
        let eventType = cgEvent.type

        let type: EventType?
        switch eventType {
        case .leftMouseDown:
            type = .mouseLeftDown
        case .leftMouseUp:
            type = .mouseLeftUp
        case .rightMouseDown:
            type = .mouseRightDown
        case .rightMouseUp:
            type = .mouseRightUp
        case .mouseMoved:
            type = .mouseMove
        case .leftMouseDragged, .rightMouseDragged:
            type = .mouseDrag
        case .keyDown:
            type = .keyDown
        case .keyUp:
            type = .keyUp
        case .scrollWheel:
            type = .scroll
        default:
            return nil
        }

        guard let eventType = type else { return nil }

        let position = cgEvent.location
        let keyCode = eventType == .keyDown || eventType == .keyUp
            ? UInt16(cgEvent.getIntegerValueField(.keyboardEventKeycode))
            : nil
        let flags = cgEvent.flags.rawValue

        let scrollDeltaX = eventType == .scroll
            ? Double(cgEvent.getIntegerValueField(.scrollWheelEventDeltaAxis2))
            : nil
        let scrollDeltaY = eventType == .scroll
            ? Double(cgEvent.getIntegerValueField(.scrollWheelEventDeltaAxis1))
            : nil

        return MacroEvent(
            type: eventType,
            timestamp: timestamp,
            position: position,
            keyCode: keyCode,
            flags: flags,
            scrollDeltaX: scrollDeltaX,
            scrollDeltaY: scrollDeltaY,
            delay: delay
        )
    }

    // Create CGEvent for playback
    func toCGEvent() -> CGEvent? {
        // These event types don't generate CGEvents - they're handled by EventPlayer
        switch type {
        case .windowFocus, .appleScript, .appleScriptFile,
             .conditionStart, .conditionElse, .conditionEnd,
             .loopStart, .loopEnd, .breakLoop, .continueLoop,
             .clickImage, .waitForImage, .dragToImage:
            return nil
        default:
            break
        }

        let eventType: CGEventType

        switch type {
        case .mouseLeftDown:
            eventType = .leftMouseDown
        case .mouseLeftUp:
            eventType = .leftMouseUp
        case .mouseRightDown:
            eventType = .rightMouseDown
        case .mouseRightUp:
            eventType = .rightMouseUp
        case .mouseMove:
            eventType = .mouseMoved
        case .mouseDrag:
            eventType = .leftMouseDragged
        case .keyDown:
            eventType = .keyDown
        case .keyUp:
            eventType = .keyUp
        case .scroll:
            eventType = .scrollWheel
        case .windowFocus, .appleScript, .appleScriptFile,
             .conditionStart, .conditionElse, .conditionEnd,
             .loopStart, .loopEnd, .breakLoop, .continueLoop,
             .clickImage, .waitForImage, .dragToImage:
            return nil  // Already handled above
        }

        var event: CGEvent?

        switch type {
        case .mouseLeftDown, .mouseLeftUp, .mouseRightDown, .mouseRightUp, .mouseMove, .mouseDrag:
            guard let position = position else { return nil }
            let mouseButton: CGMouseButton = type == .mouseRightDown || type == .mouseRightUp ? .right : .left
            event = CGEvent(mouseEventSource: nil, mouseType: eventType, mouseCursorPosition: position, mouseButton: mouseButton)

        case .keyDown, .keyUp:
            guard let keyCode = keyCode else { return nil }
            event = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: type == .keyDown)

        case .scroll:
            event = CGEvent(scrollWheelEvent2Source: nil,
                          units: .pixel,
                          wheelCount: 2,
                          wheel1: Int32(scrollDeltaY ?? 0),
                          wheel2: Int32(scrollDeltaX ?? 0),
                          wheel3: 0)
        case .windowFocus, .appleScript, .appleScriptFile,
             .conditionStart, .conditionElse, .conditionEnd,
             .loopStart, .loopEnd, .breakLoop, .continueLoop,
             .clickImage, .waitForImage, .dragToImage:
            return nil  // These don't generate CGEvents
        }

        if let flags = flags {
            event?.flags = CGEventFlags(rawValue: flags)
        }

        return event
    }
}

struct Macro: Codable, Identifiable {
    let id: UUID
    var name: String
    var events: [MacroEvent]
    let createdAt: Date
    var modifiedAt: Date

    init(id: UUID = UUID(), name: String, events: [MacroEvent] = []) {
        self.id = id
        self.name = name
        self.events = events
        self.createdAt = Date()
        self.modifiedAt = Date()
    }

    mutating func updateDelays() {
        guard events.count > 1 else { return }

        for i in 1..<events.count {
            events[i].delay = events[i].timestamp - events[i-1].timestamp
        }

        if !events.isEmpty {
            events[0].delay = 0
        }
    }
}
