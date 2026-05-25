//
//  NoteDetailView.swift
//  Glean
//

import SwiftData
import SwiftUI

struct NoteDetailView: View {
    @Bindable var note: Note

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var copyTrigger = false
    @State private var deleteTrigger = false

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HeroImageSection(note: note)
                    TitleMetaSection(note: note)
                    SummarySection(note: note)
                    DecisionsSection(note: note)
                    ActionItemsSection(note: note)
                    OpenQuestionsSection(note: note)
                    TagsSection(note: note)
                    Spacer().frame(height: 40)
                }
                .frame(alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .environment(\.noteDetailScrollProxy, proxy)
            .scrollContentBackground(.hidden)
            .background(Color(.systemBackground))
            .scrollDismissesKeyboard(.interactively)
            .dynamicTypeSize(...DynamicTypeSize.accessibility2)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .sensoryFeedback(.impact(weight: .light), trigger: note.pinned)
            .sensoryFeedback(.impact(weight: .light), trigger: copyTrigger)
            .sensoryFeedback(.impact(flexibility: .rigid), trigger: deleteTrigger)
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            ShareLink(item: shareText) {
                Image(systemName: "square.and.arrow.up")
            }
            .accessibilityLabel("Share")
        }

        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button(note.pinned ? "Unpin" : "Pin",
                       systemImage: note.pinned ? "pin.slash" : "pin")
                {
                    withAnimation(.snappy(duration: 0.25)) {
                        note.pinned.toggle()
                    }
                }
                Button("Copy summary", systemImage: "doc.on.doc") {
                    UIPasteboard.general.string = note.summary
                    copyTrigger.toggle()
                }
                Section {
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        deleteTrigger.toggle()
                        modelContext.delete(note)
                        dismiss()
                    }
                }
            } label: {
                Image(systemName: "ellipsis")
            }
            .accessibilityLabel("More options")
        }
    }

    private var shareText: String {
        var parts = ["\(note.title)", "", note.summary]
        if !note.decisions.isEmpty {
            parts.append("")
            parts.append("Decisions:")
            parts.append(contentsOf: note.decisions.map { "• \($0)" })
        }
        if !note.actionItems.isEmpty {
            parts.append("")
            parts.append("Action items:")
            parts.append(contentsOf: note.actionItems.map { "• \($0.text)" })
        }
        return parts.joined(separator: "\n")
    }
}

#if DEBUG
#Preview("Detail — Light") {
    let container = Note.previewContainer
    let note = try! container.mainContext.fetch(
        FetchDescriptor<Note>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
    ).first!
    return NavigationStack {
        NoteDetailView(note: note)
    }
    .modelContainer(container)
    .preferredColorScheme(.light)
}

#Preview("Detail — Dark") {
    let container = Note.previewContainer
    let note = try! container.mainContext.fetch(
        FetchDescriptor<Note>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
    ).first!
    return NavigationStack {
        NoteDetailView(note: note)
    }
    .modelContainer(container)
    .preferredColorScheme(.dark)
}
#endif
