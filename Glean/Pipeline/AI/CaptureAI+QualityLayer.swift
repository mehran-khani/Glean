//
//  CaptureAI+QualityLayer.swift
//  Glean
//

import Foundation

nonisolated extension CaptureAI {

    static func validateAgainstOCR(_ draft: NoteDraft, ocr: String) -> NoteDraft {
        let threshold = Validation.hallucinationThreshold
        let lowerOCR = ocr.lowercased()
        var result = draft

        result.decisions = draft.decisions
            .map(cleanDecisionText)
            .filter { !$0.isEmpty && Validation.wordOverlap($0, against: ocr) >= threshold }
        result.questions = draft.questions.filter {
            Validation.wordOverlap($0, against: ocr) >= threshold
                && questionAppearsAsQuestion($0, in: ocr)
        }

        result.actions = draft.actions.compactMap { action in
            guard Validation.wordOverlap(action.text, against: ocr) >= threshold else {
                return nil
            }
            var validated = action
            if let owner = action.owner, !owner.isEmpty {
                if !lowerOCR.contains(owner.lowercased()) {
                    validated.owner = nil
                } else {
                    validated.owner = dropParentheticalOwner(owner, in: ocr)
                }
            }
            return validated
        }

        return result
    }

    static func dedupAcrossCategories(_ draft: NoteDraft) -> NoteDraft {
        var result = draft

        result.decisions = draft.decisions.filter { decision in
            !draft.actions.contains { action in
                isNearDuplicate(action.text, decision)
            }
        }

        result.questions = draft.questions.filter { question in
            !draft.actions.contains { action in
                isNearDuplicate(action.text, question)
            }
        }

        result.questions = result.questions.filter { question in
            !result.decisions.contains { decision in
                isNearDuplicate(decision, question)
            }
        }

        return result
    }

    /// Whether the OCR contains a line ending or starting with '?' that overlaps
    /// with the candidate's first 20 chars. Drops questions hallucinated from prose.
    private static func questionAppearsAsQuestion(_ candidate: String, in ocr: String) -> Bool {
        let probe = candidate.lowercased().prefix(20)
        guard !probe.isEmpty else { return false }
        for raw in ocr.split(separator: "\n") {
            let line = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard line.lowercased().contains(probe) else { continue }
            if line.hasSuffix("?") || line.hasPrefix("?") { return true }
        }
        return false
    }

    static func isNearDuplicate(_ a: String, _ b: String) -> Bool {
        if let sim = Validation.sentenceSimilarity(a, b) {
            return sim >= Validation.duplicateSimilarityThreshold
        }
        return Validation.textSimilarityFallback(a, b) >= 0.65
    }
}
