//
//  OpenQuestionRow.swift
//  Glean
//

import SwiftUI

struct OpenQuestionRow: View {
    @Bindable var question: OpenQuestion
    var autoFocus: Bool
    var onTextEmpty: () -> Void
    var onDelete: () -> Void
    var onBeginEdit: () -> Void = {}

    @State private var isEditingAnswer = false
    @State private var draftAnswer = ""
    @State private var commitTrigger = false
    @State private var beginTrigger = false

    @FocusState private var fieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: question.isAnswered ? "checkmark.circle.fill" : "questionmark.circle")
                    .font(.subheadline)
                    .foregroundStyle(Color.accentColor.opacity(question.isAnswered ? 1.0 : 0.75))
                    .padding(.top, 4)
                    .contentTransition(.symbolEffect(.replace))

                EditableInlineText(
                    text: $question.text,
                    placeholder: "New question…",
                    font: .subheadline,
                    multiline: true,
                    lineSpacing: 2,
                    kerning: -0.15,
                    autoFocusOnAppear: autoFocus,
                    onEmpty: onTextEmpty,
                    onBeginEdit: onBeginEdit
                )
                .accessibilityLabel("Question")
            }

            answerArea
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .contentShape(.rect)
        .overlay(
            RoundedRectangle(cornerRadius: GleanRadius.lg, style: .continuous)
                .strokeBorder(
                    Color(.separator),
                    style: StrokeStyle(lineWidth: 1, dash: question.isAnswered ? [] : [4, 4])
                )
        )
        .contextMenu {
            Button("Delete", systemImage: "trash", role: .destructive, action: onDelete)
        }
        .animation(.snappy(duration: 0.24), value: isEditingAnswer)
        .animation(.snappy(duration: 0.24), value: question.isAnswered)
        .sensoryFeedback(.impact(weight: .light), trigger: commitTrigger)
        .sensoryFeedback(.selection, trigger: beginTrigger)
    }

    @ViewBuilder
    private var answerArea: some View {
        if isEditingAnswer {
            editor
                .transition(.blurReplace)
        } else if question.isAnswered, let answer = question.answer, !answer.isEmpty {
            answerLine(answer)
                .transition(.blurReplace)
        } else {
            addAnswerHint
                .transition(.blurReplace)
        }
    }

    private var editor: some View {
        VStack(alignment: .trailing, spacing: 6) {
            TextField("Type your answer…", text: $draftAnswer, axis: .vertical)
                .focused($fieldFocused)
                .lineLimit(1 ... 4)
                .font(.subheadline)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color(.systemFill).opacity(0.5))
                )
                .onChange(of: fieldFocused) { _, focused in
                    if focused {
                        onBeginEdit()
                    } else if isEditingAnswer {
                        commitAnswer()
                    }
                }

            HStack(spacing: 8) {
                Button("Cancel") {
                    draftAnswer = question.answer ?? ""
                    isEditingAnswer = false
                }
                .font(.footnote.weight(.medium))
                .foregroundStyle(.secondary)

                Button("Save") { commitAnswer() }
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
                    .disabled(draftAnswer.trimmingCharacters(in: .whitespaces).isEmpty
                        && (question.answer ?? "").isEmpty)
            }
        }
        .padding(.leading, 24)
    }

    private func answerLine(_ answer: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: "arrow.turn.down.right")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.top, 3)
            Text(answer)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
            Spacer(minLength: 0)
        }
        .padding(.leading, 24)
        .contentShape(.rect)
        .onTapGesture { beginEditingAnswer(seed: answer) }
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel("Edit answer")
    }

    private var addAnswerHint: some View {
        Text("Add an answer…")
            .font(.footnote.weight(.medium))
            .foregroundStyle(Color.accentColor)
            .padding(.leading, 24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
            .onTapGesture { beginEditingAnswer(seed: question.answer ?? "") }
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel("Add answer")
    }

    private func beginEditingAnswer(seed: String) {
        draftAnswer = seed
        isEditingAnswer = true
        beginTrigger.toggle()
        Task { @MainActor in
            fieldFocused = true
        }
    }

    private func commitAnswer() {
        let trimmed = draftAnswer.trimmingCharacters(in: .whitespacesAndNewlines)
        let didChange: Bool
        if trimmed.isEmpty {
            didChange = (question.answer ?? "").isEmpty == false
            question.answer = nil
            question.isAnswered = false
        } else {
            didChange = trimmed != (question.answer ?? "")
            question.answer = trimmed
            question.isAnswered = true
        }
        isEditingAnswer = false
        fieldFocused = false
        if didChange { commitTrigger.toggle() }
    }
}
