//
//  Tools.swift
//  Glean
//

import Foundation
import FoundationModels

nonisolated struct DateLookupTool: Tool {
    let name = "lookupDate"
    let description = """
    Resolve a date phrase like 'next Friday', 'Mar 22', 'tomorrow', \
    or 'in 3 days' to an absolute date. Returns the date in YYYY-MM-DD \
    format, or the literal string 'unparseable' if the phrase isn't a date.
    """

    @Generable
    struct Arguments: Sendable {
        @Guide(description: "The date phrase to resolve, as it appears in the source text.")
        var phrase: String
    }

    func call(arguments: Arguments) async throws -> String {
        guard let date = EntityExtractor.parseDate(arguments.phrase) else {
            return "unparseable"
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
