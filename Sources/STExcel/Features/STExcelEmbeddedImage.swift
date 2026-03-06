import SwiftUI

/// An embedded image that lives on the spreadsheet grid
struct STExcelEmbeddedImage: Identifiable {
    let id = UUID()
    var imageData: Data
    var x: CGFloat
    var y: CGFloat
    var width: CGFloat
    var height: CGFloat

    /// Original aspect ratio (width / height)
    var aspectRatio: CGFloat

    init(imageData: Data, x: CGFloat = 60, y: CGFloat = 60,
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
