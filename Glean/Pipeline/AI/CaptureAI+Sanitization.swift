//
//  CaptureAI+Sanitization.swift
//  Glean
//

import Foundation

nonisolated extension CaptureAI {

    static func sanitizeOptionalString(_ s: String?) -> String? {
        guard let s = s?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty else { return nil }
        let lowered = s.lowercased()
        let sentinels: Set<String> = ["nil", "none", "null", "n/a", "unparseable"]
        if sentinels.contains(lowered) { return nil }
        return s
    }

    static func sanitizeOwner(_ s: String?) -> String? {
        guard let cleaned = sanitizeOptionalString(s) else { return nil }
        let stripped = cleaned.trimmingCharacters(in: CharacterSet(charactersIn: "@ "))
        if stripped.isEmpty { return nil }
        let lower = stripped.lowercased()
        let nonNames: Set<String> = [
            "team", "we", "us", "everyone", "all", "anyone", "someone",
            "todo", "action", "actions", "decided", "decisions",
            "open", "questions", "followup", "followups", "next",
            "me", "myself", "i"
        ]
        return nonNames.contains(lower) ? nil : stripped
    }

    /// Drop owners that only appear parenthesized in the OCR (citations like `(Ongaro)`).
    static func dropParentheticalOwner(_ owner: String?, in ocr: String) -> String? {
        guard let owner, !owner.isEmpty else { return nil }
        let needle = "(\(owner.lowercased())"
        return ocr.lowercased().contains(needle) ? nil : owner
    }

    static func cleanDueDate(_ s: String?) -> String? {
        guard let raw = sanitizeOptionalString(s) else { return nil }
        let stripped = raw.trimmingCharacters(in: CharacterSet(charactersIn: "★☆ "))
        return stripped.isEmpty ? nil : stripped
    }

    static func cleanDecisionText(_ raw: String) -> String {
        raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "☐☑✓✔→•*- "))
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func cleanActionText(_ raw: String, dueDateString: String?) -> String {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)

        let urgencyPatterns = [
            #"\s*[—\-–]\s*URGENT\b\.?$"#,
            #"\s+URGENT\b\.?$"#,
            #"\s+ASAP\b\.?$"#,
            #"\s+IMPORTANT\b\.?$"#,
            #"\s+!!+\.?$"#,
            #"\s*[★☆]\s*$"#,
            #"^[★☆]\s+"#
        ]
        for pattern in urgencyPatterns {
            text = text.replacingOccurrences(
                of: pattern,
                with: "",
                options: [.regularExpression, .caseInsensitive]
            )
        }

        let bareRelativePatterns = [
            #"\s+next\s+week\b\.?$"#,
            #"\s+this\s+week\b\.?$"#,
            #"\s+next\s+month\b\.?$"#,
            #"\s+tomorrow\b\.?$"#,
            #"\s+today\b\.?$"#,
            #"\s+tonight\b\.?$"#,
            #"\s+by\s+(next|this)\s+(week|month|monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b\.?$"#,
            #"\s+before\s+(next|this)?\s*(week|month|monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b\.?$"#,
            #"\s+by\s+(monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b\.?$"#
        ]
        for pattern in bareRelativePatterns {
            text = text.replacingOccurrences(
                of: pattern,
                with: "",
                options: [.regularExpression, .caseInsensitive]
            )
        }

        if let due = dueDateString?.trimmingCharacters(in: .whitespacesAndNewlines),
           !due.isEmpty {
            let escaped = NSRegularExpression.escapedPattern(for: due)
            let tailPatterns = [
                #"\s+by\s+\#(escaped)\s*[\.\,]?$"#,
                #"\s+due\s+(by\s+)?\#(escaped)\s*[\.\,]?$"#,
                #"\s+on\s+\#(escaped)\s*[\.\,]?$"#,
                #"\s+before\s+\#(escaped)\s*[\.\,]?$"#
            ]
            for pattern in tailPatterns {
                text = text.replacingOccurrences(
                    of: pattern,
                    with: "",
                    options: [.regularExpression, .caseInsensitive]
                )
            }
        }

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
