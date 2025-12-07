//
//  DelayConfig.swift
//  MacroRecorder
//
//  Configuration for event delays - supports fixed, random, variable, and expression-based delays
//

import Foundation

enum DelayType: String, Codable, CaseIterable {
    case fixed       // Standard fixed delay
    case random      // Random delay within a range
    case variable    // Reference a named variable
    case expression  // Mathematical expression (e.g., "$baseDelay * 2")

    var displayName: String {
        switch self {
        case .fixed: return "Fixed"
        case .random: return "Random"
        case .variable: return "Variable"
        case .expression: return "Expression"
        }
    }

    var description: String {
        switch self {
        case .fixed: return "Use a specific delay value"
        case .random: return "Random delay between min and max"
        case .variable: return "Use a named variable for delay"
        case .expression: return "Calculate delay using an expression"
        }
    }
}

struct DelayConfig: Codable, Equatable {
    let type: DelayType
    let fixedValue: TimeInterval?      // For fixed delays
    let minValue: TimeInterval?         // For random delays (minimum)
    let maxValue: TimeInterval?         // For random delays (maximum)
    let variableName: String?           // For variable delays
    let expression: String?             // For expression delays (e.g., "$delay * 2")

    /// Create a fixed delay config
    static func fixed(_ value: TimeInterval) -> DelayConfig {
        DelayConfig(
            type: .fixed,
            fixedValue: value,
            minValue: nil,
            maxValue: nil,
            variableName: nil,
            expression: nil
        )
    }

    /// Create a random delay config
    static func random(min: TimeInterval, max: TimeInterval) -> DelayConfig {
        DelayConfig(
            type: .random,
            fixedValue: nil,
            minValue: min,
            maxValue: max,
            variableName: nil,
            expression: nil
        )
    }

    /// Create a variable-based delay config
    static func variable(named: String) -> DelayConfig {
        DelayConfig(
            type: .variable,
            fixedValue: nil,
            minValue: nil,
            maxValue: nil,
            variableName: named,
            expression: nil
        )
    }

    /// Create an expression-based delay config
    static func expression(_ expr: String) -> DelayConfig {
        DelayConfig(
            type: .expression,
            fixedValue: nil,
            minValue: nil,
            maxValue: nil,
            variableName: nil,
            expression: expr
        )
    }

    /// Default fixed delay of 0
    static var zero: DelayConfig {
        .fixed(0)
    }

    /// Display string for the delay configuration
    var displayString: String {
        switch type {
        case .fixed:
            return String(format: "%.3fs", fixedValue ?? 0)
        case .random:
            return String(format: "%.2fs - %.2fs", minValue ?? 0, maxValue ?? 0)
        case .variable:
            return "$\(variableName ?? "unnamed")"
        case .expression:
            return expression ?? ""
        }
    }
}

// MARK: - Migration support for backwards compatibility

extension DelayConfig {
    /// Create from legacy fixed delay value
    init(legacyDelay: TimeInterval) {
        self = .fixed(legacyDelay)
    }
}
