//
//  VariablesPanelView.swift
//  MacroRecorder
//
//  Panel for viewing and managing macro variables
//

import SwiftUI

struct VariablesPanelView: View {
    @ObservedObject var variableManager = VariableManager.shared
    @State private var showAddVariable = false
    @State private var selectedScope: VariableScope = .session
    @State private var searchText = ""

    private var filteredVariables: [MacroVariable] {
        let scopeVars: [MacroVariable]
        switch selectedScope {
        case .session:
            scopeVars = variableManager.sessionVariables
        case .global:
            scopeVars = variableManager.globalVariables
        case .macro:
            scopeVars = variableManager.macroVariables
        }

        if searchText.isEmpty {
            return scopeVars
        }

        return scopeVars.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Variables")
                    .font(.headline)

                Spacer()

                Button {
                    showAddVariable = true
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderless)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            // Scope picker
            Picker("Scope", selection: $selectedScope) {
                ForEach(VariableScope.allCases, id: \.self) { scope in
                    Text(scope.displayName).tag(scope)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)

            // Search
            TextField("Search variables...", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)

            // Variable list
            if filteredVariables.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tray")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    Text("No variables")
                        .foregroundColor(.secondary)
                    Text("Add a variable to store values for use in macros")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                List {
                    ForEach(filteredVariables) { variable in
                        VariableRowView(variable: variable) {
                            variableManager.deleteVariable(variable.name)
                        }
                    }
                }
                .listStyle(.inset)
            }
        }
        .frame(minWidth: 250)
        .sheet(isPresented: $showAddVariable) {
            AddVariableView(scope: selectedScope)
        }
    }
}

struct VariableRowView: View {
    let variable: MacroVariable
    let onDelete: () -> Void
    @State private var showEdit = false

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("$\(variable.name)")
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.medium)

                    Text(variable.value.typeName)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.2))
                        .cornerRadius(4)
                }

                Text(variable.value.displayString)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button {
                showEdit = true
            } label: {
                Image(systemName: "pencil")
            }
            .buttonStyle(.borderless)

            Button {
                onDelete()
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
            .foregroundColor(.red)
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showEdit) {
            EditVariableView(variable: variable)
        }
    }
}

struct AddVariableView: View {
    let scope: VariableScope
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var variableManager = VariableManager.shared

    @State private var name = ""
    @State private var selectedType = 0 // 0=number, 1=string, 2=boolean, 3=position
    @State private var numberValue: Double = 0
    @State private var stringValue = ""
    @State private var boolValue = false
    @State private var positionX: Double = 0
    @State private var positionY: Double = 0
    @State private var description = ""
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        VStack(spacing: 16) {
            Text("Add Variable")
                .font(.headline)

            Form {
                TextField("Name (no spaces)", text: $name)
                    .textFieldStyle(.roundedBorder)

                Picker("Type", selection: $selectedType) {
                    Text("Number").tag(0)
                    Text("String").tag(1)
                    Text("Boolean").tag(2)
                    Text("Position").tag(3)
                }

                switch selectedType {
                case 0:
                    TextField("Value", value: $numberValue, format: .number)
                        .textFieldStyle(.roundedBorder)
                case 1:
                    TextField("Value", text: $stringValue)
                        .textFieldStyle(.roundedBorder)
                case 2:
                    Toggle("Value", isOn: $boolValue)
                case 3:
                    HStack {
                        TextField("X", value: $positionX, format: .number)
                            .textFieldStyle(.roundedBorder)
                        TextField("Y", value: $positionY, format: .number)
                            .textFieldStyle(.roundedBorder)
                    }
                default:
                    EmptyView()
                }

                TextField("Description (optional)", text: $description)
                    .textFieldStyle(.roundedBorder)
            }
            .formStyle(.grouped)

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Add") {
                    addVariable()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.isEmpty || name.contains(" "))
            }
        }
        .padding()
        .frame(width: 350)
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private func addVariable() {
        // Validate name
        let cleanName = name.trimmingCharacters(in: .whitespaces)
        guard !cleanName.isEmpty else {
            errorMessage = "Variable name cannot be empty"
            showError = true
            return
        }

        guard !cleanName.contains(" ") else {
            errorMessage = "Variable name cannot contain spaces"
            showError = true
            return
        }

        guard variableManager.getValue(cleanName) == nil else {
            errorMessage = "Variable '\(cleanName)' already exists"
            showError = true
            return
        }

        let value: VariableValue
        switch selectedType {
        case 0: value = .number(numberValue)
        case 1: value = .string(stringValue)
        case 2: value = .boolean(boolValue)
        case 3: value = .position(x: positionX, y: positionY)
        default: value = .number(0)
        }

        variableManager.setValue(cleanName, value: value, scope: scope)
        dismiss()
    }
}

struct EditVariableView: View {
    let variable: MacroVariable
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var variableManager = VariableManager.shared

    @State private var numberValue: Double = 0
    @State private var stringValue = ""
    @State private var boolValue = false
    @State private var positionX: Double = 0
    @State private var positionY: Double = 0

    var body: some View {
        VStack(spacing: 16) {
            Text("Edit $\(variable.name)")
                .font(.headline)

            Form {
                Text("Type: \(variable.value.typeName)")
                    .foregroundColor(.secondary)

                switch variable.value {
                case .number:
                    TextField("Value", value: $numberValue, format: .number)
                        .textFieldStyle(.roundedBorder)
                case .string:
                    TextField("Value", text: $stringValue)
                        .textFieldStyle(.roundedBorder)
                case .boolean:
                    Toggle("Value", isOn: $boolValue)
                case .position:
                    HStack {
                        TextField("X", value: $positionX, format: .number)
                            .textFieldStyle(.roundedBorder)
                        TextField("Y", value: $positionY, format: .number)
                            .textFieldStyle(.roundedBorder)
                    }
                }
            }
            .formStyle(.grouped)

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Save") {
                    saveVariable()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 300)
        .onAppear {
            loadValue()
        }
    }

    private func loadValue() {
        switch variable.value {
        case .number(let val): numberValue = val
        case .string(let val): stringValue = val
        case .boolean(let val): boolValue = val
        case .position(let x, let y): positionX = x; positionY = y
        }
    }

    private func saveVariable() {
        let newValue: VariableValue
        switch variable.value {
        case .number: newValue = .number(numberValue)
        case .string: newValue = .string(stringValue)
        case .boolean: newValue = .boolean(boolValue)
        case .position: newValue = .position(x: positionX, y: positionY)
        }

        variableManager.setValue(variable.name, value: newValue, scope: variable.scope)
        dismiss()
    }
}

#Preview {
    VariablesPanelView()
}
