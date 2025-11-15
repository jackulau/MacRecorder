//
//  WindowPickerView.swift
//  MacroRecorder
//

import SwiftUI

struct WindowPickerView: View {
    @Binding var selectedWindow: WindowInfo?
    @Binding var selectedTitle: String
    @Environment(\.dismiss) var dismiss

    @State private var availableWindows: [(app: String, windows: [WindowInfo])] = []
    @State private var searchText = ""
    @State private var hoveredWindow: WindowInfo?
    @State private var loadedThumbnails: [CGWindowID: NSImage] = [:]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Select Target Window")
                    .font(.title2)
                    .bold()

                Spacer()

                Text("\(totalWindowCount) windows available")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape)
            }
            .padding()

            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search windows...", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(8)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            .padding(.horizontal)
            .padding(.bottom, 10)

            Divider()

            // Preview pane for hovered window
            if let hoveredWindow = hoveredWindow {
                VStack(spacing: 8) {
                    if let thumbnail = loadedThumbnails[hoveredWindow.windowID ?? 0] {
                        Image(nsImage: thumbnail)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 150)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.accentColor, lineWidth: 2)
                            )
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.1))
                            .frame(height: 150)
                            .overlay(
                                ProgressView()
                                    .scaleEffect(0.8)
                            )
                    }

                    Text(hoveredWindow.windowTitle ?? "Window")
                        .font(.headline)

                    Text("Size: \(Int(hoveredWindow.windowBounds.width)) × \(Int(hoveredWindow.windowBounds.height))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.gray.opacity(0.05))

                Divider()
            }

            // Window list
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    // Option to record all windows
                    Button(action: {
                        selectedWindow = nil
                        selectedTitle = "All Windows"
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "macwindow.on.rectangle")
                                .frame(width: 30)
                            Text("All Windows")
                                .font(.headline)
                            Spacer()
                            if selectedWindow == nil {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .padding(10)
                        .background(selectedWindow == nil ? Color.accentColor.opacity(0.1) : Color.clear)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)

                    Divider()

                    // Available windows grouped by app
                    ForEach(filteredWindows, id: \.app) { appGroup in
                        VStack(alignment: .leading, spacing: 5) {
                            Text(appGroup.app)
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .padding(.leading, 5)

                            ForEach(Array(appGroup.windows.enumerated()), id: \.offset) { index, window in
                                Button(action: {
                                    selectedWindow = window
                                    selectedTitle = "\(appGroup.app): \(window.windowTitle ?? "Window")"
                                    dismiss()
                                }) {
                                    HStack(spacing: 12) {
                                        // Window thumbnail
                                        WindowThumbnailView(
                                            window: window,
                                            thumbnail: loadedThumbnails[window.windowID ?? 0],
                                            size: CGSize(width: 100, height: 75)
                                        )
                                        .onAppear {
                                            loadThumbnail(for: window)
                                        }

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(window.windowTitle ?? "Window \(index + 1)")
                                                .font(.system(size: 13, weight: .medium))
                                                .lineLimit(1)

                                            HStack(spacing: 8) {
                                                Text("Size: \(Int(window.windowBounds.width))×\(Int(window.windowBounds.height))")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)

                                                if window.isActive {
                                                    Label("Active", systemImage: "circle.fill")
                                                        .font(.caption)
                                                        .foregroundColor(.green)
                                                }
                                            }
                                        }

                                        Spacer()

                                        if isSelected(window) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.accentColor)
                                                .font(.title2)
                                        }
                                    }
                                    .padding(12)
                                    .background(isSelected(window) ? Color.accentColor.opacity(0.08) : Color.gray.opacity(0.05))
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(isSelected(window) ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                                .onHover { isHovering in
                                    if isHovering {
                                        hoveredWindow = window
                                        loadThumbnail(for: window)
                                    }
                                }
                            }
                        }
                        .padding(.bottom, 10)
                    }
                }
                .padding()
            }

            Divider()

            // Footer with info
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.secondary)
                Text("Hover over a window to see a preview. Select to record events only within that window.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding()
            .background(Color.gray.opacity(0.05))
        }
        .frame(width: 700, height: 600)
        .onAppear {
            loadAvailableWindows()
            // Clear thumbnail cache periodically
            WindowDetector.shared.clearThumbnailCache()
        }
    }

    private var totalWindowCount: Int {
        availableWindows.reduce(0) { $0 + $1.windows.count }
    }

    private var filteredWindows: [(app: String, windows: [WindowInfo])] {
        if searchText.isEmpty {
            return availableWindows
        }

        return availableWindows.compactMap { appGroup in
            let filteredWindows = appGroup.windows.filter { window in
                let appMatches = appGroup.app.localizedCaseInsensitiveContains(searchText)
                let titleMatches = window.windowTitle?.localizedCaseInsensitiveContains(searchText) ?? false
                return appMatches || titleMatches
            }

            return filteredWindows.isEmpty ? nil : (app: appGroup.app, windows: filteredWindows)
        }
    }

    private func isSelected(_ window: WindowInfo) -> Bool {
        return selectedWindow?.processID == window.processID &&
               selectedWindow?.windowTitle == window.windowTitle
    }

    private func loadAvailableWindows() {
        availableWindows = WindowDetector.shared.getAllWindows()
            .filter { !$0.windows.isEmpty }
    }

    private func loadThumbnail(for window: WindowInfo) {
        guard let windowID = window.windowID,
              loadedThumbnails[windowID] == nil else { return }

        // Load thumbnail asynchronously
        DispatchQueue.global(qos: .userInitiated).async {
            if let thumbnail = WindowDetector.shared.getWindowThumbnail(for: window) {
                DispatchQueue.main.async {
                    self.loadedThumbnails[windowID] = thumbnail
                }
            }
        }
    }
}

// Separate view for window thumbnails with lazy loading
struct WindowThumbnailView: View {
    let window: WindowInfo
    let thumbnail: NSImage?
    let size: CGSize

    var body: some View {
        Group {
            if let thumbnail = thumbnail {
                Image(nsImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size.width, height: size.height)
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(radius: 2)
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.gray.opacity(0.1),
                                Color.gray.opacity(0.05)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size.width, height: size.height)
                    .overlay(
                        Image(systemName: "macwindow")
                            .font(.title2)
                            .foregroundColor(.secondary.opacity(0.5))
                    )
            }
        }
    }
}