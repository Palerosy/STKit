import PDFKit
import STKit

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

    /// Generate PDF data with all annotations flattened/rendered into the pages.
    /// Uses UIGraphicsPDFRenderer so the CGContext is UIKit-managed — this ensures
    /// UIKit drawing APIs (UIGraphicsPushContext / UIImage.draw) used by custom
    /// annotation subclasses (STImageAnnotation, STStampAnnotation) produce visible output.
    /// A raw CGContext created via CGDataConsumer does NOT support these UIKit APIs.
    public func flattenedData() -> Data? {
        guard pageCount > 0 else { return nil }

        let firstBox = pdfDocument.page(at: 0)?.bounds(for: .mediaBox)
            ?? CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: firstBox)

        return renderer.pdfData { rendererCtx in
            for i in 0..<pageCount {
                guard let page = pdfDocument.page(at: i) else { continue }
                let mediaBox = page.bounds(for: .mediaBox)

                rendererCtx.beginPage(withBounds: mediaBox, pageInfo: [:])
                let ctx = rendererCtx.cgContext

                // UIGraphicsPDFRenderer provides UIKit coordinates (origin top-left, y↓).
                // PDF page content + annotation draw() expect PDF coordinates (origin bottom-left, y↑).
                ctx.translateBy(x: 0, y: mediaBox.height)
                ctx.scaleBy(x: 1, y: -1)

                // Raw page content
                if let cgPage = page.pageRef {
                    ctx.drawPDFPage(cgPage)
                }

                // Custom annotation draw() — STImageAnnotation, STStampAnnotation use
                // UIGraphicsPushContext which requires a UIKit-managed context
                for annotation in page.annotations {
                    ctx.saveGState()
                    annotation.draw(with: .mediaBox, in: ctx)
                    ctx.restoreGState()
                }
            }
        }
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
