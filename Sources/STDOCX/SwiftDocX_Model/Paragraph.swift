import Foundation

/// Heading levels for paragraph styles
public enum HeadingLevel: Int, Sendable {
    case heading1 = 1
    case heading2 = 2
    case heading3 = 3
    case heading4 = 4
    case heading5 = 5
    case heading6 = 6

    /// The Word style ID for this heading level
    public var styleId: String {
        "Heading\(rawValue)"
    }

    /// The Word style name for this heading level
    public var styleName: String {
        "heading \(rawValue)"
    }
}

/// List type for bulleted or numbered lists
public enum ListType: Sendable {
    case bullet
    case numbered
}

/// Paragraph alignment options
public enum ParagraphAlignment: String, Sendable {
    case left = "left"
    case center = "center"
    case right = "right"
    case both = "both"  // Justified
    case distribute = "distribute"
}

/// Paragraph spacing configuration
public struct ParagraphSpacing: Equatable, Sendable {
    /// Space before the paragraph in points
    public var before: Double?

    /// Space after the paragraph in points
    public var after: Double?

    /// Line spacing (1.0 = single, 1.5 = one and a half, 2.0 = double)
    public var lineSpacing: Double?

    public init(before: Double? = nil, after: Double? = nil, lineSpacing: Double? = nil) {
        self.before = before
        self.after = after
        self.lineSpacing = lineSpacing
    }

    public static var none: ParagraphSpacing { ParagraphSpacing() }
}

/// Paragraph border configuration (top, bottom, left, right)
public struct ParagraphBorders: Equatable, Sendable {
    public var top: Border?
    public var bottom: Border?
    public var left: Border?
    public var right: Border?

    public init(top: Border? = nil, bottom: Border? = nil, left: Border? = nil, right: Border? = nil) {
        self.top = top
        self.bottom = bottom
        self.left = left
        self.right = right
    }
}

/// Paragraph indentation configuration
public struct ParagraphIndentation: Equatable, Sendable {
    /// Left indentation in points
    public var left: Double?

    /// Right indentation in points
    public var right: Double?

    /// First line indentation in points (positive for indent, negative for hanging)
    public var firstLine: Double?

    public init(left: Double? = nil, right: Double? = nil, firstLine: Double? = nil) {
        self.left = left
        self.right = right
        self.firstLine = firstLine
    }

    public static var none: ParagraphIndentation { ParagraphIndentation() }
}

/// A paragraph in a Word document containing one or more runs of text
public class Paragraph {
    /// The runs of text in this paragraph
    public var runs: [Run]

    /// Paragraph alignment
    public var alignment: ParagraphAlignment?

    /// Paragraph spacing
    public var spacing: ParagraphSpacing

    /// Paragraph indentation
    public var indentation: ParagraphIndentation

    /// Heading level (nil for normal paragraph)
    public var headingLevel: HeadingLevel?

    /// List type (nil for non-list paragraph)
    public var listType: ListType?

    /// List level for nested lists (0-based)
    public var listLevel: Int

    /// Whether to insert a page break before this paragraph
    public var pageBreakBefore: Bool

    /// Background/shading color for the paragraph
    public var backgroundColor: DocXColor?

    /// Paragraph borders
    public var borders: ParagraphBorders?

    /// Creates an empty paragraph
    public init() {
        self.runs = []
        self.alignment = nil
        self.spacing = .none
        self.indentation = .none
        self.headingLevel = nil
        self.listType = nil
        self.listLevel = 0
        self.pageBreakBefore = false
        self.backgroundColor = nil
        self.borders = nil
    }

    /// Creates a paragraph with a single run of text
    public convenience init(_ text: String, formatting: TextFormatting = .none) {
        self.init()
        addRun(text, formatting: formatting)
    }

    /// Adds a run with the specified text and formatting
    @discardableResult
    public func addRun(_ text: String, formatting: TextFormatting = .none) -> Run {
        let run = Run(text: text, formatting: formatting)
        runs.append(run)
        return run
    }

    /// Adds an existing run to the paragraph
    @discardableResult
    public func addRun(_ run: Run) -> Run {
        runs.append(run)
        return run
    }

    /// Adds a hyperlink to the paragraph
    @discardableResult
    public func addHyperlink(url: String, text: String, tooltip: String? = nil) -> Run {
        let hyperlink = Hyperlink(url: url, text: text, tooltip: tooltip)
        let run = Run(text: text, formatting: hyperlink.formatting)
        run.hyperlink = hyperlink
        runs.append(run)
        return run
    }

    /// Adds an image to the paragraph
    @discardableResult
    public func addImage(_ image: DocImage) -> Run {
        let run = Run(text: "")
        run.image = image
        runs.append(run)
        return run
    }

    /// Adds an image from file URL
    @discardableResult
    public func addImage(contentsOf url: URL, width: Double? = nil, height: Double? = nil, altText: String? = nil) -> Run? {
        guard let image = DocImage(contentsOf: url, width: width, height: height) else { return nil }
        image.altText = altText
        return addImage(image)
    }

    /// Returns the full text of the paragraph (all runs concatenated)
    public var text: String {
        runs.map { $0.text }.joined()
    }

    /// Returns true if the paragraph has no content
    public var isEmpty: Bool {
        runs.isEmpty || runs.allSatisfy { $0.text.isEmpty && $0.image == nil }
    }
}

extension Paragraph: CustomStringConvertible {
    public var description: String {
        "Paragraph(runs: \(runs.count), text: \"\(text.prefix(50))\(text.count > 50 ? "..." : "")\")"
    }
}
