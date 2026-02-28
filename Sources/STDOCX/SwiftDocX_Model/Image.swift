import Foundation

/// Image positioning type
public enum ImagePosition: Sendable {
    /// Inline with text
    case inline
    /// Floating, anchored to paragraph
    case floating(horizontalAlign: ImageHorizontalAlignment, verticalAlign: ImageVerticalAlignment)
}

/// Horizontal alignment for floating images
public enum ImageHorizontalAlignment: String, Sendable {
    case left = "left"
    case center = "center"
    case right = "right"
}

/// Vertical alignment for floating images
public enum ImageVerticalAlignment: String, Sendable {
    case top = "top"
    case center = "center"
    case bottom = "bottom"
}

/// Represents an image in a Word document
public class DocImage {
    /// Image data (PNG, JPEG, etc.)
    public var data: Data

    /// Image file extension (png, jpeg, jpg, gif)
    public var fileExtension: String

    /// Width in points (nil for original size)
    public var width: Double?

    /// Height in points (nil for original size)
    public var height: Double?

    /// Alt text for accessibility
    public var altText: String?

    /// Image title/description
    public var title: String?

    /// Positioning
    public var position: ImagePosition

    /// Internal relationship ID (set during document building)
    internal var relationshipId: String?

    /// Creates an image from data
    public init(data: Data, fileExtension: String, width: Double? = nil, height: Double? = nil) {
        self.data = data
        self.fileExtension = fileExtension.lowercased()
        self.width = width
        self.height = height
        self.altText = nil
        self.title = nil
        self.position = .inline
        self.relationshipId = nil
    }

    /// Creates an image from a file URL
    public convenience init?(contentsOf url: URL, width: Double? = nil, height: Double? = nil) {
        guard let data = try? Data(contentsOf: url) else { return nil }
        let ext = url.pathExtension.lowercased()
        self.init(data: data, fileExtension: ext, width: width, height: height)
    }

    /// MIME type for the image
    public var mimeType: String {
        switch fileExtension {
        case "png":
            return "image/png"
        case "jpg", "jpeg":
            return "image/jpeg"
        case "gif":
            return "image/gif"
        case "bmp":
            return "image/bmp"
        case "tiff", "tif":
            return "image/tiff"
        default:
            return "image/png"
        }
    }

    /// Content type for Word document
    public var contentType: String {
        mimeType
    }
}
