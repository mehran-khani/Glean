//
//  EmptyHint.swift
//  Glean
//

import SwiftUI

struct EmptyHint: View {
    let text: LocalizedStringKey

    var body: some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(.tertiary)
            .padding(.vertical, 4)
            .accessibilityHidden(true)
    }
}
