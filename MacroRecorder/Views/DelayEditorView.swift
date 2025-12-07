//
//  DelayEditorView.swift
//  MacroRecorder
//
//  UI for editing event delay configurations
//

import SwiftUI

struct DelayEditorView: View {
    @Binding var delayConfig: DelayConfig
    @ObservedObject var variableManager = VariableManager.shared

    @State private var delayType: DelayType = .fixed
    @State private var fixedValue: Double = 0
    @State private var minValue: Double = 0
    @State private var maxValue: Double = 1
    @State private var variableName: String = ""
    @State private var expression: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Delay type picker
            Picker("Delay Type", selection: $delayType) {
                ForEach(DelayType.allCases, id: \.self) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: delayType) { _ in
                updateConfig()
            }

            // Type-specific editor
            switch delayType {
            case .fixed:
                fixedDelayEditor

            case .random:
                randomDelayEditor

            case .variable:
                variableDelayEditor

            case .expression:
                expressionDelayEditor
            }

            // Preview
            HStack {
                Text("Preview:")
                    .foregroundColor(.secondary)
                Text(delayConfig.displayString)
                    .font(.system(.body, design: .monospaced))
            }
            .font(.caption)
        }
        .padding()
        .onAppear {
            loadFromConfig()
        }
    }

    // MARK: - Editors

    private var fixedDelayEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Fixed delay in seconds")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack {
                TextField("Delay", value: $fixedValue, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100)
                    .onChange(of: fixedValue) { _ in updateConfig() }

                Text("seconds")
                    .foregroundColor(.secondary)

                Spacer()

                // Quick presets
                Button("0.1s") { fixedValue = 0.1; updateConfig() }
                Button("0.5s") { fixedValue = 0.5; updateConfig() }
                Button("1.0s") { fixedValue = 1.0; updateConfig() }
            }
            .buttonStyle(.bordered)
        }
    }

    private var randomDelayEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Random delay between minimum and maximum")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack {
                Text("Min:")
                TextField("Min", value: $minValue, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
                    .onChange(of: minValue) { _ in updateConfig() }

                Text("Max:")
                TextField("Max", value: $maxValue, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
                    .onChange(of: maxValue) { _ in updateConfig() }

                Text("seconds")
                    .foregroundColor(.secondary)
            }

            if minValue > maxValue {
                Text("Warning: Minimum is greater than maximum")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
    }

    private var variableDelayEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Use a variable value as delay")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack {
                Text("$")
                    .font(.system(.body, design: .monospaced))

                if variableManager.variables.isEmpty {
                    TextField("variableName", text: $variableName)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: variableName) { _ in updateConfig() }
                } else {
                    Picker("Variable", selection: $variableName) {
                        Text("Select...").tag("")
                        ForEach(Array(variableManager.variables.keys.sorted()), id: \.self) { name in
                            Text(name).tag(name)
                        }
                    }
                    .onChange(of: variableName) { _ in updateConfig() }
                }
            }

            if !variableName.isEmpty {
                if let value = variableManager.getValue(variableName) {
                    Text("Current value: \(value.displayString)")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
                    Text("Variable not found")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
    }

    private var expressionDelayEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Mathematical expression with variables (e.g., $baseDelay * 2 + 0.1)")
                .font(.caption)
                .foregroundColor(.secondary)

            TextField("Expression", text: $expression)
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))
                .onChange(of: expression) { _ in updateConfig() }

            HStack {
                Text("Operators: + - * / ( )")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                if !expression.isEmpty {
                    if let result = variableManager.evaluateExpression(expression) {
                        Text("= \(String(format: "%.4g", result))s")
                            .font(.caption)
                            .foregroundColor(.green)
                    } else {
                        Text("Invalid expression")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
        }
    }

    // MARK: - Config Management

    private func loadFromConfig() {
        delayType = delayConfig.type
        fixedValue = delayConfig.fixedValue ?? 0
        minValue = delayConfig.minValue ?? 0
        maxValue = delayConfig.maxValue ?? 1
        variableName = delayConfig.variableName ?? ""
        expression = delayConfig.expression ?? ""
    }

    private func updateConfig() {
        switch delayType {
        case .fixed:
            delayConfig = .fixed(fixedValue)
        case .random:
            delayConfig = .random(min: minValue, max: maxValue)
        case .variable:
            delayConfig = .variable(named: variableName)
        case .expression:
            delayConfig = .expression(expression)
        }
    }
}

// MARK: - Compact delay editor for inline use

struct CompactDelayEditor: View {
    @Binding var delayConfig: DelayConfig
    @State private var showFullEditor = false

    var body: some View {
        Button {
            showFullEditor = true
        } label: {
            HStack {
                Image(systemName: delayConfig.type == .fixed ? "clock" : "clock.badge.questionmark")
                    .foregroundColor(.secondary)
                Text(delayConfig.displayString)
                    .font(.system(.body, design: .monospaced))
            }
        }
        .buttonStyle(.bordered)
        .popover(isPresented: $showFullEditor) {
            DelayEditorView(delayConfig: $delayConfig)
                .frame(width: 350)
        }
    }
}

#Preview {
    DelayEditorView(delayConfig: .constant(.fixed(0.5)))
}
