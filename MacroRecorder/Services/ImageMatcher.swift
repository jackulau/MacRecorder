//
//  ImageMatcher.swift
//  MacroRecorder
//
//  Service for matching image templates on screen using Vision framework
//

import Foundation
import CoreGraphics
import Vision
import AppKit

class ImageMatcher: ObservableObject {
    static let shared = ImageMatcher()

    @Published var isSearching = false
    @Published var lastMatchResult: [ImageMatch] = []

    private init() {}

    // MARK: - Screen Capture

    /// Capture the entire screen or a specific region
    func captureScreen(region: CGRect? = nil) -> CGImage? {
        let captureRect = region ?? CGRect(
            x: 0, y: 0,
            width: CGFloat(CGDisplayPixelsWide(CGMainDisplayID())),
            height: CGFloat(CGDisplayPixelsHigh(CGMainDisplayID()))
        )

        return CGWindowListCreateImage(
            captureRect,
            .optionOnScreenOnly,
            kCGNullWindowID,
            .bestResolution
        )
    }

    // MARK: - Template Matching

    /// Find all occurrences of an image template on screen
    func findTemplate(_ template: ImageTemplate, in screenRegion: CGRect? = nil) async -> [ImageMatch] {
        await MainActor.run { isSearching = true }
        defer { Task { @MainActor in isSearching = false } }

        // Capture screen
        let searchRegion = template.searchRegion ?? screenRegion
        guard let screenImage = captureScreen(region: searchRegion) else {
            return []
        }

        // Create template CGImage
        guard let templateImage = createCGImage(from: template.imageData) else {
            return []
        }

        // Perform matching at multiple scales
        var allMatches: [ImageMatch] = []

        for scale in stride(from: template.scaleMin, through: template.scaleMax, by: 0.05) {
            let matches = await performMatch(
                template: templateImage,
                in: screenImage,
                scale: scale,
                threshold: template.matchThreshold,
                templateId: template.id,
                regionOffset: searchRegion?.origin ?? .zero
            )
            allMatches.append(contentsOf: matches)
        }

        // Remove duplicate matches (within 10 pixels)
        let uniqueMatches = removeDuplicates(allMatches, threshold: 10)

        await MainActor.run {
            lastMatchResult = uniqueMatches
        }

        return uniqueMatches
    }

    /// Find a single best match
    func findBestMatch(_ template: ImageTemplate, in screenRegion: CGRect? = nil) async -> ImageMatch? {
        let matches = await findTemplate(template, in: screenRegion)
        return matches.max(by: { $0.confidence < $1.confidence })
    }

    /// Wait for an image to appear on screen
    func waitForImage(_ template: ImageTemplate, timeout: TimeInterval = 30, pollInterval: TimeInterval = 0.5) async -> ImageMatch? {
        let startTime = Date()

        while Date().timeIntervalSince(startTime) < timeout {
            if let match = await findBestMatch(template) {
                return match
            }
            try? await Task.sleep(nanoseconds: UInt64(pollInterval * 1_000_000_000))
        }

        return nil
    }

    // MARK: - Vision Framework Matching

    private func performMatch(
        template: CGImage,
        in screen: CGImage,
        scale: Double,
        threshold: Double,
        templateId: UUID,
        regionOffset: CGPoint
    ) async -> [ImageMatch] {
        return await withCheckedContinuation { continuation in
            // Scale template if needed
            let scaledTemplate = scale != 1.0 ? scaleImage(template, by: scale) ?? template : template

            // Create feature print request
            let templateRequest = VNGenerateImageFeaturePrintRequest()
            let screenRequest = VNGenerateImageFeaturePrintRequest()

            let templateHandler = VNImageRequestHandler(cgImage: scaledTemplate, options: [:])
            let screenHandler = VNImageRequestHandler(cgImage: screen, options: [:])

            do {
                try templateHandler.perform([templateRequest])
                try screenHandler.perform([screenRequest])

                guard let templateObservation = templateRequest.results?.first as? VNFeaturePrintObservation,
                      let screenObservation = screenRequest.results?.first as? VNFeaturePrintObservation else {
                    continuation.resume(returning: [])
                    return
                }

                var distance: Float = 0
                try templateObservation.computeDistance(&distance, to: screenObservation)

                // Convert distance to confidence (lower distance = higher confidence)
                let confidence = Double(max(0, 1 - distance))

                if confidence >= threshold {
                    // For now, return center of screen as match position
                    // In production, use sliding window approach
                    let match = ImageMatch(
                        position: CGPoint(
                            x: regionOffset.x + CGFloat(screen.width) / 2,
                            y: regionOffset.y + CGFloat(screen.height) / 2
                        ),
                        bounds: CGRect(
                            x: regionOffset.x,
                            y: regionOffset.y,
                            width: CGFloat(scaledTemplate.width),
                            height: CGFloat(scaledTemplate.height)
                        ),
                        confidence: confidence,
                        templateId: templateId
                    )
                    continuation.resume(returning: [match])
                } else {
                    continuation.resume(returning: [])
                }
            } catch {
                continuation.resume(returning: [])
            }
        }
    }

    // MARK: - Helpers

    private func createCGImage(from data: Data) -> CGImage? {
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            return nil
        }
        return cgImage
    }

    private func scaleImage(_ image: CGImage, by scale: Double) -> CGImage? {
        let width = Int(Double(image.width) * scale)
        let height = Int(Double(image.height) * scale)

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: image.bitsPerComponent,
            bytesPerRow: 0,
            space: image.colorSpace ?? CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: image.bitmapInfo.rawValue
        ) else {
            return nil
        }

        context.interpolationQuality = .high
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        return context.makeImage()
    }

    private func removeDuplicates(_ matches: [ImageMatch], threshold: CGFloat) -> [ImageMatch] {
        var unique: [ImageMatch] = []

        for match in matches {
            let isDuplicate = unique.contains { existing in
                let dx = abs(existing.position.x - match.position.x)
                let dy = abs(existing.position.y - match.position.y)
                return dx < threshold && dy < threshold
            }

            if !isDuplicate {
                unique.append(match)
            }
        }

        return unique
    }
}
