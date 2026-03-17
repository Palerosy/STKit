import SwiftUI

/// Shape types available for insertion
public enum STExcelShapeType: String, CaseIterable, Identifiable {
    // Basic shapes
    case rectangle, roundedRectangle, circle, oval
    // Triangles & arrows
    case triangle, rightTriangle, diamond
    case arrowRight, arrowLeft, arrowUp, arrowDown
    // Stars & misc
    case star, hexagon, pentagon
    // Lines
    case line, dashedLine

    public var id: String { rawValue }

    var displayName: String {
        switch self {
        case .rectangle: return STExcelStrings.shapeRectangle
        case .roundedRectangle: return STExcelStrings.shapeRoundedRect
        case .circle: return STExcelStrings.shapeCircle
        case .oval: return STExcelStrings.shapeOval
        case .triangle: return STExcelStrings.shapeTriangle
        case .rightTriangle: return STExcelStrings.shapeRightTriangle
        case .diamond: return STExcelStrings.shapeDiamond
        case .arrowRight: return STExcelStrings.shapeArrowRight
        case .arrowLeft: return STExcelStrings.shapeArrowLeft
        case .arrowUp: return STExcelStrings.shapeArrowUp
        case .arrowDown: return STExcelStrings.shapeArrowDown
        case .star: return STExcelStrings.shapeStar
        case .hexagon: return STExcelStrings.shapeHexagon
        case .pentagon: return STExcelStrings.shapePentagon
        case .line: return STExcelStrings.shapeLine
        case .dashedLine: return STExcelStrings.shapeDashedLine
        }
    }

    var iconName: String {
        switch self {
        case .rectangle: return "rectangle"
        case .roundedRectangle: return "rectangle.roundedtop"
        case .circle: return "circle"
        case .oval: return "oval"
        case .triangle: return "triangle"
        case .rightTriangle: return "arrowtriangle.right"
        case .diamond: return "diamond"
        case .arrowRight: return "arrow.right"
        case .arrowLeft: return "arrow.left"
        case .arrowUp: return "arrow.up"
        case .arrowDown: return "arrow.down"
        case .star: return "star"
        case .hexagon: return "hexagon"
        case .pentagon: return "pentagon"
        case .line: return "line.diagonal"
        case .dashedLine: return "line.horizontal.3"
        }
    }

    static var basicShapes: [STExcelShapeType] {
        [.rectangle, .roundedRectangle, .circle, .oval]
    }

    static var trianglesAndArrows: [STExcelShapeType] {
        [.triangle, .rightTriangle, .diamond, .arrowRight, .arrowLeft, .arrowUp, .arrowDown]
    }

    static var starsAndMisc: [STExcelShapeType] {
        [.star, .hexagon, .pentagon]
    }

    static var lines: [STExcelShapeType] {
        [.line, .dashedLine]
    }
}

/// An embedded shape on the spreadsheet grid
public struct STExcelEmbeddedShape: Identifiable {
    public let id = UUID()
    public var shapeType: STExcelShapeType
    public var x: CGFloat
    public var y: CGFloat
    public var width: CGFloat
    public var height: CGFloat
    public var fillColor: Color
    public var strokeColor: Color
    public var strokeWidth: CGFloat
    public var text: String
    public var rotation: Double

    public init(
        shapeType: STExcelShapeType = .rectangle,
        x: CGFloat = 60, y: CGFloat = 60,
        width: CGFloat = 120, height: CGFloat = 80,
        fillColor: Color = .blue.opacity(0.3),
        strokeColor: Color = .blue,
        strokeWidth: CGFloat = 2,
        text: String = "",
        rotation: Double = 0
    ) {
        self.shapeType = shapeType
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.fillColor = fillColor
        self.strokeColor = strokeColor
        self.strokeWidth = strokeWidth
        self.text = text
        self.rotation = rotation
    }

    /// XLSX preset geometry name
    public var xlsxPresetGeometry: String {
        switch shapeType {
        case .rectangle: return "rect"
        case .roundedRectangle: return "roundRect"
        case .circle, .oval: return "ellipse"
        case .triangle: return "triangle"
        case .rightTriangle: return "rtTriangle"
        case .diamond: return "diamond"
        case .arrowRight: return "rightArrow"
        case .arrowLeft: return "leftArrow"
        case .arrowUp: return "upArrow"
        case .arrowDown: return "downArrow"
        case .star: return "star5"
        case .hexagon: return "hexagon"
        case .pentagon: return "pentagon"
        case .line, .dashedLine: return "line"
        }
    }

    /// Convert SwiftUI Color to hex string for XLSX
    public var fillColorHex: String {
        Self.colorToHex(fillColor)
    }

    public var strokeColorHex: String {
        Self.colorToHex(strokeColor)
    }

    #if canImport(UIKit)
    private static func colorToHex(_ color: Color) -> String {
        let uiColor = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
    #else
    private static func colorToHex(_ color: Color) -> String {
        return "4472C4"
    }
    #endif

    var sizeTooltip: String {
        let wCm = width / 96.0 * 2.54
        let hCm = height / 96.0 * 2.54
        return String(format: "Width: %.2f cm\nHeight: %.2f cm", wCm, hCm)
    }
}
