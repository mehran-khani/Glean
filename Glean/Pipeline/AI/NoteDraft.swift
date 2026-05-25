//
//  NoteDraft.swift
//  Glean
//

import FoundationModels

struct NoteDraft: Equatable, Sendable {
    var title: String
    var summary: String
    var decisions: [String]
    var actions: [ActionDraft]
    var questions: [String]
    var tags: [String]
}

@Generable
struct TitleSummaryPass: Equatable, Sendable {
    @Guide(description: "Topic title, 4–8 words, plain prose, no quotes, no 'Action Items' or 'Outcomes' suffix.")
    var title: String

    @Guide(description: "1–2 sentences describing concrete content from the source (what was discussed, what came out of it). Do NOT write a meta-description like 'list of tasks' or 'review of progress'. If the source is too unreadable to summarize, say so.")
    var summary: String
}

@Generable
struct DecisionsPass: Equatable, Sendable {
    @Guide(description: "Things explicitly DECIDED in the source. Each entry is a past-tense outcome statement ('Ship variant B Friday'). Tasks (anything with an owner or 'will do') do NOT belong here. Questions do NOT belong here. Empty array if no clear decisions.")
    var decisions: [String]
}

@Generable
struct ActionsPass: Equatable, Sendable {
    @Guide(description: "Tasks for someone to do, drawn from the source. Each action's fields come ONLY from that action's own line — never copy a field across lines.")
    var actions: [ActionDraft]
}

@Generable
struct QuestionsPass: Equatable, Sendable {
    @Guide(description: "Items ending in '?', labeled as open questions, or explicitly unresolved. A question is not an action even when phrased as 'Should we…'. Empty array if none.")
    var questions: [String]
}

@Generable
struct TagsPass: Equatable, Sendable {
    @Guide(description: "1–5 short topic labels describing what this note is about. Each tag is a single word or short hyphenated phrase, lowercase, drawn from words meaningfully present in the source ('payments', 'q4', 'infra', '1on1', 'sprint-14'). No generic filler like 'note' or 'meeting'. Empty array if no clear themes emerge.")
    var tags: [String]
}

@Generable
struct ActionDraft: Equatable, Sendable {
    @Guide(description: "Just the task: verb + object. Strip the owner name, the date, and any urgency markers from this field.")
    var text: String

    @Guide(description: "First name of the person named on this action's line (strip the '@'). Nil if no person is named on this line. Generic words ('team', 'we', 'everyone') are not owners.")
    var owner: String?

    @Guide(description: "Date phrase from this action's own line, copied as written ('Mar 22', 'next Friday', 'tomorrow'). Nil if no date appears on this line.")
    var dueDate: String?

    @Guide(description: "True only when the line contains an explicit urgency marker ('urgent', 'asap', '!!'). Default to false.")
    var urgent: Bool
}
