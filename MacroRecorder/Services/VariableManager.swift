//
//  VariableManager.swift
//  MacroRecorder
//
//  Manages macro variables - storage, retrieval, and expression evaluation
//

import Foundation
import Combine

class VariableManager: ObservableObject {
    static let shared = VariableManager()

    /// All variables by name
    @Published private(set) var variables: [String: MacroVariable] = [:]

    /// Variables grouped by scope
    var sessionVariables: [MacroVariable] {
        variables.values.filter { $0.scope == .session }.sorted { $0.name < $1.name }
    }

    var globalVariables: [MacroVariable] {
        variables.values.filter { $0.scope == .global }.sorted { $0.name < $1.name }
    }

    var macroVariables: [MacroVariable] {
        variables.values.filter { $0.scope == .macro }.sorted { $0.name < $1.name }
    }

    private let userDefaultsKey = "macrorecorder.globalVariables"

    private init() {
        loadGlobalVariables()
    }

    // MARK: - Variable Management

    /// Set a variable value
    func setValue(_ name: String, value: VariableValue, scope: VariableScope = .session) {
        if var existing = variables[name] {
            existing.value = value
            variables[name] = existing
        } else {
            variables[name] = MacroVariable(name: name, value: value, scope: scope)
        }

        if scope == .global {
            saveGlobalVariables()
        }
    }

    /// Get a variable value
    func getValue(_ name: String) -> VariableValue? {
        return variables[name]?.value
    }

    /// Get a variable as Double (for delays)
    func getNumber(_ name: String) -> Double? {
        return getValue(name)?.asDouble
    }

    /// Check if a variable exists
    func hasVariable(_ name: String) -> Bool {
        return variables[name] != nil
    }

    /// Delete a variable
    func deleteVariable(_ name: String) {
        let scope = variables[name]?.scope
        variables.removeValue(forKey: name)

        if scope == .global {
            saveGlobalVariables()
        }
    }

    /// Clear all macro-scoped variables (called at end of playback)
    func clearMacroVariables() {
        variables = variables.filter { $0.value.scope != .macro }
    }

    /// Clear all session variables (called on app restart - handled by init)
    func clearSessionVariables() {
        variables = variables.filter { $0.value.scope == .global }
    }

    // MARK: - Expression Evaluation

    /// Resolve a delay configuration to an actual TimeInterval
    func resolveDelay(_ config: DelayConfig) -> TimeInterval {
        switch config.type {
        case .fixed:
            return config.fixedValue ?? 0

        case .random:
            let min = config.minValue ?? 0
            let max = config.maxValue ?? 0
            guard max > min else { return min }
            return Double.random(in: min...max)

        case .variable:
            guard let name = config.variableName else { return 0 }
            return getNumber(name) ?? 0

        case .expression:
            guard let expr = config.expression else { return 0 }
            return evaluateExpression(expr) ?? 0
        }
    }

    /// Evaluate a mathematical expression with variable substitution
    /// Supports: $variableName, +, -, *, /, (), and numbers
    func evaluateExpression(_ expression: String) -> Double? {
        // First, substitute all variables
        var substituted = expression

        // Find all $variableName patterns
        let pattern = "\\$([a-zA-Z_][a-zA-Z0-9_]*)"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return nil
        }

        let matches = regex.matches(in: expression, options: [], range: NSRange(expression.startIndex..., in: expression))

        // Replace in reverse order to preserve indices
        for match in matches.reversed() {
            guard let range = Range(match.range(at: 1), in: expression) else { continue }
            let varName = String(expression[range])

            if let value = getNumber(varName) {
                let fullRange = Range(match.range, in: substituted)!
                substituted.replaceSubrange(fullRange, with: String(value))
            } else {
                // Variable not found, use 0
                let fullRange = Range(match.range, in: substituted)!
                substituted.replaceSubrange(fullRange, with: "0")
            }
        }

        // Use NSExpression to evaluate the mathematical expression
        // Clean up the expression for NSExpression
        substituted = substituted.trimmingCharacters(in: .whitespaces)

        // Try to evaluate using NSExpression
        let nsExpression = NSExpression(format: substituted)
        if let result = nsExpression.expressionValue(with: nil, context: nil) as? NSNumber {
            return result.doubleValue
        }

        return nil
    }

    // MARK: - Persistence

    private func loadGlobalVariables() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let saved = try? JSONDecoder().decode([MacroVariable].self, from: data) else {
            return
        }

        for variable in saved {
            variables[variable.name] = variable
        }
    }

    private func saveGlobalVariables() {
        let globalVars = globalVariables
        if let data = try? JSONEncoder().encode(globalVars) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }

    // MARK: - Built-in Variables

    /// Set up common built-in variables
    func setupBuiltInVariables() {
        // Random value (re-evaluated each time it's accessed would require special handling)
        setValue("random", value: .number(Double.random(in: 0...1)), scope: .session)

        // Common delay presets
        setValue("shortDelay", value: .number(0.1), scope: .session)
        setValue("mediumDelay", value: .number(0.5), scope: .session)
        setValue("longDelay", value: .number(1.0), scope: .session)
    }
}
