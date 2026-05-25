//
//  HeroImageSection.swift
//  Glean
//

import SwiftData
import SwiftUI

struct HeroImageSection: View {
    let note: Note

    @Namespace private var heroZoom

    var body: some View {
        NavigationLink {
            SourceImageView(note: note)
                .navigationTransition(.zoom(sourceID: note.id, in: heroZoom))
        } label: {
            ZStack(alignment: .bottomTrailing) {
                content
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(Color.black.opacity(0.05), lineWidth: 0.5)
                    )
                    .shadow(color: Color(red: 40/255, green: 30/255, blue: 20/255).opacity(0.12),
                            radius: 22, x: 0, y: 10)
                    .matchedTransitionSource(id: note.id, in: heroZoom)

                HStack(spacing: 5) {
                    Image(systemName: "camera.viewfinder")
                        .font(.caption2.weight(.bold))
                    Text("View source")
                        .font(.caption2.weight(.semibold))
                        .kerning(0.2)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .glassEffect(.regular.tint(Color.black.opacity(0.45)), in: .capsule)
                .padding(10)
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .accessibilityLabel("View source photo")
    }

    @ViewBuilder
    private var content: some View {
        if let ui = note.thumbnail(maxDimension: 500) {
            Image(uiImage: ui)
                .resizable()
                .scaledToFill()
        } else {
            GleanPagePlaceholder()
        }
    }
}
