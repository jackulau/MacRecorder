//
//  ConditionEvaluator.swift
//  MacroRecorder
//
//  Service for evaluating conditions at runtime
//

import Foundation
import CoreGraphics
import AppKit

class ConditionEvaluator {
    static let shared = ConditionEvaluator()

    private let variableManager = VariableManager.shared
    private let windowDetector = WindowDetector.shared

    private init() {}

    /// Evaluate a condition and return true/false
    func evaluate(_ condition: Condition) -> Bool {
        switch condition.type {
        case .pixelColor:
            return evaluatePixelColor(condition)
        case .windowExists:
            return evaluateWindowExists(condition)
        case .windowFocused:
            return evaluateWindowFocused(condition)
        case .variableCompare:
            return evaluateVariableCompare(condition)
        case .always:
            return condition.alwaysValue ?? true
        }
    }

    // MARK: - Pixel Color

    private func evaluatePixelColor(_ condition: Condition) -> Bool {
        guard let position = condition.position,
              let targetColorHex = condition.targetColor else {
            return false
        }

        // Capture pixel color at position
        guard let pixelColor = getPixelColor(at: position) else {
            return false
        }

        // Parse target color
        guard let targetColor = parseHexColor(targetColorHex) else {
            return false
        }

        // Compare colors with tolerance
        let tolerance = condition.colorTolerance ?? 10
        return colorsMatch(pixelColor, targetColor, tolerance: tolerance)
    }

    private func getPixelColor(at point: CGPoint) -> (r: Int, g: Int, b: Int)? {
        // Create a 1x1 image at the point
        let rect = CGRect(x: point.x, y: point.y, width: 1, height: 1)

        guard let image = CGWindowListCreateImage(
            rect,
            .optionOnScreenOnly,
            kCGNullWindowID,
            .bestResolution
        ) else {
            return nil
        }

        // Get bitmap representation
        let bitmap = NSBitmapImageRep(cgImage: image)
        guard let color = bitmap.colorAt(x: 0, y: 0) else {
            return nil
        }

        let r = Int(color.redComponent * 255)
        let g = Int(color.greenComponent * 255)
        let b = Int(color.blueComponent * 255)

        return (r, g, b)
    }

    private func parseHexColor(_ hex: String) -> (r: Int, g: Int, b: Int)? {
        var hexClean = hex.trimmingCharacters(in: .whitespaces)
        if hexClean.hasPrefix("#") {
            hexClean = String(hexClean.dropFirst())
        }

        guard hexClean.count == 6,
              let hexInt = UInt32(hexClean, radix: 16) else {
            return nil
        }

        let r = Int((hexInt >> 16) & 0xFF)
        let g = Int((hexInt >> 8) & 0xFF)
        let b = Int(hexInt & 0xFF)

        return (r, g, b)
    }

    private func colorsMatch(_ c1: (r: Int, g: Int, b: Int), _ c2: (r: Int, g: Int, b: Int), tolerance: Int) -> Bool {
        return abs(c1.r - c2.r) <= tolerance &&
               abs(c1.g - c2.g) <= tolerance &&
               abs(c1.b - c2.b) <= tolerance
    }

    // MARK: - Window Conditions

    private func evaluateWindowExists(_ condition: Condition) -> Bool {
        guard let bundleId = condition.windowBundleId else {
            return false
        }

        let runningApps = NSWorkspace.shared.runningApplications
        return runningApps.contains { $0.bundleIdentifier == bundleId }
    }

    private func evaluateWindowFocused(_ condition: Condition) -> Bool {
        guard let bundleId = condition.windowBundleId else {
            return false
        }

        guard let frontApp = NSWorkspace.shared.frontmostApplication else {
            return false
        }

        return frontApp.bundleIdentifier == bundleId
    }

    // MARK: - Variable Comparison

    private func evaluateVariableCompare(_ condition: Condition) -> Bool {
        guard let varName = condition.variableName,
              let op = condition.comparisonOperator,
              let compareValue = condition.comparisonValue else {
            return false
        }

        guard let varValue = variableManager.getValue(varName) else {
            return false
        }

        // Compare based on variable type
        switch varValue {
        case .number(let num):
            guard let compareNum = Double(compareValue) else { return false }
            return compareNumbers(num, op, compareNum)

        case .string(let str):
            return compareStrings(str, op, compareValue)

        case .boolean(let bool):
            let compareBool = compareValue.lowercased() == "true"
            return compareBooleans(bool, op, compareBool)

        case .position:
            return false // Position comparison not supported
        }
    }

    private func compareNumbers(_ a: Double, _ op: ComparisonOperator, _ b: Double) -> Bool {
        switch op {
        case .equals: return a == b
        case .notEquals: return a != b
        case .greaterThan: return a > b
        case .lessThan: return a < b
        case .greaterOrEqual: return a >= b
        case .lessOrEqual: return a <= b
        case .contains: return false
        }
    }

    private func compareStrings(_ a: String, _ op: ComparisonOperator, _ b: String) -> Bool {
        switch op {
        case .equals: return a == b
        case .notEquals: return a != b
        case .greaterThan: return a > b
        case .lessThan: return a < b
        case .greaterOrEqual: return a >= b
        case .lessOrEqual: return a <= b
        case .contains: return a.contains(b)
        }
    }

    private func compareBooleans(_ a: Bool, _ op: ComparisonOperator, _ b: Bool) -> Bool {
        switch op {
        case .equals: return a == b
        case .notEquals: return a != b
        default: return false
        }
    }
}
