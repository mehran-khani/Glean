//
//  LibraryView.swift
//  Glean
//

import SwiftData
import SwiftUI

struct LibraryView: View {
    private static let captureSheetHeight: CGFloat = 400

    @Environment(\.modelContext) private var modelContext

    @AppStorage(AppTheme.storageKey) private var theme: AppTheme = .light

    @Query(sort: \Note.createdAt, order: .reverse, animation: .bouncy)
    private var notes: [Note]

    @State private var search = ""
    @State private var sortOrder: SortOrder = .newest
    @State private var pinnedOnly = false

    @State private var showingCapture = false
    @State private var showingSettings = false
    @State private var pendingImageData: Data?
    @State private var captureDetent: PresentationDetent = .height(Self.captureSheetHeight)

    @State private var navigationTarget: Note?

    @State private var selectedNoteIDs: Set<UUID> = []
    @State private var editMode: EditMode = .inactive
    @State private var showingBulkDeleteConfirm = false
    @State private var bulkDeleteTrigger = false

    enum SortOrder: String, CaseIterable, Identifiable {
        case newest = "Newest first"
        case oldest = "Oldest first"
        case title = "Title"
        var id: String { rawValue }
        var icon: String {
            switch self {
            case .newest: return "arrow.down.to.line"
            case .oldest: return "arrow.up.to.line"
            case .title: return "textformat"
            }
        }
    }

    private var filteredNotes: [Note] {
        var result = notes
        if pinnedOnly { result = result.filter(\.pinned) }
        if !search.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(search)
                    || $0.summary.localizedCaseInsensitiveContains(search)
                    || $0.tags.contains { $0.localizedCaseInsensitiveContains(search) }
            }
        }
        return result.sorted { lhs, rhs in
            if lhs.pinned != rhs.pinned { return lhs.pinned }
            switch sortOrder {
            case .newest: return lhs.createdAt > rhs.createdAt
            case .oldest: return lhs.createdAt < rhs.createdAt
            case .title: return lhs.title.localizedCompare(rhs.title) == .orderedAscending
            }
        }
    }

    private var selectedNotes: [Note] {
        notes.filter { selectedNoteIDs.contains($0.id) }
    }

    /// If every selected note is already pinned, the bulk button unpins them all;
    /// otherwise it pins everything in the selection.
    private var bulkAllPinned: Bool {
        let s = selectedNotes
        return !s.isEmpty && s.allSatisfy(\.pinned)
    }

    private var bulkPinLabel: String { bulkAllPinned ? "Unpin" : "Pin" }
    private var bulkPinSymbol: String { bulkAllPinned ? "pin.slash" : "pin" }

    var body: some View {
        NavigationStack {
            List(selection: $selectedNoteIDs) {
                ForEach(filteredNotes) { note in
                    LibraryListItem(note: note, navigationTarget: $navigationTarget)
                }
            }
            .environment(\.editMode, $editMode)
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color(.systemBackground))
            .overlay {
                if notes.isEmpty {
                    emptyState
                }
            }
            .navigationTitle("Notes")
            .navigationSubtitle(editMode.isEditing
                ? "\(selectedNoteIDs.count) selected"
                : "\(notes.count) notes · on-device")
            .searchable(
                text: $search,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search notes"
            )
            .toolbar { toolbarContent }
            .toolbar {
                if editMode.isEditing {
                    ToolbarItem(placement: .bottomBar) {
                        Button {
                            togglePinOnSelected()
                        } label: {
                            Label(bulkPinLabel, systemImage: bulkPinSymbol)
                        }
                        .disabled(selectedNoteIDs.isEmpty)
                    }
                    ToolbarSpacer(.fixed, placement: .bottomBar)
                    ToolbarItem(placement: .bottomBar) {
                        Button(role: .destructive) {
                            showingBulkDeleteConfirm = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .disabled(selectedNoteIDs.isEmpty)
                    }
                }
            }
            .toolbar(editMode.isEditing ? .visible : .hidden, for: .bottomBar)
            .toolbarColorScheme(theme.colorScheme)
            .navigationDestination(item: $navigationTarget) { note in
                NoteDetailView(note: note)
            }
            .sheet(isPresented: $showingCapture, onDismiss: {
                pendingImageData = nil
                captureDetent = .height(Self.captureSheetHeight)
            }) {
                captureFlowSheet
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .alert("Delete \(selectedNoteIDs.count) notes?", isPresented: $showingBulkDeleteConfirm) {
                Button("Delete all", role: .destructive) {
                    bulkDeleteTrigger.toggle()
                    deleteSelected()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This permanently removes the selected notes from this device. This action can't be undone.")
            }
            .sensoryFeedback(.impact(weight: .light), trigger: showingCapture) { _, new in new }
            .sensoryFeedback(.impact(weight: .light), trigger: showingSettings) { _, new in new }
            .sensoryFeedback(.selection, trigger: sortOrder)
            .sensoryFeedback(.selection, trigger: pinnedOnly)
            .sensoryFeedback(.impact(flexibility: .rigid), trigger: bulkDeleteTrigger)
            .onChange(of: editMode) { _, new in
                if !new.isEditing { selectedNoteIDs.removeAll() }
            }
        }
    }

    private func togglePinOnSelected() {
        let shouldPin = !bulkAllPinned
        withAnimation(.snappy(duration: 0.35)) {
            for note in selectedNotes {
                note.pinned = shouldPin
            }
        }
    }

    private func deleteSelected() {
        withAnimation(.snappy(duration: 0.3)) {
            for note in selectedNotes {
                modelContext.delete(note)
            }
            selectedNoteIDs.removeAll()
            editMode = .inactive
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                showingSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .foregroundStyle(Color.accentColor)
            }
            .accessibilityLabel("Settings")
        }

        ToolbarItem(placement: .topBarLeading) {
            sortFilterMenu
        }

        ToolbarItem(placement: .topBarTrailing) {
            Button {
                withAnimation {
                    editMode = editMode.isEditing ? .inactive : .active
                }
            } label: {
                Image(systemName: editMode.isEditing ? "checkmark" : "checklist")
                    .contentTransition(.symbolEffect(.replace))
            }
            .tint(.accentColor)
            .accessibilityLabel(editMode.isEditing ? "Done" : "Edit")
        }

        ToolbarSpacer(.fixed, placement: .topBarTrailing)

        if !editMode.isEditing {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingCapture = true
                } label: {
                    Image(systemName: "camera.viewfinder")
                }
                .tint(.accentColor)
                .accessibilityLabel("New note")
            }
        }
    }

    @ViewBuilder
    private var captureFlowSheet: some View {
        ZStack {
            if let data = pendingImageData {
                ProcessingView(
                    imageData: data,
                    onComplete: {
                        pendingImageData = nil
                        showingCapture = false
                    }
                )
                .transition(.blurReplace.combined(with: .scale(0.98)))
            } else {
                CaptureSheet { data in
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.88)) {
                        pendingImageData = data
                        captureDetent = .large
                    }
                }
                .transition(.blurReplace.combined(with: .scale(0.98)))
            }
        }
        .presentationDetents([.height(Self.captureSheetHeight), .large], selection: $captureDetent)
        .presentationDragIndicator(pendingImageData == nil ? .visible : .hidden)
        .interactiveDismissDisabled(pendingImageData != nil)
    }

    private var sortFilterMenu: some View {
        Menu {
            Section("Sort") {
                ForEach(SortOrder.allCases) { option in
                    Button {
                        sortOrder = option
                    } label: {
                        Label(
                            option.rawValue,
                            systemImage: sortOrder == option ? "checkmark" : option.icon
                        )
                    }
                }
            }
            Section("Filter") {
                Toggle(isOn: $pinnedOnly) {
                    Label("Pinned only", systemImage: "pin.fill")
                }
            }
        } label: {
            Image(systemName: pinnedOnly
                ? "line.3.horizontal.decrease.circle.fill"
                : "line.3.horizontal.decrease.circle")
                .foregroundStyle(Color.accentColor)
        }
        .accessibilityLabel("Sort and filter")
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "tray")
                .font(.system(.largeTitle, weight: .light))
                .foregroundStyle(.secondary)
            Text("No notes yet")
                .font(.system(.headline, design: .serif, weight: .semibold))
                .foregroundStyle(.primary)
            Text("Tap \(Image(systemName: "camera.viewfinder")) to capture your first note.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }
}

#if DEBUG
#Preview("Library — Light") {
    LibraryView()
        .modelContainer(Note.previewContainer)
        .preferredColorScheme(.light)
}

#Preview("Library — Dark") {
    LibraryView()
        .modelContainer(Note.previewContainer)
        .preferredColorScheme(.dark)
}
#endif
