//
//  EditableTagChip.swift
//  Glean
//

import SwiftUI

struct EditableTagChip: View {
    @Binding var text: String
    var accent: Bool
    var autoFocus: Bool
    var onEmpty: () -> Void
    var onDelete: () -> Void
    var onBeginEdit: () -> Void = {}
    var isDuplicate: (String) -> Bool = { _ in false }

    @State private var isEditing = false
    @State private var draft = ""
    @State private var commitTrigger = false
    @State private var beginTrigger = false
    @State private var rejectTrigger = false

    @FocusState private var focused: Bool

    private static let swapAnimation: Animation = .spring(response: 0.42, dampingFraction: 0.62)

    var body: some View {
        Group {
            if isEditing {
                editorChip
                    .transition(.scale(scale: 0.55, anchor: .center).combined(with: .opacity))
            } else {
                displayChip
                    .transition(.scale(scale: 0.55, anchor: .center).combined(with: .opacity))
            }
        }
        .onAppear {
            if autoFocus && !isEditing { beginEdit() }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: commitTrigger)
        .sensoryFeedback(.selection, trigger: beginTrigger)
        .sensoryFeedback(.warning, trigger: rejectTrigger)
    }

    private var displayChip: some View {
        GleanTag(text: text.isEmpty ? "tag" : text, accent: accent, leading: "number")
            .opacity(text.isEmpty ? 0.5 : 1)
            .contentShape(.capsule)
            .onTapGesture { beginEdit() }
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel("Tag \(text)")
            .contextMenu {
                Button("Delete", systemImage: "trash", role: .destructive, action: onDelete)
            }
    }

    private var editorChip: some View {
        HStack(spacing: 4) {
            Image(systemName: "number")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(accent ? Color.accentColor : Color.secondary)
            TextField("tag", text: $draft)
                .focused($focused)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .onSubmit { commit() }
                .onChange(of: focused) { _, f in
                    if f {
                        onBeginEdit()
                    } else if isEditing {
                        commit()
                    }
                }
                .font(.caption.weight(.medium))
                .frame(minWidth: 40, idealWidth: 60)
                .fixedSize()
                .foregroundStyle(accent ? Color.accentColor : Color.primary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule().fill(
                accent
                    ? Color.accentColor.opacity(0.12)
                    : Color(.systemFill).opacity(0.5)
            )
        )
        .overlay(
            Capsule().strokeBorder(
                accent ? Color.accentColor.opacity(0.5) : Color(.separator),
                lineWidth: 0.8
            )
        )
    }

    private func beginEdit() {
        draft = text
        withAnimation(Self.swapAnimation) {
            isEditing = true
        }
        beginTrigger.toggle()

        Task { @MainActor in
            focused = true
        }
    }

    private func commit() {
        let trimmed = draft
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "-")
            .lowercased()
        if trimmed.isEmpty {
            withAnimation(Self.swapAnimation) {
                isEditing = false
            }
            focused = false
            onEmpty()
            return
        }
        if isDuplicate(trimmed) {
            if text.isEmpty {
                withAnimation(Self.swapAnimation) {
                    isEditing = false
                }
                focused = false
                onEmpty()
            } else {
                draft = text
                withAnimation(Self.swapAnimation) {
                    isEditing = false
                }
                focused = false
                rejectTrigger.toggle()
            }
            return
        }
        let didChange = trimmed != text
        text = trimmed
        withAnimation(Self.swapAnimation) {
            isEditing = false
        }
        focused = false
        if didChange { commitTrigger.toggle() }
    }
}
