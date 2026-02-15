import Foundation
import UIKit
import SwiftDocX
import STKit

/// Wrapper around SwiftDocX Document for use with STKit
public final class STDOCXDocument: STDocument {

    /// The underlying SwiftDocX document
    public let document: Document

    /// The URL the document was loaded from
    public let sourceURL: URL?

    /// Display title
    public let title: String

    /// The document content as NSAttributedString
    public private(set) var attributedString: NSAttributedString

    // MARK: - STDocument Protocol

    public var plainText: String {
        attributedString.string
    }

    // MARK: - Init

    /// Create from a URL (reads the DOCX file)
    public init?(url: URL, title: String? = nil) {
        guard let doc = try? Document(contentsOf: url) else { return nil }
        self.document = doc
        self.sourceURL = url
        self.title = title ?? url.deletingPathExtension().lastPathComponent
        self.attributedString = STDOCXConverter.toAttributedString(doc)
    }

    /// Create from an existing SwiftDocX Document
    public init(document: Document, url: URL? = nil, title: String = "Untitled") {
        self.document = document
        self.sourceURL = url
        self.title = title
        self.attributedString = STDOCXConverter.toAttributedString(document)
    }

    /// Create a blank document
    public init(title: String = "Untitled") {
        self.document = Document()
        self.document.addParagraph("")
        self.sourceURL = nil
        self.title = title

        let font = UIFont(name: "Helvetica Neue", size: 14) ?? UIFont.systemFont(ofSize: 14)
        self.attributedString = NSAttributedString(
            string: "",
            attributes: [.font: font, .foregroundColor: UIColor.label]
        )
    }

    /// Update the attributed string (called by the editor)
    public func update(attributedString: NSAttributedString) {
        self.attributedString = attributedString
    }

    /// Get document statistics
    public var stats: STDocumentStats {
        STDocumentStats(from: plainText)
    }

    // MARK: - Save

    /// Save the current content as a DOCX file
    @discardableResult
    public func save(to url: URL) -> Bool {
        let doc = STDOCXConverter.toDocument(attributedString)
        do {
            try doc.write(to: url)
            return true
        } catch {
            print("[STDOCX] Failed to save: \(error.localizedDescription)")
            return false
        }
    }

    /// Export as plain text
    @discardableResult
    public func exportAsText(to url: URL) -> Bool {
        do {
            try plainText.write(to: url, atomically: true, encoding: .utf8)
            return true
        } catch {
            return false
        }
    }

    /// Export as PDF
    @discardableResult
    public func exportAsPDF(to url: URL) -> Bool {
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))
        do {
            try renderer.writePDF(to: url) { context in
                let pageRect = CGRect(x: 36, y: 36, width: 540, height: 720)
                context.beginPage()

                let framesetter = CTFramesetterCreateWithAttributedString(attributedString as CFAttributedString)
                let path = CGPath(rect: pageRect, transform: nil)
                var textPos = 0
                let totalLength = attributedString.length

                while textPos < totalLength {
                    let frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(textPos, 0), path, nil)
                    CTFrameDraw(frame, context.cgContext)
                    let visibleRange = CTFrameGetVisibleStringRange(frame)
                    textPos += visibleRange.length

                    if textPos < totalLength {
                        context.beginPage()
                    }
                }
            }
            return true
        } catch {
            return false
        }
    }
}
