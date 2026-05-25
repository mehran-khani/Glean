//
//  PrivacyDetailSheet.swift
//  Glean
//

import SwiftUI

struct PrivacyDetailSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    block(
                        "On-device only",
                        "Capture, OCR, summarization, and storage all run on this iPhone using Apple Intelligence's on-device Foundation Model. Your notes never leave the device."
                    )
                    block(
                        "No network",
                        "Glean does not contact any server. No analytics, no crash reporting to third parties, no cloud LLM fallback. Run a network proxy like Charles or Proxyman against the app and you will see zero outbound traffic."
                    )
                    block(
                        "No accounts",
                        "There is no sign-in, no account, and no identifier tied to you. The notes you make are stored locally and are visible only to you."
                    )
                    block(
                        "Your data, your move",
                        "Export individual notes via the share sheet. Delete any note (or all of them) from Settings. Uninstalling the app removes every byte Glean wrote to your device."
                    )
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .navigationTitle("Privacy promise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
    }

    @ViewBuilder
    private func block(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(.headline, design: .serif, weight: .semibold))
                .kerning(-0.2)
                .foregroundStyle(.primary)
            Text(body)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
