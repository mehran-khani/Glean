//
//  CaptureProcessor.swift
//  Glean
//

import Foundation
@preconcurrency import SwiftData
import UIKit
@preconcurrency import Vision

@ModelActor
actor CaptureProcessor: CaptureProcessing {

    nonisolated private static let phaseDwellFloor: Duration = .milliseconds(700)

    nonisolated func process(imageData: Data) -> AsyncStream<ProcessingEvent> {
        AsyncStream { continuation in
            let task = Task {
                await self.run(imageData: imageData, continuation: continuation)
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private func run(
        imageData: Data,
        continuation: AsyncStream<ProcessingEvent>.Continuation
    ) async {
        let clock = ContinuousClock()

        continuation.yield(.phase(.reading))
        let readingStart = clock.now

        let ocrText: String
        do {
            ocrText = try await Self.recognizeText(in: imageData)
        } catch {
            continuation.yield(.failed(error.localizedDescription))
            continuation.finish()
            return
        }
        guard !Task.isCancelled else { continuation.finish(); return }
        await Self.holdPhase(start: readingStart, clock: clock)
        guard !Task.isCancelled else { continuation.finish(); return }

        continuation.yield(.phase(.structuring))
        let structuringStart = clock.now
        let draft = await CaptureAI.generateDraft(from: ocrText)
        guard !Task.isCancelled else { continuation.finish(); return }
        await Self.holdPhase(start: structuringStart, clock: clock)
        guard !Task.isCancelled else { continuation.finish(); return }

        continuation.yield(.phase(.filing))
        let filingStart = clock.now

        let note = autoreleasepool {
            let n = makeNote(draft: draft, ocrText: ocrText, imageData: imageData)
            modelContext.insert(n)
            attachRelationships(from: draft, to: n)
            return n
        }

        do {
            try modelContext.save()
            await Self.holdPhase(start: filingStart, clock: clock)
            continuation.yield(.finished(note.persistentModelID))
        } catch {
            continuation.yield(.failed(error.localizedDescription))
        }
        continuation.finish()
    }

    nonisolated private static func holdPhase(
        start: ContinuousClock.Instant,
        clock: ContinuousClock
    ) async {
        let elapsed = clock.now - start
        if elapsed < phaseDwellFloor {
            try? await Task.sleep(for: phaseDwellFloor - elapsed)
        }
    }

    private func makeNote(draft: NoteDraft?, ocrText: String, imageData: Data) -> Note {
        let thumbData = Thumbnail.encodedThumbData(from: imageData) ?? Data()

        if let draft {
            return Note(
                createdAt: .now,
                title: draft.title,
                summary: draft.summary,
                ocrText: ocrText,
                imageData: imageData,
                thumbData: thumbData,
                tags: draft.tags,
                isPlainOCR: false,
                decisions: draft.decisions
            )
        }
        return Note(
            createdAt: .now,
            title: "Untitled",
            summary: Self.fallbackSummary(from: ocrText),
            ocrText: ocrText,
            imageData: imageData,
            thumbData: thumbData,
            isPlainOCR: true
        )
    }

    private func attachRelationships(from draft: NoteDraft?, to note: Note) {
        guard let draft else { return }
        for action in draft.actions {
            let cleanedDueString = CaptureAI.cleanDueDate(action.dueDate)
            let item = ActionItem(
                text: CaptureAI.cleanActionText(action.text, dueDateString: cleanedDueString),
                owner: CaptureAI.sanitizeOwner(action.owner),
                dueDate: EntityExtractor.parseDate(cleanedDueString),
                isDone: false,
                urgent: action.urgent,
                note: note
            )
            modelContext.insert(item)
        }
        for q in draft.questions {
            let trimmed = q.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            modelContext.insert(OpenQuestion(text: trimmed, note: note))
        }
    }

    nonisolated private static func recognizeText(in data: Data) async throws -> String {
        let decoded: (CGImage, CGImagePropertyOrientation)? = autoreleasepool {
            guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }

            let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
            let exifInt = (props?[kCGImagePropertyOrientation] as? Int) ?? 1
            let orientation = CGImagePropertyOrientation(rawValue: UInt32(exifInt)) ?? .up

            guard let cg = CGImageSourceCreateImageAtIndex(source, 0, nil) else { return nil }
            return (cg, orientation)
        }
        guard let (cgImage, orientation) = decoded else { return "" }

        var request = RecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        let observations = try await request.perform(on: cgImage, orientation: orientation)
        return observations
            .compactMap { $0.topCandidates(1).first?.string }
            .joined(separator: "\n")
    }

    nonisolated private static func fallbackSummary(from ocr: String) -> String {
        let collapsed = ocr
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if collapsed.isEmpty { return "No text detected." }
        if collapsed.count <= 200 { return collapsed }
        return String(collapsed.prefix(200)) + "…"
    }
}
