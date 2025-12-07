//
//  TimelinePopoverView.swift
//  MacroRecorder
//
//  Quick edit popover for timeline events
//

import SwiftUI

struct TimelinePopoverView: View {
    @Binding var event: MacroEvent
    @Environment(\.dismiss) private var dismiss

    @State private var delayValue: Double = 0
    @State private var positionX: Double = 0
    @State private var positionY: Double = 0
    @State private var showAdvancedDelay = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: iconForEventType(event.type))
                    .foregroundColor(colorForEventType(event.type))
                Text(event.type.rawValue)
                    .font(.headline)
                Spacer()
            }

            Divider()

            // Delay editor
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Delay")
                        .foregroundColor(.secondary)
                    Spacer()
                    Button {
                        showAdvancedDelay.toggle()
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                    .buttonStyle(.borderless)
                    .help("Advanced delay options")
                }

                if showAdvancedDelay {
                    if var config = event.delayConfig {
                        DelayEditorView(delayConfig: Binding(
                            get: { config },
                            set: { newConfig in
                                config = newConfig
                                // Update the event
                                updateEventDelay(config)
                            }
                        ))
                    }
                } else {
                    HStack {
                        Slider(value: $delayValue, in: 0...5, step: 0.01)
                            .frame(width: 150)

                        TextField("", value: $delayValue, format: .number.precision(.fractionLength(3)))
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 70)

                        Text("s")
                            .foregroundColor(.secondary)
                    }
                    .onChange(of: delayValue) { newValue in
                        var mutableEvent = event
                        mutableEvent.delay = newValue
                        event = mutableEvent
                    }
                }
            }

            // Position editor (for mouse events)
            if event.position != nil {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Position")
                        .foregroundColor(.secondary)

                    HStack {
                        Text("X:")
                        TextField("", value: $positionX, format: .number.precision(.fractionLength(1)))
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)

                        Text("Y:")
                        TextField("", value: $positionY, format: .number.precision(.fractionLength(1)))
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                    }
                }
            }

            // Key code info (for keyboard events)
            if let keyCode = event.keyCode {
                HStack {
                    Text("Key Code:")
                        .foregroundColor(.secondary)
                    Text("\(keyCode)")
                        .font(.system(.body, design: .monospaced))
                }
            }

            // Scroll info
            if event.type == .scroll {
                VStack(alignment: .leading) {
                    Text("Scroll Delta")
                        .foregroundColor(.secondary)
                    HStack {
                        Text("X: \(String(format: "%.1f", event.scrollDeltaX ?? 0))")
                        Text("Y: \(String(format: "%.1f", event.scrollDeltaY ?? 0))")
                    }
                    .font(.system(.body, design: .monospaced))
                }
            }

            Divider()

            // Timestamp info
            HStack {
                Text("Timestamp:")
                    .foregroundColor(.secondary)
                Text(formatTimestamp(event.timestamp))
                    .font(.caption)
            }

            // Action buttons
            HStack {
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 300)
        .onAppear {
            delayValue = event.delay
            positionX = Double(event.position?.x ?? 0)
            positionY = Double(event.position?.y ?? 0)
        }
    }

    private func updateEventDelay(_ config: DelayConfig) {
        var mutableEvent = event
        mutableEvent.delayConfig = config
        event = mutableEvent
    }

    private func formatTimestamp(_ timestamp: TimeInterval) -> String {
        let date = Date(timeIntervalSince1970: timestamp)
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: date)
    }

    private func iconForEventType(_ type: EventType) -> String {
        switch type {
        case .mouseLeftDown, .mouseLeftUp: return "cursorarrow.click"
        case .mouseRightDown, .mouseRightUp: return "cursorarrow.click.2"
        case .mouseMove: return "cursorarrow.motionlines"
        case .mouseDrag: return "cursorarrow.and.square.on.square.dashed"
        case .keyDown, .keyUp: return "keyboard"
        case .scroll: return "scroll"
        case .windowFocus: return "macwindow"
        case .appleScript, .appleScriptFile: return "applescript"
        case .conditionStart: return "arrow.branch"
        case .conditionElse: return "arrow.triangle.branch"
        case .conditionEnd: return "arrow.triangle.merge"
        case .loopStart, .loopEnd: return "repeat"
        case .breakLoop: return "stop.circle"
        case .continueLoop: return "arrow.forward.to.line"
        case .clickImage, .waitForImage, .dragToImage: return "photo"
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

#Preview {
    TimelinePopoverView(event: .constant(
        MacroEvent(
            type: .mouseLeftDown,
            timestamp: Date().timeIntervalSince1970,
            position: CGPoint(x: 100, y: 200),
            delay: 0.5
        )
    ))
}
