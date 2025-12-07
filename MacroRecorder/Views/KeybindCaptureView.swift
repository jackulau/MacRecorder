//
//  KeybindCaptureView.swift
//  MacroRecorder
//

import SwiftUI
import Carbon

// HotkeyConfig is now defined in Models/HotkeyConfig.swift

struct KeybindCaptureView: View {
    @Binding var hotkeyConfig: HotkeyConfig
    @State private var isCapturing = false
    @State private var capturedKey: String = ""
    let label: String

    var body: some View {
        HStack {
            Text(label)
                .frame(width: 150, alignment: .leading)

            Button(action: {
                isCapturing = true
            }) {
                Text(isCapturing ? "Press keys..." : hotkeyConfig.displayString)
                    .font(.system(.body, design: .monospaced))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .frame(minWidth: 100)
                    .background(isCapturing ? Color.accentColor.opacity(0.2) : Color(NSColor.controlBackgroundColor))
                    .cornerRadius(6)
            }
            .buttonStyle(.plain)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isCapturing ? Color.accentColor : Color.clear, lineWidth: 2)
            )
            .background(KeybindCaptureHelper(isCapturing: $isCapturing, onCapture: { keyCode, modifiers in
                hotkeyConfig = HotkeyConfig(keyCode: UInt32(keyCode), modifiers: modifiers)
            }))

            if isCapturing {
                Button("Cancel") {
                    isCapturing = false
                }
                .buttonStyle(.borderless)
            }
        }
    }
}

struct KeybindCaptureHelper: NSViewRepresentable {
    @Binding var isCapturing: Bool
    let onCapture: (UInt16, UInt32) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = KeyCaptureNSView()
        view.onKeyCapture = { keyCode, modifiers in
            onCapture(keyCode, modifiers)
            isCapturing = false
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        if let captureView = nsView as? KeyCaptureNSView {
            captureView.isCapturing = isCapturing
            if isCapturing {
                DispatchQueue.main.async {
                    nsView.window?.makeFirstResponder(nsView)
                }
            }
        }
    }
}

class KeyCaptureNSView: NSView {
    var isCapturing = false
    var onKeyCapture: ((UInt16, UInt32) -> Void)?

    override var acceptsFirstResponder: Bool {
        return isCapturing
    }

    override func keyDown(with event: NSEvent) {
        guard isCapturing else {
            super.keyDown(with: event)
            return
        }

        let keyCode = event.keyCode
        var modifiers: UInt32 = 0

        if event.modifierFlags.contains(.command) {
            modifiers |= UInt32(cmdKey)
        }
        if event.modifierFlags.contains(.shift) {
            modifiers |= UInt32(shiftKey)
        }
        if event.modifierFlags.contains(.option) {
            modifiers |= UInt32(optionKey)
        }
        if event.modifierFlags.contains(.control) {
            modifiers |= UInt32(controlKey)
        }

        // Require at least one modifier key
        if modifiers != 0 {
            onKeyCapture?(keyCode, modifiers)
        }
    }

    override func flagsChanged(with event: NSEvent) {
        // Ignore modifier-only key presses
    }
}
