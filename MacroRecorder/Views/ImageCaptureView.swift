//
//  ImageCaptureView.swift
//  MacroRecorder
//
//  View for capturing screen regions as image templates
//

import SwiftUI
import AppKit

struct ImageCaptureView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var templateManager = ImageTemplateManager.shared

    @State private var templateName: String = "New Template"
    @State private var matchThreshold: Double = 0.8
    @State private var capturedImage: NSImage?
    @State private var capturedRegion: CGRect?
    @State private var isCapturing = false
    @State private var error: String?

    var onTemplateCreated: ((ImageTemplate) -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "viewfinder")
                    .font(.title2)
                Text("Capture Image Template")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
            }

            // Preview
            GroupBox("Preview") {
                if let image = capturedImage {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 200)
                        .background(Color.black.opacity(0.1))
                        .cornerRadius(8)
                } else {
                    VStack {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No image captured")
                            .foregroundColor(.secondary)
                    }
                    .frame(height: 200)
                }
            }

            // Capture controls
            HStack {
                Button(action: captureRegion) {
                    HStack {
                        Image(systemName: "crop")
                        Text("Select Region")
                    }
                }
                .disabled(isCapturing)

                Button(action: captureFullScreen) {
                    HStack {
                        Image(systemName: "rectangle.dashed")
                        Text("Full Screen")
                    }
                }
                .disabled(isCapturing)

                Button(action: captureFromClipboard) {
                    HStack {
                        Image(systemName: "doc.on.clipboard")
                        Text("From Clipboard")
                    }
                }

                Spacer()
            }

            Divider()

            // Template settings
            GroupBox("Template Settings") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Name:")
                        TextField("Template name", text: $templateName)
                    }

                    HStack {
                        Text("Match Threshold:")
                        Slider(value: $matchThreshold, in: 0.5...1.0, step: 0.05)
                        Text("\(Int(matchThreshold * 100))%")
                            .frame(width: 40)
                    }

                    if let region = capturedRegion {
                        HStack {
                            Text("Captured Region:")
                            Text("\(Int(region.width)) × \(Int(region.height)) px")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(4)
            }

            if let error = error {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
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

                Button("Save Template") {
                    saveTemplate()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(capturedImage == nil || templateName.isEmpty)
            }
        }
        .padding()
        .frame(width: 500, height: 500)
    }

    private func captureRegion() {
        isCapturing = true
        error = nil

        // Hide the window temporarily
        NSApp.hide(nil)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Use screencapture command for region selection
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")

            let tempPath = NSTemporaryDirectory() + "macrorecorder_capture.png"
            task.arguments = ["-i", "-s", tempPath]

            do {
                try task.run()
                task.waitUntilExit()

                if task.terminationStatus == 0,
                   let image = NSImage(contentsOfFile: tempPath) {
                    DispatchQueue.main.async {
                        capturedImage = image
                        capturedRegion = CGRect(origin: .zero, size: image.size)
                        isCapturing = false

                        // Clean up temp file
                        try? FileManager.default.removeItem(atPath: tempPath)
                    }
                } else {
                    DispatchQueue.main.async {
                        isCapturing = false
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.error = error.localizedDescription
                    isCapturing = false
                }
            }

            NSApp.activate(ignoringOtherApps: true)
        }
    }

    private func captureFullScreen() {
        isCapturing = true
        error = nil

        guard let screen = NSScreen.main else {
            error = "No main screen found"
            isCapturing = false
            return
        }

        let rect = screen.frame
        guard let cgImage = CGWindowListCreateImage(
            rect,
            .optionOnScreenOnly,
            kCGNullWindowID,
            .bestResolution
        ) else {
            error = "Failed to capture screen"
            isCapturing = false
            return
        }

        capturedImage = NSImage(cgImage: cgImage, size: rect.size)
        capturedRegion = rect
        isCapturing = false
    }

    private func captureFromClipboard() {
        error = nil

        guard let items = NSPasteboard.general.pasteboardItems else {
            error = "Clipboard is empty"
            return
        }

        for item in items {
            if let data = item.data(forType: .png),
               let image = NSImage(data: data) {
                capturedImage = image
                capturedRegion = CGRect(origin: .zero, size: image.size)
                return
            }
            if let data = item.data(forType: .tiff),
               let image = NSImage(data: data) {
                capturedImage = image
                capturedRegion = CGRect(origin: .zero, size: image.size)
                return
            }
        }

        error = "No image found in clipboard"
    }

    private func saveTemplate() {
        guard let image = capturedImage else { return }

        if let template = templateManager.createTemplate(
            name: templateName,
            from: image,
            matchThreshold: matchThreshold
        ) {
            onTemplateCreated?(template)
            dismiss()
        } else {
            error = "Failed to create template"
        }
    }
}
