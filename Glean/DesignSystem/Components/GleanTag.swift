//
//  GleanTag.swift
//  Glean
//

import SwiftUI

struct GleanTag: View {
    var text: String
    var accent: Bool = false
    /// Optional SF Symbol drawn before the text (e.g. "number" for hash).
    var leading: String? = nil

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 4) {
            if let leading {
                Image(systemName: leading)
                    .font(.system(.caption2, weight: .semibold))
                    .opacity(0.6)
            }
            Text(text)
                .font(.system(.caption, weight: .medium))
                .kerning(-0.1)
        }
        .foregroundStyle(accent ? Color.accentColor : Color.secondary)
        .padding(.horizontal, 9)
        .frame(height: 24)
        .background(
            Capsule().fill(tagFill)
        )
        .contentShape(.rect(cornerRadius: GleanRadius.lg))
        .frame(minHeight: 44, alignment: .center)
    }

    private var tagFill: Color {
        if accent {
            return Color.accentColor.opacity(colorScheme == .dark ? 0.18 : 0.10)
        }
        return colorScheme == .dark
            ? Color.white.opacity(0.08)
            : Color(red: 60/255, green: 60/255, blue: 67/255).opacity(0.07)
    }
}
