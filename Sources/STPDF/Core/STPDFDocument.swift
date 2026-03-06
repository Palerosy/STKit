import PDFKit

/// Enhanced wrapper around Apple's PDFDocument
public class STPDFDocument: ObservableObject {

    /// The underlying Apple PDFDocument
    public let pdfDocument: PDFDocument

    /// The source URL of the document
    public let url: URL?

    /// Display title
    @Published public var title: String

    /// Total page count
    public var pageCount: Int {
        pdfDocument.pageCount
    }

    /// Initialize from a file URL
    public init?(url: URL, title: String? = nil) {
        guard let doc = PDFDocument(url: url) else { return nil }
        self.pdfDocument = doc
        self.url = url
        self.title = title ?? url.deletingPathExtension().lastPathComponent
    }

    /// Initialize from an existing PDFDocument
    public init(document: PDFDocument, url: URL? = nil, title: String = "Untitled") {
        self.pdfDocument = document
        self.url = url
        self.title = title
    }

    /// Get a page at the given index
    public func page(at index: Int) -> PDFPage? {
        pdfDocument.page(at: index)
    }

    /// Save the document to its source URL
    @discardableResult
    public func save() -> Bool {
        guard let url else { return false }
        return pdfDocument.write(to: url)
    }

    /// Save the document to a specific URL
    @discardableResult
    public func save(to url: URL) -> Bool {
        pdfDocument.write(to: url)
    }

    /// Extract full text from all pages
    public func extractFullText() -> String {
        var text = ""
        for i in 0..<pageCount {
            if let pageText = pdfDocument.page(at: i)?.string {
                if !text.isEmpty { text += "\n\n" }
                text += pageText
            }
        }
        return text
    }
}
