//
//  TemplateCreatorView.swift
//  MacroRecorder
//
//  View for saving a macro as a template
//

import SwiftUI

struct TemplateCreatorView: View {
    let macro: Macro
    @Environment(\.dismiss) private var dismiss
    @StateObject private var templateManager = TemplateManager.shared

    @State private var templateName: String = ""
    @State private var templateDescription: String = ""
    @State private var selectedCategory: TemplateCategory = .custom
    @State private var tags: [String] = []
    @State private var newTag: String = ""
    @State private var error: String?

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "doc.badge.plus")
                    .font(.title2)
                Text("Save as Template")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
            }

            // Form
            Form {
                Section("Template Info") {
                    TextField("Name", text: $templateName)
                        .textFieldStyle(.roundedBorder)

                    VStack(alignment: .leading) {
                        Text("Description")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextEditor(text: $templateDescription)
                            .frame(height: 80)
                            .font(.body)
                            .padding(4)
                            .background(Color(NSColor.textBackgroundColor))
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                }

                Section("Category") {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(TemplateCategory.allCases, id: \.self) { category in
                            Label(category.displayName, systemImage: category.iconName)
                                .tag(category)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("Tags") {
                    FlowLayout(spacing: 8) {
                        ForEach(tags, id: \.self) { tag in
                            HStack(spacing: 4) {
                                Text(tag)
                                Button(action: { tags.removeAll { $0 == tag } }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.caption)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.accentColor.opacity(0.2))
                            .cornerRadius(12)
                        }

                        HStack {
                            TextField("Add tag...", text: $newTag, onCommit: addTag)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 100)
                            Button(action: addTag) {
                                Image(systemName: "plus.circle.fill")
                            }
                            .disabled(newTag.isEmpty)
                        }
                    }
                }

                Section("Macro Details") {
                    HStack {
                        Text("Based on:")
                        Spacer()
                        Text(macro.name)
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Events:")
                        Spacer()
                        Text("\(macro.events.count)")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Duration:")
                        Spacer()
                        Text(formatDuration(macro))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .formStyle(.grouped)

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
                .disabled(templateName.isEmpty)
            }
        }
        .padding()
        .frame(width: 500, height: 550)
        .onAppear {
            templateName = macro.name
        }
    }

    private func addTag() {
        let tag = newTag.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !tag.isEmpty && !tags.contains(tag) {
            tags.append(tag)
        }
        newTag = ""
    }

    private func saveTemplate() {
        guard !templateName.isEmpty else {
            error = "Template name is required"
            return
        }

        _ = templateManager.saveAsTemplate(
            macro,
            name: templateName,
            description: templateDescription,
            category: selectedCategory,
            tags: tags
        )

        dismiss()
    }

    private func formatDuration(_ macro: Macro) -> String {
        guard let first = macro.events.first,
              let last = macro.events.last else {
            return "0s"
        }

        let duration = last.timestamp - first.timestamp
        if duration < 1 {
            return String(format: "%.2fs", duration)
        } else if duration < 60 {
            return String(format: "%.1fs", duration)
        } else {
            let minutes = Int(duration / 60)
            let seconds = Int(duration) % 60
            return "\(minutes)m \(seconds)s"
        }
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = computeLayout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = computeLayout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func computeLayout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        let maxWidth = proposal.width ?? .infinity

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: currentY + lineHeight), positions)
    }
}
