//
//  ExportScriptView.swift
//  MacroRecorder
//
//  View for exporting macros as AppleScript
//

import SwiftUI

struct ExportScriptView: View {
    let macro: Macro
    @Environment(\.dismiss) private var dismiss
    @StateObject private var executor = AppleScriptExecutor.shared

    @State private var generatedScript: String = ""
    @State private var showingSavePanel = false
    @State private var exportError: String?
    @State private var copied = false

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "applescript")
                    .font(.title2)
                Text("Export as AppleScript")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
            }

            // Script preview
            GroupBox("Generated Script") {
                ScrollView {
                    Text(generatedScript)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 300)
            }

            // Info
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                Text("This script was generated from your macro. Some events may not be fully convertible to AppleScript.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let error = exportError {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }

            Divider()

            // Actions
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button(action: copyToClipboard) {
                    HStack {
                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                        Text(copied ? "Copied!" : "Copy")
                    }
                }

                Button(action: saveToFile) {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                        Text("Save...")
                    }
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 600, height: 500)
        .onAppear {
            generatedScript = executor.generateScript(from: macro)
        }
    }

    private func copyToClipboard() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(generatedScript, forType: .string)
        copied = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            copied = false
        }
    }

    private func saveToFile() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.appleScript]
        panel.nameFieldStringValue = "\(macro.name).scpt"
        panel.message = "Choose where to save the AppleScript"

        panel.begin { response in
            if response == .OK, let url = panel.url {
                do {
                    try generatedScript.write(to: url, atomically: true, encoding: .utf8)
                    dismiss()
                } catch {
                    exportError = error.localizedDescription
                }
            }
        }
    }
}
