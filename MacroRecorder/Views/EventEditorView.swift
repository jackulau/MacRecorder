//
//  EventEditorView.swift
//  MacroRecorder
//

import SwiftUI

struct EventEditorView: View {
    let event: MacroEvent
    let onSave: (MacroEvent) -> Void
    let onCancel: () -> Void

    @State private var delay: Double
    @State private var positionX: String
    @State private var positionY: String

    init(event: MacroEvent, onSave: @escaping (MacroEvent) -> Void, onCancel: @escaping () -> Void) {
        self.event = event
        self.onSave = onSave
        self.onCancel = onCancel

        _delay = State(initialValue: event.delay)
        _positionX = State(initialValue: String(format: "%.1f", event.position?.x ?? 0))
        _positionY = State(initialValue: String(format: "%.1f", event.position?.y ?? 0))
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Edit Event")
                .font(.headline)

            Form {
                // Event type (read-only)
                LabeledContent("Type") {
                    Text(eventTypeName)
                        .foregroundColor(.secondary)
                }

                // Delay
                VStack(alignment: .leading, spacing: 5) {
                    LabeledContent("Delay (seconds)") {
                        TextField("", value: $delay, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                    }

                    Slider(value: $delay, in: 0...10, step: 0.01)
                        .frame(width: 300)

                    Text("Current: \(String(format: "%.3f", delay))s")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Position (if applicable)
                if event.position != nil {
                    Divider()

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Position")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        HStack {
                            VStack(alignment: .leading) {
                                Text("X")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                TextField("X", text: $positionX)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 100)
                            }

                            VStack(alignment: .leading) {
                                Text("Y")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                TextField("Y", text: $positionY)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 100)
                            }
                        }
                    }
                }

                // Key code (if applicable)
                if let keyCode = event.keyCode {
                    Divider()

                    LabeledContent("Key Code") {
                        Text("\(keyCode)")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()

            // Buttons
            HStack(spacing: 10) {
                Button("Cancel") {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)

                Button("Save") {
                    saveChanges()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 450, height: 400)
    }

    private var eventTypeName: String {
        switch event.type {
        case .mouseLeftDown:
            return "Left Mouse Down"
        case .mouseLeftUp:
            return "Left Mouse Up"
        case .mouseRightDown:
            return "Right Mouse Down"
        case .mouseRightUp:
            return "Right Mouse Up"
        case .mouseMove:
            return "Mouse Move"
        case .mouseDrag:
            return "Mouse Drag"
        case .keyDown:
            return "Key Down"
        case .keyUp:
            return "Key Up"
        case .scroll:
            return "Scroll"
        case .windowFocus:
            return "Window Focus"
        }
    }

    private func saveChanges() {
        var updatedEvent = event

        // Update delay
        updatedEvent.delay = delay

        // Update position if applicable
        if event.position != nil,
           let x = Double(positionX),
           let y = Double(positionY) {
            updatedEvent = MacroEvent(
                id: updatedEvent.id,
                type: updatedEvent.type,
                timestamp: updatedEvent.timestamp,
                position: CGPoint(x: x, y: y),
                keyCode: updatedEvent.keyCode,
                flags: updatedEvent.flags,
                scrollDeltaX: updatedEvent.scrollDeltaX,
                scrollDeltaY: updatedEvent.scrollDeltaY,
                delay: delay
            )
        }

        onSave(updatedEvent)
    }
}

struct EventCreatorView: View {
    let onSave: (MacroEvent) -> Void
    let onCancel: () -> Void

    @State private var eventType: EventType = .mouseLeftDown
    @State private var delay: Double = 0.5
    @State private var positionX: String = "0"
    @State private var positionY: String = "0"
    @State private var keyCode: String = "0"
    @State private var scrollDeltaX: String = "0"
    @State private var scrollDeltaY: String = "0"

    var body: some View {
        VStack(spacing: 20) {
            Text("Create New Event")
                .font(.headline)

            Form {
                // Event type selector
                Picker("Event Type", selection: $eventType) {
                    Text("Left Mouse Down").tag(EventType.mouseLeftDown)
                    Text("Left Mouse Up").tag(EventType.mouseLeftUp)
                    Text("Right Mouse Down").tag(EventType.mouseRightDown)
                    Text("Right Mouse Up").tag(EventType.mouseRightUp)
                    Text("Mouse Move").tag(EventType.mouseMove)
                    Text("Mouse Drag").tag(EventType.mouseDrag)
                    Text("Key Down").tag(EventType.keyDown)
                    Text("Key Up").tag(EventType.keyUp)
                    Text("Scroll").tag(EventType.scroll)
                }

                // Delay
                VStack(alignment: .leading, spacing: 5) {
                    LabeledContent("Delay (seconds)") {
                        TextField("", value: $delay, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                    }

                    Slider(value: $delay, in: 0...10, step: 0.01)
                        .frame(width: 300)

                    Text("Current: \(String(format: "%.3f", delay))s")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Position (for mouse events)
                if isMouseEvent {
                    Divider()

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Position")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        HStack {
                            VStack(alignment: .leading) {
                                Text("X")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                TextField("X", text: $positionX)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 100)
                            }

                            VStack(alignment: .leading) {
                                Text("Y")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                TextField("Y", text: $positionY)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 100)
                            }
                        }

                        Button("Use Current Mouse Position") {
                            let mouseLocation = NSEvent.mouseLocation
                            let screenHeight = NSScreen.main?.frame.height ?? 0
                            // Convert from Cocoa coordinates (bottom-left origin) to Quartz coordinates (top-left origin)
                            let y = screenHeight - mouseLocation.y
                            positionX = String(format: "%.1f", mouseLocation.x)
                            positionY = String(format: "%.1f", y)
                        }
                        .buttonStyle(.borderless)
                    }
                }

                // Key code (for keyboard events)
                if isKeyboardEvent {
                    Divider()

                    VStack(alignment: .leading, spacing: 5) {
                        LabeledContent("Key Code") {
                            TextField("Key Code", text: $keyCode)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 100)
                        }

                        Text("Enter the virtual key code (e.g., 0 for A, 1 for S)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Scroll delta (for scroll events)
                if isScrollEvent {
                    Divider()

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Scroll Delta")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        HStack {
                            VStack(alignment: .leading) {
                                Text("X (horizontal)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                TextField("Delta X", text: $scrollDeltaX)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 100)
                            }

                            VStack(alignment: .leading) {
                                Text("Y (vertical)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                TextField("Delta Y", text: $scrollDeltaY)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 100)
                            }
                        }
                    }
                }
            }
            .padding()

            // Buttons
            HStack(spacing: 10) {
                Button("Cancel") {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)

                Button("Create") {
                    createEvent()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 500, height: 500)
    }

    private var isMouseEvent: Bool {
        switch eventType {
        case .mouseLeftDown, .mouseLeftUp, .mouseRightDown, .mouseRightUp, .mouseMove, .mouseDrag:
            return true
        default:
            return false
        }
    }

    private var isKeyboardEvent: Bool {
        switch eventType {
        case .keyDown, .keyUp:
            return true
        default:
            return false
        }
    }

    private var isScrollEvent: Bool {
        eventType == .scroll
    }

    private func createEvent() {
        let timestamp = Date().timeIntervalSince1970

        var position: CGPoint?
        if isMouseEvent, let x = Double(positionX), let y = Double(positionY) {
            position = CGPoint(x: x, y: y)
        }

        var eventKeyCode: UInt16?
        if isKeyboardEvent, let code = UInt16(keyCode) {
            eventKeyCode = code
        }

        var deltaX: Double?
        var deltaY: Double?
        if isScrollEvent {
            deltaX = Double(scrollDeltaX)
            deltaY = Double(scrollDeltaY)
        }

        let newEvent = MacroEvent(
            type: eventType,
            timestamp: timestamp,
            position: position,
            keyCode: eventKeyCode,
            flags: nil,
            scrollDeltaX: deltaX,
            scrollDeltaY: deltaY,
            delay: delay
        )

        onSave(newEvent)
    }
}
