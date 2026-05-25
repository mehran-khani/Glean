//
//  MockProcessor.swift
//  Glean
//

import Foundation

#if DEBUG
struct MockProcessor: CaptureProcessing {
    var phaseDelay: Duration = .milliseconds(700)

    func process(imageData: Data) -> AsyncStream<ProcessingEvent> {
        AsyncStream { continuation in
            let task = Task {
                for phase in ProcessingPhase.allCases {
                    continuation.yield(.phase(phase))
                    try? await Task.sleep(for: phaseDelay)
                    if Task.isCancelled { continuation.finish(); return }
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
#endif
