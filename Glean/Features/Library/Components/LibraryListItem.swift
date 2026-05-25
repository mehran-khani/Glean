//
//  LibraryListItem.swift
//  Glean
//

import SwiftData
import SwiftUI

struct LibraryListItem: View {
    let note: Note

    @Binding var navigationTarget: Note?

    @Environment(\.modelContext) private var modelContext

    @State private var deleteTrigger = false
    @State private var copyTrigger = false

    var body: some View {
        Button {
            navigationTarget = note
        } label: {
            LibraryRow(note: note)
        }
        .buttonStyle(.plain)
        .tag(note.id)
        .listRowInsets(.init(top: 10, leading: 16, bottom: 10, trailing: 16))
        .alignmentGuide(.listRowSeparatorLeading) { _ in 94 }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                deleteTrigger.toggle()
                modelContext.delete(note)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .contextMenu { contextMenu }
        .sensoryFeedback(.impact(flexibility: .rigid), trigger: deleteTrigger)
        .sensoryFeedback(.impact(weight: .light), trigger: copyTrigger)
        .sensoryFeedback(.selection, trigger: note.pinned)
    }

    @ViewBuilder
    private var contextMenu: some View {
        Button {
            note.pinned.toggle()
        } label: {
            Label(pinTitle, systemImage: pinSymbol)
        }
        Button {} label: {
            Label("Export…", systemImage: "square.and.arrow.up")
        }
        Button {
            UIPasteboard.general.string = note.summary
            copyTrigger.toggle()
        } label: {
            Label("Copy summary", systemImage: "doc.on.doc")
        }
        Section {
            Button(role: .destructive) {
                deleteTrigger.toggle()
                modelContext.delete(note)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private var pinTitle: String { note.pinned ? "Unpin" : "Pin" }
    private var pinSymbol: String { note.pinned ? "pin.slash" : "pin" }
}
