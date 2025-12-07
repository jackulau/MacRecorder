//
//  TemplateBrowserView.swift
//  MacroRecorder
//
//  View for browsing and applying macro templates
//

import SwiftUI

struct TemplateBrowserView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var templateManager = TemplateManager.shared

    @State private var selectedCategory: TemplateCategory?
    @State private var searchText = ""
    @State private var selectedTemplate: MacroTemplate?
    @State private var showingCreateSheet = false

    var onTemplateApplied: ((Macro) -> Void)?

    var body: some View {
        HSplitView {
            // Sidebar - Categories
            VStack(alignment: .leading, spacing: 0) {
                Text("Categories")
                    .font(.headline)
                    .padding()

                List(selection: $selectedCategory) {
                    // All templates
                    Label("All Templates", systemImage: "square.grid.2x2")
                        .tag(nil as TemplateCategory?)

                    Divider()

                    // Categories
                    ForEach(TemplateCategory.allCases, id: \.self) { category in
                        Label(category.displayName, systemImage: category.iconName)
                            .tag(category as TemplateCategory?)
                    }
                }
                .listStyle(.sidebar)
            }
            .frame(width: 180)

            // Main content
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search templates...", text: $searchText)
                        .textFieldStyle(.plain)
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(8)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                .padding()

                // Template grid
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 200, maximum: 250))
                    ], spacing: 16) {
                        ForEach(filteredTemplates) { template in
                            TemplateCard(
                                template: template,
                                isSelected: selectedTemplate?.id == template.id
                            )
                            .onTapGesture {
                                selectedTemplate = template
                            }
                            .onTapGesture(count: 2) {
                                applyTemplate(template)
                            }
                        }
                    }
                    .padding()
                }

                Divider()

                // Bottom bar
                HStack {
                    if let template = selectedTemplate {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(template.name)
                                .font(.headline)
                            Text(template.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    } else {
                        Text("Select a template to use")
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button("Cancel") {
                        dismiss()
                    }
                    .keyboardShortcut(.cancelAction)

                    Button("Use Template") {
                        if let template = selectedTemplate {
                            applyTemplate(template)
                        }
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(selectedTemplate == nil)
                }
                .padding()
            }
        }
        .frame(width: 800, height: 600)
    }

    private var filteredTemplates: [MacroTemplate] {
        var templates = templateManager.allTemplates

        // Filter by category
        if let category = selectedCategory {
            templates = templates.filter { $0.category == category }
        }

        // Filter by search
        if !searchText.isEmpty {
            templates = templateManager.search(searchText)
            if let category = selectedCategory {
                templates = templates.filter { $0.category == category }
            }
        }

        return templates
    }

    private func applyTemplate(_ template: MacroTemplate) {
        let macro = template.createMacro()
        onTemplateApplied?(macro)
        dismiss()
    }
}

// MARK: - Template Card

struct TemplateCard: View {
    let template: MacroTemplate
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Icon
            HStack {
                Image(systemName: template.iconName ?? template.category.iconName)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .accentColor)
                Spacer()
                if template.isBuiltIn {
                    Text("Built-in")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(isSelected ? 0.3 : 0.2))
                        .foregroundColor(isSelected ? .white : .blue)
                        .cornerRadius(4)
                }
            }

            // Name
            Text(template.name)
                .font(.headline)
                .foregroundColor(isSelected ? .white : .primary)
                .lineLimit(1)

            // Description
            Text(template.description)
                .font(.caption)
                .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                .lineLimit(2)

            Spacer()

            // Tags
            if !template.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(template.tags.prefix(3), id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.gray.opacity(isSelected ? 0.3 : 0.2))
                                .foregroundColor(isSelected ? .white : .secondary)
                                .cornerRadius(4)
                        }
                    }
                }
            }

            // Event count
            HStack {
                Image(systemName: "list.bullet")
                    .font(.caption)
                Text("\(template.macro.events.count) events")
                    .font(.caption)
            }
            .foregroundColor(isSelected ? .white.opacity(0.7) : .secondary)
        }
        .padding()
        .frame(height: 160)
        .background(isSelected ? Color.accentColor : Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.clear : Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}
