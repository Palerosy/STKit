import Foundation

/// Error types for document operations
public enum DocumentError: Error, LocalizedError {
    case readFailed(String)
    case writeFailed(String)

    public var errorDescription: String? {
        switch self {
        case .readFailed(let detail):
            return "Failed to read document: \(detail)"
        case .writeFailed(let detail):
            return "Failed to write document: \(detail)"
        }
    }
}

/// Document element that can be a paragraph, table, chart, or shape
public enum DocumentElement {
    case paragraph(Paragraph)
    case table(Table)
    case chart(Chart)
    case shape(Shape)
}

/// Document properties for metadata and accessibility
public struct DocumentProperties: Sendable {
    /// Document title (accessibility)
    public var title: String?

    /// Document subject
    public var subject: String?

    /// Document author
    public var author: String?

    /// Document keywords
    public var keywords: String?

    /// Document description
    public var description: String?

    /// Document language (e.g., "en-US", "es-ES")
    public var language: String?

    public init(
        title: String? = nil,
        subject: String? = nil,
        author: String? = nil,
        keywords: String? = nil,
        description: String? = nil,
        language: String? = nil
    ) {
        self.title = title
        self.subject = subject
        self.author = author
        self.keywords = keywords
        self.description = description
        self.language = language
    }
}

/// Represents a Word document (.docx file)
public class Document {
    /// The paragraphs in the document
    public var paragraphs: [Paragraph]

    /// The tables in the document
    public var tables: [Table]

    /// The charts in the document
    public var charts: [Chart]

    /// The shapes in the document
    public var shapes: [Shape]

    /// All elements in document order
    public var elements: [DocumentElement]

    /// Document properties (metadata and accessibility)
    public var properties: DocumentProperties

    /// Document header (appears at top of pages)
    public var header: Header?

    /// Document footer (appears at bottom of pages)
    public var footer: Footer?

    /// Original styles.xml data preserved from the source DOCX (for round-trip fidelity)
    public var originalStylesData: Data?

    /// Original theme XML data preserved from the source DOCX
    public var originalThemeData: Data?
    /// Theme entry path (e.g. "word/theme/theme1.xml")
    public var themeEntryPath: String?

    /// Original DOCX file URL — used for ZIP-preserving save (keep images, styles, etc.)
    public var originalDocxURL: URL?

    /// Creates an empty document
    public init() {
        self.paragraphs = []
        self.tables = []
        self.charts = []
        self.shapes = []
        self.elements = []
        self.properties = DocumentProperties()
        self.header = nil
        self.footer = nil
    }

    /// Creates a document by reading from a .docx file
    /// - Parameter url: URL to the .docx file
    public convenience init(contentsOf url: URL) throws {
        self.init()
        let reader = DocumentReader()
        do {
            let parsed = try reader.readDocument(from: url)
            self.elements = parsed.elements
            self.paragraphs = parsed.paragraphs
            self.tables = parsed.tables
            self.charts = parsed.charts
            self.shapes = parsed.shapes
            self.originalStylesData = parsed.originalStylesData
            self.originalThemeData = parsed.originalThemeData
            self.themeEntryPath = parsed.themeEntryPath
            self.originalDocxURL = url
        } catch {
            throw DocumentError.readFailed(error.localizedDescription)
        }
    }

    /// Writes the document to a .docx file
    /// - Parameter url: Destination URL for the .docx file
    public func write(to url: URL) throws {
        let writer = DocumentWriter()
        do {
            // If we have the original DOCX, preserve its ZIP structure (images, styles, themes, rels)
            // and only replace word/document.xml with our updated content
            if let originalURL = originalDocxURL,
               FileManager.default.fileExists(atPath: originalURL.path) {
                try writer.writePreservingOriginal(document: self, to: url, originalURL: originalURL)
            } else {
                try writer.write(document: self, to: url)
            }
        } catch {
            throw DocumentError.writeFailed(error.localizedDescription)
        }
    }

    // MARK: - Title Extraction

    /// Extracts a meaningful title from the document content by finding the most prominent text.
    /// Looks at the first ~10 elements for: heading paragraphs, largest font size, or style IDs like "Title".
    public func extractContentTitle() -> String? {
        var bestCandidate: String?
        var bestScore: Double = 0

        let scanLimit = min(elements.count, 15)
        for i in 0..<scanLimit {
            guard case .paragraph(let para) = elements[i] else { continue }
            let text = para.text.trimmingCharacters(in: .whitespacesAndNewlines)
            if text.isEmpty { continue }

            var score: Double = 0

            // Style ID "Title" is the strongest signal
            if let sid = para.pStyleId?.lowercased(), sid.contains("title") || sid.contains("name") {
                score += 100
            }

            // Heading level is a strong signal (h1 = 50, h2 = 40, ...)
            if let level = para.headingLevel {
                switch level {
                case .heading1: score += 50
                case .heading2: score += 40
                case .heading3: score += 30
                default: score += 20
                }
            }

            // Largest font size among runs
            var maxFontSize: Double = 0
            for run in para.runs {
                let fs = run.formatting.fontSize ?? 11
                if fs > maxFontSize { maxFontSize = fs }
            }
            // Bonus for large fonts (> 14pt gets progressively more score)
            if maxFontSize > 14 {
                score += maxFontSize
            }

            // Bold text gets a small bonus
            if para.runs.contains(where: { $0.formatting.bold }) {
                score += 5
            }

            // Earlier paragraphs get a position bonus
            score += Double(scanLimit - i)

            // Skip very long text (likely a body paragraph, not a title)
            if text.count > 80 { score *= 0.3 }

            if score > bestScore {
                bestScore = score
                bestCandidate = text
            }
        }

        // Also check first cell of first table (some resumes put name in table)
        for element in elements.prefix(5) {
            if case .table(let table) = element, let firstRow = table.rows.first, let firstCell = firstRow.cells.first {
                for cellPara in firstCell.paragraphs {
                    let text = cellPara.text.trimmingCharacters(in: .whitespacesAndNewlines)
                    if text.isEmpty { continue }
                    var maxFS: Double = 0
                    for run in cellPara.runs {
                        let fs = run.formatting.fontSize ?? 11
                        if fs > maxFS { maxFS = fs }
                    }
                    if maxFS > 18 && maxFS > bestScore {
                        bestScore = maxFS + 10
                        bestCandidate = text
                    }
                }
            }
        }

        // Truncate if too long
        if let candidate = bestCandidate, candidate.count > 50 {
            return String(candidate.prefix(50))
        }

        return bestCandidate
    }

    // MARK: - Paragraph Methods

    /// Adds a paragraph with the specified text
    @discardableResult
    public func addParagraph(_ text: String, formatting: TextFormatting = .none) -> Paragraph {
        let paragraph = Paragraph(text, formatting: formatting)
        paragraphs.append(paragraph)
        elements.append(.paragraph(paragraph))
        return paragraph
    }

    /// Adds an empty paragraph
    @discardableResult
    public func addParagraph() -> Paragraph {
        let paragraph = Paragraph()
        paragraphs.append(paragraph)
        elements.append(.paragraph(paragraph))
        return paragraph
    }

    // MARK: - Heading Methods

    /// Adds a heading with the specified level
    @discardableResult
    public func addHeading(_ text: String, level: HeadingLevel, formatting: TextFormatting = .none) -> Paragraph {
        let paragraph = Paragraph(text, formatting: formatting)
        paragraph.headingLevel = level
        paragraphs.append(paragraph)
        elements.append(.paragraph(paragraph))
        return paragraph
    }

    /// Adds a Heading 1
    @discardableResult
    public func addHeading1(_ text: String) -> Paragraph {
        addHeading(text, level: .heading1)
    }

    /// Adds a Heading 2
    @discardableResult
    public func addHeading2(_ text: String) -> Paragraph {
        addHeading(text, level: .heading2)
    }

    /// Adds a Heading 3
    @discardableResult
    public func addHeading3(_ text: String) -> Paragraph {
        addHeading(text, level: .heading3)
    }

    // MARK: - List Methods

    /// Adds a bullet list item
    @discardableResult
    public func addBulletItem(_ text: String, level: Int = 0, formatting: TextFormatting = .none) -> Paragraph {
        let paragraph = Paragraph(text, formatting: formatting)
        paragraph.listType = .bullet
        paragraph.listLevel = level
        paragraphs.append(paragraph)
        elements.append(.paragraph(paragraph))
        return paragraph
    }

    /// Adds multiple bullet items at once
    public func addBulletList(_ items: [String]) {
        for item in items {
            addBulletItem(item)
        }
    }

    /// Adds a numbered list item
    @discardableResult
    public func addNumberedItem(_ text: String, level: Int = 0, formatting: TextFormatting = .none) -> Paragraph {
        let paragraph = Paragraph(text, formatting: formatting)
        paragraph.listType = .numbered
        paragraph.listLevel = level
        paragraphs.append(paragraph)
        elements.append(.paragraph(paragraph))
        return paragraph
    }

    /// Adds multiple numbered items at once
    public func addNumberedList(_ items: [String]) {
        for item in items {
            addNumberedItem(item)
        }
    }

    // MARK: - Table Methods

    /// Adds a table with the specified rows and columns
    @discardableResult
    public func addTable(rows: Int, columns: Int) -> Table {
        let table = Table(rows: rows, columns: columns)
        tables.append(table)
        elements.append(.table(table))
        return table
    }

    /// Adds an existing table
    @discardableResult
    public func addTable(_ table: Table) -> Table {
        tables.append(table)
        elements.append(.table(table))
        return table
    }

    /// Creates a table from a 2D array of strings
    @discardableResult
    public func addTable(from data: [[String]], hasHeader: Bool = false) -> Table {
        let table = Table()
        for (rowIndex, rowData) in data.enumerated() {
            let row = table.addRow()
            if hasHeader && rowIndex == 0 {
                row.isHeader = true
            }
            for cellText in rowData {
                row.addCell(cellText)
            }
        }
        tables.append(table)
        elements.append(.table(table))
        return table
    }

    // MARK: - Chart Methods

    /// Adds an existing chart to the document
    @discardableResult
    public func addChart(_ chart: Chart) -> Chart {
        charts.append(chart)
        elements.append(.chart(chart))
        return chart
    }

    // MARK: - Shape Methods

    /// Adds a shape to the document
    @discardableResult
    public func addShape(_ shape: Shape) -> Shape {
        shapes.append(shape)
        elements.append(.shape(shape))
        return shape
    }

    // MARK: - Page Break

    /// Adds a page break
    public func addPageBreak() {
        let para = Paragraph()
        para.pageBreakBefore = true
        paragraphs.append(para)
        elements.append(.paragraph(para))
    }

    // MARK: - Hyperlink Methods

    /// Adds a hyperlink as its own paragraph
    @discardableResult
    public func addHyperlink(url: String, text: String, tooltip: String? = nil) -> Paragraph {
        let para = Paragraph()
        para.addHyperlink(url: url, text: text, tooltip: tooltip)
        paragraphs.append(para)
        elements.append(.paragraph(para))
        return para
    }

    // MARK: - Image Methods

    /// Adds an image as its own paragraph
    @discardableResult
    public func addImage(_ image: DocImage) -> Paragraph {
        let para = Paragraph()
        para.addImage(image)
        paragraphs.append(para)
        elements.append(.paragraph(para))
        return para
    }

    /// Adds an image from file URL
    @discardableResult
    public func addImage(contentsOf url: URL, width: Double? = nil, height: Double? = nil, altText: String? = nil) -> Paragraph? {
        guard let image = DocImage(contentsOf: url, width: width, height: height) else { return nil }
        image.altText = altText
        return addImage(image)
    }

    // MARK: - Header/Footer Methods

    /// Creates and returns a header for the document
    @discardableResult
    public func createHeader() -> Header {
        let header = Header()
        self.header = header
        return header
    }

    /// Creates and returns a footer for the document
    @discardableResult
    public func createFooter() -> Footer {
        let footer = Footer()
        self.footer = footer
        return footer
    }

    /// Convenience: Adds a simple text header
    @discardableResult
    public func setHeader(_ text: String, alignment: ParagraphAlignment = .center) -> Header {
        let header = createHeader()
        let para = header.addParagraph(text)
        para.alignment = alignment
        return header
    }

    /// Convenience: Adds a simple text footer
    @discardableResult
    public func setFooter(_ text: String, alignment: ParagraphAlignment = .center) -> Footer {
        let footer = createFooter()
        let para = footer.addParagraph(text)
        para.alignment = alignment
        return footer
    }

    /// Convenience: Adds a footer with page numbers
    @discardableResult
    public func setFooterWithPageNumbers(alignment: ParagraphAlignment = .center) -> Footer {
        let footer = createFooter()
        footer.addPageNumber(alignment: alignment)
        return footer
    }

    /// Convenience: Adds a footer with "Page X of Y" format
    @discardableResult
    public func setFooterWithPageNumbersAndTotal(alignment: ParagraphAlignment = .center) -> Footer {
        let footer = createFooter()
        footer.addPageNumberWithTotal(alignment: alignment)
        return footer
    }

    // MARK: - Properties

    /// Returns the full text of the document (all paragraphs joined with newlines)
    public var text: String {
        paragraphs.map { $0.text }.joined(separator: "\n")
    }

    /// Returns true if the document has no content
    public var isEmpty: Bool {
        elements.isEmpty
    }

    /// Number of paragraphs in the document
    public var paragraphCount: Int {
        paragraphs.count
    }

    /// Number of tables in the document
    public var tableCount: Int {
        tables.count
    }

    /// Number of charts in the document
    public var chartCount: Int {
        charts.count
    }

    /// Removes all content from the document
    public func clear() {
        paragraphs.removeAll()
        tables.removeAll()
        charts.removeAll()
        elements.removeAll()
        header = nil
        footer = nil
    }
}

extension Document: CustomStringConvertible {
    public var description: String {
        "Document(paragraphs: \(paragraphs.count))"
    }
}
