//
//  GleanTests.swift
//  Foundation Models extraction harness + date-parser unit tests.
//
//  The harness suite calls CaptureProcessor.generateDraft against a small
//  library of canned OCR samples and prints the structured output so the
//  prompt + parser can be iterated without manually re-running the app.

import Foundation
import Testing
@testable import Glean

// MARK: - FM extraction harness

@Suite("FM extraction harness")
struct FMExtractionHarness {

    @Test("Run all canned OCR cases through CaptureProcessor.generateDraft")
    func runAll() async throws {
        for testCase in TestCase.all {
            print("\n" + String(repeating: "=", count: 60))
            print("CASE: \(testCase.name)")
            print(String(repeating: "=", count: 60))
            print("OCR INPUT:")
            print(testCase.ocr)
            print()
            print("MODEL OUTPUT:")
            let draft = await CaptureAI.generateDraft(from: testCase.ocr)
            if let draft {
                printDraft(draft)
            } else {
                print("(nil — model unavailable, or generation failed)")
            }
            print()
        }
    }

    private func printDraft(_ draft: NoteDraft) {
        print("  TITLE:    \(draft.title)")
        print("  SUMMARY:  \(draft.summary)")
        if !draft.decisions.isEmpty {
            print("  DECISIONS (\(draft.decisions.count)):")
            for d in draft.decisions { print("    \u{2022} \(d)") }
        }
        if !draft.actions.isEmpty {
            print("  ACTIONS (\(draft.actions.count)) — post-sanitization:")
            for a in draft.actions {
                let dueStr = CaptureAI.sanitizeOptionalString(a.dueDate)
                let cleanedText = CaptureAI.cleanActionText(a.text, dueDateString: dueStr)
                let owner = CaptureAI.sanitizeOwner(a.owner)
                let parsedDate = EntityExtractor.parseDate(dueStr)
                var line = "    \u{2022} text='\(cleanedText)'"
                line += " owner=\(owner.map { "'\($0)'" } ?? "nil")"
                line += " dueDate=\(parsedDate.map { ISO8601DateFormatter().string(from: $0).prefix(10) }.map { "'\($0)'" } ?? "nil")"
                if dueStr != nil && parsedDate == nil {
                    line += " (unparsed: '\(dueStr!)')"
                }
                line += " urgent=\(a.urgent)"
                print(line)
            }
        }
        if !draft.questions.isEmpty {
            print("  QUESTIONS (\(draft.questions.count)):")
            for q in draft.questions { print("    ? \(q)") }
        }
    }
}

// MARK: - Canned OCR cases

private struct TestCase {
    let name: String
    let ocr: String

    static let all: [TestCase] = [
        sprintReview,
        retroLite,
        lectureNotes,
        stickyWorkshop,
        oneOnOne,
        personalJournal,
        errandsList,
        sparseUnreadable
    ]

    /// The original test note used during V2 iteration. Heavy on @owner
    /// markers, mix of explicit and implicit dates, exactly one URGENT.
    static let sprintReview = TestCase(name: "Sprint review", ocr: """
    SPRINT 23 REVIEW · Mar 18

    What shipped:
    - Search v2 — +27% click-through
    - iPad polish — App Store re-feature on Wed
    - Onboarding A/B → variant B wins

    DECIDED:
    - Ship variant B to 100% Friday
    - Pause notifications rework until Q3
    - Hire two iOS contractors before payments work starts

    TODO:
    - @Mira  draft payments RFC by Mar 22 — URGENT
    - @Jon  confirm budget envelope by Mar 19
    - @Priya  sync with design on mobile timeline
    - @Alex  set up infra hiring loop next week

    OPEN QUESTIONS:
    - Do we backport search v2 to v3?
    - Who owns the new mobile RFC?
    - Migration window for the payments cutover?
    """)

    /// Shorter, single section. Tests behavior when there's no explicit
    /// DECISIONS / OPEN QUESTIONS header.
    static let retroLite = TestCase(name: "Retro lite", ocr: """
    Sprint retro — what went well / didn't

    Went well:
    - Pairing helped onboarding land
    - Faster reviews after the rotation policy

    Didn't:
    - Flaky integration tests cost us 2 days
    - Slack threads scattered across channels

    Next:
    - Migrate flaky tests to the new harness — @Sam, by next Friday
    - Pick one #engineering channel for incident chatter
    - Should we keep the rotation policy or sunset?
    """)

    /// Academic content. Owners should be sparse/nil. Lots of questions
    /// the model should NOT classify as open questions for the user.
    static let lectureNotes = TestCase(name: "Lecture notes", ocr: """
    Distributed systems — Lecture 7 — Consensus

    Two-phase commit:
    - Coordinator + participants
    - Pre-commit phase, commit/abort phase
    - Blocking if coordinator fails

    Paxos:
    - Prepare, accept, learn
    - Safety vs liveness
    - FLP impossibility under async + faults

    Raft:
    - Strong leader, log replication
    - Easier to reason about than Paxos

    Open question for office hours:
    - When does Raft beat Paxos in practice?
    """)

    /// UX-research output. Owners often implied ("we'll", "team").
    /// Should yield decisions + an explicit open question; few owned actions.
    static let stickyWorkshop = TestCase(name: "Sticky workshop", ocr: """
    Onboarding friction — sticky workshop, Mar 14

    Top friction clusters (32 stickies):
    1. Account creation flow (12)
    2. Empty state — no first action (9)
    3. Billing setup mid-flow (7)
    4. Notification permission timing (4)

    DECIDED:
    - Move billing to after first save
    - Add a single suggested action on empty state
    - Defer notification prompt until session 2

    Followups (this sprint):
    - Audrey to wireframe the new empty state
    - Devon to prototype delayed-prompt copy

    Q: Should account creation be optional for read-only mode?
    """)

    /// 1:1 meeting notes. Owners are the two participants. Actions are
    /// often hedged ("look into", "consider"). Tests model's judgment
    /// about what counts as an action.
    static let oneOnOne = TestCase(name: "Mira / Jon 1:1", ocr: """
    Mira <> Jon 1:1 — Mar 12

    Career topics:
    - Mira: payments staffing concern, comp band question
    - Jon: tech-lead role expectations

    Growth areas (Mira):
    - More cross-team alignment
    - Deeper infra review participation
    - Promo case study by Q3

    Asks of me (Jon):
    - Calibration check on Mira's last 2 reviews

    Followups:
    - Jon: pull Mira's last 6 review entries by Friday
    - Mira: write up payments staffing memo this week
    """)

    /// Personal note, no team, no meeting structure. Owners should be nil
    /// or sparse. Actions are personal commitments, not assigned tasks.
    static let personalJournal = TestCase(name: "Personal journal", ocr: """
    Sunday afternoon, Mar 10

    Things to think about:
    - The hike up Mt. Tam \u{2014} try the dipsea trail
    - Bread starter needs feeding tonight
    - Books to read: Stoner, The Sympathizer
    - Coffee with Sam next week if possible

    Mood: tired but settling
    """)

    /// Single-actor errand list. All owners should be nil (no @Name in
    /// source). One item has IMPORTANT marker.
    static let errandsList = TestCase(name: "Saturday errands", ocr: """
    Saturday errands

    - Pick up dry cleaning
    - Return library books by tomorrow
    - Buy bread + milk
    - Call dentist re: appointment
    - Renew gym membership before Friday \u{2014} IMPORTANT
    """)

    /// Mostly-unreadable OCR — fragments, isolated words. The model
    /// should produce a short neutral title and admit the source is
    /// unreadable in the summary. Empty arrays expected for all
    /// structured fields.
    static let sparseUnreadable = TestCase(name: "Mostly unreadable", ocr: """
    ... mig... infr...
    ?? sched
    Q4
    todo
    sync
    ----
    Frid
    Jen
    """)
}

// MARK: - Entity extractor tests

@Suite("EntityExtractor.parseDate — formatted")
struct EntityParseDateFormatted {

    @Test func iso8601() {
        let date = EntityExtractor.parseDate("2026-03-22")
        #expect(date != nil)
        let comps = Calendar.current.dateComponents([.year, .month, .day], from: date!)
        #expect(comps.year == 2026)
        #expect(comps.month == 3)
        #expect(comps.day == 22)
    }

    @Test func shortMonthDay() {
        let date = EntityExtractor.parseDate("Mar 22")
        #expect(date != nil)
        let comps = Calendar.current.dateComponents([.month, .day], from: date!)
        #expect(comps.month == 3 && comps.day == 22)
    }

    @Test func longMonthDayWithOrdinal() {
        let date = EntityExtractor.parseDate("March 22nd")
        #expect(date != nil)
        let comps = Calendar.current.dateComponents([.month, .day], from: date!)
        #expect(comps.month == 3 && comps.day == 22)
    }

    @Test func slashFormat() {
        let date = EntityExtractor.parseDate("3/22")
        #expect(date != nil)
        let comps = Calendar.current.dateComponents([.month, .day], from: date!)
        #expect(comps.month == 3 && comps.day == 22)
    }

    @Test func extractsFromLeadingBy() {
        // NSDataDetector picks the date out of surrounding text.
        let date = EntityExtractor.parseDate("by Mar 22")
        #expect(date != nil)
    }

    @Test func nilForEmpty() {
        #expect(EntityExtractor.parseDate("") == nil)
        #expect(EntityExtractor.parseDate(nil) == nil)
        #expect(EntityExtractor.parseDate("   ") == nil)
    }

    @Test func nilForSentinelStrings() {
        #expect(EntityExtractor.parseDate("nil") == nil)
        #expect(EntityExtractor.parseDate("None") == nil)
        #expect(EntityExtractor.parseDate("n/a") == nil)
    }
}

@Suite("EntityExtractor.parseDate — relative")
struct EntityParseDateRelative {

    @Test func todayResolves() {
        #expect(EntityExtractor.parseDate("today") != nil)
    }

    @Test func tomorrowResolves() {
        let today = Calendar.current.startOfDay(for: .now)
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        let parsed = EntityExtractor.parseDate("tomorrow")
        #expect(parsed != nil)
        // Tomorrow should be within ~36h of computed tomorrow.
        let delta = abs(parsed!.timeIntervalSince(tomorrow))
        #expect(delta < 36 * 3600)
    }

    @Test func nextFridayResolves() {
        #expect(EntityExtractor.parseDate("next Friday") != nil)
    }

    @Test func bareWeekdayResolves() {
        #expect(EntityExtractor.parseDate("Friday") != nil)
    }
}

@Suite("EntityExtractor.isPersonName")
struct EntityIsPersonName {

    @Test func recognizesCommonNames() {
        #expect(EntityExtractor.isPersonName("Mira"))
        #expect(EntityExtractor.isPersonName("Jon"))
        #expect(EntityExtractor.isPersonName("Priya"))
        #expect(EntityExtractor.isPersonName("Alex"))
    }

    @Test func rejectsGenericWords() {
        #expect(!EntityExtractor.isPersonName("team"))
        #expect(!EntityExtractor.isPersonName("everyone"))
    }

    @Test func rejectsEmpty() {
        #expect(!EntityExtractor.isPersonName(""))
        #expect(!EntityExtractor.isPersonName(nil))
    }
}
