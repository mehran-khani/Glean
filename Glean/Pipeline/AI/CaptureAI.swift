//
//  CaptureAI.swift
//  Glean
//

import Foundation
import FoundationModels

nonisolated enum CaptureAI {

    static let maxOCRPromptChars = 3000

    static let baseInstructions = """
    You extract structured note data from OCR text of pages: meeting notes, \
    lecture notes, whiteboards, sticky-note walls, handwritten brainstorms, \
    and similar sources. Be factual. Never invent items, owners, dates, or \
    content that isn't in the OCR. Never expand abbreviations: 'mgmt' stays \
    'mgmt', 'eng' stays 'eng', 'RFC' stays 'RFC'. Never guess what an \
    abbreviation might stand for. When the OCR is fragmentary or unreadable, \
    prefer empty arrays or brief summaries over fabrication.
    """

    static func generateDraft(from ocr: String) async -> NoteDraft? {
        let trimmed = ocr.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let model = SystemLanguageModel.default
        guard case .available = model.availability else { return nil }

        // The on-device language detector occasionally misclassifies em-dash-heavy
        // English as Romanian and aborts the session. Normalize to ASCII hyphens.
        let normalized = trimmed
            .replacingOccurrences(of: "—", with: " - ")
            .replacingOccurrences(of: "–", with: " - ")

        let promptOCR: String
        if normalized.count > maxOCRPromptChars {
            promptOCR = String(normalized.prefix(maxOCRPromptChars)) + "\n[truncated]"
        } else {
            promptOCR = normalized
        }

        let structure = OCRStructureParser.parse(promptOCR)

        async let titleSummary = generateTitleSummary(ocr: promptOCR)
        async let decisions = decisionsIfGated(structure: structure)
        async let actions = generateActions(
            ocr: structure.actionsInput,
            owners: structure.personNames
        )
        async let questions = generateQuestions(ocr: structure.questionsInput)
        async let tags = generateTags(ocr: promptOCR)

        guard let ts = await titleSummary else { return nil }

        var draft = NoteDraft(
            title: ts.title,
            summary: ts.summary,
            decisions: (await decisions) ?? [],
            actions: (await actions) ?? [],
            questions: (await questions) ?? [],
            tags: normalizeTags((await tags) ?? [], against: promptOCR)
        )

        draft = validateAgainstOCR(draft, ocr: promptOCR)
        draft = dedupAcrossCategories(draft)
        return draft
    }

    /// Skip the decisions pass when no explicit header is present: without one,
    /// the model misclassifies task-shaped bullets as decisions.
    static func decisionsIfGated(structure: OCRStructure) async -> [String]? {
        guard structure.decidedSection != nil else { return nil }
        return await generateDecisions(ocr: structure.decisionsInput)
    }

    /// Drops fabricated tags (words must appear in OCR), caps at 5.
    static func normalizeTags(_ raw: [String], against ocr: String) -> [String] {
        let lowerOCR = ocr.lowercased()
        var seen: Set<String> = []
        var result: [String] = []
        for tag in raw {
            let cleaned = tag
                .lowercased()
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: " ", with: "-")
            guard !cleaned.isEmpty, cleaned.count <= 24, !seen.contains(cleaned) else { continue }
            let probeWords = cleaned
                .replacingOccurrences(of: "-", with: " ")
                .split(separator: " ")
                .filter { $0.count >= 3 }
            guard probeWords.contains(where: { lowerOCR.contains($0) }) else { continue }
            seen.insert(cleaned)
            result.append(cleaned)
            if result.count == 5 { break }
        }
        return result
    }

    static func runPass<T>(
        instructions: String,
        ocr: String,
        temperature: Double,
        tools: [any Tool],
        generating: T.Type
    ) async -> T? where T: Generable & Sendable {
        let session = LanguageModelSession(tools: tools, instructions: instructions)
        let options = GenerationOptions(temperature: temperature)
        do {
            let response = try await session.respond(
                to: ocrPrompt(ocr),
                generating: T.self,
                options: options
            )
            return response.content
        } catch {
            return nil
        }
    }

    static func ocrPrompt(_ ocr: String) -> String {
        """
        OCR text:
        ---
        \(ocr)
        ---
        """
    }
}
