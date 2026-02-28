import Foundation

/// Represents a color for text formatting in Word documents
public struct DocXColor: Equatable, Sendable {
    /// Red component (0-255)
    public var red: UInt8
    /// Green component (0-255)
    public var green: UInt8
    /// Blue component (0-255)
    public var blue: UInt8

    /// Creates a color from RGB components
    public init(red: UInt8, green: UInt8, blue: UInt8) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    /// Creates a color from a hex string (e.g., "FF0000" for red)
    public init?(hex: String) {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if hexString.hasPrefix("#") {
            hexString.removeFirst()
        }

        guard hexString.count == 6 else { return nil }

        var rgbValue: UInt64 = 0
        guard Scanner(string: hexString).scanHexInt64(&rgbValue) else { return nil }

        self.red = UInt8((rgbValue & 0xFF0000) >> 16)
        self.green = UInt8((rgbValue & 0x00FF00) >> 8)
        self.blue = UInt8(rgbValue & 0x0000FF)
    }

    /// Returns the color as a hex string (without #)
    public var hexString: String {
        String(format: "%02X%02X%02X", red, green, blue)
    }

    // MARK: - Predefined Colors

    public static var black: DocXColor { DocXColor(red: 0, green: 0, blue: 0) }
    public static var white: DocXColor { DocXColor(red: 255, green: 255, blue: 255) }
    public static var red: DocXColor { DocXColor(red: 255, green: 0, blue: 0) }
    public static var green: DocXColor { DocXColor(red: 0, green: 128, blue: 0) }
    public static var blue: DocXColor { DocXColor(red: 0, green: 0, blue: 255) }
    public static var yellow: DocXColor { DocXColor(red: 255, green: 255, blue: 0) }
    public static var orange: DocXColor { DocXColor(red: 255, green: 165, blue: 0) }
    public static var purple: DocXColor { DocXColor(red: 128, green: 0, blue: 128) }
    public static var gray: DocXColor { DocXColor(red: 128, green: 128, blue: 128) }
}
