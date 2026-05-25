//
//  Note.swift
//  Glean
//

import Foundation
import SwiftData

@Model
final class Note {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var title: String
    var summary: String
    var ocrText: String
    @Attribute(.externalStorage) var imageData: Data
    /// Pre-rendered thumbnail; avoids materializing the full `imageData` blob in list views.
    @Attribute(.externalStorage) var thumbData: Data = Data()
    var pinned: Bool
    var tags: [String]
    var isPlainOCR: Bool = false
    var decisions: [String] = []

    @Relationship(deleteRule: .cascade, inverse: \ActionItem.note)
    var actionItems: [ActionItem] = []

    @Relationship(deleteRule: .cascade, inverse: \OpenQuestion.note)
    var openQuestions: [OpenQuestion] = []

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        title: String,
        summary: String,
        ocrText: String,
        imageData: Data,
        thumbData: Data = Data(),
        pinned: Bool = false,
        tags: [String] = [],
        isPlainOCR: Bool = false,
        decisions: [String] = [],
        actionItems: [ActionItem] = [],
        openQuestions: [OpenQuestion] = []
    ) {
        self.id = id
        self.createdAt = createdAt
        self.title = title
        self.summary = summary
        self.ocrText = ocrText
        self.imageData = imageData
        self.thumbData = thumbData
        self.pinned = pinned
        self.tags = tags
        self.isPlainOCR = isPlainOCR
        self.decisions = decisions
        self.actionItems = actionItems
        self.openQuestions = openQuestions
    }
}

extension Note {
    /// Short uppercase relative-date string for Library row.
    /// Matches the design pass: "2H AGO", "YESTERDAY", "TUE", "MAR 14".
    static func shortRelativeDate(from date: Date, now: Date = .now) -> String {
        let interval = now.timeIntervalSince(date)
        let cal = Calendar.current

        if interval < 60 { return "JUST NOW" }
        if interval < 3600 { return "\(Int(interval / 60))M AGO" }
        if interval < 86_400 { return "\(Int(interval / 3600))H AGO" }
        if cal.isDateInYesterday(date) { return "YESTERDAY" }

        let formatter = DateFormatter()
        if interval < 7 * 86_400 {
            formatter.dateFormat = "EEE"
        } else {
            formatter.dateFormat = "MMM d"
        }
        return formatter.string(from: date).uppercased()
    }
}

#if DEBUG
@MainActor
extension Note {
    /// In-memory ModelContainer seeded with realistic notes for SwiftUI previews.
    /// Real images aren't seeded — rows fall back to GleanThumb when imageData is empty.
    static let previewContainer: ModelContainer = {
        let schema = Schema([Note.self, ActionItem.self, OpenQuestion.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [config])
        let ctx = container.mainContext

        let seeds: [(title: String, summary: String, tags: [String], hoursAgo: Double, pinned: Bool, decisions: [String])] = [
            ("Q4 Roadmap Review",
             "Sync between Mira, Jon, and Priya covering Q4 priorities. Consensus around three workstreams; staffing is the open thread.",
             ["planning", "q4", "roadmap"], 2, true,
             ["Payments overhaul is P0 for Q4. Locked.",
              "Mobile redesign moves to Q1 next year.",
              "Hire one infra engineer before kicking off cleanup."]),
            ("Auth migration spike",
             "Architecture review \u{2014} Cognito vs Auth0 vs roll-our-own. Tradeoffs on the board.",
             ["backend", "spike"], 26, false, []),
            ("Distributed systems \u{2014} lecture 7",
             "Two-phase commit, Paxos, the cost of consensus. Tuesday afternoon notes.",
             ["school", "dist-sys"], 96, false, []),
            ("Sticky workshop \u{2014} onboarding",
             "Top friction surfaced: account creation, empty state, billing setup. 32 stickies clustered.",
             ["research", "ux", "workshop", "internal", "discovery"], 24 * 8, false, []),
            ("Mira / Jon 1:1",
             "Career conversation. Three growth areas, two stretch projects, one ask of me.",
             ["1on1"], 24 * 10, false, []),
            ("Sunday journal",
             "Bike-ride loop sketch. Books to read. Brewery list. Don\u{2019}t forget the bread starter.",
             ["personal"], 24 * 12, false, [])
        ]

        for seed in seeds {
            let note = Note(
                createdAt: .now.addingTimeInterval(-seed.hoursAgo * 3600),
                title: seed.title,
                summary: seed.summary,
                ocrText: seed.summary,
                imageData: Data(),
                pinned: seed.pinned,
                tags: seed.tags,
                decisions: seed.decisions
            )
            ctx.insert(note)
        }

        // Beef up the first note with action items + open questions so
        // NoteDetailView previews show the V2 sections populated.
        let cal = Calendar.current
        if let first = try? ctx.fetch(FetchDescriptor<Note>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])).first {
            let actions: [ActionItem] = [
                .init(text: "Confirm budget envelope", owner: "Jon",
                      dueDate: cal.date(byAdding: .day, value: -3, to: .now),
                      isDone: true, urgent: false, note: first),
                .init(text: "Draft payments RFC", owner: "Mira",
                      dueDate: cal.date(byAdding: .day, value: 4, to: .now),
                      isDone: false, urgent: true, note: first),
                .init(text: "Schedule infra hiring loop", owner: "Jon",
                      dueDate: cal.date(byAdding: .day, value: 7, to: .now),
                      isDone: false, urgent: false, note: first),
                .init(text: "Sync with design on mobile timeline shift", owner: "Priya",
                      dueDate: nil, isDone: false, urgent: false, note: first)
            ]
            actions.forEach { ctx.insert($0) }

            let questions: [OpenQuestion] = [
                .init(text: "Do we backport payment changes to v3?", note: first),
                .init(text: "Who owns the mobile design RFC?",
                      answer: "Mira will pair with design Friday.",
                      isAnswered: true, note: first)
            ]
            questions.forEach { ctx.insert($0) }
        }
        return container
    }()
}
#endif
