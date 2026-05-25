//
//  CaptureSheet.swift
//  Glean
//

import PhotosUI
import SwiftData
import SwiftUI
import VisionKit

struct CaptureSheet: View {
    var onImage: (Data) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var photoItem: PhotosPickerItem?
    @State private var isLoadingPhoto = false
    @State private var showingCamera = false
    @State private var pickTrigger = false

    var body: some View {
        VStack(spacing: 24) {
            header
            sourceCards
            Spacer(minLength: 0)
            privacyNote
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onChange(of: photoItem) { _, newItem in
            guard let newItem else { return }
            isLoadingPhoto = true
            Task { @MainActor in
                defer { isLoadingPhoto = false }
                if let data = try? await newItem.loadTransferable(type: Data.self) {
                    onImage(data)
                }
            }
        }
        .fullScreenCover(isPresented: $showingCamera) {
            DocumentScannerView(
                onScan: { data in
                    showingCamera = false
                    onImage(data)
                },
                onCancel: { showingCamera = false },
                onError: { _ in showingCamera = false }
            )
            .ignoresSafeArea()
        }
        .sensoryFeedback(.impact(weight: .light), trigger: pickTrigger)
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("New note")
                    .font(.system(.title, design: .serif, weight: .semibold))
                    .kerning(-0.4)
                    .foregroundStyle(.primary)
                Text("Photograph or pick a page")
                    .font(.subheadline)
                    .kerning(-0.15)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding()
                    .glassEffect(.regular.interactive())
            }
            .accessibilityLabel("Dismiss")
        }
    }

    private var scannerAvailable: Bool {
        VNDocumentCameraViewController.isSupported
    }

    private var sourceCards: some View {
        HStack(spacing: 10) {
            if scannerAvailable {
                Button {
                    pickTrigger.toggle()
                    showingCamera = true
                } label: {
                    SourceCard(
                        icon: "doc.viewfinder.fill",
                        title: "Scan a page",
                        subtitle: "Auto-detects edges and crops perfectly.",
                        accent: true
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Scan a page")
            }

            PhotosPicker(
                selection: $photoItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                SourceCard(
                    icon: "photo.on.rectangle.angled",
                    title: "Choose from Library",
                    subtitle: "Pick an existing photo.",
                    accent: false
                )
            }
            .buttonStyle(.plain)
            .disabled(isLoadingPhoto)
            .accessibilityLabel("Choose from Library")
        }
    }

    private var privacyNote: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: "lock.fill")
                .font(.footnote)
                .foregroundStyle(Color.accentColor)
                .padding(.top, 1)
            Text("Reading, parsing, and storage happen entirely on this iPhone. \(Text("Nothing leaves the device.").foregroundStyle(.primary).fontWeight(.medium))")
                .foregroundStyle(.secondary)
                .font(.caption)
                .kerning(-0.1)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(
            Color(.systemFill).opacity(0.5),
            in: RoundedRectangle(cornerRadius: GleanRadius.lg, style: .continuous)
        )
    }
}

#if DEBUG
#Preview("Sheet — Light") {
    CaptureSheet { _ in }
        .modelContainer(Note.previewContainer)
        .preferredColorScheme(.light)
}

#Preview("Sheet — Dark") {
    CaptureSheet { _ in }
        .modelContainer(Note.previewContainer)
        .preferredColorScheme(.dark)
}
#endif
