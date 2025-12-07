//
//  EventListView.swift
//  MacroRecorder
//

import SwiftUI
import UniformTypeIdentifiers

struct EventListView: View {
    let macro: Macro
    @ObservedObject var session: MacroSession
    let currentEventIndex: Int

    @State private var selectedEvents: Set<UUID> = []
    @State private var lastSelectedIndex: Int?
    @State private var showingEventEditor = false
    @State private var editingEvent: MacroEvent?
    @State private var showingEventCreator = false
    @State private var draggedEventIndex: Int?

    var body: some View {
        VStack(spacing: 0) {
            // Timeline visualization
            TimelineView(
                events: macro.events,
                currentEventIndex: currentEventIndex,
                isPlaying: session.isPlaying
            )
            .frame(height: 100)
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // Event list header
            HStack {
                if !selectedEvents.isEmpty {
                    HStack(spacing: 4) {
                        Text("\(selectedEvents.count)")
                            .fontWeight(.medium)
                            .foregroundColor(.accentColor)
                        Text("selected")
                            .foregroundColor(.accentColor)
                    }
                    .font(.caption)
                    .frame(width: 100, alignment: .leading)
                } else {
                    Text("Event")
                        .frame(width: 100, alignment: .leading)
                }

                Text("Type")
                    .frame(width: 120, alignment: .leading)

                Text("Position")
                    .frame(width: 120, alignment: .leading)

                Text("Delay (s)")
                    .frame(width: 100, alignment: .leading)

                Spacer()

                HStack(spacing: 10) {
                    if !selectedEvents.isEmpty {
                        Button(action: {
                            selectedEvents.removeAll()
                            lastSelectedIndex = nil
                        }) {
                            Text("Clear")
                                .font(.caption)
                        }
                        .buttonStyle(.borderless)
                        .help("Clear Selection (Esc)")

                        Button(action: {
                            for eventId in selectedEvents {
                                session.removeEvent(eventId: eventId)
                            }
                            selectedEvents.removeAll()
                            lastSelectedIndex = nil
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.borderless)
                        .help("Delete Selected Events (⌫)")
                    }

                    Button(action: {
                        // Select all
                        selectedEvents.removeAll()
                        for event in macro.events {
                            selectedEvents.insert(event.id)
                        }
                        lastSelectedIndex = macro.events.count - 1
                    }) {
                        Image(systemName: "checkmark.square")
                    }
                    .buttonStyle(.borderless)
                    .help("Select All (⌘A)")

                    Button(action: {
                        showingEventCreator = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                    }
                    .buttonStyle(.borderless)
                    .help("Add New Event")
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // Event list with optimized rendering
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 2, pinnedViews: []) {
                        ForEach(Array(macro.events.enumerated()), id: \.element.id) { index, event in
                            EventRow(
                                event: event,
                                index: index,
                                isSelected: selectedEvents.contains(event.id),
                                isCurrent: currentEventIndex == index && session.isPlaying,
                                onEdit: {
                                    editingEvent = event
                                    showingEventEditor = true
                                },
                                onDelete: {
                                    session.removeEvent(eventId: event.id)
                                    selectedEvents.remove(event.id)
                                }
                            )
                            .id(event.id)
                            .padding(.horizontal)
                            .contentShape(Rectangle())
                            .onTapGesture(count: 1) {
                                let shiftPressed = NSEvent.modifierFlags.contains(.shift)
                                let cmdPressed = NSEvent.modifierFlags.contains(.command)
                                handleSelection(index: index, event: event, shiftPressed: shiftPressed, cmdPressed: cmdPressed)
                            }
                            .onDrag {
                                self.draggedEventIndex = index
                                return NSItemProvider(object: String(index) as NSString)
                            }
                            .onDrop(of: [.text], delegate: EventDropDelegate(
                                destinationIndex: index,
                                draggedIndex: $draggedEventIndex,
                                session: session
                            ))
                        }
                    }
                }
                .onChange(of: currentEventIndex) { newIndex in
                    if newIndex < macro.events.count {
                        withAnimation {
                            proxy.scrollTo(macro.events[newIndex].id, anchor: .center)
                        }
                    }
                }
            }
        }
        .onAppear {
            // Ensure we can receive key events
            DispatchQueue.main.async {
                NSApp.keyWindow?.makeFirstResponder(nil)
            }
        }
        .sheet(isPresented: $showingEventEditor) {
            if let event = editingEvent {
                EventEditorView(
                    event: event,
                    onSave: { updatedEvent in
                        session.updateEvent(updatedEvent)
                        showingEventEditor = false
                    },
                    onCancel: {
                        showingEventEditor = false
                    }
                )
            }
        }
        .sheet(isPresented: $showingEventCreator) {
            EventCreatorView(
                onSave: { newEvent in
                    session.insertEvent(newEvent, at: macro.events.count)
                    showingEventCreator = false
                },
                onCancel: {
                    showingEventCreator = false
                }
            )
        }
    }

    private func handleSelection(index: Int, event: MacroEvent, shiftPressed: Bool, cmdPressed: Bool) {
        if shiftPressed {
            // Shift-click: select range
            if let lastIndex = lastSelectedIndex {
                let startIndex = min(lastIndex, index)
                let endIndex = max(lastIndex, index)

                // Add to existing selection when shift is pressed
                for i in startIndex...endIndex {
                    if i < macro.events.count {
                        selectedEvents.insert(macro.events[i].id)
                    }
                }
            } else {
                // No previous selection, just select this one
                selectedEvents.insert(event.id)
                lastSelectedIndex = index
            }
        } else if cmdPressed {
            // Cmd-click: toggle selection
            if selectedEvents.contains(event.id) {
                selectedEvents.remove(event.id)
                // Update last selected index if we're removing
                if selectedEvents.isEmpty {
                    lastSelectedIndex = nil
                }
            } else {
                selectedEvents.insert(event.id)
                lastSelectedIndex = index
            }
        } else {
            // Regular click: replace selection
            selectedEvents = [event.id]
            lastSelectedIndex = index
        }
    }
}

struct EventRow: View {
    let event: MacroEvent
    let index: Int
    let isSelected: Bool
    let isCurrent: Bool
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 10) {
            // Index
            Text("\(index + 1)")
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 40, alignment: .leading)

            // Type icon
            Image(systemName: eventIcon)
                .foregroundColor(eventColor)
                .frame(width: 30)

            // Type name
            Text(eventTypeName)
                .frame(width: 120, alignment: .leading)

            // Position or key
            Text(eventDetails)
                .font(.system(.caption, design: .monospaced))
                .frame(width: 120, alignment: .leading)

            // Delay
            Text(String(format: "%.3f", event.delay))
                .font(.system(.body, design: .monospaced))
                .frame(width: 100, alignment: .leading)

            Spacer()

            if isHovering {
                HStack(spacing: 5) {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                    }
                    .buttonStyle(.borderless)

                    Button(action: onDelete) {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.borderless)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(backgroundColor)
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .onHover { hovering in
            isHovering = hovering
        }
        .contextMenu {
            Button(action: onEdit) {
                Label("Edit", systemImage: "pencil")
            }

            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private var backgroundColor: Color {
        if isCurrent {
            return Color.green.opacity(0.2)
        } else if isSelected {
            return Color.accentColor.opacity(0.1)
        } else {
            return Color.clear
        }
    }

    private var eventIcon: String {
        switch event.type {
        case .mouseLeftDown, .mouseLeftUp:
            return "cursorarrow.click"
        case .mouseRightDown, .mouseRightUp:
            return "cursorarrow.click.2"
        case .mouseMove:
            return "cursorarrow.rays"
        case .mouseDrag:
            return "cursorarrow.and.square.on.square.dashed"
        case .keyDown, .keyUp:
            return "keyboard"
        case .scroll:
            return "scroll"
        case .windowFocus:
            return "macwindow"
        case .appleScript, .appleScriptFile:
            return "applescript"
        case .conditionStart:
            return "arrow.branch"
        case .conditionElse:
            return "arrow.triangle.branch"
        case .conditionEnd:
            return "arrow.triangle.merge"
        case .loopStart:
            return "repeat"
        case .loopEnd:
            return "repeat.1"
        case .breakLoop:
            return "stop.circle"
        case .continueLoop:
            return "arrow.forward.to.line"
        case .clickImage, .waitForImage, .dragToImage:
            return "photo"
        }
    }

    private var eventColor: Color {
        switch event.type {
        case .mouseLeftDown, .mouseRightDown:
            return .blue
        case .mouseLeftUp, .mouseRightUp:
            return .cyan
        case .mouseMove:
            return .purple
        case .mouseDrag:
            return .orange
        case .keyDown:
            return .green
        case .keyUp:
            return .mint
        case .scroll:
            return .indigo
        case .windowFocus:
            return .yellow
        case .appleScript, .appleScriptFile:
            return .teal
        case .conditionStart, .conditionElse, .conditionEnd:
            return .pink
        case .loopStart, .loopEnd, .breakLoop, .continueLoop:
            return .brown
        case .clickImage, .waitForImage, .dragToImage:
            return .gray
        }
    }

    private var eventTypeName: String {
        return event.type.displayName
    }

    private var eventDetails: String {
        var details = ""

        switch event.type {
        case .mouseLeftDown, .mouseLeftUp, .mouseRightDown, .mouseRightUp, .mouseMove, .mouseDrag:
            if let pos = event.position {
                if let relPos = event.relativePosition {
                    // Show relative position if available
                    details = String(format: "(%.1f%%, %.1f%%)", relPos.x * 100, relPos.y * 100)
                } else {
                    details = "(\(Int(pos.x)), \(Int(pos.y)))"
                }
            }
        case .keyDown, .keyUp:
            if let keyCode = event.keyCode {
                details = "Key: \(keyCode)"
            }
        case .scroll:
            if let dx = event.scrollDeltaX, let dy = event.scrollDeltaY {
                details = "(\(Int(dx)), \(Int(dy)))"
            }
        case .windowFocus:
            if let windowInfo = event.windowInfo {
                details = windowInfo.windowTitle ?? "Window"
            }
        case .appleScript, .appleScriptFile:
            details = event.scriptContent != nil ? "Inline script" : (event.scriptPath ?? "Script")
        case .conditionStart, .conditionElse, .conditionEnd:
            details = event.controlFlowConfig?.condition?.displayString ?? "Condition"
        case .loopStart, .loopEnd:
            if let count = event.controlFlowConfig?.loopCount {
                details = "Count: \(count)"
            } else {
                details = "Loop"
            }
        case .breakLoop:
            details = "Exit loop"
        case .continueLoop:
            details = "Next iteration"
        case .clickImage, .waitForImage, .dragToImage:
            details = "Image match"
        }

        // Add window indicator if event has window info
        if event.windowInfo != nil && event.type != .windowFocus {
            return "🪟 " + (details.isEmpty ? "-" : details)
        }

        return details.isEmpty ? "-" : details
    }
}

struct TimelineView: View {
    let events: [MacroEvent]
    let currentEventIndex: Int
    let isPlaying: Bool

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                Rectangle()
                    .fill(Color(NSColor.controlBackgroundColor))

                // Timeline track
                Rectangle()
                    .fill(Color.secondary.opacity(0.1))
                    .frame(height: 4)
                    .padding(.horizontal, 20)

                // Events on timeline
                ForEach(Array(events.enumerated()), id: \.element.id) { index, event in
                    let position = calculatePosition(for: index, in: geometry.size.width)

                    Circle()
                        .fill(index == currentEventIndex && isPlaying ? Color.green : eventColor(for: event))
                        .frame(width: 8, height: 8)
                        .offset(x: position)
                }

                // Playhead
                if isPlaying && currentEventIndex < events.count {
                    let position = calculatePosition(for: currentEventIndex, in: geometry.size.width)

                    Rectangle()
                        .fill(Color.green)
                        .frame(width: 2)
                        .offset(x: position)
                }
            }
        }
    }

    private func calculatePosition(for index: Int, in width: CGFloat) -> CGFloat {
        let padding: CGFloat = 20
        let usableWidth = width - (padding * 2)

        guard events.count > 1 else {
            return padding + usableWidth / 2
        }

        let percentage = CGFloat(index) / CGFloat(events.count - 1)
        return padding + (usableWidth * percentage)
    }

    private func eventColor(for event: MacroEvent) -> Color {
        switch event.type {
        case .mouseLeftDown, .mouseLeftUp, .mouseRightDown, .mouseRightUp:
            return .blue
        case .mouseMove, .mouseDrag:
            return .purple
        case .keyDown, .keyUp:
            return .green
        case .scroll:
            return .orange
        case .windowFocus:
            return .yellow
        case .appleScript, .appleScriptFile:
            return .teal
        case .conditionStart, .conditionElse, .conditionEnd:
            return .pink
        case .loopStart, .loopEnd, .breakLoop, .continueLoop:
            return .brown
        case .clickImage, .waitForImage, .dragToImage:
            return .gray
        }
    }
}

struct EventDropDelegate: DropDelegate {
    let destinationIndex: Int
    @Binding var draggedIndex: Int?
    let session: MacroSession

    func performDrop(info: DropInfo) -> Bool {
        guard let draggedIndex = draggedIndex else { return false }

        if draggedIndex != destinationIndex {
            session.moveEvent(from: draggedIndex, to: destinationIndex)
        }

        self.draggedIndex = nil
        return true
    }

    func dropEntered(info: DropInfo) {
        guard let draggedIndex = draggedIndex else { return }

        if draggedIndex != destinationIndex {
            withAnimation(.default) {
                // Visual feedback could be added here
            }
        }
    }
}
