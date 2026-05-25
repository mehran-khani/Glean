//
//  TitleMetaSection.swift
//  Glean
//

import SwiftData
import SwiftUI

struct TitleMetaSection: View {
    @Bindable var note: Note

    @Environment(\.noteDetailScrollProxy) private var scrollProxy

    private static let scrollID = "title-section"

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d, HH:mm"
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            EditableInlineText(
                text: $note.title,
                placeholder: "Untitled",
                font: .system(.title, design: .serif, weight: .semibold),
                kerning: -0.4,
                onEmpty: { note.title = "Untitled" },
                onBeginEdit: { scrollProxy.reveal(Self.scrollID) }
            )
            .accessibilityLabel("Title")
            .accessibilityValue(note.title)

            metaRow
                .font(.footnote.weight(.medium))
                .kerning(0.2)
                .foregroundStyle(Color(.tertiaryLabel))
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .id(Self.scrollID)
    }

    @ViewBuilder
    private var metaRow: some View {
        HStack(spacing: 8) {
            Text(Self.dateFormatter.string(from: note.createdAt).uppercased())
            if !note.decisions.isEmpty {
                circleDivider
                Text("\(note.decisions.count) \(note.decisions.count == 1 ? "DECISION" : "DECISIONS")")
            }
            if !note.actionItems.isEmpty {
                circleDivider
                Text("\(note.actionItems.count) \(note.actionItems.count == 1 ? "ACTION" : "ACTIONS")")
            }
            if note.pinned {
                circleDivider
                Label("PINNED", systemImage: "pin.fill")
                    .labelStyle(.titleAndIcon)
                    .foregroundStyle(Color.accentColor)
            }
        }
    }

    private var circleDivider: some View {
        Circle()
            .fill(Color(.quaternaryLabel))
            .frame(width: 2, height: 2)
    }
}
