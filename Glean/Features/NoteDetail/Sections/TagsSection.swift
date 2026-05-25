//
//  TagsSection.swift
//  Glean
//

import SwiftData
import SwiftUI

struct TagsSection: View {
    @Bindable var note: Note

    @Environment(\.noteDetailScrollProxy) private var scrollProxy

    private static let scrollID = "tags-section"

    @State private var addTrigger = false
    @State private var deleteTrigger = false
    @State private var freshlyAddedIndex: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(
                title: "Tags",
                count: note.tags.isEmpty ? nil : note.tags.count,
                addLabel: "Add tag"
            ) { addTag() }

            if note.tags.isEmpty {
                EmptyHint(text: "No tags yet. Tap \(Image(systemName: "plus.circle.fill")) to add one.")
            } else {
                FlowLayout(hSpacing: 6, vSpacing: 6) {
                    ForEach(Array(note.tags.enumerated()), id: \.offset) { idx, _ in
                        EditableTagChip(
                            text: Binding(
                                get: { idx < note.tags.count ? note.tags[idx] : "" },
                                set: { newValue in
                                    guard idx < note.tags.count else { return }
                                    note.tags[idx] = newValue
                                }
                            ),
                            accent: idx == 0,
                            autoFocus: idx == freshlyAddedIndex,
                            onEmpty: { removeTag(at: idx) },
                            onDelete: { removeTag(at: idx) },
                            onBeginEdit: { scrollProxy.reveal(Self.scrollID) },
                            isDuplicate: { candidate in
                                note.tags.enumerated().contains { otherIdx, t in
                                    otherIdx != idx && t == candidate
                                }
                            }
                        )
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.92)),
                            removal: .opacity.combined(with: .scale(scale: 0.92))
                        ))
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .id(Self.scrollID)
        .animation(.snappy(duration: 0.28), value: note.tags.count)
        .sensoryFeedback(.impact(weight: .light), trigger: addTrigger)
        .sensoryFeedback(.impact(flexibility: .rigid), trigger: deleteTrigger)
    }

    private func addTag() {
        withAnimation(.snappy(duration: 0.28)) {
            note.tags.append("")
        }
        freshlyAddedIndex = note.tags.count - 1
        addTrigger.toggle()
    }

    private func removeTag(at index: Int) {
        guard index < note.tags.count else { return }
        withAnimation(.snappy(duration: 0.28)) {
            _ = note.tags.remove(at: index)
        }
        deleteTrigger.toggle()
    }
}
