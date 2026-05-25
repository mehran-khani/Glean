//
//  CaptureAI+Passes.swift
//  Glean
//

import Foundation
import FoundationModels

nonisolated extension CaptureAI {

    static func generateTitleSummary(ocr: String) async -> TitleSummaryPass? {
        let instructions = """
        \(baseInstructions)

        Your only job in this pass is to produce a TitleSummaryPass: a \
        topic title and a 1–2 sentence summary of what the source is \
        about and what came out of it. Do not produce decisions, action \
        items, or questions in this pass.
        """
        return await runPass(
            instructions: instructions,
            ocr: ocr,
            temperature: 0.4,
            tools: [],
            generating: TitleSummaryPass.self
        )
    }

    static func generateDecisions(ocr: String) async -> [String]? {
        let instructions = """
        \(baseInstructions)

        Your only job in this pass is to extract DECISIONS — settled \
        conclusions the source treats as final. Decisions are signalled by:

        • Headers like DECIDED / LOCKED / RESOLVED / AGREED / OUTCOMES / \
        FINAL, with content under them.
        • Inline markers: a leading arrow (→), a checked box (☑ ✓ ✔), \
        or phrases like 'done', 'no revisit', 'locked in'.
        • Past-tense outcome statements that describe what was decided.

        A GOAL is NOT a decision (a goal is aspirational; a decision is \
        settled). Tasks with an owner or due date are NOT decisions — \
        another pass collects them. Open questions ending in '?' are NOT \
        decisions. The section header itself ('DECIDED:', 'LOCKED:') is \
        NOT a decision — only the items under it are.

        Copy each decision's text as it appears in the source, stripped of \
        leading marker glyphs (→, ☑, ☐, -, •, *). Do NOT include any text \
        from these instructions in your output — only text that appears in \
        the source. Return an empty array if no clear decisions are present.
        """
        let pass: DecisionsPass? = await runPass(
            instructions: instructions,
            ocr: ocr,
            temperature: 0.2,
            tools: [],
            generating: DecisionsPass.self
        )
        return pass?.decisions
    }

    static func generateActions(
        ocr: String,
        owners: [String]
    ) async -> [ActionDraft]? {
        var instructions = """
        \(baseInstructions)

        Your only job in this pass is to extract ACTION ITEMS — tasks for \
        someone to do.

        STRONG action signals (extract one action per line for these):
        • Lines starting with an unchecked checkbox: ☐, [ ], [].
        • Lines starting with '- ', '• ', or '* ' followed by a verb phrase.
        • Lines under headers like TODO / ACTIONS / ACTION ITEMS / TASKS / \
        NEXT STEPS / FOLLOWUPS.

        For each action, fill four fields by reading THIS action's own \
        line in isolation. Do not read fields from any other line, from \
        headers, or from the page title. If a field is absent on this \
        specific line, the field is nil — do not borrow it from elsewhere.

        • text: the bare task (verb + object). Strip owner names, dates, \
        urgency markers (URGENT, ASAP, !!, ★, ☆), checkbox glyphs, and \
        leading bullets from text.
        • owner: the person RESPONSIBLE for doing this task — the doer. \
        Two negative rules: (a) 'tell Priya' / 'send to Jon' / 'ask X' \
        means the named person is the RECIPIENT, so owner is nil. \
        (b) Names in parentheses, like '(Ongaro)' or '(Smith et al.)', \
        are citations or asides, never owners. Drop any leading '@'. \
        Generic words ('team', 'we', 'everyone', 'me') are NOT owners.
        • dueDate: a date phrase that appears on THIS line only ('Wed', \
        'Thu', 'Mar 22', 'next Friday', 'tomorrow', 'next wk', 'wknd'). \
        If this line has no date phrase, dueDate is nil. NEVER copy a \
        date from a title, header, or another action's line. You may \
        call the lookupDate tool to confirm a phrase resolves to a real \
        date.
        • urgent: true ONLY when this specific line contains one of these \
        markers: URGENT, ASAP, IMPORTANT, !!, ★, or ☆. Default to false. \
        Urgency NEVER carries from one line to another — if only Jon's \
        line has ★, only Jon's action is urgent.

        A line ending in '?' is an open question, NOT an action — skip it \
        here. Discussion-topic bullets ('Talk about: promo timeline') are \
        NOT actions either. GOAL statements are NOT actions.

        Every checkbox line (☐, [ ]) MUST become an action even if short. \
        Empty array is correct only if there are no tasks.
        """

        // Owner constraint only when 2+ explicit @-names are present; a
        // single-name constraint causes the model to over-attribute.
        if owners.count >= 2 {
            instructions += "\n\n@-OWNERS IN SOURCE: \(owners.joined(separator: ", ")). "
            instructions += "If an action is tagged with one of these names, attribute it. Otherwise, leave owner nil. Do not invent owners not in the source."
        }

        let session = LanguageModelSession(
            tools: [DateLookupTool()],
            instructions: instructions
        )
        let options = GenerationOptions(temperature: 0.2)
        do {
            let response = try await session.respond(
                to: ocrPrompt(ocr),
                generating: ActionsPass.self,
                options: options
            )
            return response.content.actions
        } catch {
            return nil
        }
    }

    static func generateQuestions(ocr: String) async -> [String]? {
        let instructions = """
        \(baseInstructions)

        Your only job in this pass is to extract OPEN QUESTIONS — items \
        the source raises but does not answer.

        A line is a question ONLY if at least one of these is true:
        • It ends with '?'.
        • It is wrapped in '?' markers ('? what's next ?').
        • It appears under a header like OPEN / OPEN QUESTIONS / \
        QUESTIONS / UNRESOLVED.

        Copy each question's text as it appears, with leading and trailing \
        '?' markers stripped.

        Lines starting with a checkbox (☐, [ ]) are actions, never \
        questions, even if the content sounds question-like. \
        Discussion-topic bullets ('promo timeline', 'who owns search \
        infra') are NOT questions unless explicitly marked with '?'. \
        Action items, decisions, and headers are NOT questions.

        Return an empty array if no questions are present.
        """
        let pass: QuestionsPass? = await runPass(
            instructions: instructions,
            ocr: ocr,
            temperature: 0.2,
            tools: [],
            generating: QuestionsPass.self
        )
        return pass?.questions
    }

    static func generateTags(ocr: String) async -> [String]? {
        let instructions = """
        \(baseInstructions)

        Your only job in this pass is to extract TAGS — 1 to 5 short topic \
        labels that describe what this source is about.

        If the source contains an explicit 'tags:' line, those words ARE \
        the tags (split on commas, lowercase, hyphenate multi-word). Do not \
        invent additional tags when an explicit line is present.

        Otherwise, infer tags from the source's themes. Each tag is a \
        single word or a short hyphenated phrase (max two words joined \
        with a hyphen), lowercase, drawn from words meaningfully present \
        in the source. Skip generic filler like 'note', 'meeting', 'list'. \
        Prefer concrete topics ('payments', 'q4', 'infra') over verbs from \
        action items ('cut', 'save').

        Empty array if no clear themes emerge.
        """
        let pass: TagsPass? = await runPass(
            instructions: instructions,
            ocr: ocr,
            temperature: 0.3,
            tools: [],
            generating: TagsPass.self
        )
        return pass?.tags
    }
}
