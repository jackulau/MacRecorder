//
//  Condition.swift
//  MacroRecorder
//
//  Models for conditional playback logic
//

import Foundation
import CoreGraphics

/// Types of conditions that can be evaluated
enum ConditionType: String, Codable, CaseIterable {
    case pixelColor       // Check pixel color at position
    case windowExists     // Check if window exists
    case windowFocused    // Check if window is focused
    case variableCompare  // Compare variable value
    case always           // Always true or false

    var displayName: String {
        switch self {
        case .pixelColor: return "Pixel Color"
        case .windowExists: return "Window Exists"
        case .windowFocused: return "Window Focused"
        case .variableCompare: return "Variable Compare"
        case .always: return "Always"
        }
    }
}

/// Comparison operators for conditions
enum ComparisonOperator: String, Codable, CaseIterable {
    case equals = "=="
    case notEquals = "!="
    case greaterThan = ">"
    case lessThan = "<"
    case greaterOrEqual = ">="
    case lessOrEqual = "<="
    case contains = "contains"

    var displayName: String {
        switch self {
        case .equals: return "Equals"
        case .notEquals: return "Not Equals"
        case .greaterThan: return "Greater Than"
        case .lessThan: return "Less Than"
        case .greaterOrEqual: return "Greater or Equal"
        case .lessOrEqual: return "Less or Equal"
        case .contains: return "Contains"
        }
    }
}

/// A condition that can be evaluated at runtime
struct Condition: Codable, Identifiable, Equatable {
    let id: UUID
    let type: ConditionType

    // Pixel color condition
    var position: CGPoint?
    var targetColor: String?       // Hex color (e.g., "#FF0000")
    var colorTolerance: Int?       // Color matching tolerance (0-255)

    // Window condition
    var windowBundleId: String?
    var windowTitle: String?

    // Variable condition
    var variableName: String?
    var comparisonOperator: ComparisonOperator?
    var comparisonValue: String?

    // Always condition
    var alwaysValue: Bool?

    init(
        id: UUID = UUID(),
        type: ConditionType,
        position: CGPoint? = nil,
        targetColor: String? = nil,
        colorTolerance: Int? = nil,
        windowBundleId: String? = nil,
        windowTitle: String? = nil,
        variableName: String? = nil,
        comparisonOperator: ComparisonOperator? = nil,
        comparisonValue: String? = nil,
        alwaysValue: Bool? = nil
    ) {
        self.id = id
        self.type = type
        self.position = position
        self.targetColor = targetColor
        self.colorTolerance = colorTolerance
        self.windowBundleId = windowBundleId
        self.windowTitle = windowTitle
        self.variableName = variableName
        self.comparisonOperator = comparisonOperator
        self.comparisonValue = comparisonValue
        self.alwaysValue = alwaysValue
    }

    /// Create a pixel color condition
    static func pixelColor(at position: CGPoint, color: String, tolerance: Int = 10) -> Condition {
        Condition(type: .pixelColor, position: position, targetColor: color, colorTolerance: tolerance)
    }

    /// Create a window exists condition
    static func windowExists(bundleId: String) -> Condition {
        Condition(type: .windowExists, windowBundleId: bundleId)
    }

    /// Create a window focused condition
    static func windowFocused(bundleId: String) -> Condition {
        Condition(type: .windowFocused, windowBundleId: bundleId)
    }

    /// Create a variable comparison condition
    static func variable(_ name: String, _ op: ComparisonOperator, _ value: String) -> Condition {
        Condition(type: .variableCompare, variableName: name, comparisonOperator: op, comparisonValue: value)
    }

    /// Create an always true/false condition
    static func always(_ value: Bool) -> Condition {
        Condition(type: .always, alwaysValue: value)
    }

    var displayString: String {
        switch type {
        case .pixelColor:
            return "Pixel at (\(Int(position?.x ?? 0)), \(Int(position?.y ?? 0))) = \(targetColor ?? "?")"
        case .windowExists:
            return "Window exists: \(windowBundleId ?? "?")"
        case .windowFocused:
            return "Window focused: \(windowBundleId ?? "?")"
        case .variableCompare:
            return "$\(variableName ?? "?") \(comparisonOperator?.rawValue ?? "==") \(comparisonValue ?? "?")"
        case .always:
            return alwaysValue == true ? "Always true" : "Always false"
        }
    }
}

/// Control flow event types for conditional execution
enum ControlFlowType: String, Codable {
    case conditionStart   // If condition begins
    case conditionElse    // Else branch
    case conditionEnd     // End of conditional block
    case loopStart        // Loop begins
    case loopEnd          // Loop ends
    case breakLoop        // Break out of loop
    case continueLoop     // Continue to next iteration
}

/// Configuration for a control flow event
struct ControlFlowConfig: Codable, Equatable {
    let flowType: ControlFlowType
    let condition: Condition?
    let loopCount: Int?          // For counted loops
    let loopVariableName: String? // For variable-based loops

    static func ifCondition(_ condition: Condition) -> ControlFlowConfig {
        ControlFlowConfig(flowType: .conditionStart, condition: condition, loopCount: nil, loopVariableName: nil)
    }

    static func elseCondition() -> ControlFlowConfig {
        ControlFlowConfig(flowType: .conditionElse, condition: nil, loopCount: nil, loopVariableName: nil)
    }

    static func endIf() -> ControlFlowConfig {
        ControlFlowConfig(flowType: .conditionEnd, condition: nil, loopCount: nil, loopVariableName: nil)
    }

    static func loop(count: Int) -> ControlFlowConfig {
        ControlFlowConfig(flowType: .loopStart, condition: nil, loopCount: count, loopVariableName: nil)
    }

    static func loopWhile(_ condition: Condition) -> ControlFlowConfig {
        ControlFlowConfig(flowType: .loopStart, condition: condition, loopCount: nil, loopVariableName: nil)
    }

    static func endLoop() -> ControlFlowConfig {
        ControlFlowConfig(flowType: .loopEnd, condition: nil, loopCount: nil, loopVariableName: nil)
    }
}
