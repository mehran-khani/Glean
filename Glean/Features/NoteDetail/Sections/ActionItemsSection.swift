//
//  ActionItemsSection.swift
//  Glean
//

import SwiftData
import SwiftUI

struct ActionItemsSection: View {
    @Bindable var note: Note

    @Environment(\.modelContext) private var modelContext

    @State private var sheetMode: SheetMode?
    @State private var deleteTrigger = false

    private enum SheetMode: Identifiable {
        case new
        case edit(ActionItem)

        var id: String {
            switch self {
            case .new: return "new"
            case .edit(let item): return item.id.uuidString
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(
                title: "Action items",
                count: note.actionItems.isEmpty ? nil : note.actionItems.count,
                addLabel: "Add action"
            ) {
                sheetMode = .new
            }

            if note.actionItems.isEmpty {
                EmptyHint(text: "No action items yet. Tap \(Image(systemName: "plus.circle.fill")) to add one.")
            } else {
                VStack(spacing: 0) {
                    ForEach(sortedActionItems) { item in
                        ActionItemRow(item: item) {
                            sheetMode = .edit(item)
                        }
                        .contextMenu {
                            Button("Edit", systemImage: "pencil") {
                                sheetMode = .edit(item)
                            }
                            Button("Toggle done",
                                   systemImage: item.isDone ? "circle" : "checkmark.circle")
                            {
                                withAnimation(.snappy(duration: 0.22)) {
                                    item.isDone.toggle()
                                }
                            }
                            Section {
                                Button("Delete", systemImage: "trash", role: .destructive) {
                                    removeActionItem(item)
                                }
                            }
                        }
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .top)),
                            removal: .opacity.combined(with: .scale(scale: 0.94))
                        ))
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .animation(.snappy(duration: 0.28), value: note.actionItems.count)
        .sheet(item: $sheetMode) { mode in
            switch mode {
            case .new:
                ActionEditorSheet(mode: .new) { text, owner, due, urgent in
                    addActionItem(text: text, owner: owner, due: due, urgent: urgent)
                }
            case .edit(let item):
                ActionEditorSheet(
                    mode: .edit(
                        initialText: item.text,
                        initialOwner: item.owner,
                        initialDue: item.dueDate,
                        initialUrgent: item.urgent
                    )
                ) { text, owner, due, urgent in
                    updateActionItem(item, text: text, owner: owner, due: due, urgent: urgent)
                }
            }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: sheetMode != nil) { _, isOpen in
            isOpen
        }
        .sensoryFeedback(.impact(flexibility: .rigid), trigger: deleteTrigger)
    }

    private var sortedActionItems: [ActionItem] {
        note.actionItems.sorted { a, b in
            if a.isDone != b.isDone { return !a.isDone }
            if a.urgent != b.urgent { return a.urgent }
            return (a.dueDate ?? .distantFuture) < (b.dueDate ?? .distantFuture)
        }
    }

    private func addActionItem(text: String, owner: String?, due: Date?, urgent: Bool) {
        let item = ActionItem(text: text, owner: owner, dueDate: due, urgent: urgent, note: note)
        withAnimation(.snappy(duration: 0.28)) {
            modelContext.insert(item)
        }
    }

    private func updateActionItem(_ item: ActionItem, text: String, owner: String?, due: Date?, urgent: Bool) {
        item.text = text
        item.owner = owner
        item.dueDate = due
        item.urgent = urgent
    }

    private func removeActionItem(_ item: ActionItem) {
        withAnimation(.snappy(duration: 0.28)) {
            modelContext.delete(item)
        }
        deleteTrigger.toggle()
    }
}
