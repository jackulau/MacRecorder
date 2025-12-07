//
//  MacroTemplate.swift
//  MacroRecorder
//
//  Template model for pre-built and user-created macro templates
//

import Foundation
import CoreGraphics

/// Categories for organizing templates
enum TemplateCategory: String, Codable, CaseIterable {
    case productivity
    case automation
    case testing
    case accessibility
    case gaming
    case custom

    var displayName: String {
        switch self {
        case .productivity: return "Productivity"
        case .automation: return "Automation"
        case .testing: return "Testing"
        case .accessibility: return "Accessibility"
        case .gaming: return "Gaming"
        case .custom: return "Custom"
        }
    }

    var iconName: String {
        switch self {
        case .productivity: return "doc.text"
        case .automation: return "gearshape.2"
        case .testing: return "checkmark.seal"
        case .accessibility: return "accessibility"
        case .gaming: return "gamecontroller"
        case .custom: return "star"
        }
    }
}

/// A macro template with metadata
struct MacroTemplate: Codable, Identifiable {
    let id: UUID
    var name: String
    var description: String
    var category: TemplateCategory
    var tags: [String]
    var macro: Macro
    var author: String?
    var version: String
    var minAppVersion: String?     // Minimum app version required
    var iconName: String?          // SF Symbol name
    var isBuiltIn: Bool            // Whether this is a built-in template
    var createdAt: Date
    var modifiedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        category: TemplateCategory = .custom,
        tags: [String] = [],
        macro: Macro,
        author: String? = nil,
        version: String = "1.0",
        minAppVersion: String? = nil,
        iconName: String? = nil,
        isBuiltIn: Bool = false
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.tags = tags
        self.macro = macro
        self.author = author
        self.version = version
        self.minAppVersion = minAppVersion
        self.iconName = iconName
        self.isBuiltIn = isBuiltIn
        self.createdAt = Date()
        self.modifiedAt = Date()
    }

    /// Create a new macro from this template
    func createMacro(name: String? = nil) -> Macro {
        var newMacro = macro
        if let customName = name {
            newMacro = Macro(id: UUID(), name: customName, events: macro.events)
        } else {
            newMacro = Macro(id: UUID(), name: "\(self.name) Copy", events: macro.events)
        }
        return newMacro
    }
}

/// Manager for template operations
class TemplateManager: ObservableObject {
    static let shared = TemplateManager()

    @Published private(set) var builtInTemplates: [MacroTemplate] = []
    @Published private(set) var userTemplates: [MacroTemplate] = []

    private let userTemplatesKey = "macrorecorder.userTemplates"

    var allTemplates: [MacroTemplate] {
        builtInTemplates + userTemplates
    }

    private init() {
        loadBuiltInTemplates()
        loadUserTemplates()
    }

    // MARK: - Built-in Templates

    private func loadBuiltInTemplates() {
        builtInTemplates = [
            createCopyPasteTemplate(),
            createFormFillerTemplate(),
            createScreenshotSequenceTemplate(),
            createWindowArrangerTemplate(),
            createTextExpanderTemplate()
        ]
    }

    private func createCopyPasteTemplate() -> MacroTemplate {
        let events = [
            MacroEvent(type: .keyDown, timestamp: 0, keyCode: 0x08, flags: UInt64(CGEventFlags.maskCommand.rawValue), delay: 0),
            MacroEvent(type: .keyUp, timestamp: 0.1, keyCode: 0x08, flags: 0, delay: 0.1),
            MacroEvent(type: .keyDown, timestamp: 0.3, keyCode: 0x09, flags: UInt64(CGEventFlags.maskCommand.rawValue), delay: 0.2),
            MacroEvent(type: .keyUp, timestamp: 0.4, keyCode: 0x09, flags: 0, delay: 0.1)
        ]
        let macro = Macro(name: "Copy-Paste", events: events)

        return MacroTemplate(
            name: "Copy & Paste",
            description: "Copy selected text and paste it. Useful as a starting point for clipboard operations.",
            category: .productivity,
            tags: ["copy", "paste", "clipboard"],
            macro: macro,
            author: "MacroRecorder",
            iconName: "doc.on.doc",
            isBuiltIn: true
        )
    }

    private func createFormFillerTemplate() -> MacroTemplate {
        let events = [
            MacroEvent(type: .keyDown, timestamp: 0, keyCode: 0x30, flags: 0, delay: 0),
            MacroEvent(type: .keyUp, timestamp: 0.05, keyCode: 0x30, flags: 0, delay: 0.05),
        ]
        let macro = Macro(name: "Form Filler", events: events)

        return MacroTemplate(
            name: "Form Filler",
            description: "Tab through form fields. Customize with your own keystrokes.",
            category: .productivity,
            tags: ["form", "tab", "input"],
            macro: macro,
            author: "MacroRecorder",
            iconName: "doc.text.fill",
            isBuiltIn: true
        )
    }

    private func createScreenshotSequenceTemplate() -> MacroTemplate {
        let events = [
            MacroEvent(type: .keyDown, timestamp: 0, keyCode: 0x15, flags: UInt64(CGEventFlags.maskCommand.rawValue | CGEventFlags.maskShift.rawValue), delay: 0),
            MacroEvent(type: .keyUp, timestamp: 0.1, keyCode: 0x15, flags: 0, delay: 0.1),
        ]
        let macro = Macro(name: "Screenshot", events: events)

        return MacroTemplate(
            name: "Screenshot Sequence",
            description: "Take screenshots at intervals. Uses Cmd+Shift+4 for region capture.",
            category: .automation,
            tags: ["screenshot", "capture", "image"],
            macro: macro,
            author: "MacroRecorder",
            iconName: "camera",
            isBuiltIn: true
        )
    }

    private func createWindowArrangerTemplate() -> MacroTemplate {
        let macro = Macro(name: "Window Arranger", events: [])

        return MacroTemplate(
            name: "Window Arranger",
            description: "Arrange windows in a grid pattern. Customize positions as needed.",
            category: .automation,
            tags: ["window", "arrange", "layout"],
            macro: macro,
            author: "MacroRecorder",
            iconName: "rectangle.split.2x2",
            isBuiltIn: true
        )
    }

    private func createTextExpanderTemplate() -> MacroTemplate {
        let macro = Macro(name: "Text Expander", events: [])

        return MacroTemplate(
            name: "Text Expander",
            description: "Type common phrases quickly. Add your frequently used text.",
            category: .productivity,
            tags: ["text", "typing", "snippet"],
            macro: macro,
            author: "MacroRecorder",
            iconName: "text.insert",
            isBuiltIn: true
        )
    }

    // MARK: - User Templates

    private func loadUserTemplates() {
        guard let data = UserDefaults.standard.data(forKey: userTemplatesKey),
              let templates = try? JSONDecoder().decode([MacroTemplate].self, from: data) else {
            return
        }
        userTemplates = templates
    }

    private func saveUserTemplates() {
        if let data = try? JSONEncoder().encode(userTemplates) {
            UserDefaults.standard.set(data, forKey: userTemplatesKey)
        }
    }

    func saveAsTemplate(_ macro: Macro, name: String, description: String, category: TemplateCategory, tags: [String]) -> MacroTemplate {
        let template = MacroTemplate(
            name: name,
            description: description,
            category: category,
            tags: tags,
            macro: macro,
            isBuiltIn: false
        )
        userTemplates.append(template)
        saveUserTemplates()
        return template
    }

    func deleteTemplate(_ template: MacroTemplate) {
        guard !template.isBuiltIn else { return }
        userTemplates.removeAll { $0.id == template.id }
        saveUserTemplates()
    }

    func updateTemplate(_ template: MacroTemplate) {
        guard !template.isBuiltIn else { return }
        if let index = userTemplates.firstIndex(where: { $0.id == template.id }) {
            userTemplates[index] = template
            saveUserTemplates()
        }
    }

    // MARK: - Search and Filter

    func templates(for category: TemplateCategory) -> [MacroTemplate] {
        allTemplates.filter { $0.category == category }
    }

    func search(_ query: String) -> [MacroTemplate] {
        guard !query.isEmpty else { return allTemplates }

        let lowercaseQuery = query.lowercased()
        return allTemplates.filter { template in
            template.name.lowercased().contains(lowercaseQuery) ||
            template.description.lowercased().contains(lowercaseQuery) ||
            template.tags.contains { $0.lowercased().contains(lowercaseQuery) }
        }
    }
}
