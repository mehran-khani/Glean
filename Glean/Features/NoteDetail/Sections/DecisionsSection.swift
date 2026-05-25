//
//  DecisionsSection.swift
//  Glean
//

import SwiftData
import SwiftUI

struct DecisionsSection: View {
    @Bindable var note: Note

    @Environment(\.noteDetailScrollProxy) private var scrollProxy

    @State private var addTrigger = false
    @State private var deleteTrigger = false
    @State private var freshlyAddedIndex: Int?

    private func rowID(_ idx: Int) -> String { "decision-row-\(idx)" }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(
                title: "Decisions",
                count: note.decisions.isEmpty ? nil : note.decisions.count,
                addLabel: "Add decision"
            ) { addDecision() }

            if note.decisions.isEmpty {
                EmptyHint(text: "No decisions yet. Tap \(Image(systemName: "plus.circle.fill")) to add one.")
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(note.decisions.enumerated()), id: \.offset) { idx, _ in
                        DecisionRow(
                            text: Binding(
                                get: { idx < note.decisions.count ? note.decisions[idx] : "" },
                                set: { newValue in
                                    guard idx < note.decisions.count else { return }
                                    note.decisions[idx] = newValue
                                }
                            ),
                            autoFocus: idx == freshlyAddedIndex,
                            onEmpty: { removeDecision(at: idx) },
                            onDelete: { removeDecision(at: idx) },
                            onBeginEdit: { scrollProxy.reveal(rowID(idx)) }
                        )
                        .id(rowID(idx))
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .opacity.combined(with: .scale(scale: 0.92))
                        ))
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .animation(.snappy(duration: 0.28), value: note.decisions.count)
        .sensoryFeedback(.impact(weight: .light), trigger: addTrigger)
        .sensoryFeedback(.impact(flexibility: .rigid), trigger: deleteTrigger)
    }

    private func addDecision() {
        withAnimation(.snappy(duration: 0.28)) {
            note.decisions.append("")
        }
        freshlyAddedIndex = note.decisions.count - 1
        addTrigger.toggle()
    }

    private func removeDecision(at index: Int) {
        guard index < note.decisions.count else { return }
        withAnimation(.snappy(duration: 0.28)) {
            _ = note.decisions.remove(at: index)
        }
        deleteTrigger.toggle()
    }
}

private struct DecisionRow: View {
    @Binding var text: String
    var autoFocus: Bool
    var onEmpty: () -> Void
    var onDelete: () -> Void
    var onBeginEdit: () -> Void = {}

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color.accentColor)
                .frame(width: 6, height: 6)
                .padding(.top, 9)

            EditableInlineText(
                text: $text,
                placeholder: "New decision…",
                font: .subheadline,
                multiline: true,
                lineSpacing: 2,
                kerning: -0.15,
                autoFocusOnAppear: autoFocus,
                onEmpty: onEmpty,
                onBeginEdit: onBeginEdit
            )
            .accessibilityLabel("Decision")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: GleanRadius.lg, style: .continuous)
                .fill(Color(.systemFill).opacity(0.4))
        )
        .contextMenu {
            Button("Delete", systemImage: "trash", role: .destructive, action: onDelete)
        }
    }
}
