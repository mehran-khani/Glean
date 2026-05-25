//
//  CaptureProcessing.swift
//  Glean
//

import Foundation
import SwiftData

protocol CaptureProcessing: Sendable {
    func process(imageData: Data) -> AsyncStream<ProcessingEvent>
}

enum ProcessingPhase: Int, Sendable, CaseIterable {
    case reading, structuring, filing

    var title: String {
        switch self {
        case .reading: return "Reading the page"
        case .structuring: return "Making sense of it"
        case .filing: return "Filing your note"
        }
    }

    var subtitle: String {
        switch self {
        case .reading: return "Recognizing handwriting and printed marks."
        case .structuring: return "Structuring decisions, action items, and questions."
        case .filing: return "Saving to your on-device library."
        }
    }

    var symbol: String {
        switch self {
        case .reading: return "text.viewfinder"
        case .structuring: return "sparkles"
        case .filing: return "tray.and.arrow.down.fill"
        }
    }
}

enum ProcessingEvent: Sendable {
    case phase(ProcessingPhase)
    case finished(PersistentIdentifier)
    case failed(String)
}
