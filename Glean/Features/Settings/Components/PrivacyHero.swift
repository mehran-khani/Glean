//
//  PrivacyHero.swift
//  Glean
//

import SwiftUI

struct PrivacyHero: View {
    var onShowDetail: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.accentColor.opacity(0.20), Color.accentColor.opacity(0)],
                        center: .center, startRadius: 0, endRadius: 75
                    )
                )
                .frame(width: 160, height: 160)
                .offset(x: 30, y: -40)
                .allowsHitTesting(false)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 0) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.accentColor)
                        .frame(width: 38, height: 38)
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(.body, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .shadow(color: Color(red: 60/255, green: 90/255, blue: 75/255).opacity(0.22),
                        radius: 6, y: 6)
                .accessibilityHidden(true)

                Text("Your notes stay on this iPhone.")
                    .font(.system(.title3, design: .serif, weight: .semibold))
                    .kerning(-0.3)
                    .foregroundStyle(.primary)
                    .padding(.top, 12)

                Text("No server, no analytics, no cloud LLM fallback. Verify it yourself with Charles or Proxyman.")
                    .font(.footnote)
                    .kerning(-0.15)
                    .foregroundStyle(.secondary)
                    .lineSpacing(3)
                    .padding(.top, 4)
                    .fixedSize(horizontal: false, vertical: true)

                Button(action: onShowDetail) {
                    HStack(spacing: 4) {
                        Text("Read the privacy promise")
                            .font(.system(.footnote, weight: .semibold))
                            .kerning(-0.1)
                        Image(systemName: "chevron.right")
                            .font(.system(.caption2, weight: .bold))
                    }
                    .foregroundStyle(Color.accentColor)
                }
                .buttonStyle(.plain)
                .padding(.top, 14)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .clipShape(RoundedRectangle(cornerRadius: GleanRadius.xl, style: .continuous))
        .background(
            Color(.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: GleanRadius.xl, style: .continuous)
        )
    }
}
