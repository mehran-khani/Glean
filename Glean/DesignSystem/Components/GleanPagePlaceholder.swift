//
//  GleanPagePlaceholder.swift
//  Glean
//

import SwiftUI

struct GleanPagePlaceholder: View {
    private struct Mark: Identifiable {
        let id = UUID()
        enum Kind { case line, box }
        let x: CGFloat
        let y: CGFloat
        let w: CGFloat
        let h: CGFloat
        let kind: Kind
    }

    private static let marks: [Mark] = [
        .init(x: 0.09, y: 0.12, w: 0.36, h: 0.030, kind: .line),
        .init(x: 0.09, y: 0.20, w: 0.22, h: 0.030, kind: .line),
        .init(x: 0.09, y: 0.32, w: 0.28, h: 0.140, kind: .box),
        .init(x: 0.11, y: 0.36, w: 0.20, h: 0.024, kind: .line),
        .init(x: 0.11, y: 0.41, w: 0.15, h: 0.024, kind: .line),
        .init(x: 0.38, y: 0.395, w: 0.17, h: 0.010, kind: .line),
        .init(x: 0.56, y: 0.32, w: 0.28, h: 0.140, kind: .box),
        .init(x: 0.58, y: 0.36, w: 0.20, h: 0.024, kind: .line),
        .init(x: 0.58, y: 0.41, w: 0.14, h: 0.024, kind: .line),
        .init(x: 0.09, y: 0.56, w: 0.42, h: 0.030, kind: .line),
        .init(x: 0.09, y: 0.62, w: 0.30, h: 0.030, kind: .line),
        .init(x: 0.09, y: 0.68, w: 0.38, h: 0.030, kind: .line),
        .init(x: 0.56, y: 0.56, w: 0.32, h: 0.200, kind: .box),
        .init(x: 0.58, y: 0.60, w: 0.22, h: 0.024, kind: .line),
        .init(x: 0.58, y: 0.65, w: 0.26, h: 0.024, kind: .line),
        .init(x: 0.58, y: 0.70, w: 0.18, h: 0.024, kind: .line),
        .init(x: 0.09, y: 0.82, w: 0.20, h: 0.030, kind: .line),
        .init(x: 0.32, y: 0.82, w: 0.15, h: 0.030, kind: .line)
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(
                    stops: [
                        .init(color: Color(red: 0xF1/255, green: 0xEC/255, blue: 0xDF/255), location: 0.0),
                        .init(color: Color(red: 0xDC/255, green: 0xD4/255, blue: 0xC2/255), location: 0.75),
                        .init(color: Color(red: 0xC9/255, green: 0xC0/255, blue: 0xAB/255), location: 1.0)
                    ],
                    startPoint: .center,
                    endPoint: .bottomTrailing
                )

                ForEach(Self.marks) { mark in
                    let w = mark.w * geo.size.width
                    let h = mark.h * geo.size.height
                    let cx = mark.x * geo.size.width + w / 2
                    let cy = mark.y * geo.size.height + h / 2
                    Group {
                        switch mark.kind {
                        case .line:
                            Capsule().fill(Color(red: 35/255, green: 35/255, blue: 45/255).opacity(0.78))
                        case .box:
                            Rectangle().strokeBorder(
                                Color(red: 35/255, green: 35/255, blue: 45/255).opacity(0.78),
                                lineWidth: 2
                            )
                        }
                    }
                    .frame(width: w, height: h)
                    .position(x: cx, y: cy)
                }

                RadialGradient(
                    colors: [Color.clear, Color.black.opacity(0.18)],
                    center: .center,
                    startRadius: geo.size.width * 0.3,
                    endRadius: geo.size.width * 0.75
                )
                .allowsHitTesting(false)
            }
        }
        .accessibilityLabel("Empty page")
    }
}

#Preview {
    GleanPagePlaceholder()
        .frame(width: 360, height: 220)
        .clipShape(RoundedRectangle(cornerRadius: GleanRadius.xl, style: .continuous))
        .padding()
}
