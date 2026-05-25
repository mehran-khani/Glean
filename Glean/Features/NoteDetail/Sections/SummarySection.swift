//
//  SummarySection.swift
//  Glean
//

import SwiftData
import SwiftUI

struct SummarySection: View {
    @Bindable var note: Note

    @Environment(\.noteDetailScrollProxy) private var scrollProxy

    private static let scrollID = "summary-section"

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Summary")
            if note.isPlainOCR {
                plainOCRBadge
            }
            EditableInlineText(
                text: $note.summary,
                placeholder: "Add a summary…",
                font: .system(.body, design: .serif),
                multiline: true,
                lineSpacing: 4,
                kerning: -0.1,
                onEmpty: { note.summary = "" },
                onBeginEdit: { scrollProxy.reveal(Self.scrollID) }
            )
            .padding(.top, note.isPlainOCR ? 0 : 2)
            .accessibilityLabel("Summary")
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .id(Self.scrollID)
    }

    private var plainOCRBadge: some View {
        HStack(spacing: 5) {
            Image(systemName: "doc.text")
                .font(.caption2.weight(.semibold))
            Text("Plain OCR — Apple Intelligence not available")
                .font(.caption.weight(.medium))
                .kerning(0.1)
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Capsule().fill(Color(.tertiarySystemFill)))
        .accessibilityElement(children: .combine)
    }
}
