//
//  Storage.swift
//  Glean
//

import Foundation

enum Storage {
    nonisolated static func totalBytes() -> Int64 {
        guard let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else { return 0 }

        guard let enumerator = FileManager.default.enumerator(
            at: appSupport,
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else { return 0 }

        var total: Int64 = 0
        for case let url as URL in enumerator {
            let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            total += Int64(size)
        }
        return total
    }
}
