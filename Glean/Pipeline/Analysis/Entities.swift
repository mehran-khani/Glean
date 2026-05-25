//
//  Entities.swift
//  Glean
//

import Foundation
import NaturalLanguage

nonisolated enum EntityExtractor {

    static func parseDate(_ phrase: String?) -> Date? {
        guard let raw = phrase?.trimmingCharacters(in: .whitespacesAndNewlines),
              !raw.isEmpty else { return nil }

        let types = NSTextCheckingResult.CheckingType.date.rawValue
        if let detector = try? NSDataDetector(types: types) {
            let range = NSRange(raw.startIndex..., in: raw)
            if let match = detector.matches(in: raw, options: [], range: range).first,
               let date = match.date {
                return date
            }
        }

        // Relative phrases NSDataDetector doesn't resolve to concrete dates.
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        switch raw.lowercased() {
        case "next week":  return calendar.date(byAdding: .day, value: 7, to: today)
        case "this week":  return calendar.date(byAdding: .day, value: 3, to: today)
        case "next month": return calendar.date(byAdding: .month, value: 1, to: today)
        default:           return nil
        }
    }

    static func isPersonName(_ candidate: String?) -> Bool {
        guard let cleaned = candidate?.trimmingCharacters(in: .whitespacesAndNewlines),
              !cleaned.isEmpty else { return false }

        let normalized: String
        if let first = cleaned.first, first.isLowercase {
            normalized = first.uppercased() + cleaned.dropFirst()
        } else {
            normalized = cleaned
        }

        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = normalized
        let range = normalized.startIndex..<normalized.endIndex
        var found = false
        tagger.enumerateTags(
            in: range,
            unit: .word,
            scheme: .nameType,
            options: [.omitWhitespace, .omitPunctuation]
        ) { tag, _ in
            if tag == .personalName {
                found = true
                return false
            }
            return true
        }
        return found
    }
}
