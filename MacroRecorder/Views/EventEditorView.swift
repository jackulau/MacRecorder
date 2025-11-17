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
    @State private var showValidationError = false
    @State private var validationErrorMessage = ""

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                Text("Create New Event")
                    .font(.headline)
            }

            ScrollView {
                Form {
                    // Event type selector with categories
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Event Type")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Picker("", selection: $eventType) {
                            Text("Mouse Events").tag(EventType.mouseLeftDown)
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Group {
                                Text("  Left Mouse Down").tag(EventType.mouseLeftDown)
                                Text("  Left Mouse Up").tag(EventType.mouseLeftUp)
                                Text("  Right Mouse Down").tag(EventType.mouseRightDown)
                                Text("  Right Mouse Up").tag(EventType.mouseRightUp)
                                Text("  Mouse Move").tag(EventType.mouseMove)
                                Text("  Mouse Drag").tag(EventType.mouseDrag)
                            }

                            Divider()

                            Group {
                                Text("  Key Down").tag(EventType.keyDown)
                                Text("  Key Up").tag(EventType.keyUp)
                            }

                            Divider()

                            Text("  Scroll").tag(EventType.scroll)
                        }
                        .labelsHidden()

                        Text(eventTypeDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 4)
                    }

                    Divider()

                    // Delay
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text("Delay Before Event")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Image(systemName: "info.circle")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .help("Time to wait before executing this event")
                        }

                        HStack {
                            TextField("", value: $delay, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                            Text("seconds")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Slider(value: $delay, in: 0...10, step: 0.01)
                            .frame(maxWidth: 350)

                        Text("Current: \(String(format: "%.3f", delay))s")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // Position (for mouse events)
                    if isMouseEvent {
                        Divider()

                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Mouse Position")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Image(systemName: "info.circle")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .help("Screen coordinates where the event will occur")
                            }

                            HStack(spacing: 15) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("X (horizontal)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    TextField("X", text: $positionX)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 120)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Y (vertical)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    TextField("Y", text: $positionY)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 120)
                                }
                            }

                            Button(action: {
                                let mouseLocation = NSEvent.mouseLocation
                                let screenHeight = NSScreen.main?.frame.height ?? 0
                                // Convert from Cocoa coordinates (bottom-left origin) to Quartz coordinates (top-left origin)
                                let y = screenHeight - mouseLocation.y
                                positionX = String(format: "%.1f", mouseLocation.x)
                                positionY = String(format: "%.1f", y)
                            }) {
                                HStack {
                                    Image(systemName: "scope")
                                    Text("Capture Current Mouse Position")
                                }
                            }
                            .buttonStyle(.bordered)
                            .help("Click to use your current mouse position")
                        }
                    }

                    // Key code (for keyboard events)
                    if isKeyboardEvent {
                        Divider()

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Virtual Key Code")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Image(systemName: "info.circle")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .help("The macOS virtual key code for the key to press")
                            }

                            TextField("Key Code", text: $keyCode)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 120)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Common key codes:")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)

                                Group {
                                    Text("A=0, S=1, D=2, F=3, H=4, G=5, Z=6, X=7, C=8, V=9")
                                    Text("Return=36, Tab=48, Space=49, Delete=51, Escape=53")
                                    Text("Arrow Left=123, Right=124, Down=125, Up=126")
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                            .padding(.top, 4)
                        }
                    }

                    // Scroll delta (for scroll events)
                    if isScrollEvent {
                        Divider()

                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Scroll Amount")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Image(systemName: "info.circle")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .help("Positive values scroll down/right, negative values scroll up/left")
                            }

                            HStack(spacing: 15) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("X (horizontal)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    TextField("Delta X", text: $scrollDeltaX)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 120)
                                    Text("Positive = right")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Y (vertical)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    TextField("Delta Y", text: $scrollDeltaY)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 120)
                                    Text("Positive = down")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }

                            Text("Typical values range from -10 to 10")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
            }

            // Validation error
            if showValidationError {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(validationErrorMessage)
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                .padding(.horizontal)
            }

            // Buttons
            HStack(spacing: 10) {
                Button("Cancel") {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)

                Button("Create Event") {
                    if validateAndCreateEvent() {
                        // Event created successfully
                    }
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 550, height: 650)
    }

    private var eventTypeDescription: String {
        switch eventType {
        case .mouseLeftDown:
            return "Press the left mouse button"
        case .mouseLeftUp:
            return "Release the left mouse button"
        case .mouseRightDown:
            return "Press the right mouse button"
        case .mouseRightUp:
            return "Release the right mouse button"
        case .mouseMove:
            return "Move the mouse cursor to a position"
        case .mouseDrag:
            return "Drag the mouse while holding a button"
        case .keyDown:
            return "Press a keyboard key"
        case .keyUp:
            return "Release a keyboard key"
        case .scroll:
            return "Scroll the mouse wheel"
        case .windowFocus:
            return "Focus a specific window"
        }
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

    private func validateAndCreateEvent() -> Bool {
        // Reset validation state
        showValidationError = false
        validationErrorMessage = ""

        // Validate mouse events
        if isMouseEvent {
            guard let x = Double(positionX), let y = Double(positionY) else {
                showValidationError = true
                validationErrorMessage = "Please enter valid numbers for X and Y position"
                return false
            }

            if x < 0 || y < 0 {
                showValidationError = true
                validationErrorMessage = "Position values must be positive numbers"
                return false
            }
        }

        // Validate keyboard events
        if isKeyboardEvent {
            guard let code = UInt16(keyCode) else {
                showValidationError = true
                validationErrorMessage = "Please enter a valid key code (0-127)"
                return false
            }

            if code > 127 {
                showValidationError = true
                validationErrorMessage = "Key code must be between 0 and 127"
                return false
            }
        }

        // Validate scroll events
        if isScrollEvent {
            guard let _ = Double(scrollDeltaX), let _ = Double(scrollDeltaY) else {
                showValidationError = true
                validationErrorMessage = "Please enter valid numbers for scroll delta"
                return false
            }
        }

        // Validate delay
        if delay < 0 {
            showValidationError = true
            validationErrorMessage = "Delay must be a positive number"
            return false
        }

        // All validation passed, create the event
        createEvent()
        return true
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
