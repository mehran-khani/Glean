//
//  OCRStructure.swift
//  Glean
//

import Foundation
import NaturalLanguage

nonisolated struct OCRStructure: Sendable {
    var fullText: String
    var topMatter: String
    var decidedSection: String?
    var todoSection: String?
    var openQuestionsSection: String?
    var personNames: [String]
}

extension OCRStructure {
    var hasAnySection: Bool {
        decidedSection != nil || todoSection != nil || openQuestionsSection != nil
    }

    var decisionsInput: String {
        decidedSection ?? fullText
    }

    var actionsInput: String {
        guard let todoSection else { return fullText }
        let top = topMatter.trimmingCharacters(in: .whitespacesAndNewlines)
        return top.isEmpty ? todoSection : "\(top)\n\n\(todoSection)"
    }

    var questionsInput: String { fullText }
}

nonisolated enum OCRStructureParser {
    static func parse(_ ocr: String) -> OCRStructure {
        let cleaned = ocr.trimmingCharacters(in: .whitespacesAndNewlines)
        let lines = cleaned.components(separatedBy: .newlines)

        var topMatter: [String] = []
        var sections: [SectionKind: [String]] = [:]
        var current: SectionKind? = nil
        var seenAnySection = false

        for line in lines {
            if let kind = sectionHeader(in: line) {
                current = kind
                seenAnySection = true
                continue
            }
            if let current {
                sections[current, default: []].append(line)
            } else if !seenAnySection {
                topMatter.append(line)
            }
        }

        return OCRStructure(
            fullText: cleaned,
            topMatter: joinNonEmpty(topMatter),
            decidedSection: sections[.decided].map { joinNonEmpty($0) },
            todoSection: sections[.todo].map { joinNonEmpty($0) },
            openQuestionsSection: sections[.questions].map { joinNonEmpty($0) },
            personNames: extractPersonNames(from: cleaned)
        )
    }

    private enum SectionKind: Hashable, Sendable { case decided, todo, questions }

    /// Semantic header classification via NLEmbedding cosine similarity against
    /// canonical labels. Handles arbitrary phrasing (LOCKED, AGREED, OUTCOMES,
    /// TO-DO, OPEN QS, etc.) without enumerating synonyms.
    private static func sectionHeader(in line: String) -> SectionKind? {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.count <= 40 else { return nil }

        let candidate = trimmed
            .trimmingCharacters(in: CharacterSet(charactersIn: ":-•*— "))
            .lowercased()
        guard !candidate.isEmpty, candidate.count <= 30 else { return nil }

        return classifyHeader(candidate)
    }

    /// Semantic anchors per section, tuned from real cosine measurements.
    /// Each candidate is classified by its closest anchor across all categories.
    private static let canonicalHeaders: [(SectionKind, [String])] = [
        (.decided, ["decisions", "decided", "agreed", "resolved", "locked", "locked in", "outcomes", "final", "settled", "confirmed"]),
        (.todo, ["action items", "actions", "tasks", "to do", "todo", "next steps", "followups", "follow-ups"]),
        (.questions, ["open questions", "questions", "unresolved", "open", "open qs"])
    ]

    private static let headerSimilarityThreshold: Double = 0.625

    private static func classifyHeader(_ candidate: String) -> SectionKind? {
        var best: (kind: SectionKind, sim: Double) = (.decided, 0)
        for (kind, anchors) in canonicalHeaders {
            for anchor in anchors {
                guard let sim = Validation.sentenceSimilarity(candidate, anchor) else { continue }
                if sim > best.sim {
                    best = (kind, sim)
                }
            }
        }
        return best.sim >= headerSimilarityThreshold ? best.kind : nil
    }

    /// Pulls names from literal `@Name` markers, the one unambiguous signal in
    /// informal notation. `NLTagger.personalName` was tried; false-positives
    /// on common nouns made it net-negative without a stop-word list.
    static func extractPersonNames(from text: String) -> [String] {
        var names: Set<String> = []
        guard let regex = try? NSRegularExpression(pattern: #"@([A-Z][a-zA-Z]{1,20})\b"#) else {
            return []
        }
        let range = NSRange(text.startIndex..., in: text)
        regex.enumerateMatches(in: text, range: range) { match, _, _ in
            guard let match, match.numberOfRanges >= 2,
                  let r = Range(match.range(at: 1), in: text) else { return }
            names.insert(String(text[r]))
        }
        return Array(names).sorted()
    }

    private static func joinNonEmpty(_ lines: [String]) -> String {
        lines
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }
}
