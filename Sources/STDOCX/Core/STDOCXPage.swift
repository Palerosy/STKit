import PDFKit
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif
import STKit

/// Enhanced wrapper around Apple's PDFPage with thumbnail support
public struct STDOCXPage: Identifiable {

    public let id: Int
    public let page: PDFPage

    /// Page bounds in PDF coordinate space
    public var bounds: CGRect {
        page.bounds(for: .mediaBox)
    }

    /// Page rotation in degrees (0, 90, 180, 270)
    public var rotation: Int {
        get { page.rotation }
        nonmutating set { page.rotation = newValue }
    }

    /// Page text content
    public var text: String? {
        page.string
    }

    /// Generate a thumbnail image for this page
    /// - Parameter maxSize: Maximum dimension (width or height) of the thumbnail
    /// - Returns: Thumbnail PlatformImage
    public func thumbnail(maxSize: CGFloat = 200) -> PlatformImage {
        let pageSize = bounds.size
        let scale = min(maxSize / pageSize.width, maxSize / pageSize.height)
        let thumbnailSize = CGSize(
            width: pageSize.width * scale,
            height: pageSize.height * scale
        )
        return page.thumbnail(of: thumbnailSize, for: .cropBox)
    }
}
