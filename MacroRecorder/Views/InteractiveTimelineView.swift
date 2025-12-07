//
//  InteractiveTimelineView.swift
//  MacroRecorder
//
//  Interactive timeline for viewing and editing macro events
//

import SwiftUI

struct InteractiveTimelineView: View {
    @Binding var events: [MacroEvent]
    @Binding var selectedEventIds: Set<UUID>
    let isPlaying: Bool
    let currentEventIndex: Int

    @State private var zoomLevel: Double = 1.0
    @State private var scrollOffset: CGFloat = 0
    @State private var draggedEventId: UUID?
    @State private var editingEventId: UUID?

    private let trackHeight: CGFloat = 60
    private let nodeSize: CGFloat = 16
    private let minPixelsPerSecond: CGFloat = 50

    private var pixelsPerSecond: CGFloat {
        minPixelsPerSecond * zoomLevel
    }

    private var totalDuration: TimeInterval {
        events.reduce(0) { $0 + $1.delay }
    }

    private var timelineWidth: CGFloat {
        max(300, CGFloat(totalDuration) * pixelsPerSecond + 100)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            timelineToolbar

            Divider()

            // Timeline content
            ScrollView(.horizontal, showsIndicators: true) {
                ZStack(alignment: .topLeading) {
                    // Background with time markers
                    timeRuler

                    // Event track
                    eventTrack
                        .padding(.top, 30)

                    // Playhead
                    if isPlaying {
                        playhead
                    }
                }
                .frame(width: timelineWidth, height: trackHeight + 40)
            }
            .frame(height: trackHeight + 50)
            .background(Color(NSColor.controlBackgroundColor))
        }
        .popover(item: $editingEventId) { eventId in
            if let index = events.firstIndex(where: { $0.id == eventId }) {
                TimelinePopoverView(event: $events[index])
            }
        }
    }

    // MARK: - Subviews

    private var timelineToolbar: some View {
        HStack {
            Text("Timeline")
                .font(.headline)

            Spacer()

            // Zoom controls
            HStack(spacing: 8) {
                Button {
                    withAnimation { zoomLevel = max(0.25, zoomLevel - 0.25) }
                } label: {
                    Image(systemName: "minus.magnifyingglass")
                }
                .buttonStyle(.borderless)

                Text(String(format: "%.0f%%", zoomLevel * 100))
                    .font(.caption)
                    .frame(width: 40)

                Button {
                    withAnimation { zoomLevel = min(4.0, zoomLevel + 0.25) }
                } label: {
                    Image(systemName: "plus.magnifyingglass")
                }
                .buttonStyle(.borderless)

                Button {
                    withAnimation { zoomLevel = 1.0 }
                } label: {
                    Text("Fit")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    private var timeRuler: some View {
        Canvas { context, size in
            let step = calculateTimeStep()
            var time: TimeInterval = 0

            while time <= totalDuration + 1 {
                let x = CGFloat(time) * pixelsPerSecond + 20

                // Major tick
                var path = Path()
                path.move(to: CGPoint(x: x, y: 20))
                path.addLine(to: CGPoint(x: x, y: 28))
                context.stroke(path, with: .color(.secondary), lineWidth: 1)

                // Time label
                let text = formatTime(time)
                context.draw(
                    Text(text).font(.caption2).foregroundColor(.secondary),
                    at: CGPoint(x: x, y: 10)
                )

                time += step
            }
        }
    }

    private var eventTrack: some View {
        ZStack(alignment: .leading) {
            // Track background
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.secondary.opacity(0.1))
                .frame(height: trackHeight)

            // Connection lines
            ForEach(Array(events.enumerated()), id: \.element.id) { index, event in
                if index > 0 {
                    let prevX = xPosition(for: index - 1)
                    let currX = xPosition(for: index)
                    Path { path in
                        path.move(to: CGPoint(x: prevX + nodeSize/2 + 20, y: trackHeight/2))
                        path.addLine(to: CGPoint(x: currX - nodeSize/2 + 20, y: trackHeight/2))
                    }
                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                }
            }

            // Event nodes
            ForEach(Array(events.enumerated()), id: \.element.id) { index, event in
                eventNode(for: event, at: index)
                    .position(x: xPosition(for: index) + 20, y: trackHeight/2)
            }
        }
        .frame(width: timelineWidth, height: trackHeight)
        .padding(.horizontal, 10)
    }

    private func eventNode(for event: MacroEvent, at index: Int) -> some View {
        let isSelected = selectedEventIds.contains(event.id)
        let isCurrent = isPlaying && index == currentEventIndex

        return Circle()
            .fill(colorForEventType(event.type))
            .frame(width: nodeSize, height: nodeSize)
            .overlay(
                Circle()
                    .stroke(isSelected ? Color.accentColor : (isCurrent ? Color.green : Color.clear), lineWidth: 2)
            )
            .scaleEffect(isCurrent ? 1.3 : (isSelected ? 1.1 : 1.0))
            .shadow(color: isCurrent ? .green.opacity(0.5) : .clear, radius: 4)
            .onTapGesture {
                if selectedEventIds.contains(event.id) {
                    selectedEventIds.remove(event.id)
                } else {
                    if !NSEvent.modifierFlags.contains(.command) {
                        selectedEventIds.removeAll()
                    }
                    selectedEventIds.insert(event.id)
                }
            }
            .onTapGesture(count: 2) {
                editingEventId = event.id
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        draggedEventId = event.id
                        // Could implement drag-to-reorder here
                    }
                    .onEnded { value in
                        draggedEventId = nil
                        // Apply reorder
                    }
            )
            .help("\(event.type.rawValue) - Delay: \(String(format: "%.3fs", event.delay))")
    }

    private var playhead: some View {
        GeometryReader { geo in
            Rectangle()
                .fill(Color.green)
                .frame(width: 2)
                .offset(x: xPosition(for: currentEventIndex) + 20 - 1)
        }
    }

    // MARK: - Helpers

    private func xPosition(for index: Int) -> CGFloat {
        guard index < events.count else { return 0 }
        var totalTime: TimeInterval = 0
        for i in 0..<index {
            totalTime += events[i].delay
        }
        totalTime += events[index].delay
        return CGFloat(totalTime) * pixelsPerSecond
    }

    private func calculateTimeStep() -> TimeInterval {
        let targetSteps = 10.0
        let rawStep = totalDuration / targetSteps
        let magnitude = pow(10, floor(log10(max(rawStep, 0.001))))
        let normalized = rawStep / magnitude

        if normalized <= 1 { return magnitude }
        if normalized <= 2 { return 2 * magnitude }
        if normalized <= 5 { return 5 * magnitude }
        return 10 * magnitude
    }

    private func formatTime(_ time: TimeInterval) -> String {
        if time < 60 {
            return String(format: "%.1fs", time)
        } else {
            let minutes = Int(time) / 60
            let seconds = time.truncatingRemainder(dividingBy: 60)
            return String(format: "%d:%04.1f", minutes, seconds)
        }
    }

    private func colorForEventType(_ type: EventType) -> Color {
        switch type {
        case .mouseLeftDown, .mouseLeftUp: return .blue
        case .mouseRightDown, .mouseRightUp: return .purple
        case .mouseMove: return .gray
        case .mouseDrag: return .orange
        case .keyDown, .keyUp: return .green
        case .scroll: return .cyan
        case .windowFocus: return .yellow
        case .appleScript, .appleScriptFile: return .teal
        case .conditionStart, .conditionElse, .conditionEnd: return .pink
        case .loopStart, .loopEnd, .breakLoop, .continueLoop: return .brown
        case .clickImage, .waitForImage, .dragToImage: return .indigo
        }
    }
}

// Extension to make UUID work with .popover(item:)
extension UUID: Identifiable {
    public var id: UUID { self }
}

#Preview {
    InteractiveTimelineView(
        events: .constant([]),
        selectedEventIds: .constant([]),
        isPlaying: false,
        currentEventIndex: 0
    )
}
