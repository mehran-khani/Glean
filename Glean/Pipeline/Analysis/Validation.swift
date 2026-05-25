//
//  Validation.swift
//  Glean
//

import Foundation
import NaturalLanguage

nonisolated enum Validation {

    /// At least 55% of a candidate's significant words must appear in the OCR.
    static let hallucinationThreshold: Double = 0.55

    /// Cosine-similarity threshold for cross-category dedup.
    static let duplicateSimilarityThreshold: Double = 0.85

    static func wordOverlap(_ candidate: String, against ocr: String) -> Double {
        let candidateWords = significantWords(in: candidate)
        guard !candidateWords.isEmpty else { return 1.0 }
        let ocrWords = Set(significantWords(in: ocr))
        let overlap = candidateWords.filter { ocrWords.contains($0) }.count
        return Double(overlap) / Double(candidateWords.count)
    }

    private static let stopWords: Set<String> = [
        "the", "and", "for", "with", "this", "that", "from", "into",
        "have", "will", "their", "they", "them", "would", "could",
        "about", "after", "before", "between", "during", "while", "more",
        "some", "than", "then", "your", "what", "when", "where", "which",
        "should", "shall", "must", "make", "made", "take", "took",
        "been", "were", "very", "much", "many"
    ]

    private static func significantWords(in text: String) -> [String] {
        let lowered = text.lowercased()
        let allowed = CharacterSet.lowercaseLetters.union(.decimalDigits)
        let tokens = lowered.unicodeScalars
            .split { !allowed.contains($0) }
            .map { String($0) }
        return tokens.filter { $0.count >= 4 && !stopWords.contains($0) }
    }

    static func sentenceSimilarity(_ a: String, _ b: String) -> Double? {
        guard let embedder = NLEmbedding.sentenceEmbedding(for: .english) else { return nil }
        guard let va = embedder.vector(for: a),
              let vb = embedder.vector(for: b) else { return nil }
        return cosineSimilarity(va, vb)
    }

    private static func cosineSimilarity(_ a: [Double], _ b: [Double]) -> Double {
        let dot = zip(a, b).reduce(0.0) { $0 + $1.0 * $1.1 }
        let normA = (a.reduce(0.0) { $0 + $1 * $1 }).squareRoot()
        let normB = (b.reduce(0.0) { $0 + $1 * $1 }).squareRoot()
        guard normA > 0, normB > 0 else { return 0 }
        return dot / (normA * normB)
    }

    static func textSimilarityFallback(_ a: String, _ b: String) -> Double {
        let aw = Set(significantWords(in: a))
        let bw = Set(significantWords(in: b))
        guard !aw.isEmpty, !bw.isEmpty else { return 0 }
        let intersection = aw.intersection(bw).count
        let union = aw.union(bw).count
        return Double(intersection) / Double(union)
    }
}
