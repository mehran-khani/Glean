//
//  EditableInlineText.swift
//  Glean
//

import SwiftUI

struct EditableInlineText: View {
    @Binding var text: String

    var placeholder: String = "Add text…"
    var font: Font = .body
    var foregroundColor: Color = .primary
    var placeholderColor: Color = .secondary
    var multiline: Bool = false
    var lineSpacing: CGFloat = 0
    var kerning: CGFloat = 0
    var autoFocusOnAppear: Bool = false
    var onEmpty: () -> Void = {}
    var onCommit: () -> Void = {}
    var onBeginEdit: () -> Void = {}

    @State private var draft = ""
    @State private var isEditing = false
    @State private var commitTrigger = false
    @State private var beginTrigger = false

    @FocusState private var isFocused: Bool

    var body: some View {
        Group {
            if isEditing {
                editorView
                    .transition(.blurReplace)
            } else {
                readingView
                    .transition(.blurReplace)
            }
        }
        .animation(.easeInOut(duration: 0.26), value: isEditing)
        .onAppear {
            if autoFocusOnAppear && !isEditing {
                beginEditing()
            }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: commitTrigger)
        .sensoryFeedback(.selection, trigger: beginTrigger)
    }

    private var readingView: some View {
        Text(text.isEmpty ? placeholder : text)
            .font(font)
            .kerning(kerning)
            .lineSpacing(lineSpacing)
            .foregroundStyle(text.isEmpty ? placeholderColor : foregroundColor)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
            .onTapGesture { beginEditing() }
            .accessibilityAddTraits(.isButton)
            .accessibilityHint(text.isEmpty ? "Double tap to add" : "Double tap to edit")
    }

    @ViewBuilder
    private var editorView: some View {
        if multiline {
            VStack(alignment: .trailing, spacing: 8) {
                TextField(placeholder, text: $draft, axis: .vertical)
                    .font(font)
                    .kerning(kerning)
                    .lineSpacing(lineSpacing)
                    .foregroundStyle(foregroundColor)
                    .lineLimit(1 ... 12)
                    .focused($isFocused)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .onChange(of: isFocused) { _, focused in
                        handleFocusChange(focused)
                    }

                HStack(spacing: 12) {
                    Button("Cancel") { cancel() }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                    Button("Done") { commit() }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                        .disabled(draft == text)
                }
            }
        } else {
            TextField(placeholder, text: $draft, axis: .horizontal)
                .font(font)
                .kerning(kerning)
                .foregroundStyle(foregroundColor)
                .focused($isFocused)
                .submitLabel(.done)
                .onSubmit { commit() }
                .onChange(of: isFocused) { _, focused in
                    handleFocusChange(focused)
                }
        }
    }

    private func handleFocusChange(_ focused: Bool) {
        if focused {
            onBeginEdit()
        } else if isEditing {
            commit()
        }
    }

    private func beginEditing() {
        draft = text
        withAnimation(.easeInOut(duration: 0.18)) {
            isEditing = true
        }
        beginTrigger.toggle()
        
        Task { @MainActor in
            isFocused = true
        }
    }

    private func commit() {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            text = ""
            endEditing()
            onEmpty()
        } else {
            let didChange = trimmed != text
            text = trimmed
            endEditing()
            if didChange { commitTrigger.toggle() }
            onCommit()
        }
    }

    private func cancel() {
        draft = text
        endEditing()
        if text.isEmpty {
            onEmpty()
        }
    }

    private func endEditing() {
        isFocused = false
        withAnimation(.easeInOut(duration: 0.18)) {
            isEditing = false
        }
    }
}
