import Foundation

/// Underline styles available in Word documents
public enum UnderlineStyle: String, Sendable {
    case single = "single"
    case double = "double"
    case thick = "thick"
    case dotted = "dotted"
    case dottedHeavy = "dottedHeavy"
    case dash = "dash"
    case dashedHeavy = "dashedHeavy"
    case dashLong = "dashLong"
    case dashLongHeavy = "dashLongHeavy"
    case dotDash = "dotDash"
    case dashDotHeavy = "dashDotHeavy"
    case dotDotDash = "dotDotDash"
    case dashDotDotHeavy = "dashDotDotHeavy"
    case wave = "wave"
    case wavyHeavy = "wavyHeavy"
    case wavyDouble = "wavyDouble"
    case words = "words"
}

/// Represents text formatting options for a run of text
public struct TextFormatting: Equatable, Sendable {
    /// Whether the text is bold
    public var bold: Bool

    /// Whether the text is italic
    public var italic: Bool

    /// Underline style (nil for no underline)
    public var underline: UnderlineStyle?

    /// Whether the text has strikethrough
    public var strikethrough: Bool

    /// Font for the text
    public var font: Font?

    /// Text color
    public var color: DocXColor?

    /// Font size in points
    public var fontSize: Double?

    /// Whether the text is subscript
    public var subscriptText: Bool

    /// Whether the text is superscript
    public var superscript: Bool

    /// Whether all caps
    public var allCaps: Bool

    /// Whether small caps
    public var smallCaps: Bool

    /// Highlight color
    public var highlight: HighlightColor?

    /// Creates default formatting (no special formatting applied)
    public init(
        bold: Bool = false,
        italic: Bool = false,
        underline: UnderlineStyle? = nil,
        strikethrough: Bool = false,
        font: Font? = nil,
        color: DocXColor? = nil,
        fontSize: Double? = nil,
        subscriptText: Bool = false,
        superscript: Bool = false,
        allCaps: Bool = false,
        smallCaps: Bool = false,
        highlight: HighlightColor? = nil
    ) {
        self.bold = bold
        self.italic = italic
        self.underline = underline
        self.strikethrough = strikethrough
        self.font = font
        self.color = color
        self.fontSize = fontSize
        self.subscriptText = subscriptText
        self.superscript = superscript
        self.allCaps = allCaps
        self.smallCaps = smallCaps
        self.highlight = highlight
    }

    /// Returns true if no formatting is applied
    public var isEmpty: Bool {
        !bold && !italic && underline == nil && !strikethrough &&
        font == nil && color == nil && fontSize == nil &&
        !subscriptText && !superscript && !allCaps && !smallCaps && highlight == nil
    }

    /// Default formatting with no styles applied
    public static var none: TextFormatting { TextFormatting() }
}

/// Highlight colors available in Word
public enum HighlightColor: String, Sendable {
    case yellow = "yellow"
    case green = "green"
    case cyan = "cyan"
    case magenta = "magenta"
    case blue = "blue"
    case red = "red"
    case darkBlue = "darkBlue"
    case darkCyan = "darkCyan"
    case darkGreen = "darkGreen"
    case darkMagenta = "darkMagenta"
    case darkRed = "darkRed"
    case darkYellow = "darkYellow"
    case darkGray = "darkGray"
    case lightGray = "lightGray"
    case black = "black"
}
