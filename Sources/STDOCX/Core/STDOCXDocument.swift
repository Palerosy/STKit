import Foundation
import ImageIO
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif
import PDFKit
import STKit

/// DOCX document wrapper — loads DOCX content and renders it as in-memory PDF
/// for page-based viewing with annotations, thumbnails, and all viewer features.
public class STDOCXDocument: ObservableObject {

    /// The rendered PDF document (used by the viewer, annotations, thumbnails)
    public private(set) var pdfDocument: PDFDocument

    /// The source URL (original DOCX file)
    public let url: URL?

    /// Display title
    @Published public var title: String

    /// Whether the document content is still being loaded asynchronously (e.g. WebKit rendering for DOC files)
    @Published public private(set) var isLoading: Bool = false

    /// Whether this is a legacy DOC file (rendered via WebKit — PDF includes graphics, text editor is text-only)
    public private(set) var isLegacyDoc: Bool = false

    /// Extracted HTML from WebKit rendering (for legacy DOC files — preserves tables and structure)
    private(set) var extractedHTML: String?

    /// Guard against re-entrant WebKit loading (.task can fire again during await)
    private var webKitLoadStarted: Bool = false

    /// The underlying SwiftDocX document (for re-saving as DOCX and HTML conversion)
    private(set) var swiftDocXDocument: Document?

    /// The original attributed string from DOCX (accessible for text editing)
    private(set) var attributedString: NSAttributedString?

    /// Mutable copy for live text editing
    var editableAttributedString: NSMutableAttributedString?

    // MARK: - Computed

    /// Total page count
    public var pageCount: Int {
        pdfDocument.pageCount
    }

    // MARK: - Init from DOCX URL

    /// Create from a DOCX file URL — parses the document and renders it as PDF pages
    public init?(url: URL, title: String? = nil) {
        var doc: Document? = nil
        var attrString: NSAttributedString?
        var nativeHTML: String?
        let isLegacyDoc = Self.isOLE2CompoundDocument(url: url)

        if isLegacyDoc {
            // ── Legacy DOC (binary OLE2 format) ──
            #if os(macOS)
            // macOS: Read DOC natively via NSAttributedString (Cocoa's built-in Word reader).
            // Then export to HTML preserving tables, formatting, and convert images to base64.
            if let nativeAttr = try? NSAttributedString(
                url: url,
                options: [:],
                documentAttributes: nil
            ), nativeAttr.length > 0 {
                attrString = nativeAttr
                nativeHTML = Self.attributedStringToRichHTML(nativeAttr)

                // Extract embedded images from DOC binary (OLE charts stored as PNG/JPEG previews)
                let binaryImages = Self.extractImagesFromDOCBinary(url)
                if !binaryImages.isEmpty, var html = nativeHTML {
                    // Build base64 img tags for each extracted image
                    var imgTags: [String] = []
                    for img in binaryImages {
                        // Re-encode via CGImage to convert progressive JPEG to baseline
                        // (WKWebView's sandboxed WebContent can't decode progressive JPEGs)
                        let finalData: Data
                        let finalMime: String
                        if let reencoded = Self.reencodeImageAsBaselineJPEG(img.data) {
                            finalData = reencoded
                            finalMime = "image/jpeg"
                        } else {
                            finalData = img.data
                            finalMime = img.mimeType
                        }
                        let base64 = finalData.base64EncodedString()
                        imgTags.append("<img src=\"data:\(finalMime);base64,\(base64)\" style=\"max-width:100%;height:auto;display:block;margin:16px auto;\">")
                    }

                    // Replace "EMBED ClassName.Type" text with extracted images (in-place)
                    if let embedRegex = try? NSRegularExpression(pattern: "EMBED\\s+\\S+\\.\\S+", options: []) {
                        let matches = embedRegex.matches(in: html, range: NSRange(html.startIndex..., in: html))
                        var replacements: [(Range<String.Index>, String)] = []
                        var imgIdx = 0
                        for match in matches {
                            guard imgIdx < imgTags.count,
                                  let range = Range(match.range, in: html) else { continue }
                            replacements.append((range, imgTags[imgIdx]))
                            imgIdx += 1
                        }
                        // Apply replacements in reverse order to preserve indices
                        for (range, tag) in replacements.reversed() {
                            html.replaceSubrange(range, with: tag)
                        }
                        // Append any remaining images that had no matching EMBED text
                        while imgIdx < imgTags.count {
                            html += "<div style=\"margin:16px 0;text-align:center;\">\(imgTags[imgIdx])</div>"
                            imgIdx += 1
                        }
                    } else {
                        // Regex failed — fallback: append all images at the end
                        for tag in imgTags {
                            html += "<div style=\"margin:16px 0;text-align:center;\">\(tag)</div>"
                        }
                    }

                    nativeHTML = html
                    print("[STDOCXDocument] Extracted \(binaryImages.count) images from DOC binary, replaced in-place")
                }

                print("[STDOCXDocument] macOS native DOC → HTML: \(nativeHTML?.count ?? 0) chars")
            } else {
                print("[STDOCXDocument] macOS native DOC reading failed")
            }
            #else
            print("[STDOCXDocument] Detected legacy DOC format — loading via WebKit")
            #endif
        } else {
            // ── DOCX (ZIP/XML format) ──

            // 1. Try SwiftDocX parser
            do {
                doc = try Document(contentsOf: url)
                let converted = STDOCXConverter.toAttributedString(doc!)
                if converted.length > 0 {
                    attrString = converted
                }
            } catch {
                print("[STDOCXDocument] SwiftDocX parsing failed: \(error.localizedDescription)")
            }

            // 2. Fallback: extract raw text from ZIP XML
            if attrString == nil || attrString!.length == 0 {
                if let rawText = Self.extractRawText(from: url), !rawText.isEmpty {
                    let font = PlatformFont(name: "Calibri", size: 11) ?? .systemFont(ofSize: 11)
                    attrString = NSAttributedString(string: rawText, attributes: [
                        .font: font,
                        .foregroundColor: PlatformColor.label
                    ])
                    print("[STDOCXDocument] Used raw XML text fallback (\(rawText.count) chars)")
                }
            }

            // 3. Fallback: NSAttributedString auto-detection (RTF, HTML, etc. — NOT for DOC)
            if attrString == nil || attrString!.length == 0 {
                if let legacyAttr = Self.readWithNSAttributedString(url: url), legacyAttr.length > 0 {
                    attrString = legacyAttr
                    print("[STDOCXDocument] Used NSAttributedString fallback (\(legacyAttr.length) chars)")
                }
            }
        }

        // Legacy DOC with native HTML (macOS): content already extracted
        if isLegacyDoc && nativeHTML != nil && attrString != nil {
            let finalAttr = attrString!
            let pdf: PDFDocument
            #if os(macOS)
            // Use NSTextView rendering for full-fidelity PDF (includes charts, images, OLE objects)
            if let pdfData = Self.renderToPDFViaNSTextView(finalAttr),
               let rendered = PDFDocument(data: pdfData) {
                pdf = rendered
            } else if let pdfData = Self.renderToPDF(finalAttr),
                      let rendered = PDFDocument(data: pdfData) {
                pdf = rendered
            } else {
                pdf = Self.createBlankPDF()
            }
            #else
            if let pdfData = Self.renderToPDF(finalAttr),
               let rendered = PDFDocument(data: pdfData) {
                pdf = rendered
            } else {
                pdf = Self.createBlankPDF()
            }
            #endif
            self.pdfDocument = pdf
            self.url = url
            self.title = title ?? url.deletingPathExtension().lastPathComponent
            self.attributedString = finalAttr
            self.editableAttributedString = NSMutableAttributedString(attributedString: finalAttr)
            self.swiftDocXDocument = nil
            self.isLegacyDoc = true
            self.isLoading = false
            self.extractedHTML = nativeHTML
            return
        }

        // Legacy DOC: no content — create blank placeholder, load via WebKit asynchronously (iOS)
        if isLegacyDoc && (attrString == nil || attrString!.length == 0) {
            let placeholderPDF = Self.createBlankPDF()
            self.pdfDocument = placeholderPDF
            self.url = url
            self.title = title ?? url.deletingPathExtension().lastPathComponent
            self.attributedString = nil
            self.editableAttributedString = NSMutableAttributedString(string: " ")
            self.swiftDocXDocument = nil
            self.isLegacyDoc = true
            self.isLoading = true
            return
        }

        // Final: If nothing worked, create minimal placeholder
        if attrString == nil || attrString!.length == 0 {
            let font = PlatformFont(name: "Calibri", size: 11) ?? .systemFont(ofSize: 11)
            attrString = NSAttributedString(string: " ", attributes: [.font: font])
        }

        let finalAttrString = attrString!

        // Try rendering PDF — if it fails, use a blank placeholder
        // (web editor only needs swiftDocXDocument, not the PDF)
        let pdf: PDFDocument
        if let pdfData = Self.renderToPDF(finalAttrString),
           let rendered = PDFDocument(data: pdfData) {
            pdf = rendered
        } else {
            pdf = Self.createBlankPDF()
        }

        self.pdfDocument = pdf
        self.url = url
        self.title = title ?? url.deletingPathExtension().lastPathComponent
        self.attributedString = finalAttrString
        self.editableAttributedString = NSMutableAttributedString(attributedString: finalAttrString)
        self.swiftDocXDocument = doc
    }

    /// Fallback init from a pre-made PDFDocument (used when DOCX loading fails)
    public init(document: PDFDocument, url: URL? = nil, title: String = "Untitled") {
        self.pdfDocument = document
        self.url = url
        self.title = title
        self.attributedString = nil
        self.editableAttributedString = NSMutableAttributedString(string: " ")
        self.swiftDocXDocument = nil
    }

    // MARK: - Page Access

    /// Get a page at the given index
    public func page(at index: Int) -> PDFPage? {
        pdfDocument.page(at: index)
    }

    // MARK: - Save

    /// Save the annotated PDF alongside the original DOCX
    @discardableResult
    public func save() -> Bool {
        guard let url else { return false }
        let pdfURL = url.deletingPathExtension().appendingPathExtension("pdf")
        return pdfDocument.write(to: pdfURL)
    }

    /// Save to a specific URL (DOCX when possible, PDF fallback)
    @discardableResult
    public func save(to targetURL: URL) -> Bool {
        let ext = targetURL.pathExtension.lowercased()
        if (ext == "docx" || ext == "doc"), let doc = swiftDocXDocument {
            do {
                // Write DOCX content (ZIP/XML) — even for .doc files.
                // On next open, isOLE2CompoundDocument will return false
                // so the file takes the normal DOCX parsing path.
                try doc.write(to: targetURL)
                return true
            } catch {
                return false
            }
        }
        return pdfDocument.write(to: targetURL)
    }

    /// Extract full text from all rendered pages
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

    // MARK: - Read-Only Document Loading

    /// Update the PDF document (used after async WebKit rendering for DOC files)
    func updatePDFDocument(_ newPDF: PDFDocument) {
        self.pdfDocument = newPDF
        self.isLoading = false
        objectWillChange.send()
    }

    /// Mark loading as finished (even if rendering failed — shows blank page)
    func finishLoading() {
        self.isLoading = false
        objectWillChange.send()
    }

    /// Create a blank single-page PDF (placeholder while loading)
    private static func createBlankPDF() -> PDFDocument {
        let pageWidth: CGFloat = 612
        let pageHeight: CGFloat = 792
        let renderer = UIGraphicsPDFRenderer(
            bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        )
        let data = renderer.pdfData { context in
            context.beginPage()
        }
        return PDFDocument(data: data) ?? PDFDocument()
    }

    /// Asynchronously load a DOC file via WebKit — renders paginated PDF and extracts text
    @MainActor
    func loadDocViaWebKit() async {
        guard let url, isLoading, !webKitLoadStarted else { return }
        webKitLoadStarted = true
        print("[STDOCXDocument] Starting WebKit rendering for: \(url.lastPathComponent)")

        do {
            let result = try await STWebKitDocRenderer.render(fileURL: url)

            // Update PDF (for view/draw mode with graphics)
            if let pdf = PDFDocument(data: result.pdfData), pdf.pageCount > 0 {
                print("[STDOCXDocument] WebKit PDF: \(pdf.pageCount) pages")
                self.pdfDocument = pdf
            }

            // Update extracted HTML (preserves tables and structure for WKWebView editor)
            let html = result.extractedHTML.trimmingCharacters(in: .whitespacesAndNewlines)
            if !html.isEmpty {
                self.extractedHTML = html
                print("[STDOCXDocument] WebKit HTML: \(html.count) chars extracted")
            }

            // Update editable text (fallback for text editor mode)
            let text = result.extractedText.trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty {
                let font = PlatformFont(name: "Calibri", size: 11) ?? .systemFont(ofSize: 11)
                let attrStr = NSAttributedString(string: text, attributes: [
                    .font: font,
                    .foregroundColor: PlatformColor.label
                ])
                self.attributedString = attrStr
                self.editableAttributedString = NSMutableAttributedString(attributedString: attrStr)
                print("[STDOCXDocument] WebKit text: \(text.count) chars extracted")
            }

            self.isLoading = false
            objectWillChange.send()
        } catch {
            print("[STDOCXDocument] WebKit rendering failed: \(error.localizedDescription)")
            finishLoading()
        }
    }

    // MARK: - Web Editor Support

    /// Update the document model from a parsed Document (from web editor save)
    /// Converts the new Document to NSAttributedString and re-renders PDF
    func updateFromParsedDocument(_ newDoc: Document) {
        self.swiftDocXDocument = newDoc

        // Convert Document → NSAttributedString for PDF rendering
        let attrStr = STDOCXConverter.toAttributedString(newDoc)
        self.attributedString = attrStr
        self.editableAttributedString = NSMutableAttributedString(attributedString: attrStr)

        // Re-render PDF
        if let data = Self.renderToPDF(attrStr),
           let newPDF = PDFDocument(data: data) {
            self.pdfDocument = newPDF
        }

        objectWillChange.send()
    }

    // MARK: - Text Editing Support

    /// Re-render PDF from current editable attributed string
    func refreshPDFFromEditableText() {
        guard let attrStr = editableAttributedString,
              let data = Self.renderToPDF(attrStr),
              let newPDF = PDFDocument(data: data) else { return }
        self.pdfDocument = newPDF
        objectWillChange.send()
    }

    // MARK: - Raw Text Extraction (Fallback)

    /// Fallback text extraction — reads XML from ZIP and extracts <w:t> text content
    /// Tries multiple paths: word/document.xml, then any XML file containing <w:t> tags
    private static func extractRawText(from url: URL) -> String? {
        let reader = ZIPReader()

        // Try standard path first
        let xmlPaths = ["word/document.xml", "word/document2.xml", "content.xml"]
        var xmlData: Data?
        for path in xmlPaths {
            if let data = try? reader.readEntry(at: url, entryPath: path) {
                xmlData = data
                break
            }
        }

        // If standard paths fail, list ZIP entries and find XML files with text
        if xmlData == nil {
            if let entries = try? reader.listEntries(at: url) {
                print("[STDOCXDocument] ZIP entries: \(entries)")
                for entry in entries where entry.hasSuffix(".xml") && entry.contains("document") {
                    if let data = try? reader.readEntry(at: url, entryPath: entry) {
                        xmlData = data
                        break
                    }
                }
                // Last resort: try any XML file in word/ folder
                if xmlData == nil {
                    for entry in entries where entry.hasPrefix("word/") && entry.hasSuffix(".xml") {
                        if let data = try? reader.readEntry(at: url, entryPath: entry) {
                            if let str = String(data: data, encoding: .utf8), str.contains("<w:t") {
                                xmlData = data
                                break
                            }
                        }
                    }
                }
            }
        }

        guard let data = xmlData, let xml = String(data: data, encoding: .utf8) else {
            print("[STDOCXDocument] No XML found in ZIP — file may be legacy DOC format")
            return nil
        }

        return extractTextFromXML(xml)
    }

    /// Extract paragraph-structured text from Office XML
    private static func extractTextFromXML(_ xml: String) -> String? {
        var paragraphs: [String] = []
        let paraPattern = "<w:p[\\s>/].*?</w:p>"
        if let paraRegex = try? NSRegularExpression(pattern: paraPattern, options: .dotMatchesLineSeparators) {
            let matches = paraRegex.matches(in: xml, range: NSRange(xml.startIndex..., in: xml))
            for match in matches {
                guard let range = Range(match.range, in: xml) else { continue }
                let paraXml = String(xml[range])
                if let text = extractAllTextTags(from: paraXml), !text.isEmpty {
                    paragraphs.append(text)
                }
            }
        }
        if !paragraphs.isEmpty { return paragraphs.joined(separator: "\n") }
        return extractAllTextTags(from: xml)
    }

    /// Extract text from all <w:t> tags in an XML string
    private static func extractAllTextTags(from xml: String) -> String? {
        let pattern = "<w:t[^>]*>(.*?)</w:t>"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .dotMatchesLineSeparators) else { return nil }
        let matches = regex.matches(in: xml, range: NSRange(xml.startIndex..., in: xml))
        var texts: [String] = []
        for match in matches {
            if let range = Range(match.range(at: 1), in: xml) {
                let text = String(xml[range])
                    .replacingOccurrences(of: "&amp;", with: "&")
                    .replacingOccurrences(of: "&lt;", with: "<")
                    .replacingOccurrences(of: "&gt;", with: ">")
                    .replacingOccurrences(of: "&quot;", with: "\"")
                    .replacingOccurrences(of: "&apos;", with: "'")
                texts.append(text)
            }
        }
        return texts.isEmpty ? nil : texts.joined()
    }

    // MARK: - Legacy Format Support

    /// Check if file is an OLE2 Compound Document (legacy DOC format)
    /// Magic bytes: D0 CF 11 E0 A1 B1 1A E1
    #if os(macOS)
    /// Extracted image data with its MIME type
    private struct BinaryImageData {
        let data: Data
        let mimeType: String // "image/png" or "image/jpeg"
    }

    /// Extract embedded images (PNG/JPEG) from a binary DOC file by scanning for signatures.
    /// Returns raw image data to avoid NSImage decoding issues with progressive JPEGs.
    private static func extractImagesFromDOCBinary(_ url: URL) -> [BinaryImageData] {
        guard let data = try? Data(contentsOf: url), data.count > 100 else { return [] }
        var images: [BinaryImageData] = []

        data.withUnsafeBytes { rawBuffer in
            guard let basePtr = rawBuffer.baseAddress else { return }
            let bytes = basePtr.assumingMemoryBound(to: UInt8.self)
            let count = rawBuffer.count

            var i = 0
            while i < count - 12 {
                // PNG signature: 89 50 4E 47 0D 0A 1A 0A
                if bytes[i] == 0x89 && bytes[i+1] == 0x50 && bytes[i+2] == 0x4E && bytes[i+3] == 0x47
                    && bytes[i+4] == 0x0D && bytes[i+5] == 0x0A && bytes[i+6] == 0x1A && bytes[i+7] == 0x0A {
                    var found = false
                    let maxEnd = min(count - 7, i + 5_000_000)
                    for j in (i + 8)..<maxEnd {
                        if bytes[j] == 0x49 && bytes[j+1] == 0x45 && bytes[j+2] == 0x4E && bytes[j+3] == 0x44
                            && bytes[j+4] == 0xAE && bytes[j+5] == 0x42 && bytes[j+6] == 0x60 && bytes[j+7] == 0x82 {
                            let endIdx = j + 8
                            let imgData = Data(bytes: bytes.advanced(by: i), count: endIdx - i)
                            if imgData.count > 1000 { // Skip tiny images (icons etc.)
                                images.append(BinaryImageData(data: imgData, mimeType: "image/png"))
                                print("[STDOCXDocument] Found PNG in binary: \(imgData.count) bytes")
                            }
                            i = endIdx
                            found = true
                            break
                        }
                    }
                    if !found { i += 1 }
                    continue
                }

                // JPEG signature: FF D8 FF
                if bytes[i] == 0xFF && bytes[i+1] == 0xD8 && bytes[i+2] == 0xFF {
                    var found = false
                    let maxEnd = min(count - 1, i + 10_000_000)
                    for j in (i + 3)..<maxEnd {
                        if bytes[j] == 0xFF && bytes[j+1] == 0xD9 {
                            let endIdx = j + 2
                            let imgData = Data(bytes: bytes.advanced(by: i), count: endIdx - i)
                            if imgData.count > 5000 { // Skip tiny images
                                images.append(BinaryImageData(data: imgData, mimeType: "image/jpeg"))
                                print("[STDOCXDocument] Found JPEG in binary: \(imgData.count) bytes")
                            }
                            i = endIdx
                            found = true
                            break
                        }
                    }
                    if !found { i += 1 }
                    continue
                }

                i += 1
            }
        }

        return images
    }

    /// Re-encode image data as baseline JPEG via CGImage (converts progressive JPEG to baseline).
    /// Uses multiple decode strategies to handle problematic progressive JPEGs.
    private static func reencodeImageAsBaselineJPEG(_ data: Data) -> Data? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            print("[STDOCXDocument] CGImageSource failed to create source")
            return nil
        }

        // Strategy 1: Force thumbnail creation (more robust for progressive JPEGs)
        let thumbnailOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: 2000,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true
        ]
        var cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbnailOptions as CFDictionary)

        // Strategy 2: Regular decode with immediate caching
        if cgImage == nil {
            let decodeOptions: [CFString: Any] = [
                kCGImageSourceShouldCacheImmediately: true
            ]
            cgImage = CGImageSourceCreateImageAtIndex(source, 0, decodeOptions as CFDictionary)
        }

        // Strategy 3: Use NSImage as intermediate decoder
        if cgImage == nil || (cgImage!.width < 10 || cgImage!.height < 10) {
            if let nsImage = NSImage(data: data),
               let tiffData = nsImage.tiffRepresentation,
               let bitmapRep = NSBitmapImageRep(data: tiffData),
               bitmapRep.pixelsWide > 10 && bitmapRep.pixelsHigh > 10 {
                cgImage = bitmapRep.cgImage
            }
        }

        guard let finalImage = cgImage, finalImage.width > 10, finalImage.height > 10 else {
            print("[STDOCXDocument] All decode strategies failed for image (\(data.count) bytes)")
            return nil
        }

        // Re-encode as baseline JPEG
        let mutableData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            mutableData as CFMutableData,
            "public.jpeg" as CFString,
            1,
            nil
        ) else { return nil }

        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: 0.85
        ]
        CGImageDestinationAddImage(destination, finalImage, options as CFDictionary)

        guard CGImageDestinationFinalize(destination) else { return nil }

        print("[STDOCXDocument] Re-encoded image: \(data.count) → \(mutableData.length) bytes, \(finalImage.width)x\(finalImage.height)")
        return mutableData as Data
    }
    #endif

    private static func isOLE2CompoundDocument(url: URL) -> Bool {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return false }
        defer { try? handle.close() }
        let header = handle.readData(ofLength: 8)
        guard header.count >= 4 else { return false }
        return header[0] == 0xD0 && header[1] == 0xCF && header[2] == 0x11 && header[3] == 0xE0
    }

    /// Try reading with NSAttributedString auto-detection (RTF only — NOT for binary DOC)
    private static func readWithNSAttributedString(url: URL) -> NSAttributedString? {
        // Only try RTF — .html triggers WebKit internally which spins a nested run loop
        // and crashes with NSInternalInconsistencyException during SwiftUI body evaluation
        // or iOS snapshot taking. Legacy DOC files use loadDocViaWebKit() instead.
        let rtfType: NSAttributedString.DocumentType = .rtf
        if let attr = try? NSAttributedString(
            url: url,
            options: [.documentType: rtfType],
            documentAttributes: nil
        ), attr.length > 0 {
            return attr
        }
        return nil
    }

    // MARK: - Rich HTML from NSAttributedString (macOS DOC)

    #if os(macOS)
    /// Pre-process NSAttributedString: render all text attachments (charts, OLE objects, images)
    /// to actual NSImage objects so the HTML export can serialize them as <img> tags.
    private static func preprocessAttachments(_ attrString: NSAttributedString) -> NSAttributedString {
        let mutable = NSMutableAttributedString(attributedString: attrString)
        var replacements: [(NSRange, NSImage)] = []

        mutable.enumerateAttribute(.attachment, in: NSRange(location: 0, length: mutable.length), options: []) { value, range, _ in
            guard let attachment = value as? NSTextAttachment else { return }

            var renderedImage: NSImage?

            // Method 1: attachment already has an image
            if let img = attachment.image, img.size.width > 1 && img.size.height > 1 {
                renderedImage = img
            }

            // Method 2: file wrapper contains image data
            if renderedImage == nil,
               let fw = attachment.fileWrapper,
               let data = fw.regularFileContents,
               let img = NSImage(data: data),
               img.size.width > 1 {
                renderedImage = img
            }

            // Method 3: use attachment cell to render (for OLE objects like charts)
            if renderedImage == nil,
               let cell = attachment.attachmentCell as? NSTextAttachmentCell {
                let cellSize = cell.cellSize
                if cellSize.width > 5 && cellSize.height > 5 {
                    let img = NSImage(size: cellSize)
                    img.lockFocusFlipped(false)
                    let tempView = NSTextView(frame: NSRect(origin: .zero, size: cellSize))
                    cell.draw(withFrame: NSRect(origin: .zero, size: cellSize), in: tempView)
                    img.unlockFocus()
                    // Verify the image has actual content (not blank)
                    if let tiff = img.tiffRepresentation, tiff.count > 500 {
                        renderedImage = img
                    }
                }
            }

            if let image = renderedImage {
                replacements.append((range, image))
            }
        }

        // Apply replacements in reverse order to preserve indices
        for (range, image) in replacements.reversed() {
            let newAttachment = NSTextAttachment()
            newAttachment.image = image
            let replacement = NSAttributedString(attachment: newAttachment)
            mutable.replaceCharacters(in: range, with: replacement)
        }

        if !replacements.isEmpty {
            print("[STDOCXDocument] Pre-processed \(replacements.count) text attachments to images")
        }

        return mutable
    }

    /// Convert NSAttributedString to rich HTML, preserving tables and converting images to base64.
    /// NSAttributedString's HTML export produces well-formed HTML with tables, lists, and formatting,
    /// but image src attributes point to file:// URLs. We convert those to inline base64 data URLs.
    private static func attributedStringToRichHTML(_ attrString: NSAttributedString) -> String? {
        // Pre-process: render OLE objects (charts, etc.) to images before HTML export
        let processed = preprocessAttachments(attrString)

        guard let htmlData = try? processed.data(
            from: NSRange(location: 0, length: processed.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.html]
        ), var htmlString = String(data: htmlData, encoding: .utf8)
              ?? String(data: htmlData, encoding: .unicode) else {
            return nil
        }

        // Convert file:// image references to base64 data URLs
        // NSAttributedString HTML export creates <img src="file:///var/..."> for embedded images
        let imgPattern = try? NSRegularExpression(
            pattern: #"<img\s+[^>]*src\s*=\s*"(file://[^"]+)"[^>]*>"#,
            options: .caseInsensitive
        )
        if let regex = imgPattern {
            let matches = regex.matches(in: htmlString, range: NSRange(htmlString.startIndex..., in: htmlString))
            // Process in reverse to preserve indices
            for match in matches.reversed() {
                guard match.numberOfRanges >= 2,
                      let fullRange = Range(match.range(at: 0), in: htmlString),
                      let srcRange = Range(match.range(at: 1), in: htmlString) else { continue }
                let filePath = String(htmlString[srcRange])
                if let fileURL = URL(string: filePath),
                   let imageData = try? Data(contentsOf: fileURL) {
                    let mimeType = filePath.hasSuffix(".png") ? "image/png" : "image/jpeg"
                    let base64 = imageData.base64EncodedString()
                    let dataURL = "data:\(mimeType);base64,\(base64)"
                    let newImg = "<img src=\"\(dataURL)\" style=\"max-width:100%;height:auto;\">"
                    htmlString.replaceSubrange(fullRange, with: newImg)
                }
            }
        }

        // Extract <head> styles — NSAttributedString HTML may define table/cell styles here
        var headStyles = ""
        if let headStart = htmlString.range(of: "<style", options: .caseInsensitive),
           let headEnd = htmlString.range(of: "</style>", options: .caseInsensitive) {
            headStyles = String(htmlString[headStart.lowerBound...headEnd.upperBound])
        }

        // Extract <body> content (body tag may have style attributes)
        var body: String
        if let bodyStartRange = htmlString.range(of: "<body", options: .caseInsensitive),
           let bodyTagEnd = htmlString[bodyStartRange.upperBound...].range(of: ">"),
           let bodyEndRange = htmlString.range(of: "</body>", options: .caseInsensitive) {
            body = String(htmlString[bodyTagEnd.upperBound..<bodyEndRange.lowerBound])
        } else {
            body = htmlString
        }

        // Prepend head styles + table border CSS (setContent will move <style> to <head>)
        var styles = headStyles
        if body.range(of: "<table", options: .caseInsensitive) != nil {
            styles += """
            <style>
            table { border-collapse: collapse; width: 100%; margin: 12px 0; }
            td, th { border: 1px solid #999; padding: 6px 10px; }
            </style>
            """
        }
        if !styles.isEmpty {
            body = styles + body
        }

        return body
    }

    /// Render NSAttributedString to PDF using NSTextView (macOS only).
    /// Unlike CoreText, NSTextView renders text attachments (charts, OLE objects, images).
    private static func renderToPDFViaNSTextView(_ attrString: NSAttributedString) -> Data? {
        let pageWidth: CGFloat = 612
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 36
        let contentWidth = pageWidth - 2 * margin

        // Pre-process attachments to ensure they have renderable images
        let processed = preprocessAttachments(attrString)

        // Create text system
        let textStorage = NSTextStorage(attributedString: processed)
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: NSSize(width: contentWidth, height: .greatestFiniteMagnitude))
        textContainer.widthTracksTextView = true
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        // Force complete layout
        layoutManager.ensureLayout(for: textContainer)
        let usedRect = layoutManager.usedRect(for: textContainer)
        let contentHeight = max(usedRect.height + 1, 100)

        // Create NSTextView to render
        let textView = NSTextView(frame: NSRect(x: 0, y: 0, width: contentWidth, height: contentHeight))
        textView.textContainer?.replaceLayoutManager(layoutManager)
        textView.textContainer?.containerSize = NSSize(width: contentWidth, height: contentHeight)
        textView.isEditable = false
        textView.isSelectable = false
        textView.backgroundColor = .white

        // Render to single-page PDF via NSView
        let singlePDF = textView.dataWithPDF(inside: textView.bounds)
        guard !singlePDF.isEmpty,
              let sourcePDFDoc = PDFDocument(data: singlePDF),
              sourcePDFDoc.pageCount > 0,
              let sourcePage = sourcePDFDoc.page(at: 0) else {
            return nil
        }

        let sourceRect = sourcePage.bounds(for: .mediaBox)
        let contentH = pageHeight - 2 * margin

        // Single page: fits in one page
        if sourceRect.height <= contentH {
            let data = NSMutableData()
            var mediaBox = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
            guard let consumer = CGDataConsumer(data: data as CFMutableData),
                  let ctx = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else { return nil }
            ctx.beginPDFPage(nil)
            ctx.saveGState()
            ctx.translateBy(x: margin, y: margin)
            if let cgPage = sourcePage.pageRef { ctx.drawPDFPage(cgPage) }
            ctx.restoreGState()
            ctx.endPDFPage()
            ctx.closePDF()
            return data as Data
        }

        // Multi-page: split tall content into letter-sized pages
        let numPages = max(1, Int(ceil(sourceRect.height / contentH)))
        let data = NSMutableData()
        var mediaBox = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        guard let consumer = CGDataConsumer(data: data as CFMutableData),
              let ctx = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else { return nil }

        for i in 0..<numPages {
            ctx.beginPDFPage(nil)
            ctx.saveGState()
            ctx.clip(to: CGRect(x: margin, y: margin, width: contentWidth, height: contentH))
            // sourceRect origin is (0,0), content grows upward in PDF coords
            // Slice i shows content from (i * contentH) to ((i+1) * contentH) from top
            let yOffset = margin - (sourceRect.height - contentH * CGFloat(numPages - i))
            ctx.translateBy(x: margin, y: yOffset)
            if let cgPage = sourcePage.pageRef { ctx.drawPDFPage(cgPage) }
            ctx.restoreGState()
            ctx.endPDFPage()
        }

        ctx.closePDF()
        return data as Data
    }
    #endif

    // MARK: - PDF Rendering

    /// Render NSAttributedString into PDF data using CoreText pagination
    static func renderToPDF(_ attributedString: NSAttributedString) -> Data? {
        let pageWidth: CGFloat = 612   // US Letter
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 36
        let contentRect = CGRect(
            x: margin, y: margin,
            width: pageWidth - 2 * margin,
            height: pageHeight - 2 * margin
        )

        let renderer = UIGraphicsPDFRenderer(
            bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        )

        let data = renderer.pdfData { context in
            let framesetter = CTFramesetterCreateWithAttributedString(attributedString as CFAttributedString)
            let path = CGPath(rect: contentRect, transform: nil)
            var textPos = 0
            let totalLength = attributedString.length

            while textPos < totalLength {
                context.beginPage()

                let cgContext = context.cgContext
                // Flip coordinate system: UIKit uses top-left origin (Y down),
                // but CoreText/CoreGraphics expects bottom-left origin (Y up)
                cgContext.saveGState()
                cgContext.translateBy(x: 0, y: pageHeight)
                cgContext.scaleBy(x: 1, y: -1)

                let frame = CTFramesetterCreateFrame(
                    framesetter, CFRangeMake(textPos, 0), path, nil
                )
                CTFrameDraw(frame, cgContext)
                cgContext.restoreGState()

                let visibleRange = CTFrameGetVisibleStringRange(frame)
                if visibleRange.length == 0 { break }
                textPos += visibleRange.length
            }

            // Ensure at least one page for empty documents
            if totalLength == 0 {
                context.beginPage()
            }
        }

        return data
    }
}

// MARK: - STDocument Conformance

extension STDOCXDocument: STDocument {
    public var sourceURL: URL? { url }
    public var plainText: String { extractFullText() }
}
