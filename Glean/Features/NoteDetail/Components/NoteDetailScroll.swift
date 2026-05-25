//
//  NoteDetailScroll.swift
//  Glean
//

import SwiftUI

private struct NoteDetailScrollProxyKey: EnvironmentKey {
    static let defaultValue: ScrollViewProxy? = nil
}

extension EnvironmentValues {
    var noteDetailScrollProxy: ScrollViewProxy? {
        get { self[NoteDetailScrollProxyKey.self] }
        set { self[NoteDetailScrollProxyKey.self] = newValue }
    }
}

extension Optional where Wrapped == ScrollViewProxy {
    func reveal(_ id: some Hashable, anchor: UnitPoint = .top) {
        withAnimation(.snappy(duration: 0.32)) {
            self?.scrollTo(id, anchor: anchor)
        }
    }
}
