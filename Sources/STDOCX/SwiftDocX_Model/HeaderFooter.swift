import Foundation

/// Type of header or footer
public enum HeaderFooterType: String, Sendable {
    /// Default header/footer for all pages
    case `default` = "default"
    /// First page only
    case first = "first"
    /// Even pages (when different odd/even is enabled)
    case even = "even"
}

/// Represents a header in a Word document
public class Header {
    /// Paragraphs in the header
    public var paragraphs: [Paragraph]

    /// Header type
    public var type: HeaderFooterType

    /// Internal relationship ID
    internal var relationshipId: String?

    public init(type: HeaderFooterType = .default) {
        self.paragraphs = []
        self.type = type
        self.relationshipId = nil
    }

    /// Adds a paragraph to the header
    @discardableResult
    public func addParagraph(_ text: String = "", formatting: TextFormatting = .none) -> Paragraph {
        let para = Paragraph(text, formatting: formatting)
        paragraphs.append(para)
        return para
    }

    /// Adds a page number field to the header
    @discardableResult
    public func addPageNumber(formatting: TextFormatting = .none, alignment: ParagraphAlignment = .center) -> Paragraph {
        let para = Paragraph()
        para.alignment = alignment
        let run = para.addRun("", formatting: formatting)
        run.isPageNumberField = true
        paragraphs.append(para)
        return para
    }
}

/// Represents a footer in a Word document
public class Footer {
    /// Paragraphs in the footer
    public var paragraphs: [Paragraph]

    /// Footer type
    public var type: HeaderFooterType

    /// Internal relationship ID
    internal var relationshipId: String?

    public init(type: HeaderFooterType = .default) {
        self.paragraphs = []
        self.type = type
        self.relationshipId = nil
    }

    /// Adds a paragraph to the footer
    @discardableResult
    public func addParagraph(_ text: String = "", formatting: TextFormatting = .none) -> Paragraph {
        let para = Paragraph(text, formatting: formatting)
        paragraphs.append(para)
        return para
    }

    /// Adds a page number field to the footer
    @discardableResult
    public func addPageNumber(formatting: TextFormatting = .none, alignment: ParagraphAlignment = .center) -> Paragraph {
        let para = Paragraph()
        para.alignment = alignment
        let run = para.addRun("", formatting: formatting)
        run.isPageNumberField = true
        paragraphs.append(para)
        return para
    }

    /// Adds "Page X of Y" format to footer
    @discardableResult
    public func addPageNumberWithTotal(formatting: TextFormatting = .none, alignment: ParagraphAlignment = .center) -> Paragraph {
        let para = Paragraph()
        para.alignment = alignment

        para.addRun("Page ", formatting: formatting)
        let pageNum = para.addRun("", formatting: formatting)
        pageNum.isPageNumberField = true
        para.addRun(" of ", formatting: formatting)
        let totalPages = para.addRun("", formatting: formatting)
        totalPages.isTotalPagesField = true

        paragraphs.append(para)
        return para
    }
}
