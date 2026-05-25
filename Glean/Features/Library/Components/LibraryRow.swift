//
//  LibraryRow.swift
//  Glean
//

import SwiftUI

struct LibraryRow: View {
    let note: Note

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            thumbnail
            content
            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let ui = note.thumbnail(maxDimension: 64) {
            Image(uiImage: ui)
                .resizable()
                .scaledToFill()
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: GleanRadius.md, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: GleanRadius.md, style: .continuous)
                        .strokeBorder(Color.black.opacity(0.06), lineWidth: 0.5)
                )
        } else {
            GleanThumb(
                variant: GleanThumb.Variant.allCases[abs(note.id.hashValue) % GleanThumb.Variant.allCases.count],
                size: 64,
                radius: GleanRadius.md
            )
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                if note.pinned {
                    Image(systemName: "pin.fill")
                        .font(.caption2)
                        .foregroundStyle(Color.accentColor)
                        .rotationEffect(.degrees(35))
                        .opacity(0.85)
                }
                Text(note.title)
                    .font(.system(.headline, design: .serif, weight: .semibold))
                    .kerning(-0.2)
                    .lineLimit(1)
                    .foregroundStyle(.primary)
            }
            Text(note.summary)
                .font(.footnote)
                .kerning(-0.15)
                .foregroundStyle(.secondary)
                .lineSpacing(2)
                .lineLimit(2)
                .padding(.top, 1)

            HStack(spacing: 6) {
                Text(Note.shortRelativeDate(from: note.createdAt))
                    .font(.system(.caption2, weight: .medium))
                    .monospacedDigit()
                    .kerning(0.1)
                    .foregroundStyle(Color(.tertiaryLabel))
                    .padding(.trailing, 2)
                let visibleTags = Array(note.tags.prefix(3))
                ForEach(visibleTags, id: \.self) { tag in
                    GleanTag(text: tag, accent: tag == visibleTags.first)
                }
                let extra = max(0, note.tags.count - visibleTags.count)
                if extra > 0 {
                    GleanTag(text: "+\(extra)")
                }
            }
            .padding(.top, 5)
        }
    }
}
