//
//  GleanGlass.swift
//  Glean
//

import SwiftUI

struct GleanGlass<Content: View>: View {
    var radius: CGFloat = GleanRadius.xl
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
    }
}
