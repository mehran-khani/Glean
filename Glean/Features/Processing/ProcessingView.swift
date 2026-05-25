//
//  ProcessingView.swift
//  Glean
//

import SwiftData
import SwiftUI

struct ProcessingView: View {
    private static let entranceSpring: Animation = .bouncy(duration: 0.55, extraBounce: 0.1)
    private static let phaseSpring: Animation = .bouncy(duration: 0.45, extraBounce: 0.05)

    let imageData: Data
    let makeProcessor: (() -> any CaptureProcessing)?
    let onComplete: () -> Void

    private let heroImage: UIImage?

    @Environment(\.modelContext) private var modelContext

    @State private var phase: ProcessingPhase = .reading
    @State private var errorMessage: String?
    @State private var showShimmer = false
    @State private var didAppear = false
    @State private var successTrigger = false
    @State private var cancelTrigger = false

    init(
        imageData: Data,
        makeProcessor: (() -> any CaptureProcessing)? = nil,
        onComplete: @escaping () -> Void
    ) {
        self.imageData = imageData
        self.heroImage = Thumbnail.uncachedImage(from: imageData, maxDimension: 600)
        self.makeProcessor = makeProcessor
        self.onComplete = onComplete
    }

    var body: some View {
        VStack(spacing: 0) {
            topPill
                .padding(.top, 14)
                .opacity(didAppear ? 1 : 0)
                .offset(y: didAppear ? 0 : -6)
                .animation(Self.entranceSpring.delay(0.10), value: didAppear)

            hero
                .padding(.top, 18)
                .opacity(didAppear ? 1 : 0)
                .scaleEffect(didAppear ? 1 : 0.94, anchor: .center)
                .animation(.bouncy(duration: 0.65, extraBounce: 0.18), value: didAppear)

            Spacer(minLength: 16)

            phaseDots
                .opacity(didAppear ? 1 : 0)
                .offset(y: didAppear ? 0 : 6)
                .animation(Self.entranceSpring.delay(0.20), value: didAppear)

            phaseText
                .padding(.top, 14)
                .padding(.horizontal, 24)
                .opacity(didAppear ? 1 : 0)
                .offset(y: didAppear ? 0 : 6)
                .animation(Self.entranceSpring.delay(0.26), value: didAppear)

            stepCounter
                .padding(.top, 10)
                .opacity(didAppear ? 1 : 0)
                .animation(Self.entranceSpring.delay(0.32), value: didAppear)

            Spacer(minLength: 16)

            cancelPill
                .padding(.bottom, 20)
                .opacity(didAppear ? 1 : 0)
                .scaleEffect(didAppear ? 1 : 0.88)
                .animation(.bouncy(duration: 0.55, extraBounce: 0.15).delay(0.40), value: didAppear)
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            didAppear = true
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(600))
                withAnimation(.easeIn(duration: 0.35)) { showShimmer = true }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(errorMessage ?? phase.title)
        .sensoryFeedback(.selection, trigger: phase)
        .sensoryFeedback(.success, trigger: successTrigger)
        .sensoryFeedback(.error, trigger: errorMessage)
        .sensoryFeedback(.impact(weight: .light), trigger: cancelTrigger)
        .task {
            let processor: any CaptureProcessing = makeProcessor?()
                ?? CaptureProcessor(modelContainer: modelContext.container)
            for await event in processor.process(imageData: imageData) {
                switch event {
                case .phase(let next):
                    withAnimation(Self.phaseSpring) {
                        phase = next
                    }
                case .finished:
                    withAnimation(.easeOut(duration: 0.3)) { showShimmer = false }
                    successTrigger.toggle()
                    onComplete()
                    return
                case .failed(let message):
                    withAnimation(.easeOut(duration: 0.25)) { showShimmer = false }
                    errorMessage = message
                    try? await Task.sleep(for: .seconds(1.2))
                    onComplete()
                    return
                }
            }
        }
    }

    private var topPill: some View {
        HStack(spacing: 6) {
            ZStack {
                Circle().fill(Color.accentColor.opacity(0.2)).frame(width: 14, height: 14)
                Circle().fill(Color.accentColor).frame(width: 6, height: 6)
            }
            Text("On-device · Apple Intelligence")
                .font(.system(.caption, weight: .medium))
                .kerning(0.2)
                .foregroundStyle(.primary.opacity(0.85))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .glassEffect(.regular, in: .capsule)
    }

    private var hero: some View {
        ZStack {
            haloGlow
            heroPhoto
        }
        .containerRelativeFrame(.vertical) { length, _ in
            min(440, max(280, length * 0.50))
        }
        .frame(maxWidth: .infinity)
    }

    private var haloGlow: some View {
        RadialGradient(
            colors: [
                Color.accentColor.opacity(0.22),
                Color.accentColor.opacity(0.08),
                Color.clear
            ],
            center: .center,
            startRadius: 0,
            endRadius: 280
        )
        .blur(radius: 40)
        .scaleEffect(1.25)
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private var heroPhoto: some View {
        Group {
            if let ui = heroImage {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFit()
            } else {
                GleanPagePlaceholder()
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: GleanRadius.lg, style: .continuous))
        .overlay(shimmerOverlay)
    }

    @ViewBuilder private var shimmerOverlay: some View {
        if showShimmer {
            TimelineView(.animation) { context in
                let cycle: TimeInterval = 2.0
                let t = context.date.timeIntervalSinceReferenceDate
                let progress = (t.truncatingRemainder(dividingBy: cycle)) / cycle
                let leading = max(progress - 0.20, 0)
                let trailing = min(progress + 0.20, 1)
                RoundedRectangle(cornerRadius: GleanRadius.lg, style: .continuous)
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: .white.opacity(0), location: leading),
                                .init(color: .white.opacity(0.6), location: progress),
                                .init(color: .white.opacity(0), location: trailing)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .blendMode(.plusLighter)
                    .allowsHitTesting(false)
            }
            .transition(.opacity)
        }
    }

    private var phaseDots: some View {
        HStack(spacing: 8) {
            ForEach(ProcessingPhase.allCases, id: \.self) { p in
                PhaseDot(state: state(for: p))
            }
        }
    }

    private var phaseText: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: errorMessage == nil ? phase.symbol : "exclamationmark.triangle.fill")
                    .font(.system(.callout, weight: .semibold))
                    .foregroundStyle(errorMessage == nil ? Color.accentColor : Color.orange)
                    .symbolEffect(.pulse, options: .repeating, isActive: errorMessage == nil)
                    .contentTransition(.symbolEffect(.replace))
                Text(errorMessage == nil ? phase.title : "Something went wrong")
                    .font(.system(.title3, design: .serif, weight: .semibold))
                    .kerning(-0.3)
                    .foregroundStyle(.primary)
                    .contentTransition(.opacity)
            }
            Text(errorMessage ?? phase.subtitle)
                .font(.footnote)
                .kerning(-0.1)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .contentTransition(.opacity)
        }
    }

    private var stepCounter: some View {
        Text("STEP \(phase.rawValue + 1) OF \(ProcessingPhase.allCases.count)")
            .font(.system(.caption2, weight: .semibold))
            .kerning(0.3)
            .foregroundStyle(Color(.tertiaryLabel))
            .monospacedDigit()
            .contentTransition(.numericText(value: Double(phase.rawValue)))
    }

    private func state(for p: ProcessingPhase) -> PhaseDot.State {
        if p.rawValue < phase.rawValue { return .done }
        if p == phase { return .active }
        return .todo
    }

    private var cancelPill: some View {
        Button("Cancel") {
            cancelTrigger.toggle()
            onComplete()
        }
        .font(.system(.subheadline, weight: .medium))
        .kerning(-0.2)
        .foregroundStyle(.primary.opacity(0.92))
        .padding(.horizontal, 22)
        .padding(.vertical, 12)
        .glassEffect(.regular.interactive(), in: .capsule)
        .accessibilityLabel("Cancel processing")
    }
}

#if DEBUG
#Preview("Processing — Light") {
    ProcessingView(
        imageData: Data(),
        makeProcessor: { MockProcessor() },
        onComplete: {}
    )
    .preferredColorScheme(.light)
}

#Preview("Processing — Dark") {
    ProcessingView(
        imageData: Data(),
        makeProcessor: { MockProcessor() },
        onComplete: {}
    )
    .preferredColorScheme(.dark)
}
#endif
