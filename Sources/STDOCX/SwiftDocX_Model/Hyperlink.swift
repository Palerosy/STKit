import Foundation

/// Represents a hyperlink in a Word document
public class Hyperlink {
    /// The URL the hyperlink points to
    public var url: String

    /// Display text for the hyperlink
    public var text: String

    /// Text formatting for the hyperlink (default is blue underline)
    public var formatting: TextFormatting

    /// Tooltip text shown on hover
    public var tooltip: String?

    /// Internal relationship ID (set during document building)
    internal var relationshipId: String?

    /// Creates a hyperlink
    public init(url: String, text: String, formatting: TextFormatting? = nil, tooltip: String? = nil) {
        self.url = url
        self.text = text
        // Default hyperlink style: blue and underlined
        self.formatting = formatting ?? TextFormatting(
            underline: .single,
            color: DocXColor(red: 5, green: 99, blue: 193)  // Standard Word hyperlink blue
        )
        self.tooltip = tooltip
        self.relationshipId = nil
    }

    /// Creates a hyperlink with the URL as display text
    public convenience init(url: String) {
        self.init(url: url, text: url)
    }
}
