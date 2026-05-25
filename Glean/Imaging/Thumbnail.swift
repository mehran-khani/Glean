//
//  Thumbnail.swift
//  Glean
//

import ImageIO
import UIKit
import UniformTypeIdentifiers

enum Thumbnail {
    private static let cache: NSCache<NSString, UIImage> = {
        let c = NSCache<NSString, UIImage>()
        c.countLimit = 200
        return c
    }()

    static func image(
        from data: Data,
        maxDimension: CGFloat,
        cacheKey: String
    ) -> UIImage? {
        let scale = displayScale()
        let pixelDimension = Int(maxDimension * scale)
        let key = "\(cacheKey)#\(pixelDimension)" as NSString

        if let cached = cache.object(forKey: key) {
            return cached
        }

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: pixelDimension
        ]

        guard
            let source = CGImageSourceCreateWithData(data as CFData, nil),
            let cg = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
        else { return nil }

        let image = UIImage(cgImage: cg, scale: scale, orientation: .up)
        cache.setObject(image, forKey: key)
        return image
    }

    /// Skips the shared cache; use for transient views where the IOSurface should release immediately.
    static func uncachedImage(from data: Data, maxDimension: CGFloat) -> UIImage? {
        let scale = displayScale()
        let pixelDimension = Int(maxDimension * scale)

        return autoreleasepool {
            let options: [CFString: Any] = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceShouldCacheImmediately: true,
                kCGImageSourceThumbnailMaxPixelSize: pixelDimension
            ]
            guard
                let source = CGImageSourceCreateWithData(data as CFData, nil),
                let cg = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
            else { return nil }
            return UIImage(cgImage: cg, scale: scale, orientation: .up)
        }
    }

    /// Re-encodes source bytes as a downsampled JPEG for long-term storage on the model.
    nonisolated static func encodedThumbData(from data: Data, maxPixelSize: Int = 1500) -> Data? {
        autoreleasepool {
            let decodeOptions: [CFString: Any] = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceShouldCacheImmediately: true,
                kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
            ]
            guard
                let source = CGImageSourceCreateWithData(data as CFData, nil),
                let cg = CGImageSourceCreateThumbnailAtIndex(source, 0, decodeOptions as CFDictionary)
            else { return nil }

            let destinationData = NSMutableData()
            guard let destination = CGImageDestinationCreateWithData(
                destinationData,
                UTType.jpeg.identifier as CFString,
                1,
                nil
            ) else { return nil }
            let encodeOptions: [CFString: Any] = [
                kCGImageDestinationLossyCompressionQuality: 0.85
            ]
            CGImageDestinationAddImage(destination, cg, encodeOptions as CFDictionary)
            guard CGImageDestinationFinalize(destination) else { return nil }
            return destinationData as Data
        }
    }

    private static func displayScale() -> CGFloat {
        let s = UITraitCollection.current.displayScale
        return s > 0 ? s : 3.0
    }
}

extension Note {
    func thumbnail(maxDimension: CGFloat) -> UIImage? {
        let source = thumbData.isEmpty ? imageData : thumbData
        return Thumbnail.image(
            from: source,
            maxDimension: maxDimension,
            cacheKey: id.uuidString
        )
    }
}
