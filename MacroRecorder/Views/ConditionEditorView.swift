//
//  ConditionEditorView.swift
//  MacroRecorder
//
//  View for editing conditions in control flow events
//

import SwiftUI

struct ConditionEditorView: View {
    @Binding var condition: Condition
    @StateObject private var variableManager = VariableManager.shared
    @State private var selectedType: ConditionType

    init(condition: Binding<Condition>) {
        self._condition = condition
        self._selectedType = State(initialValue: condition.wrappedValue.type)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Condition type picker
            HStack {
                Text("Condition Type:")
                Picker("", selection: $selectedType) {
                    ForEach(ConditionType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .onChange(of: selectedType) { newType in
                    updateConditionType(newType)
                }
            }

            Divider()

            // Type-specific editors
            switch condition.type {
            case .pixelColor:
                pixelColorEditor
            case .windowExists:
                windowExistsEditor
            case .windowFocused:
                windowFocusedEditor
            case .variableCompare:
                variableCompareEditor
            case .always:
                alwaysEditor
            }

            // Preview
            GroupBox("Condition Preview") {
                Text(condition.displayString)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }

    // MARK: - Pixel Color Editor

    private var pixelColorEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Check pixel color at position")
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack {
                Text("X:")
                TextField("0", value: Binding(
                    get: { Double(condition.position?.x ?? 0) },
                    set: { updateCondition(position: CGPoint(x: $0, y: Double(condition.position?.y ?? 0))) }
                ), format: .number)
                .frame(width: 80)

                Text("Y:")
                TextField("0", value: Binding(
                    get: { Double(condition.position?.y ?? 0) },
                    set: { updateCondition(position: CGPoint(x: Double(condition.position?.x ?? 0), y: $0)) }
                ), format: .number)
                .frame(width: 80)

                Button("Pick...") {
                    // TODO: Implement screen position picker
                }
            }

            HStack {
                Text("Target Color:")
                TextField("#FF0000", text: Binding(
                    get: { condition.targetColor ?? "#FF0000" },
                    set: { updateCondition(targetColor: $0) }
                ))
                .frame(width: 100)

                if let hex = condition.targetColor {
                    Rectangle()
                        .fill(Color(hex: hex) ?? .clear)
                        .frame(width: 24, height: 24)
                        .cornerRadius(4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                }

                Button("Pick Color...") {
                    // TODO: Implement color picker from screen
                }
            }

            HStack {
                Text("Tolerance:")
                Slider(value: Binding(
                    get: { Double(condition.colorTolerance ?? 10) },
                    set: { updateCondition(colorTolerance: Int($0)) }
                ), in: 0...50, step: 1)
                Text("\(condition.colorTolerance ?? 10)")
                    .frame(width: 30)
            }
        }
    }

    // MARK: - Window Exists Editor

    private var windowExistsEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Check if application is running")
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack {
                Text("Bundle ID:")
                TextField("com.apple.finder", text: Binding(
                    get: { condition.windowBundleId ?? "" },
                    set: { updateCondition(bundleId: $0) }
                ))

                Button("Select App...") {
                    selectApplication()
                }
            }
        }
    }

    // MARK: - Window Focused Editor

    private var windowFocusedEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Check if application is in focus")
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack {
                Text("Bundle ID:")
                TextField("com.apple.finder", text: Binding(
                    get: { condition.windowBundleId ?? "" },
                    set: { updateCondition(bundleId: $0) }
                ))

                Button("Select App...") {
                    selectApplication()
                }
            }
        }
    }

    // MARK: - Variable Compare Editor

    private var variableCompareEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Compare variable value")
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack {
                Text("$")
                if variableManager.variables.isEmpty {
                    TextField("variableName", text: Binding(
                        get: { condition.variableName ?? "" },
                        set: { updateCondition(variableName: $0) }
                    ))
                    .frame(width: 120)
                } else {
                    Picker("", selection: Binding(
                        get: { condition.variableName ?? "" },
                        set: { updateCondition(variableName: $0) }
                    )) {
                        ForEach(Array(variableManager.variables.keys), id: \.self) { name in
                            Text(name).tag(name)
                        }
                    }
                    .frame(width: 120)
                }

                Picker("", selection: Binding(
                    get: { condition.comparisonOperator ?? .equals },
                    set: { updateCondition(comparisonOperator: $0) }
                )) {
                    ForEach(ComparisonOperator.allCases, id: \.self) { op in
                        Text(op.rawValue).tag(op)
                    }
                }
                .frame(width: 80)

                TextField("value", text: Binding(
                    get: { condition.comparisonValue ?? "" },
                    set: { updateCondition(comparisonValue: $0) }
                ))
                .frame(width: 100)
            }
        }
    }

    // MARK: - Always Editor

    private var alwaysEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Always evaluates to a fixed value")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Picker("Value:", selection: Binding(
                get: { condition.alwaysValue ?? true },
                set: { updateCondition(alwaysValue: $0) }
            )) {
                Text("True").tag(true)
                Text("False").tag(false)
            }
            .pickerStyle(.segmented)
            .frame(width: 200)
        }
    }

    // MARK: - Actions

    private func updateConditionType(_ type: ConditionType) {
        condition = Condition(type: type)
    }

    private func updateCondition(
        position: CGPoint? = nil,
        targetColor: String? = nil,
        colorTolerance: Int? = nil,
        bundleId: String? = nil,
        variableName: String? = nil,
        comparisonOperator: ComparisonOperator? = nil,
        comparisonValue: String? = nil,
        alwaysValue: Bool? = nil
    ) {
        condition = Condition(
            id: condition.id,
            type: condition.type,
            position: position ?? condition.position,
            targetColor: targetColor ?? condition.targetColor,
            colorTolerance: colorTolerance ?? condition.colorTolerance,
            windowBundleId: bundleId ?? condition.windowBundleId,
            windowTitle: condition.windowTitle,
            variableName: variableName ?? condition.variableName,
            comparisonOperator: comparisonOperator ?? condition.comparisonOperator,
            comparisonValue: comparisonValue ?? condition.comparisonValue,
            alwaysValue: alwaysValue ?? condition.alwaysValue
        )
    }

    private func selectApplication() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")

        if panel.runModal() == .OK, let url = panel.url {
            if let bundle = Bundle(url: url),
               let bundleId = bundle.bundleIdentifier {
                updateCondition(bundleId: bundleId)
            }
        }
    }
}

// MARK: - Color Extension

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        guard hexSanitized.count == 6,
              let int = UInt64(hexSanitized, radix: 16) else {
            return nil
        }

        let r = Double((int >> 16) & 0xFF) / 255.0
        let g = Double((int >> 8) & 0xFF) / 255.0
        let b = Double(int & 0xFF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}
