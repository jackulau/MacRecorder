//
//  AppleScriptEditorView.swift
//  MacroRecorder
//
//  View for editing AppleScript in macro events
//

import SwiftUI

struct AppleScriptEditorView: View {
    @Binding var event: MacroEvent
    @StateObject private var executor = AppleScriptExecutor.shared
    @State private var scriptText: String = ""
    @State private var validationError: String?
    @State private var isValidating = false
    @State private var testOutput: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "applescript")
                Text("AppleScript Editor")
                    .font(.headline)
                Spacer()

                Button(action: validateScript) {
                    HStack(spacing: 4) {
                        if isValidating {
                            ProgressView()
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: "checkmark.circle")
                        }
                        Text("Validate")
                    }
                }
                .disabled(scriptText.isEmpty || isValidating)

                Button(action: testScript) {
                    HStack(spacing: 4) {
                        Image(systemName: "play.circle")
                        Text("Test Run")
                    }
                }
                .disabled(scriptText.isEmpty || executor.isExecuting)
            }

            // Script editor
            TextEditor(text: $scriptText)
                .font(.system(.body, design: .monospaced))
                .frame(minHeight: 200)
                .padding(8)
                .background(Color(NSColor.textBackgroundColor))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .onChange(of: scriptText) { newValue in
                    updateEvent(script: newValue)
                }

            // Options
            GroupBox("Options") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Timeout:")
                        TextField("30", value: Binding(
                            get: { event.scriptTimeout ?? 30 },
                            set: { updateEvent(timeout: $0) }
                        ), format: .number)
                        .frame(width: 60)
                        Text("seconds")
                    }

                    Toggle("Capture output to variable", isOn: Binding(
                        get: { event.captureScriptOutput ?? false },
                        set: { updateEvent(captureOutput: $0) }
                    ))

                    if event.captureScriptOutput == true {
                        HStack {
                            Text("Variable name:")
                            TextField("result", text: Binding(
                                get: { event.outputVariableName ?? "result" },
                                set: { updateEvent(outputVariable: $0) }
                            ))
                            .frame(width: 120)
                        }
                    }
                }
                .padding(4)
            }

            // Validation/error messages
            if let error = validationError {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }

            // Test output
            if let output = testOutput {
                GroupBox("Output") {
                    ScrollView {
                        Text(output)
                            .font(.system(.caption, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 100)
                }
            }

            // Snippets
            GroupBox("Common Snippets") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(snippets, id: \.name) { snippet in
                            Button(snippet.name) {
                                insertSnippet(snippet.code)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                }
            }
        }
        .padding()
        .onAppear {
            scriptText = event.scriptContent ?? ""
        }
    }

    private func validateScript() {
        isValidating = true
        validationError = nil

        DispatchQueue.global(qos: .userInitiated).async {
            let result = executor.validate(script: scriptText)

            DispatchQueue.main.async {
                isValidating = false
                if !result.valid {
                    validationError = result.error
                }
            }
        }
    }

    private func testScript() {
        testOutput = nil
        Task {
            do {
                let result = try await executor.execute(script: scriptText)
                await MainActor.run {
                    testOutput = result ?? "(No output)"
                }
            } catch {
                await MainActor.run {
                    testOutput = "Error: \(error.localizedDescription)"
                }
            }
        }
    }

    private func insertSnippet(_ code: String) {
        scriptText += (scriptText.isEmpty ? "" : "\n") + code
    }

    private func updateEvent(
        script: String? = nil,
        timeout: TimeInterval? = nil,
        captureOutput: Bool? = nil,
        outputVariable: String? = nil
    ) {
        var newEvent = MacroEvent(
            id: event.id,
            type: event.type,
            timestamp: event.timestamp,
            position: event.position,
            keyCode: event.keyCode,
            flags: event.flags,
            scrollDeltaX: event.scrollDeltaX,
            scrollDeltaY: event.scrollDeltaY,
            delay: event.delay,
            delayConfig: event.delayConfig,
            windowInfo: event.windowInfo,
            relativePosition: event.relativePosition,
            scriptContent: script ?? event.scriptContent,
            scriptPath: event.scriptPath,
            scriptTimeout: timeout ?? event.scriptTimeout,
            captureScriptOutput: captureOutput ?? event.captureScriptOutput,
            outputVariableName: outputVariable ?? event.outputVariableName,
            controlFlowConfig: event.controlFlowConfig,
            imageEventConfig: event.imageEventConfig
        )
        event = newEvent
    }

    private var snippets: [(name: String, code: String)] {
        [
            ("Tell Finder", "tell application \"Finder\"\n    -- Your code here\nend tell"),
            ("Display Dialog", "display dialog \"Hello, World!\""),
            ("Get Clipboard", "get the clipboard"),
            ("Set Clipboard", "set the clipboard to \"text\""),
            ("Keystroke", "tell application \"System Events\"\n    keystroke \"a\" using command down\nend tell"),
            ("Open App", "tell application \"Safari\" to activate"),
            ("Delay", "delay 1"),
        ]
    }
}
