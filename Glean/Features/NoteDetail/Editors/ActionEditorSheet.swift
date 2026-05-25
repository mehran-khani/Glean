//
//  ActionEditorSheet.swift
//  Glean
//

import SwiftUI

struct ActionEditorSheet: View {
    enum Mode {
        case new
        case edit(initialText: String, initialOwner: String?, initialDue: Date?, initialUrgent: Bool)
    }

    let mode: Mode
    var onSave: (_ text: String, _ owner: String?, _ dueDate: Date?, _ urgent: Bool) -> Void
    var onCancel: () -> Void = {}

    @Environment(\.dismiss) private var dismiss

    @State private var text = ""
    @State private var owner = ""
    @State private var hasDueDate = false
    @State private var dueDate: Date = .now
    @State private var urgent = false
    @State private var saveTrigger = false

    @FocusState private var focus: Field?

    private enum Field: Hashable { case text, owner }

    private var trimmedText: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSave: Bool { !trimmedText.isEmpty }

    private var title: String {
        if case .new = mode { return "New action" }
        return "Edit action"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("What needs to happen?", text: $text, axis: .vertical)
                        .lineLimit(1...6)
                        .focused($focus, equals: .text)
                        .submitLabel(.next)
                        .onSubmit { focus = .owner }
                } header: {
                    Text("Action")
                } footer: {
                    Text("Short, specific. Examples: “Draft payments RFC”, “Schedule infra hiring loop”.")
                }

                Section {
                    TextField("Owner (optional)", text: $owner)
                        .focused($focus, equals: .owner)
                        .autocorrectionDisabled()
                        .submitLabel(SubmitLabel.done)
                        .onSubmit { focus = nil }
                } header: {
                    Text("Owner")
                }

                Section {
                    Toggle(isOn: $hasDueDate.animation(.smooth(duration: 0.3))) {
                        Label("Due date", systemImage: "calendar")
                    }
                    if hasDueDate {
                        DatePicker(
                            "Due",
                            selection: $dueDate,
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(.graphical)
                    }
                }

                Section {
                    Toggle(isOn: $urgent) {
                        Label {
                            Text("Mark urgent")
                        } icon: {
                            Image(systemName: "exclamationmark.circle")
                                .foregroundStyle(urgent ? Color(red: 0xC0/255, green: 0x4A/255, blue: 0x24/255) : .secondary)
                        }
                    }
                } footer: {
                    Text("Urgent actions surface first in the list with a coloured due date.")
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                }
            }
            .sensoryFeedback(.success, trigger: saveTrigger)
            .sensoryFeedback(.selection, trigger: hasDueDate)
            .sensoryFeedback(.selection, trigger: urgent)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackgroundInteraction(.disabled)
        .onAppear { applyInitialValues() }
    }

    private func applyInitialValues() {
        switch mode {
        case .new:
            text = ""
            owner = ""
            hasDueDate = false
            dueDate = .now
            urgent = false
            Task { @MainActor in focus = .text }
        case .edit(let t, let o, let d, let u):
            text = t
            owner = o ?? ""
            hasDueDate = d != nil
            dueDate = d ?? .now
            urgent = u
        }
    }

    private func save() {
        guard canSave else { return }
        let trimmedOwner = owner.trimmingCharacters(in: .whitespacesAndNewlines)
        saveTrigger.toggle()
        onSave(
            trimmedText,
            trimmedOwner.isEmpty ? nil : trimmedOwner,
            hasDueDate ? Calendar.current.startOfDay(for: dueDate) : nil,
            urgent
        )
        dismiss()
    }
}

#Preview("New") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            ActionEditorSheet(mode: .new) { _, _, _, _ in }
        }
}

#Preview("Edit") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            ActionEditorSheet(
                mode: .edit(
                    initialText: "Draft payments RFC",
                    initialOwner: "Mira",
                    initialDue: Date().addingTimeInterval(86_400 * 3),
                    initialUrgent: true
                )
            ) { _, _, _, _ in }
        }
}
