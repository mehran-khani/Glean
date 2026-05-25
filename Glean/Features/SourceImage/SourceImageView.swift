//
//  SourceImageView.swift
//  Glean
//

import CoreTransferable
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct SourceImageView: View {
    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d · HH:mm"
        return f
    }()

    let note: Note

    @Environment(\.dismiss) private var dismiss

    @State private var image: UIImage?

    @State private var currentScale: CGFloat = 1.0
    @State private var currentOffset: CGSize = .zero

    @State private var saveTrigger = false
    @State private var copyTrigger = false

    @GestureState private var magnifyBy: CGFloat = 1.0
    @GestureState private var dragOffset: CGSize = .zero

    private var totalScale: CGFloat { currentScale * magnifyBy }
    private var totalOffset: CGSize {
        CGSize(
            width: currentOffset.width + dragOffset.width,
            height: currentOffset.height + dragOffset.height
        )
    }

    var body: some View {
        ZStack {
            Color(red: 10/255, green: 9/255, blue: 7/255)
                .ignoresSafeArea()

            imageLayer

            VStack {
                Spacer()
                infoStrip
            }
        }
        .navigationTitle("")
        .navigationBarBackButtonHidden(true)
        .toolbar { toolbarContent }
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sensoryFeedback(.success, trigger: saveTrigger)
        .sensoryFeedback(.impact(weight: .light), trigger: copyTrigger)
        .preferredColorScheme(.dark)
        .task {
            // Decoded async so the zoom transition isn't blocked by the
            // full-res JPEG decode; the thumbnail covers the screen meanwhile.
            guard image == nil else { return }
            let data = note.imageData
            let decoded = await Task.detached(priority: .userInitiated) {
                UIImage(data: data)
            }.value
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.15)) {
                    image = decoded
                }
            }
        }
    }

    @ViewBuilder
    private var imageLayer: some View {
        if let ui = image {
            Image(uiImage: ui)
                .resizable()
                .scaledToFit()
                .scaleEffect(totalScale)
                .offset(totalOffset)
                .gesture(SimultaneousGesture(magnifyGesture, dragGesture))
                .onTapGesture(count: 2) { toggleZoom() }
                .animation(.spring(response: 0.35, dampingFraction: 0.78), value: currentScale)
                .animation(.spring(response: 0.35, dampingFraction: 0.78), value: currentOffset)
        } else if let thumb = note.thumbnail(maxDimension: 500) {
            Image(uiImage: thumb)
                .resizable()
                .scaledToFit()
        } else {
            GleanPagePlaceholder()
                .ignoresSafeArea()
        }
    }

    private var magnifyGesture: some Gesture {
        MagnifyGesture()
            .updating($magnifyBy) { value, state, _ in
                state = value.magnification
            }
            .onEnded { value in
                let proposed = currentScale * value.magnification
                currentScale = min(4.0, max(1.0, proposed))
                if currentScale == 1.0 { currentOffset = .zero }
            }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .updating($dragOffset) { value, state, _ in
                state = value.translation
            }
            .onEnded { value in
                guard currentScale > 1.0 else { return }
                currentOffset.width += value.translation.width
                currentOffset.height += value.translation.height
            }
    }

    private func toggleZoom() {
        if currentScale > 1.5 {
            currentScale = 1.0
            currentOffset = .zero
        } else {
            currentScale = 2.0
        }
    }

    private func adjustZoom(by delta: CGFloat) {
        currentScale = max(1.0, min(4.0, currentScale + delta))
        if currentScale == 1.0 { currentOffset = .zero }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
            }
            .accessibilityLabel("Close")
        }
        ToolbarItem(placement: .topBarTrailing) {
            if let ui = image {
                ShareLink(
                    item: ShareableImage(image: ui, title: note.title),
                    preview: SharePreview(note.title, image: Image(uiImage: ui))
                ) {
                    Image(systemName: "square.and.arrow.up")
                }
                .accessibilityLabel("Share")
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button("Save to Photos", systemImage: "square.and.arrow.down") {
                    saveToPhotos()
                }
                Button("Copy", systemImage: "doc.on.doc") {
                    copyToPasteboard()
                }
            } label: {
                Image(systemName: "ellipsis")
            }
            .accessibilityLabel("More")
        }
    }

    private func saveToPhotos() {
        guard let ui = image else { return }
        UIImageWriteToSavedPhotosAlbum(ui, nil, nil, nil)
        saveTrigger.toggle()
    }

    private func copyToPasteboard() {
        guard let ui = image else { return }
        UIPasteboard.general.image = ui
        copyTrigger.toggle()
    }

    private var infoStrip: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(note.title)
                    .font(.system(.subheadline, design: .serif, weight: .semibold))
                    .kerning(-0.2)
                    .foregroundStyle(.white)
                metaText
                    .font(.caption.weight(.semibold))
                    .monospacedDigit()
                    .kerning(0.2)
                    .foregroundStyle(.white.opacity(0.65))
            }
            Spacer()
            zoomControls
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .glassEffect(
            .regular.tint(Color.black.opacity(0.45)),
            in: RoundedRectangle(cornerRadius: GleanRadius.lg, style: .continuous)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 50)
    }

    private var metaText: Text {
        let date = Self.dateFormatter.string(from: note.createdAt).uppercased()
        let size = ByteCountFormatter.string(
            fromByteCount: Int64(note.imageData.count),
            countStyle: .file
        )
        if let ui = image {
            let dims = "\(Int(ui.size.width)) × \(Int(ui.size.height))"
            return Text("\(date) · \(dims) · \(size)")
        } else {
            return Text("\(date) · \(size)")
        }
    }

    private var zoomControls: some View {
        HStack(spacing: 6) {
            zoomButton(label: "−") { adjustZoom(by: -0.5) }
            Text("\(Int(currentScale * 100))%")
                .font(.system(.caption, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(.white)
                .frame(minWidth: 50, minHeight: 30)
                .padding(.horizontal, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.white.opacity(0.14))
                )
            zoomButton(label: "+") { adjustZoom(by: 0.5) }
        }
    }

    private func zoomButton(label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(.callout, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.white.opacity(0.10))
                )
        }
    }
}

/// JPEG file URL primary; SwiftUI Image proxy fallback for stricter share extensions.
private struct ShareableImage: Transferable {
    let image: UIImage
    let title: String

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .jpeg) { wrapper in
            let url = URL.temporaryDirectory.appending(component: wrapper.safeFilename)
            guard let data = wrapper.image.jpegData(compressionQuality: 0.95) else {
                throw CocoaError(.fileWriteUnknown)
            }
            try data.write(to: url, options: .atomic)
            return SentTransferredFile(url)
        }
        .suggestedFileName { $0.safeFilename }

        ProxyRepresentation { wrapper in
            Image(uiImage: wrapper.image)
        }
    }

    private var safeFilename: String {
        let safe = title
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let clamped = String(safe.prefix(60))
        return clamped.isEmpty ? "Image.jpg" : "\(clamped).jpg"
    }
}

#if DEBUG
#Preview {
    let container = Note.previewContainer
    let note = try! container.mainContext.fetch(
        FetchDescriptor<Note>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
    ).first!
    return SourceImageView(note: note)
        .modelContainer(container)
}
#endif
