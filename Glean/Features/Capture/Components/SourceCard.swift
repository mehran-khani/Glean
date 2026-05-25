//
//  SourceCard.swift
//  Glean
//

import SwiftUI

struct SourceCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let accent: Bool

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading) {
            iconChip
            Spacer()

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.headline, design: .serif, weight: .semibold))
                    .kerning(-0.2)
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.caption)
                    .kerning(-0.1)
                    .foregroundStyle(.secondary)
                    .lineSpacing(1)
            }
            .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .frame(height: 164)
        .background {
            RoundedRectangle(cornerRadius: GleanRadius.xl, style: .continuous)
                .fill(cardFill)
                .overlay(alignment: .topTrailing) {
                    if accent {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [Color.accentColor.opacity(0.16), Color.accentColor.opacity(0)],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 55
                                )
                            )
                            .frame(width: 110, height: 110)
                            .offset(x: 30, y: -30)
                            .allowsHitTesting(false)
                            .accessibilityHidden(true)
                    }
                }
        }
        .overlay(
            RoundedRectangle(cornerRadius: GleanRadius.xl, style: .continuous)
                .strokeBorder(strokeColor, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: GleanRadius.xl, style: .continuous))
    }

    private var iconChip: some View {
        ZStack {
            RoundedRectangle(cornerRadius: GleanRadius.lg, style: .continuous)
                .fill(accent ? Color.accentColor : Color(.systemFill))
                .frame(width: 44, height: 44)
                .shadow(
                    color: accent
                        ? Color(red: 60/255, green: 90/255, blue: 75/255).opacity(0.22)
                        : Color.clear,
                    radius: 6, x: 0, y: 6
                )
            Image(systemName: icon)
                .font(.system(.title3, weight: .semibold))
                .foregroundStyle(accent ? Color.white : Color.primary)
        }
    }

    private var cardFill: Color {
        accent
            ? Color.accentColor.opacity(colorScheme == .dark ? 0.14 : 0.08)
            : Color(.secondarySystemBackground)
    }

    private var strokeColor: Color {
        accent
            ? Color.accentColor.opacity(colorScheme == .dark ? 0.25 : 0.20)
            : Color(.separator)
    }
}
