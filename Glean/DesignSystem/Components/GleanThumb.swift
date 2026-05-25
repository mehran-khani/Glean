//
//  GleanThumb.swift
//  Glean
//

import SwiftUI

struct GleanThumb: View {
    enum Variant: String, CaseIterable, Hashable {
        case a, b, c, d, e, f

        var background: Color {
            switch self {
            case .a: return Color(red: 0xE4/255, green: 0xEA/255, blue: 0xE6/255)
            case .b: return Color(red: 0xEF/255, green: 0xE9/255, blue: 0xDE/255)
            case .c: return Color(red: 0xE0/255, green: 0xE6/255, blue: 0xEA/255)
            case .d: return Color(red: 0xED/255, green: 0xE7/255, blue: 0xDE/255)
            case .e: return Color(red: 0xE7/255, green: 0xEA/255, blue: 0xE0/255)
            case .f: return Color(red: 0xEA/255, green: 0xE3/255, blue: 0xD4/255)
            }
        }

        /// Marks at normalized 64×64 base: (x, y, w, h, isRect)
        var marks: [(CGFloat, CGFloat, CGFloat, CGFloat, Bool)] {
            switch self {
            case .a: return [(10,12,30,5,false),(10,22,40,5,false),(10,32,22,5,false),(44,46,14,10,true)]
            case .b: return [(8,12,18,18,true),(32,14,22,5,false),(32,24,18,5,false),(8,40,42,5,false),(8,50,30,5,false)]
            case .c: return [(10,10,44,3,false),(10,18,30,3,false),(10,26,38,3,false),(10,34,18,3,false),(10,42,30,3,false),(10,50,22,3,false)]
            case .d: return [(8,10,16,10,true),(26,10,16,10,true),(44,10,12,10,true),
                             (8,26,16,10,true),(26,26,16,10,true),
                             (8,42,16,10,true),(26,42,16,10,true),(44,42,12,10,true)]
            case .e: return [(10,14,44,4,false),(10,22,28,4,false),(10,30,40,4,false),
                             (10,46,22,12,true),(36,46,20,12,true)]
            case .f: return [(10,12,30,5,false),(10,22,42,5,false),(10,32,26,5,false),(10,42,38,5,false),(10,52,18,5,false)]
            }
        }
    }

    var variant: Variant = .a
    var size: CGFloat = 64
    var radius: CGFloat = GleanRadius.md

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        Canvas { ctx, sz in
            let scale = sz.width / 64
            let ink = Color(red: 40/255, green: 40/255, blue: 42/255).opacity(0.78)

            for (x, y, w, h, isRect) in variant.marks {
                let rect = CGRect(
                    x: x * scale,
                    y: y * scale,
                    width: w * scale,
                    height: h * scale
                )
                if isRect {
                    ctx.stroke(
                        Path(rect),
                        with: .color(ink),
                        lineWidth: max(1, scale)
                    )
                } else {
                    ctx.fill(
                        Path(roundedRect: rect, cornerRadius: rect.height / 2),
                        with: .color(ink)
                    )
                }
            }
        }
        .background(variant.background)
        .overlay(shape.strokeBorder(Color.black.opacity(0.06), lineWidth: 0.5))
        .clipShape(shape)
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

#Preview {
    HStack {
        ForEach(GleanThumb.Variant.allCases, id: \.self) { v in
            GleanThumb(variant: v)
        }
    }
    .padding()
}
