//
//  MacroVariable.swift
//  MacroRecorder
//
//  Variable system for storing and using values in macros
//

import Foundation
import CoreGraphics

/// Scope determines how long a variable persists
enum VariableScope: String, Codable, CaseIterable {
    case macro      // Scoped to current macro execution
    case global     // Persisted across macros (saved to UserDefaults)
    case session    // Cleared on app restart (in-memory only)

    var displayName: String {
        switch self {
        case .macro: return "Macro"
        case .global: return "Global"
        case .session: return "Session"
        }
    }

    var description: String {
        switch self {
        case .macro: return "Only available during macro execution"
        case .global: return "Persisted across app restarts"
        case .session: return "Available until app is closed"
        }
    }
}

/// Type-safe variable value
enum VariableValue: Codable, Equatable {
    case number(Double)
    case string(String)
    case boolean(Bool)
    case position(x: Double, y: Double)

    // Custom Codable implementation
    enum CodingKeys: String, CodingKey {
        case type, numberValue, stringValue, boolValue, positionX, positionY
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "number":
            let value = try container.decode(Double.self, forKey: .numberValue)
            self = .number(value)
        case "string":
            let value = try container.decode(String.self, forKey: .stringValue)
            self = .string(value)
        case "boolean":
            let value = try container.decode(Bool.self, forKey: .boolValue)
            self = .boolean(value)
        case "position":
            let x = try container.decode(Double.self, forKey: .positionX)
            let y = try container.decode(Double.self, forKey: .positionY)
            self = .position(x: x, y: y)
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown variable type")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .number(let value):
            try container.encode("number", forKey: .type)
            try container.encode(value, forKey: .numberValue)
        case .string(let value):
            try container.encode("string", forKey: .type)
            try container.encode(value, forKey: .stringValue)
        case .boolean(let value):
            try container.encode("boolean", forKey: .type)
            try container.encode(value, forKey: .boolValue)
        case .position(let x, let y):
            try container.encode("position", forKey: .type)
            try container.encode(x, forKey: .positionX)
            try container.encode(y, forKey: .positionY)
        }
    }

    /// Display string for the value
    var displayString: String {
        switch self {
        case .number(let value):
            return String(format: "%.4g", value)
        case .string(let value):
            return "\"\(value)\""
        case .boolean(let value):
            return value ? "true" : "false"
        case .position(let x, let y):
            return String(format: "(%.1f, %.1f)", x, y)
        }
    }

    /// Type name for display
    var typeName: String {
        switch self {
        case .number: return "Number"
        case .string: return "String"
        case .boolean: return "Boolean"
        case .position: return "Position"
        }
    }

    /// Get as Double (for delay calculations)
    var asDouble: Double? {
        switch self {
        case .number(let value): return value
        case .string(let value): return Double(value)
        case .boolean(let value): return value ? 1.0 : 0.0
        case .position: return nil
        }
    }

    /// Get as CGPoint (for position)
    var asPoint: CGPoint? {
        switch self {
        case .position(let x, let y): return CGPoint(x: x, y: y)
        default: return nil
        }
    }
}

/// A named variable with value and scope
struct MacroVariable: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var value: VariableValue
    var scope: VariableScope
    var description: String?

    init(id: UUID = UUID(), name: String, value: VariableValue, scope: VariableScope = .session, description: String? = nil) {
        self.id = id
        self.name = name
        self.value = value
        self.scope = scope
        self.description = description
    }

    /// Create a number variable
    static func number(_ name: String, value: Double, scope: VariableScope = .session) -> MacroVariable {
        MacroVariable(name: name, value: .number(value), scope: scope)
    }

    /// Create a string variable
    static func string(_ name: String, value: String, scope: VariableScope = .session) -> MacroVariable {
        MacroVariable(name: name, value: .string(value), scope: scope)
    }

    /// Create a boolean variable
    static func boolean(_ name: String, value: Bool, scope: VariableScope = .session) -> MacroVariable {
        MacroVariable(name: name, value: .boolean(value), scope: scope)
    }

    /// Create a position variable
    static func position(_ name: String, x: Double, y: Double, scope: VariableScope = .session) -> MacroVariable {
        MacroVariable(name: name, value: .position(x: x, y: y), scope: scope)
    }
}
