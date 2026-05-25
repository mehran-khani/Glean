//
//  OpenQuestionsSection.swift
//  Glean
//

import SwiftData
import SwiftUI

struct OpenQuestionsSection: View {
    @Bindable var note: Note

    @Environment(\.modelContext) private var modelContext
    @Environment(\.noteDetailScrollProxy) private var scrollProxy

    @State private var addTrigger = false
    @State private var deleteTrigger = false
    @State private var freshlyAddedID: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(
                title: "Open questions",
                count: note.openQuestions.isEmpty ? nil : note.openQuestions.count,
                addLabel: "Add question"
            ) { addQuestion() }

            if note.openQuestions.isEmpty {
                EmptyHint(text: "No open questions yet. Tap \(Image(systemName: "plus.circle.fill")) to add one.")
            } else {
                VStack(spacing: 10) {
                    ForEach(note.openQuestions) { question in
                        OpenQuestionRow(
                            question: question,
                            autoFocus: question.id == freshlyAddedID,
                            onTextEmpty: { removeQuestion(question) },
                            onDelete: { removeQuestion(question) },
                            onBeginEdit: { scrollProxy.reveal(question.id) }
                        )
                        .id(question.id)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .top)),
                            removal: .opacity.combined(with: .scale(scale: 0.94))
                        ))
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .animation(.snappy(duration: 0.28), value: note.openQuestions.count)
        .sensoryFeedback(.impact(weight: .light), trigger: addTrigger)
        .sensoryFeedback(.impact(flexibility: .rigid), trigger: deleteTrigger)
    }

    private func addQuestion() {
        let q = OpenQuestion(text: "", note: note)
        withAnimation(.snappy(duration: 0.28)) {
            modelContext.insert(q)
        }
        freshlyAddedID = q.id
        addTrigger.toggle()
    }

    private func removeQuestion(_ question: OpenQuestion) {
        withAnimation(.snappy(duration: 0.28)) {
            modelContext.delete(question)
        }
        deleteTrigger.toggle()
    }
}
