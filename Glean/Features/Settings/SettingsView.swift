//
//  SettingsView.swift
//  Glean
//

import FoundationModels
import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    @AppStorage(AppTheme.storageKey) private var theme: AppTheme = .light

    @Query private var notes: [Note]

    @State private var aiText = "Ready"
    @State private var aiOK = true
    @State private var storageString = "—"

    @State private var showingPrivacy = false
    @State private var showingClearConfirm = false
    @State private var deleteTrigger = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    PrivacyHero { showingPrivacy = true }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(.init(top: 12, leading: 0, bottom: 12, trailing: 0))
                }

                Section("Intelligence") {
                    HStack {
                        chipLabel("Apple Intelligence", icon: "sparkles", color: .accentColor)
                        Spacer()
                        StatusPill(text: aiText, ok: aiOK)
                    }
                    HStack {
                        chipLabel("Foundation model", icon: "bolt.fill",
                                  color: Color(red: 0x7A/255, green: 0x8F/255, blue: 0x82/255))
                        Spacer()
                        Text("\(UIDevice.current.model) · Local")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Appearance") {
                    HStack {
                        chipLabel("Theme", icon: "moon.fill",
                                  color: Color(red: 0x7E/255, green: 0x89/255, blue: 0xA1/255))
                        Spacer()
                        Picker("Theme", selection: $theme) {
                            ForEach(AppTheme.allCases) { Text($0.rawValue).tag($0) }
                        }
                        .labelsHidden()
                        .pickerStyle(.segmented)
                        .frame(width: 180)
                    }
                }

                Section("Data") {
                    HStack {
                        chipLabel("Notes stored", icon: "tray.fill",
                                  color: Color(red: 0x9A/255, green: 0x8A/255, blue: 0xA1/255))
                        Spacer()
                        Text("\(notes.count) · \(storageString)")
                            .font(.subheadline)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                            .contentTransition(.numericText())
                    }
                    Button(role: .destructive) {
                        showingClearConfirm = true
                    } label: {
                        chipLabel(
                            "Clear all notes",
                            icon: "trash.fill",
                            color: Color(red: 0x9F/255, green: 0x4D/255, blue: 0x3A/255),
                            destructive: true
                        )
                    }
                }

                Section {
                    footer
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.accentColor)
                }
            }
            .toolbarColorScheme(theme.colorScheme)
            .alert("Delete all notes?", isPresented: $showingClearConfirm) {
                Button("Delete all", role: .destructive) {
                    deleteTrigger.toggle()
                    clearAllNotes()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This permanently removes all \(notes.count) notes from this device. This action can't be undone.")
            }
            .sheet(isPresented: $showingPrivacy) {
                PrivacyDetailSheet()
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .sensoryFeedback(.selection, trigger: theme)
            .sensoryFeedback(.impact(weight: .light), trigger: showingClearConfirm) { _, new in new }
            .sensoryFeedback(.impact(weight: .light), trigger: showingPrivacy) { _, new in new }
            .sensoryFeedback(.impact(flexibility: .rigid), trigger: deleteTrigger)
            .onAppear { refreshAvailability() }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active { refreshAvailability() }
            }
            .task(id: notes.count) {
                let bytes = await Task.detached(priority: .background) {
                    Storage.totalBytes()
                }.value
                storageString = ByteCountFormatter.string(
                    fromByteCount: bytes,
                    countStyle: .file
                )
            }
        }
        .preferredColorScheme(theme.colorScheme)
    }

    private var versionString: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "0.0"
        let build = info?["CFBundleVersion"] as? String ?? "0"
        return "GLEAN · v \(version) (\(build))"
    }

    private func clearAllNotes() {
        withAnimation(.snappy(duration: 0.3)) {
            for note in notes {
                modelContext.delete(note)
            }
        }
    }

    private func refreshAvailability() {
        switch SystemLanguageModel.default.availability {
        case .available:
            aiText = "Ready"
            aiOK = true
        case .unavailable(let reason):
            aiOK = false
            switch reason {
            case .deviceNotEligible:
                aiText = "Not supported"
            case .appleIntelligenceNotEnabled:
                aiText = "Disabled"
            case .modelNotReady:
                aiText = "Downloading…"
            @unknown default:
                aiText = "Unavailable"
            }
        }
    }

    private func chipLabel(
        _ title: String,
        icon: String,
        color: Color,
        destructive: Bool = false
    ) -> some View {
        Label {
            Text(title)
                .foregroundStyle(destructive ? Color.red : Color.primary)
        } icon: {
            ZStack {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(color)
                    .frame(width: 28, height: 28)
                Image(systemName: icon)
                    .font(.system(.subheadline, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
        .labelStyle(.titleAndIcon)
    }
    private var footer: some View {
        VStack(spacing: 4) {
            Text("Built for notes, on-device.")
                .font(.system(.subheadline, design: .serif, weight: .medium))
                .italic()
                .kerning(-0.1)
                .foregroundStyle(.secondary)
            Text(versionString)
                .font(.caption2.weight(.semibold))
                .kerning(0.4)
                .monospacedDigit()
                .foregroundStyle(Color(.tertiaryLabel))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
    }
}

#Preview("Settings — Light") {
    SettingsView().preferredColorScheme(.light)
}

#Preview("Settings — Dark") {
    SettingsView().preferredColorScheme(.dark)
}
