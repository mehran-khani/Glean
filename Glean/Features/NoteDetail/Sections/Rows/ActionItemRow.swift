//
//  ActionItemRow.swift
//  Glean
//

import SwiftUI

struct ActionItemRow: View {
    let item: ActionItem
    var onTap: () -> Void

    @ScaledMetric(relativeTo: .body) private var ownerCircleSize: CGFloat = 16
    @ScaledMetric(relativeTo: .body) private var ownerInitialFontSize: CGFloat = 9

    private static let dueDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE MMM d"
        return f
    }()

    private var hasMetaRow: Bool {
        item.urgent || (item.owner?.isEmpty == false) || item.dueDate != nil
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                Button {
                    withAnimation(.snappy(duration: 0.22)) {
                        item.isDone.toggle()
                    }
                } label: {
                    checkbox
                }
                .buttonStyle(.plain)
                .sensoryFeedback(.selection, trigger: item.isDone)
                .accessibilityLabel(item.isDone ? "Mark not done" : "Mark done")

                VStack(alignment: .leading, spacing: 5) {
                    Text(item.text)
                        .font(.subheadline)
                        .kerning(-0.15)
                        .foregroundStyle(item.isDone ? Color.secondary : Color.primary)
                        .strikethrough(item.isDone)
                        .lineSpacing(2)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if hasMetaRow {
                        FlowLayout(hSpacing: 6, vSpacing: 4) {
                            if item.urgent {
                                urgentChip
                            }
                            if let owner = item.owner, !owner.isEmpty {
                                ownerChip(owner)
                            }
                            if let due = item.dueDate {
                                dueLabel(due)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(.rect)
                .onTapGesture { onTap() }
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isButton)
                .accessibilityLabel(accessibilityLabel)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 4)
            .contentShape(.rect)
            Divider()
        }
        .opacity(item.isDone ? 0.7 : 1)
    }

    private var accessibilityLabel: String {
        var parts = [item.text]
        if let owner = item.owner, !owner.isEmpty { parts.append("owner \(owner)") }
        if let due = item.dueDate {
            parts.append("due \(Self.dueDateFormatter.string(from: due))")
        }
        if item.urgent { parts.append("urgent") }
        if item.isDone { parts.append("done") }
        return parts.joined(separator: ", ")
    }

    private var checkbox: some View {
        Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
            .font(.title3)
            .symbolRenderingMode(.palette)
            .foregroundStyle(
                item.isDone ? Color.white : Color(.tertiaryLabel),
                item.isDone ? Color.accentColor : Color.clear
            )
            .contentTransition(.symbolEffect(.replace))
            .padding(.top, 1)
            .contentShape(.circle)
    }

    private var urgentChip: some View {
        HStack(spacing: 3) {
            Image(systemName: "exclamationmark")
                .font(.caption2.weight(.bold))
            Text("URGENT")
                .font(.caption2.weight(.bold))
                .kerning(0.4)
        }
        .foregroundStyle(Color(red: 0xC0/255, green: 0x4A/255, blue: 0x24/255))
        .padding(.horizontal, 7)
        .padding(.vertical, 2)
        .background(
            Capsule().fill(Color(red: 0xC0/255, green: 0x4A/255, blue: 0x24/255).opacity(0.12))
        )
    }

    private func ownerChip(_ owner: String) -> some View {
        HStack(spacing: 4) {
            ZStack {
                Circle().fill(Color.accentColor)
                Text(String(owner.prefix(1)))
                    .font(.system(size: ownerInitialFontSize, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: ownerCircleSize, height: ownerCircleSize)
            Text(owner)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.accentColor)
        }
        .padding(.leading, 3)
        .padding(.trailing, 7)
        .padding(.vertical, 2)
        .background(Capsule().fill(Color.accentColor.opacity(0.10)))
    }

    private func dueLabel(_ due: Date) -> some View {
        Text("due \(Self.dueDateFormatter.string(from: due))")
            .font(.caption.weight(.medium))
            .monospacedDigit()
            .foregroundStyle(.secondary)
            .padding(.vertical, 2)
    }
}
