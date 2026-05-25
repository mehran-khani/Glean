//
//  ActionItem.swift
//  Glean
//

import Foundation
import SwiftData

@Model
final class ActionItem {
    @Attribute(.unique) var id: UUID
    var text: String
    var owner: String?
    var dueDate: Date?
    var isDone: Bool
    var urgent: Bool
    var note: Note?

    init(
        id: UUID = UUID(),
        text: String,
        owner: String? = nil,
        dueDate: Date? = nil,
        isDone: Bool = false,
        urgent: Bool = false,
        note: Note? = nil
    ) {
        self.id = id
        self.text = text
        self.owner = owner
        self.dueDate = dueDate
        self.isDone = isDone
        self.urgent = urgent
        self.note = note
    }
}
