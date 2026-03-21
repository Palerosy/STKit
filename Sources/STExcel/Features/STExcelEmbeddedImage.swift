import SwiftUI

/// An embedded image that lives on the spreadsheet grid
public struct STExcelEmbeddedImage: Identifiable {
    public let id = UUID()
    public var imageData: Data
    public var x: CGFloat
    public var y: CGFloat
    public var width: CGFloat
    public var height: CGFloat

    /// Original aspect ratio (width / height)
    public var aspectRatio: CGFloat

    /// Cell anchor — from/to row/col + sub-cell offset for accurate positioning
    /// Position and size are recalculated at render time using actual grid row heights
    public var anchorRow: Int?
    public var anchorCol: Int?
    public var anchorRowOffset: CGFloat = 0
    public var anchorColOffset: CGFloat = 0
    /// "To" anchor for twoCellAnchor images — determines size relative to grid
    public var toAnchorRow: Int?
    public var toAnchorCol: Int?
    public var toAnchorRowOffset: CGFloat = 0
    public var toAnchorColOffset: CGFloat = 0

    public init(imageData: Data, x: CGFloat = 60, y: CGFloat = 60,
         width: CGFloat = 200, height: CGFloat = 200, aspectRatio: CGFloat = 1.0) {
        self.imageData = imageData
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.aspectRatio = aspectRatio
    }

    /// Size tooltip text (cm units)
    var sizeTooltip: String {
        let wCm = width / 96.0 * 2.54
        let hCm = height / 96.0 * 2.54
        return String(format: "Width: %.2f cm\nHeight: %.2f cm", wCm, hCm)
    }
}
