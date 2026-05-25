//
//  DocumentScannerView.swift
//  Glean
//

import SwiftUI
import UIKit
import VisionKit

struct DocumentScannerView: UIViewControllerRepresentable {

    var onScan: (Data) -> Void
    var onCancel: () -> Void
    var onError: (Error) -> Void

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let viewController = VNDocumentCameraViewController()
        viewController.delegate = context.coordinator
        return viewController
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let parent: DocumentScannerView

        init(parent: DocumentScannerView) {
            self.parent = parent
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFinishWith scan: VNDocumentCameraScan
        ) {
            guard scan.pageCount > 0 else {
                parent.onCancel()
                return
            }
            let image = scan.imageOfPage(at: 0)
            guard let data = image.jpegData(compressionQuality: 0.85) else {
                parent.onError(ScannerError.encodingFailed)
                return
            }
            parent.onScan(data)
        }

        func documentCameraViewControllerDidCancel(
            _ controller: VNDocumentCameraViewController
        ) {
            parent.onCancel()
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFailWithError error: Error
        ) {
            parent.onError(error)
        }
    }

    enum ScannerError: LocalizedError {
        case encodingFailed

        var errorDescription: String? {
            switch self {
            case .encodingFailed: return "Couldn't encode the scanned page."
            }
        }
    }
}
