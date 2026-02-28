import Foundation

/// Represents font properties for text in Word documents
public struct Font: Equatable, Sendable {
    /// Font family name (e.g., "Arial", "Times New Roman")
    public var name: String

    /// Creates a font with the specified name
    public init(name: String) {
        self.name = name
    }

    // MARK: - Common Fonts

    public static var arial: Font { Font(name: "Arial") }
    public static var timesNewRoman: Font { Font(name: "Times New Roman") }
    public static var calibri: Font { Font(name: "Calibri") }
    public static var cambria: Font { Font(name: "Cambria") }
    public static var helvetica: Font { Font(name: "Helvetica") }
    public static var georgia: Font { Font(name: "Georgia") }
    public static var verdana: Font { Font(name: "Verdana") }
    public static var courierNew: Font { Font(name: "Courier New") }
}
