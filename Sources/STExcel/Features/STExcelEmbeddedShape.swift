import SwiftUI

/// Shape types available for insertion
enum STExcelShapeType: String, CaseIterable, Identifiable {
    // Basic shapes
    case rectangle, roundedRectangle, circle, oval
    // Triangles & arrows
    case triangle, rightTriangle, diamond
    case arrowRight, arrowLeft, arrowUp, arrowDown
    // Stars & misc
    case star, hexagon, pentagon
    // Lines
    case line, dashedLine

    var id: String { rawValue }

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
struct STExcelEmbeddedShape: Identifiable {
    let id = UUID()
    var shapeType: STExcelShapeType
    var x: CGFloat
    var y: CGFloat
    var width: CGFloat
    var height: CGFloat
    var fillColor: Color
    var strokeColor: Color
    var strokeWidth: CGFloat
    var text: String
    var rotation: Double

    init(
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

    var sizeTooltip: String {
        let wCm = width / 96.0 * 2.54
        let hCm = height / 96.0 * 2.54
        return String(format: "Width: %.2f cm\nHeight: %.2f cm", wCm, hCm)
    }
}
