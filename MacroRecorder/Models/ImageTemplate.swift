//
//  ImageTemplate.swift
//  MacroRecorder
//
//  Model for image templates used in visual element detection
//

import Foundation
import CoreGraphics
import ImageIO

/// An image template for visual matching
struct ImageTemplate: Codable, Identifiable, Equatable, Hashable {
    let id: UUID
    var name: String
    var imageData: Data           // PNG image data
    var searchRegion: CGRect?     // Optional search region (nil = whole screen)
    var matchThreshold: Double    // 0.0 - 1.0 confidence threshold
    var scaleMin: Double          // Minimum scale for matching (e.g., 0.8)
    var scaleMax: Double          // Maximum scale for matching (e.g., 1.2)
    var createdAt: Date
    var modifiedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        imageData: Data,
        searchRegion: CGRect? = nil,
        matchThreshold: Double = 0.8,
        scaleMin: Double = 0.9,
        scaleMax: Double = 1.1
    ) {
        self.id = id
        self.name = name
        self.imageData = imageData
        self.searchRegion = searchRegion
        self.matchThreshold = matchThreshold
        self.scaleMin = scaleMin
        self.scaleMax = scaleMax
        self.createdAt = Date()
        self.modifiedAt = Date()
    }

    var scaleRange: ClosedRange<Double> {
        scaleMin...scaleMax
    }

    /// Get the image size from the data
    var imageSize: CGSize? {
        guard let imageSource = CGImageSourceCreateWithData(imageData as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any],
              let width = properties[kCGImagePropertyPixelWidth as String] as? Int,
              let height = properties[kCGImagePropertyPixelHeight as String] as? Int else {
            return nil
        }
        return CGSize(width: width, height: height)
    }
}

/// Result of an image search
struct ImageMatch: Identifiable {
    let id = UUID()
    let position: CGPoint      // Center of match
    let bounds: CGRect         // Full bounds
    let confidence: Double     // Match confidence (0-1)
    let templateId: UUID

    var center: CGPoint {
        CGPoint(x: bounds.midX, y: bounds.midY)
    }
}

/// Configuration for image-based events
struct ImageEventConfig: Codable, Equatable {
    let templateId: UUID
    var clickOffset: CGPoint?          // Offset from image center
    var waitTimeout: TimeInterval?     // Max wait time (for waitForImage)
    var requiredConfidence: Double     // Minimum match confidence

    static func click(templateId: UUID, offset: CGPoint? = nil, confidence: Double = 0.8) -> ImageEventConfig {
        ImageEventConfig(templateId: templateId, clickOffset: offset, waitTimeout: nil, requiredConfidence: confidence)
    }

    static func waitFor(templateId: UUID, timeout: TimeInterval = 30, confidence: Double = 0.8) -> ImageEventConfig {
        ImageEventConfig(templateId: templateId, clickOffset: nil, waitTimeout: timeout, requiredConfidence: confidence)
    }
}
