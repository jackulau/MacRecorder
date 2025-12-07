//
//  ImageTemplateLibraryView.swift
//  MacroRecorder
//
//  View for browsing and managing image templates
//

import SwiftUI

struct ImageTemplateLibraryView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var templateManager = ImageTemplateManager.shared
    @StateObject private var imageMatcher = ImageMatcher.shared

    @State private var searchText = ""
    @State private var selectedTemplate: ImageTemplate?
    @State private var showingCaptureView = false
    @State private var showingDeleteAlert = false
    @State private var templateToDelete: ImageTemplate?
    @State private var testResult: ImageMatch?

    var onTemplateSelected: ((ImageTemplate) -> Void)?

    var body: some View {
        HSplitView {
            // Template list
            VStack {
                // Search
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search templates...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(8)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                .padding([.horizontal, .top])

                // List
                List(filteredTemplates, selection: $selectedTemplate) { template in
                    TemplateRow(template: template)
                        .contextMenu {
                            Button("Test Match") {
                                testTemplate(template)
                            }
                            Divider()
                            Button("Delete", role: .destructive) {
                                templateToDelete = template
                                showingDeleteAlert = true
                            }
                        }
                }
                .listStyle(.sidebar)

                // Actions
                HStack {
                    Button(action: { showingCaptureView = true }) {
                        Image(systemName: "plus")
                    }
                    .help("Capture new template")

                    Button(action: importTemplate) {
                        Image(systemName: "square.and.arrow.down")
                    }
                    .help("Import template")

                    Spacer()
                }
                .padding(8)
            }
            .frame(minWidth: 200, maxWidth: 300)

            // Detail view
            if let template = selectedTemplate {
                TemplateDetailView(
                    template: template,
                    testResult: testResult,
                    onTest: { testTemplate(template) },
                    onSelect: {
                        onTemplateSelected?(template)
                        dismiss()
                    }
                )
            } else {
                VStack {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("Select a template")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(width: 700, height: 500)
        .sheet(isPresented: $showingCaptureView) {
            ImageCaptureView()
        }
        .alert("Delete Template", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let template = templateToDelete {
                    templateManager.deleteTemplate(template)
                    if selectedTemplate?.id == template.id {
                        selectedTemplate = nil
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete this template?")
        }
    }

    private var filteredTemplates: [ImageTemplate] {
        if searchText.isEmpty {
            return templateManager.templates
        }
        return templateManager.templates.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    private func testTemplate(_ template: ImageTemplate) {
        Task {
            testResult = await imageMatcher.findBestMatch(template)
        }
    }

    private func importTemplate() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.message = "Select an image template file"

        if panel.runModal() == .OK, let url = panel.url {
            do {
                let template = try templateManager.importTemplate(from: url)
                selectedTemplate = template
            } catch {
                // Handle error
            }
        }
    }
}

// MARK: - Template Row

struct TemplateRow: View {
    let template: ImageTemplate

    var body: some View {
        HStack {
            // Thumbnail
            if let image = NSImage(data: template.imageData) {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
                    .background(Color.black.opacity(0.1))
                    .cornerRadius(4)
            } else {
                Image(systemName: "photo")
                    .frame(width: 40, height: 40)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(4)
            }

            VStack(alignment: .leading) {
                Text(template.name)
                    .font(.headline)
                if let size = template.imageSize {
                    Text("\(Int(size.width)) × \(Int(size.height))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Template Detail View

struct TemplateDetailView: View {
    let template: ImageTemplate
    let testResult: ImageMatch?
    let onTest: () -> Void
    let onSelect: () -> Void

    @StateObject private var imageMatcher = ImageMatcher.shared

    var body: some View {
        VStack(spacing: 16) {
            // Image preview
            GroupBox("Preview") {
                if let image = NSImage(data: template.imageData) {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 200)
                } else {
                    Text("Unable to load image")
                        .foregroundColor(.secondary)
                }
            }

            // Details
            GroupBox("Details") {
                VStack(alignment: .leading, spacing: 8) {
                    DetailRow(label: "Name", value: template.name)
                    if let size = template.imageSize {
                        DetailRow(label: "Size", value: "\(Int(size.width)) × \(Int(size.height)) px")
                    }
                    DetailRow(label: "Threshold", value: "\(Int(template.matchThreshold * 100))%")
                    DetailRow(label: "Scale Range", value: "\(Int(template.scaleMin * 100))% - \(Int(template.scaleMax * 100))%")
                    DetailRow(label: "Created", value: template.createdAt.formatted())
                }
                .padding(4)
            }

            // Test result
            if let result = testResult {
                GroupBox("Last Test Result") {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Found!")
                        }
                        Text("Position: (\(Int(result.position.x)), \(Int(result.position.y)))")
                            .font(.caption)
                        Text("Confidence: \(Int(result.confidence * 100))%")
                            .font(.caption)
                    }
                }
            }

            Spacer()

            // Actions
            HStack {
                Button(action: onTest) {
                    HStack {
                        if imageMatcher.isSearching {
                            ProgressView()
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: "eye")
                        }
                        Text("Test Match")
                    }
                }
                .disabled(imageMatcher.isSearching)

                Spacer()

                Button(action: onSelect) {
                    HStack {
                        Image(systemName: "checkmark")
                        Text("Select")
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label + ":")
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
        }
    }
}
