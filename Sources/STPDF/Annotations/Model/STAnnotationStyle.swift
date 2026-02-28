#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif
import STKit

/// Style configuration for an annotation tool
public struct STAnnotationStyle: Equatable, Sendable {
    public var color: PlatformColor
    public var lineWidth: CGFloat
    public var opacity: CGFloat
    public var fontSize: CGFloat
    public var fontName: String
    
    public init(
        color: PlatformColor = .systemBlue,
        lineWidth: CGFloat = 3.0,
        opacity: CGFloat = 1.0,
        fontSize: CGFloat = 16.0,
        fontName: String = "Helvetica"
    ) {
        self.color = color
        self.lineWidth = lineWidth
        self.opacity = opacity
        self.fontSize = fontSize
        self.fontName = fontName
    }
    
    /// Default style for each annotation type
    public static func defaultStyle(for type: STAnnotationType) -> STAnnotationStyle {
        switch type {
        case .ink:
            return STAnnotationStyle(color: .systemBlue, lineWidth: 3.0, opacity: 1.0)
        case .highlighter:
            return STAnnotationStyle(color: .systemYellow, lineWidth: 20.0, opacity: 0.3)
        case .freeText:
            return STAnnotationStyle(color: .black, lineWidth: 0, opacity: 1.0, fontSize: 16.0)
        case .textHighlight:
            return STAnnotationStyle(color: .systemYellow, lineWidth: 0, opacity: 0.5)
        case .textUnderline:
            return STAnnotationStyle(color: .systemRed, lineWidth: 0, opacity: 1.0)
        case .textStrikeOut:
            return STAnnotationStyle(color: .systemRed, lineWidth: 0, opacity: 1.0)
        case .rectangle:
            return STAnnotationStyle(color: .systemBlue, lineWidth: 2.0, opacity: 1.0)
        case .circle:
            return STAnnotationStyle(color: .systemBlue, lineWidth: 2.0, opacity: 1.0)
        case .line:
            return STAnnotationStyle(color: .systemBlue, lineWidth: 2.0, opacity: 1.0)
        case .arrow:
            return STAnnotationStyle(color: .systemBlue, lineWidth: 2.0, opacity: 1.0)
        case .signature:
            return STAnnotationStyle(color: .black, lineWidth: 2.0, opacity: 1.0)
        case .stamp:
            return STAnnotationStyle(color: .systemRed, lineWidth: 0, opacity: 1.0)
        case .photo:
            return STAnnotationStyle()
        case .note:
            return STAnnotationStyle(color: .systemYellow, lineWidth: 0, opacity: 1.0)
        case .textEdit:
            return STAnnotationStyle(color: .black, lineWidth: 0, opacity: 1.0, fontSize: 16.0)
        case .textRemove:
            return STAnnotationStyle()
        case .eraser:
            return STAnnotationStyle()
        }
    }
    
    /// Preset colors for the color picker
    public static let presetColors: [PlatformColor] = [
        .black, .white,
        .systemRed, .systemOrange, .systemYellow,
        .systemGreen, .systemBlue, .systemPurple,
        .systemPink, .systemTeal, .systemBrown, .systemGray
    ]
    
    /// Preset line widths
    public static let presetLineWidths: [CGFloat] = [1.0, 2.0, 3.0, 5.0, 8.0, 12.0]
}
