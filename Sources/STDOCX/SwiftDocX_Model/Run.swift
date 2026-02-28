import Foundation

/// A run represents a contiguous segment of text with consistent formatting
public class Run {
    /// The text content of the run
    public var text: String

    /// Formatting applied to this run
    public var formatting: TextFormatting

    /// Whether this run is a page number field
    public var isPageNumberField: Bool

    /// Whether this run is a total pages field
    public var isTotalPagesField: Bool

    /// Hyperlink for this run (nil if not a hyperlink)
    public var hyperlink: Hyperlink?

    /// Image for this run (nil if not an image)
    public var image: DocImage?

    /// Creates a run with the specified text and formatting
    public init(text: String, formatting: TextFormatting = .none) {
        self.text = text
        self.formatting = formatting
        self.isPageNumberField = false
        self.isTotalPagesField = false
        self.hyperlink = nil
        self.image = nil
    }

    /// Creates a run with just text (no special formatting)
    public convenience init(_ text: String) {
        self.init(text: text, formatting: .none)
    }
}

extension Run: CustomStringConvertible {
    public var description: String {
        var desc = "Run(\"\(text)\""
        var formats: [String] = []
        if formatting.bold { formats.append("bold") }
        if formatting.italic { formats.append("italic") }
        if formatting.underline != nil { formats.append("underline") }
        if formatting.strikethrough { formats.append("strikethrough") }
        if let font = formatting.font { formats.append("font: \(font.name)") }
        if let color = formatting.color { formats.append("color: #\(color.hexString)") }
        if let size = formatting.fontSize { formats.append("size: \(size)pt") }
        if !formats.isEmpty {
            desc += ", \(formats.joined(separator: ", "))"
        }
        desc += ")"
        return desc
    }
}
