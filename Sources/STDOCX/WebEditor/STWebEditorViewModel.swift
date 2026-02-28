import SwiftUI
import WebKit
import Combine
import PDFKit
import STKit

/// ViewModel for the WKWebView-based DOCX editor
/// Manages formatting state, JS bridge, and content sync
@MainActor
final class STWebEditorViewModel: ObservableObject {

    let document: STDOCXDocument

    /// Reference to the live WKWebView (set by STWebEditorView)
    weak var webView: WKWebView?

    /// Whether the editor has finished loading and is ready for interaction
    @Published var isReady: Bool = false

    /// Whether content has been modified since last save
    @Published var isContentDirty: Bool = false

    // MARK: - Formatting State (updated from JS via message handler)

    @Published var isBold: Bool = false
    @Published var isItalic: Bool = false
    @Published var isUnderline: Bool = false
    @Published var isStrikethrough: Bool = false
    @Published var currentFontSize: CGFloat = 11
    @Published var currentFontName: String = "Calibri"
    @Published var textAlignment: NSTextAlignment = .left
    @Published var isInTable: Bool = false
    @Published var isSubscript: Bool = false
    @Published var isSuperscript: Bool = false
    @Published var isBulletList: Bool = false
    @Published var isNumberedList: Bool = false

    // MARK: - Select Mode (hand tool for table selection & resize)

    @Published var isSelectMode: Bool = false

    // MARK: - Page Navigation State

    @Published var currentPage: Int = 0
    @Published var totalPages: Int = 1
    /// Page offsets (CSS pixels) for scroll tracking
    var pageOffsets: [CGFloat] = []

    // MARK: - Chart Editor State

    @Published var isChartEditorVisible: Bool = false
    @Published var editingChartModel: STChartEditorModel?

    // MARK: - Comment Tap State

    @Published var tappedComment: (id: String, text: String, contextText: String)?

    init(document: STDOCXDocument) {
        self.document = document
    }

    // MARK: - Content Operations

    /// Generate HTML from document model and load into WKWebView
    func loadContent() {
        guard let webView else { return }
        let html: String
        if document.isLegacyDoc {
            // Legacy DOC: use extracted HTML (preserves tables and structure)
            if let extractedHTML = document.extractedHTML, !extractedHTML.isEmpty {
                html = extractedHTML
            } else {
                let text = document.editableAttributedString?.string ?? ""
                html = STDocumentToHTMLConverter.plainTextToHTML(text)
            }
        } else if let swiftDoc = document.swiftDocXDocument {
            // DOCX: convert Document model to HTML
            html = STDocumentToHTMLConverter.toHTML(swiftDoc)
        } else {
            // Fallback: use editable attributed string text
            let text = document.editableAttributedString?.string ?? ""
            html = STDocumentToHTMLConverter.plainTextToHTML(text)
        }

        // Use callAsyncJavaScript to safely pass large HTML (avoids string escaping issues with base64 images)
        webView.callAsyncJavaScript(
            "setContent(html)",
            arguments: ["html": html],
            in: nil,
            in: .page
        ) { result in
            if case .failure(let error) = result {
                print("[STWebEditor] setContent error: \(error.localizedDescription)")
            }
        }
    }

    /// Extract document structure from WKWebView and save to DOCX
    func saveContent() async {
        guard let webView else { return }

        do {
            let result = try await webView.evaluateJavaScript("getDocumentStructure()")
            guard let jsonString = result as? String else {
                print("[STWebEditor] getDocumentStructure returned non-string")
                return
            }

            // Convert JSON → Document model
            if let newDoc = STHTMLToDocumentConverter.toDocument(from: jsonString) {
                // Update the document's internal model
                document.updateFromParsedDocument(newDoc)
                isContentDirty = false
                print("[STWebEditor] Content saved: \(newDoc.paragraphs.count) paragraphs, \(newDoc.tables.count) tables")
            }
        } catch {
            print("[STWebEditor] Save error: \(error.localizedDescription)")
        }
    }

    // MARK: - Formatting Actions (call JS via evaluateJavaScript)

    func toggleBold() {
        evaluateFormatJS("toggleBold()")
    }

    func toggleItalic() {
        evaluateFormatJS("toggleItalic()")
    }

    func toggleUnderline() {
        evaluateFormatJS("toggleUnderline()")
    }

    func toggleStrikethrough() {
        evaluateFormatJS("toggleStrikethrough()")
    }

    func setAlignment(_ alignment: NSTextAlignment) {
        switch alignment {
        case .left: evaluateFormatJS("setAlignLeft()")
        case .center: evaluateFormatJS("setAlignCenter()")
        case .right: evaluateFormatJS("setAlignRight()")
        case .justified: evaluateFormatJS("setAlignJustify()")
        default: evaluateFormatJS("setAlignLeft()")
        }
    }

    func increaseFontSize() {
        evaluateFormatJS("increaseFontSize()")
    }

    func decreaseFontSize() {
        evaluateFormatJS("decreaseFontSize()")
    }

    func undo() {
        evaluateJS("editorUndo()")
    }

    func redo() {
        evaluateJS("editorRedo()")
    }

    func selectAll() {
        evaluateJS("selectAll()")
    }

    // MARK: - Image Insertion

    /// Insert an image into the WKWebView editor at the cursor position
    func insertImage(data: Data) {
        guard let webView else { return }
        // Detect MIME type from data header
        let mime: String
        if data.count >= 3, data[0] == 0xFF, data[1] == 0xD8, data[2] == 0xFF {
            mime = "image/jpeg"
        } else if data.count >= 8, data[0] == 0x89, data[1] == 0x50 {
            mime = "image/png"
        } else {
            mime = "image/png"
        }
        let base64 = data.base64EncodedString()
        let dataURL = "data:\(mime);base64,\(base64)"

        // Use callAsyncJavaScript to safely pass large base64 strings
        webView.callAsyncJavaScript(
            "insertImage(dataURL)",
            arguments: ["dataURL": dataURL],
            in: nil,
            in: .page
        ) { result in
            if case .failure(let error) = result {
                print("[STWebEditor] insertImage error: \(error.localizedDescription)")
            }
        }
    }

    /// Print the WKWebView content
    func printContent() {
        guard let webView else { return }
        #if os(iOS)
        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.jobName = document.title
        printInfo.outputType = .general

        let printController = UIPrintInteractionController.shared
        printController.printInfo = printInfo
        printController.printFormatter = webView.viewPrintFormatter()
        printController.present(animated: true)
        #elseif os(macOS)
        // Use WKWebView.createPDF to capture full visual content (images, charts, tables),
        // then split into letter-sized pages and print via PDFDocument.
        Task { [weak self] in
            guard let self, let webView = self.webView else { return }

            // Save changes first
            await self.saveContent()
            if let docURL = self.document.url {
                self.document.save(to: docURL)
            }

            // Get full scrollable content height
            let jsResult = try? await webView.evaluateJavaScript("document.documentElement.scrollHeight")
            let contentHeight: CGFloat
            if let h = jsResult as? CGFloat { contentHeight = h }
            else if let h = jsResult as? Double { contentHeight = CGFloat(h) }
            else if let h = jsResult as? Int { contentHeight = CGFloat(h) }
            else { contentHeight = 792 }

            let viewWidth = webView.bounds.width > 0 ? webView.bounds.width : 612

            // Capture full content as PDF (preserves images, charts, tables)
            let config = WKPDFConfiguration()
            config.rect = CGRect(x: 0, y: 0, width: viewWidth, height: contentHeight)

            guard let pdfData = try? await webView.pdf(configuration: config),
                  let sourcePDF = PDFDocument(data: pdfData) else { return }

            let pdfToPrint: PDFDocument

            if sourcePDF.pageCount > 1 {
                // Already paginated — use as-is
                pdfToPrint = sourcePDF
            } else if let sourcePage = sourcePDF.page(at: 0) {
                // Single tall page — split into US Letter pages
                let sourceBox = sourcePage.bounds(for: .mediaBox)
                let pageW: CGFloat = 612
                let pageH: CGFloat = 792
                let margin: CGFloat = 36
                let printW = pageW - 2 * margin
                let printH = pageH - 2 * margin

                let scale = printW / sourceBox.width
                let scaledH = sourceBox.height * scale
                let numPages = max(1, Int(ceil(scaledH / printH)))

                let result = PDFDocument()

                for i in 0..<numPages {
                    let pageData = NSMutableData()
                    var mediaBox = CGRect(x: 0, y: 0, width: pageW, height: pageH)
                    guard let consumer = CGDataConsumer(data: pageData as CFMutableData),
                          let ctx = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else { continue }

                    ctx.beginPDFPage(nil)
                    ctx.saveGState()

                    // Clip to printable area
                    ctx.clip(to: CGRect(x: margin, y: margin, width: printW, height: printH))

                    // Translate and scale to show the correct page portion
                    let yTranslate = margin - scaledH + CGFloat(i + 1) * printH
                    ctx.translateBy(x: margin, y: yTranslate)
                    ctx.scaleBy(x: scale, y: scale)

                    // Draw the full source page (clipping reveals only this page's portion)
                    if let cgPage = sourcePage.pageRef {
                        ctx.drawPDFPage(cgPage)
                    }

                    ctx.restoreGState()
                    ctx.endPDFPage()
                    ctx.closePDF()

                    if let pagePDF = PDFDocument(data: pageData as Data),
                       let page = pagePDF.page(at: 0) {
                        result.insert(page, at: i)
                    }
                }
                pdfToPrint = result
            } else {
                return
            }

            guard pdfToPrint.pageCount > 0 else { return }

            // Print via PDFDocument (reliable, no crashes)
            DispatchQueue.main.async {
                let printInfo = NSPrintInfo.shared.copy() as! NSPrintInfo
                printInfo.isHorizontallyCentered = true
                printInfo.isVerticallyCentered = true
                if let printOp = pdfToPrint.printOperation(for: printInfo, scalingMode: .pageScaleToFit, autoRotate: true) {
                    printOp.showsPrintPanel = true
                    printOp.showsProgressPanel = true
                    printOp.run()
                }
            }
        }
        #endif
    }

    // MARK: - Text Color & Highlight

    func setTextColor(_ hex: String) {
        evaluateFormatJS("setTextColor('\(hex)')")
    }

    func setHighlightColor(_ hex: String) {
        evaluateFormatJS("setHighlightColor('\(hex)')")
    }

    // MARK: - Lists

    func toggleBulletList() {
        evaluateFormatJS("toggleBulletList()")
    }

    func toggleNumberedList() {
        evaluateFormatJS("toggleNumberedList()")
    }

    // MARK: - Indentation

    func increaseIndent() {
        evaluateFormatJS("increaseIndent()")
    }

    func decreaseIndent() {
        evaluateFormatJS("decreaseIndent()")
    }

    // MARK: - Subscript / Superscript

    func toggleSubscript() {
        evaluateFormatJS("toggleSubscript()")
    }

    func toggleSuperscript() {
        evaluateFormatJS("toggleSuperscript()")
    }

    // MARK: - Font Family

    func setFontFamily(_ name: String) {
        evaluateFormatJS("setFontFamily('\(name)')")
    }

    // MARK: - Line Spacing

    func setLineSpacing(_ value: Double) {
        evaluateJS("setLineSpacing('\(value)')")
    }

    // MARK: - Insert Table

    func insertTable(rows: Int, cols: Int) {
        evaluateJS("insertTable(\(rows), \(cols))")
    }

    // MARK: - Insert Link

    func insertLink(url: String) {
        guard let webView else { return }
        webView.callAsyncJavaScript(
            "insertLink(url)",
            arguments: ["url": url],
            in: nil,
            in: .page
        ) { _ in }
    }

    // MARK: - Insert Page Break

    func insertPageBreak() {
        evaluateJS("insertPageBreak()")
    }

    // MARK: - Insert Horizontal Rule

    func insertHorizontalRule() {
        evaluateJS("insertHorizontalRule()")
    }

    // MARK: - Zoom (native scrollView zoom)

    func zoomIn() {
        #if os(iOS)
        guard let sv = webView?.scrollView else { return }
        let newScale = min(sv.zoomScale + 0.25, sv.maximumZoomScale)
        sv.setZoomScale(newScale, animated: true)
        #elseif os(macOS)
        webView?.pageZoom += 0.25
        #endif
    }

    func zoomOut() {
        #if os(iOS)
        guard let sv = webView?.scrollView else { return }
        let newScale = max(sv.zoomScale - 0.25, sv.minimumZoomScale)
        sv.setZoomScale(newScale, animated: true)
        #elseif os(macOS)
        webView?.pageZoom = max((webView?.pageZoom ?? 1.0) - 0.25, 0.5)
        #endif
    }

    func resetZoom() {
        #if os(iOS)
        webView?.scrollView.setZoomScale(1.0, animated: true)
        #elseif os(macOS)
        webView?.pageZoom = 1.0
        #endif
    }

    // MARK: - Table Operations

    func addTableRow() {
        evaluateJS("addTableRow()")
    }

    func deleteTableRow() {
        evaluateJS("deleteTableRow()")
    }

    func addTableColumn() {
        evaluateJS("addTableColumn()")
    }

    func deleteTableColumn() {
        evaluateJS("deleteTableColumn()")
    }

    func setCellBackgroundColor(_ color: PlatformColor) {
        let hex = color.toHexString()
        evaluateJS("setCellBackgroundColor('\(hex)')")
    }

    func setCellBackgroundColor(_ hex: String) {
        evaluateJS("setCellBackgroundColor('\(hex)')")
    }

    func setCellBorderColor(_ hex: String) {
        evaluateJS("setCellBorderColor('\(hex)')")
    }

    // MARK: - Table Templates & Styles

    func insertTableTemplate(templateId: String, rows: Int = 0, cols: Int = 0) {
        evaluateJS("insertTableTemplate('\(templateId)', \(rows), \(cols))")
    }

    func setTableThemeColor(headerBg: String, stripeBg: String, borderColor: String) {
        evaluateJS("setTableThemeColor('\(headerBg)', '\(stripeBg)', '\(borderColor)')")
    }

    // MARK: - Bookmarks

    func insertBookmark(name: String) {
        guard let webView else { return }
        let id = UUID().uuidString
        webView.callAsyncJavaScript(
            "return insertBookmark(id, name)",
            arguments: ["id": id, "name": name],
            in: nil,
            in: .page
        ) { _ in }
    }

    func getBookmarks() async -> [(id: String, name: String)] {
        guard let webView else { return [] }
        do {
            let result = try await webView.evaluateJavaScript("getBookmarks()")
            guard let jsonString = result as? String,
                  let data = jsonString.data(using: .utf8),
                  let array = try? JSONSerialization.jsonObject(with: data) as? [[String: String]] else {
                return []
            }
            return array.compactMap { dict in
                guard let id = dict["id"], let name = dict["name"] else { return nil }
                return (id: id, name: name)
            }
        } catch {
            return []
        }
    }

    func scrollToBookmark(id: String) {
        evaluateJS("scrollToBookmark('\(id)')")
    }

    func removeBookmark(id: String) {
        evaluateJS("removeBookmark('\(id)')")
    }

    // MARK: - Comments

    func insertComment(text: String) {
        guard let webView else { return }
        let id = UUID().uuidString
        // restoreSelection() first — the alert that collected text stole focus
        webView.callAsyncJavaScript(
            "restoreSelection(); return insertComment(id, text)",
            arguments: ["id": id, "text": text],
            in: nil,
            in: .page
        ) { _ in }
    }

    func getComments() async -> [(id: String, text: String, contextText: String)] {
        guard let webView else { return [] }
        do {
            let result = try await webView.evaluateJavaScript("getComments()")
            guard let jsonString = result as? String,
                  let data = jsonString.data(using: .utf8),
                  let array = try? JSONSerialization.jsonObject(with: data) as? [[String: String]] else {
                return []
            }
            return array.compactMap { dict in
                guard let id = dict["id"], let text = dict["text"] else { return nil }
                return (id: id, text: text, contextText: dict["contextText"] ?? "")
            }
        } catch {
            return []
        }
    }

    func scrollToComment(id: String) {
        evaluateJS("scrollToComment('\(id)')")
    }

    func deleteComment(id: String) {
        evaluateJS("deleteComment('\(id)')")
    }

    // MARK: - Chart Operations

    /// Called from JS when user taps a chart in the editor
    func handleChartTapped(chartId: String) {
        guard let webView else { return }

        webView.evaluateJavaScript("getChartData('\(chartId)')") { [weak self] result, error in
            guard let self else { return }
            if let error {
                print("[STWebEditor] getChartData error: \(error.localizedDescription)")
                return
            }

            guard let jsonString = result as? String,
                  let chart = Chart.fromJSON(jsonString) else {
                print("[STWebEditor] Could not parse chart data for \(chartId)")
                return
            }

            Task { @MainActor in
                self.editingChartModel = STChartEditorModel(from: chart)
                self.isChartEditorVisible = true
            }
        }
    }

    /// Apply edited chart data back to the WKWebView
    func applyChartEdit() {
        guard let model = editingChartModel,
              let json = model.toChartJSON() else { return }

        let escaped = json
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
            .replacingOccurrences(of: "\n", with: "\\n")
        evaluateJS("updateChartData('\(model.chartId)', '\(escaped)')")
        isContentDirty = true
        isChartEditorVisible = false
        editingChartModel = nil
    }

    /// Dismiss chart editor without applying changes
    func cancelChartEdit() {
        isChartEditorVisible = false
        editingChartModel = nil
    }

    // MARK: - Page Navigation

    func goToPage(_ index: Int) {
        guard let webView, index >= 0 else { return }
        #if os(iOS)
        // Use native scrollView for reliable page navigation
        if index < pageOffsets.count {
            let offset = pageOffsets[index]
            webView.scrollView.setContentOffset(CGPoint(x: 0, y: offset), animated: true)
            currentPage = index
        } else {
            evaluateJS("goToPage(\(index))")
        }
        #elseif os(macOS)
        evaluateJS("goToPage(\(index))")
        currentPage = index
        #endif
    }

    func nextPage() {
        evaluateJS("nextPage()")
    }

    func prevPage() {
        evaluateJS("prevPage()")
    }

    /// Set target page count from PDF — makes WKWebView pagination match PDF pages
    func setTargetPageCount(_ count: Int) {
        evaluateJS("setTargetPageCount(\(count))")
    }

    func updatePageInfo(from message: [String: Any]) {
        currentPage = message["current"] as? Int ?? 0
        totalPages = message["total"] as? Int ?? 1
        // Parse page offsets for native UIScrollView paging
        if let offsets = message["offsets"] as? [Double] {
            pageOffsets = offsets.map { CGFloat($0) }
        }
        print("[STWebEditor] pageChanged: current=\(currentPage) total=\(totalPages) offsets=\(pageOffsets.count)")
    }

    // MARK: - Formatting State Update (from JS message handler)

    func updateFormattingState(from message: [String: Any]) {
        isBold = message["isBold"] as? Bool ?? false
        isItalic = message["isItalic"] as? Bool ?? false
        isUnderline = message["isUnderline"] as? Bool ?? false
        isStrikethrough = message["isStrikethrough"] as? Bool ?? false
        isSubscript = message["isSubscript"] as? Bool ?? false
        isSuperscript = message["isSuperscript"] as? Bool ?? false
        isBulletList = message["isBulletList"] as? Bool ?? false
        isNumberedList = message["isNumberedList"] as? Bool ?? false
        currentFontSize = CGFloat(message["fontSize"] as? Double ?? 11)
        currentFontName = message["fontName"] as? String ?? "Calibri"
        isInTable = message["isInTable"] as? Bool ?? false

        if let align = message["alignment"] as? String {
            switch align {
            case "center": textAlignment = .center
            case "right": textAlignment = .right
            case "justify": textAlignment = .justified
            default: textAlignment = .left
            }
        }
    }

    // MARK: - Word Count

    /// Extract plain text from WKWebView editor for word count
    func getTextContent() async -> String {
        guard let webView else { return "" }
        do {
            let result = try await webView.evaluateJavaScript("getTextContent()")
            return result as? String ?? ""
        } catch {
            print("[STWebEditor] getTextContent error: \(error.localizedDescription)")
            return ""
        }
    }

    // MARK: - Find / Replace

    /// Find all occurrences of term, return match count
    func findInContent(_ term: String, caseSensitive: Bool) async -> Int {
        guard let webView else { return 0 }
        let escaped = term
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
        do {
            let result = try await webView.evaluateJavaScript(
                "findInContent('\(escaped)', \(caseSensitive))"
            )
            if let num = result as? Int { return num }
            if let num = result as? Double { return Int(num) }
            if let num = result as? NSNumber { return num.intValue }
            return 0
        } catch {
            print("[STWebEditor] findInContent error: \(error.localizedDescription)")
            return 0
        }
    }

    /// Move to next match
    func findNext() {
        evaluateJS("findNext()")
    }

    /// Move to previous match
    func findPrevious() {
        evaluateJS("findPrevious()")
    }

    /// Replace current match, return remaining count
    func replaceCurrent(with replacement: String) async -> Int {
        guard let webView else { return 0 }
        let escaped = replacement
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
        do {
            let result = try await webView.evaluateJavaScript(
                "replaceCurrent('\(escaped)')"
            )
            if let num = result as? Int { return num }
            if let num = result as? Double { return Int(num) }
            if let num = result as? NSNumber { return num.intValue }
            return 0
        } catch {
            print("[STWebEditor] replaceCurrent error: \(error.localizedDescription)")
            return 0
        }
    }

    /// Replace all matches, return count of replacements
    func replaceAll(with replacement: String) async -> Int {
        guard let webView else { return 0 }
        let escaped = replacement
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
        do {
            let result = try await webView.evaluateJavaScript(
                "replaceAll('\(escaped)')"
            )
            if let num = result as? Int { return num }
            if let num = result as? Double { return Int(num) }
            if let num = result as? NSNumber { return num.intValue }
            return 0
        } catch {
            print("[STWebEditor] replaceAll error: \(error.localizedDescription)")
            return 0
        }
    }

    /// Clear all find highlights
    func clearFindHighlights() {
        evaluateJS("clearFindHighlights()")
    }

    // MARK: - Navigation

    func scrollToTop() { evaluateJS("scrollToTop()") }
    func scrollToBottom() { evaluateJS("scrollToBottom()") }

    // MARK: - Selection Save/Restore (used before alerts that steal focus)

    func saveSelection() { evaluateJS("saveSelection()") }

    // MARK: - Track Changes

    @Published var isTrackChangesEnabled: Bool = false

    func toggleTrackChanges() {
        isTrackChangesEnabled.toggle()
        evaluateJS("setTrackChanges(\(isTrackChangesEnabled ? "true" : "false"))")
    }

    func acceptAllChanges() { evaluateJS("acceptAllChanges()") }
    func rejectAllChanges() { evaluateJS("rejectAllChanges()") }

    // MARK: - Settings

    /// Set editor font size in points
    func setEditorFontSize(_ sizePt: Int) {
        evaluateJS("setEditorFontSize(\(sizePt))")
    }

    /// Set editor background color
    func setEditorBackgroundColor(_ hex: String) {
        evaluateJS("setEditorBackgroundColor('\(hex)')")
    }

    // MARK: - Select Mode

    /// Toggle select/hand mode for table selection & resize
    func setSelectMode(_ enabled: Bool) {
        isSelectMode = enabled
        evaluateJS("setSelectMode(\(enabled))")
        if enabled {
            // Dismiss keyboard
            webView?.resignFirstResponder()
        }
    }

    // MARK: - Private

    private func evaluateJS(_ js: String) {
        webView?.evaluateJavaScript(js) { _, error in
            if let error {
                print("[STWebEditor] JS error: \(error.localizedDescription)")
            }
        }
    }

    /// Like evaluateJS but prefixes with prepareForFormat() so cursor is restored
    /// to active table cell before the command runs (fixes typing-outside-table bug)
    private func evaluateFormatJS(_ js: String) {
        evaluateJS("prepareForFormat(); \(js)")
    }
}

// MARK: - PlatformColor Hex Extension

private extension PlatformColor {
    func toHexString() -> String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        #if os(macOS)
        let color = usingColorSpace(.sRGB) ?? self
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        #else
        getRed(&r, green: &g, blue: &b, alpha: &a)
        #endif
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}
