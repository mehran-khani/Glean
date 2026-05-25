//
//  StatusPill.swift
//  Glean
//

import SwiftUI

struct StatusPill: View {
    let text: String
    let ok: Bool

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(ok ? Color.accentColor : Color.secondary)
                .frame(width: 6, height: 6)
            Text(text)
                .font(.system(.caption, weight: .semibold))
                .kerning(-0.05)
        }
        .foregroundStyle(ok ? Color.accentColor : Color.secondary)
        .padding(.leading, 6)
        .padding(.trailing, 8)
        .padding(.vertical, 3)
        .background(
            Capsule().fill(
                ok ? Color.accentColor.opacity(0.12)
                    : Color.secondary.opacity(0.12)
            )
        )
    }
}
