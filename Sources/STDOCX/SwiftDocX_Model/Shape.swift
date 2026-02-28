import Foundation

/// Shape types available in the DOCX editor
public enum ShapeType: String, Codable, Sendable {
    case rectangle
    case circle
    case line
    case arrow
    case image
}

/// Represents a shape element in a Word document
public class Shape {
    /// Type of shape
    public var shapeType: ShapeType

    /// Width as CSS value (e.g. "200px")
    public var width: String?

    /// Height as CSS value (e.g. "120px")
    public var height: String?

    /// CSS border string (e.g. "2px solid #2B579A")
    public var border: String?

    /// CSS background color
    public var backgroundColor: String?

    /// CSS border-radius (e.g. "50%" for circles)
    public var borderRadius: String?

    /// Base64 data URL for image shapes
    public var imageSrc: String?

    /// SVG arrow color
    public var strokeColor: String?

    public init(shapeType: ShapeType) {
        self.shapeType = shapeType
    }
}
