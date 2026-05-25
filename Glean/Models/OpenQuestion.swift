//
//  OpenQuestion.swift
//  Glean
//

import Foundation
import SwiftData

@Model
final class OpenQuestion {
    @Attribute(.unique) var id: UUID
    var text: String
    var answer: String?
    var isAnswered: Bool
    var note: Note?

    init(
        id: UUID = UUID(),
        text: String,
        answer: String? = nil,
        isAnswered: Bool = false,
        note: Note? = nil
    ) {
        self.id = id
        self.text = text
        self.answer = answer
        self.isAnswered = isAnswered
        self.note = note
    }
}
