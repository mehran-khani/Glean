//
//  PhaseDot.swift
//  Glean
//

import SwiftUI

struct PhaseDot: View {
    enum State { case done, active, todo }
    let state: State

    var body: some View {
        Group {
            switch state {
            case .done:
                ZStack {
                    Circle().fill(Color.accentColor)
                    Image(systemName: "checkmark")
                        .font(.system(.caption2, weight: .bold))
                        .foregroundStyle(.white)
                }
                .frame(width: 18, height: 18)
                .transition(.scale.combined(with: .opacity))
            case .active:
                Capsule()
                    .fill(Color.accentColor)
                    .frame(width: 24, height: 8)
                    .padding(4)
                    .background(Capsule().fill(Color.accentColor.opacity(0.13)).padding(-4))
                    .transition(.scale.combined(with: .opacity))
            case .todo:
                Circle()
                    .fill(Color(.tertiaryLabel).opacity(0.5))
                    .frame(width: 8, height: 8)
                    .transition(.opacity)
            }
        }
        .animation(.bouncy(duration: 0.45, extraBounce: 0.1), value: state)
    }
}

extension PhaseDot.State: Equatable {}
