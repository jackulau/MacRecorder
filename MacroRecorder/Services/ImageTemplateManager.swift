//
//  ImageTemplateManager.swift
//  MacroRecorder
//
//  Manager for image template CRUD operations
//

import Foundation
import AppKit

class ImageTemplateManager: ObservableObject {
    static let shared = ImageTemplateManager()

    @Published private(set) var templates: [ImageTemplate] = []

    private let templatesKey = "macrorecorder.imageTemplates"

    private init() {
        loadTemplates()
    }

    // MARK: - CRUD Operations

    func addTemplate(_ template: ImageTemplate) {
        templates.append(template)
        saveTemplates()
    }

    func updateTemplate(_ template: ImageTemplate) {
        if let index = templates.firstIndex(where: { $0.id == template.id }) {
            var updated = template
            updated.modifiedAt = Date()
            templates[index] = updated
            saveTemplates()
        }
    }

    func deleteTemplate(_ template: ImageTemplate) {
        templates.removeAll { $0.id == template.id }
        saveTemplates()
    }

    func deleteTemplate(id: UUID) {
        templates.removeAll { $0.id == id }
        saveTemplates()
    }

    func getTemplate(id: UUID) -> ImageTemplate? {
        templates.first { $0.id == id }
    }

    // MARK: - Template Creation

    /// Create a template from a screen region
    func createTemplate(name: String, from region: CGRect, matchThreshold: Double = 0.8) -> ImageTemplate? {
        // Capture the region
        guard let image = CGWindowListCreateImage(
            region,
            .optionOnScreenOnly,
            kCGNullWindowID,
            .bestResolution
        ) else {
            return nil
        }

        // Convert to PNG data
        guard let data = cgImageToPNGData(image) else {
            return nil
        }

        let template = ImageTemplate(
            name: name,
            imageData: data,
            searchRegion: nil,
            matchThreshold: matchThreshold
        )

        addTemplate(template)
        return template
    }

    /// Create a template from an NSImage
    func createTemplate(name: String, from image: NSImage, searchRegion: CGRect? = nil, matchThreshold: Double = 0.8) -> ImageTemplate? {
        guard let data = image.pngData else {
            return nil
        }

        let template = ImageTemplate(
            name: name,
            imageData: data,
            searchRegion: searchRegion,
            matchThreshold: matchThreshold
        )

        addTemplate(template)
        return template
    }

    /// Create a template from file
    func createTemplate(name: String, fromFile url: URL, matchThreshold: Double = 0.8) -> ImageTemplate? {
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }

        let template = ImageTemplate(
            name: name,
            imageData: data,
            matchThreshold: matchThreshold
        )

        addTemplate(template)
        return template
    }

    // MARK: - Persistence

    private func loadTemplates() {
        guard let data = UserDefaults.standard.data(forKey: templatesKey),
              let decoded = try? JSONDecoder().decode([ImageTemplate].self, from: data) else {
            return
        }
        templates = decoded
    }

    private func saveTemplates() {
        if let data = try? JSONEncoder().encode(templates) {
            UserDefaults.standard.set(data, forKey: templatesKey)
        }
    }

    // MARK: - Export/Import

    func exportTemplate(_ template: ImageTemplate, to url: URL) throws {
        let data = try JSONEncoder().encode(template)
        try data.write(to: url)
    }

    func importTemplate(from url: URL) throws -> ImageTemplate {
        let data = try Data(contentsOf: url)
        let template = try JSONDecoder().decode(ImageTemplate.self, from: data)
        addTemplate(template)
        return template
    }

    // MARK: - Helpers

    private func cgImageToPNGData(_ image: CGImage) -> Data? {
        let bitmapRep = NSBitmapImageRep(cgImage: image)
        return bitmapRep.representation(using: .png, properties: [:])
    }
}

// MARK: - NSImage Extension

extension NSImage {
    var pngData: Data? {
        guard let tiffRepresentation = tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffRepresentation) else {
            return nil
        }
        return bitmapImage.representation(using: .png, properties: [:])
    }
}
