//
//  SectionHeader.swift
//  Glean
//

import SwiftUI

struct SectionHeader: View {
    let title: String
    var count: Int? = nil
    var addLabel: String? = nil
    var onAdd: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Text(title)
                .font(.system(.headline, design: .serif, weight: .semibold))
                .kerning(-0.2)
                .foregroundStyle(.primary)

            if let count {
                Text("\(count)")
                    .font(.caption.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(Color(.tertiaryLabel))
                    .contentTransition(.numericText(value: Double(count)))
            }

            if let onAdd, let addLabel {
                Button(action: onAdd) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(Color.accentColor)
                        .contentShape(.circle)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(addLabel)
            }

            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }
}
