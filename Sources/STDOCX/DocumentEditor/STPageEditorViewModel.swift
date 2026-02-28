import SwiftUI
import STKit
import PDFKit
import STKit
import Combine

/// Page format options for new pages
enum STPageFormat: String, CaseIterable, Identifiable {
    case a4 = "A4"
    case letter = "Letter"
    case legal = "Legal"
    case a3 = "A3"
    case a5 = "A5"
    case b5 = "B5"

    var id: String { rawValue }

    var size: CGSize {
        switch self {
        case .a4: return CGSize(width: 595, height: 842)
        case .letter: return CGSize(width: 612, height: 792)
        case .legal: return CGSize(width: 612, height: 1008)
        case .a3: return CGSize(width: 842, height: 1191)
        case .a5: return CGSize(width: 420, height: 595)
        case .b5: return CGSize(width: 499, height: 709)
        }
    }
}

/// Page color options for new pages
enum STPageColor: CaseIterable, Identifiable {
    case white
    case cream
    case gray

    var id: String { displayName }

    var displayName: String {
        switch self {
        case .white: return STStrings.pageColorWhite
        case .cream: return STStrings.pageColorCream
        case .gray: return STStrings.pageColorGray
        }
    }

    var color: PlatformColor {
        switch self {
        case .white: return .white
        case .cream: return PlatformColor(red: 0.98, green: 0.96, blue: 0.90, alpha: 1.0)
        case .gray: return PlatformColor(red: 0.93, green: 0.93, blue: 0.93, alpha: 1.0)
        }
    }
}

/// Clipboard entry for cut/copy pages
struct STPageClipboard {
    let pages: [PDFPage]
    let isCut: Bool
}

/// ViewModel for the page editor
@MainActor
final class STPageEditorViewModel: ObservableObject {

    let document: STDOCXDocument

    @Published var selectedPages: Set<Int> = []
    @Published var showAddPageSheet = false
    @Published var thumbnailRefreshID = UUID()
    @Published private(set) var currentPageCount: Int = 0

    // Page undo/redo
    @Published private(set) var canUndo = false
    @Published private(set) var canRedo = false

    private var undoStack: [PageAction] = []
    private var redoStack: [PageAction] = []
    private var clipboard: STPageClipboard?

    var hasClipboard: Bool { clipboard != nil }
    var hasSelection: Bool { !selectedPages.isEmpty }
    var allSelected: Bool { selectedPages.count == currentPageCount }

    init(document: STDOCXDocument) {
        self.document = document
        self.currentPageCount = document.pageCount
    }

    // MARK: - Page Actions

    enum PageAction {
        case insert(pageIndex: Int, pageData: Data)
        case remove(pageIndex: Int, pageData: Data)
        case rotate(pageIndex: Int, oldRotation: Int, newRotation: Int)
        case move(fromIndex: Int, toIndex: Int)
        case batch([PageAction])
    }

    // MARK: - Selection

    func toggleSelection(_ index: Int) {
        if selectedPages.contains(index) {
            selectedPages.remove(index)
        } else {
            selectedPages.insert(index)
        }
    }

    func selectAll() {
        if allSelected {
            selectedPages.removeAll()
        } else {
            selectedPages = Set(0..<document.pageCount)
        }
    }

    // MARK: - Operations

    func addBlankPage(count: Int, format: STPageFormat, color: STPageColor, afterPage: Int) {
        var actions: [PageAction] = []
        for i in 0..<count {
            let insertIndex = afterPage + 1 + i
            let page = createBlankPage(size: format.size, color: color.color)
            document.pdfDocument.insert(page, at: insertIndex)
            if let data = page.dataRepresentation {
                actions.append(.insert(pageIndex: insertIndex, pageData: data))
            }
        }
        if !actions.isEmpty {
            record(actions.count == 1 ? actions[0] : .batch(actions))
        }
        selectedPages.removeAll()
        refreshThumbnails()
    }

    func removeSelectedPages() {
        guard !selectedPages.isEmpty else { return }
        // Don't allow removing all pages
        guard selectedPages.count < document.pageCount else { return }

        let sortedIndices = selectedPages.sorted().reversed()
        var actions: [PageAction] = []

        for index in sortedIndices {
            guard let page = document.pdfDocument.page(at: index) else { continue }
            // dataRepresentation may be nil for in-memory rendered pages; use empty fallback for undo stack
            let data = page.dataRepresentation ?? Data()
            actions.append(.remove(pageIndex: index, pageData: data))
            document.pdfDocument.removePage(at: index)
        }

        if !actions.isEmpty {
            record(.batch(actions))
        }
        selectedPages.removeAll()
        refreshThumbnails()
    }

    func duplicateSelectedPages() {
        guard !selectedPages.isEmpty else { return }

        let sortedIndices = selectedPages.sorted()
        var actions: [PageAction] = []
        var offset = 0

        for index in sortedIndices {
            let sourceIndex = index + offset
            guard let page = document.pdfDocument.page(at: sourceIndex) else { continue }

            // Copy via dataRepresentation; fall back to rendering the page to a new PDF
            let copiedPage: PDFPage?
            if let data = page.dataRepresentation,
               let tempDoc = PDFDocument(data: data) {
                copiedPage = tempDoc.page(at: 0)
            } else {
                copiedPage = copyPageViaRendering(page)
            }

            if let copied = copiedPage {
                let insertIndex = sourceIndex + 1
                document.pdfDocument.insert(copied, at: insertIndex)
                let insertedData = copied.dataRepresentation ?? Data()
                actions.append(.insert(pageIndex: insertIndex, pageData: insertedData))
                offset += 1
            }
        }

        if !actions.isEmpty {
            record(.batch(actions))
        }
        selectedPages.removeAll()
        refreshThumbnails()
    }

    /// Renders a PDF page to a PlatformImage and wraps it in a new PDFPage.
    /// Used as a fallback when PDFPage.dataRepresentation is nil (in-memory pages).
    private func copyPageViaRendering(_ page: PDFPage) -> PDFPage? {
        let bounds = page.bounds(for: .mediaBox)
        guard bounds.width > 0, bounds.height > 0 else { return nil }
        let scale: CGFloat = 2
        let renderer = UIGraphicsImageRenderer(
            size: CGSize(width: bounds.width * scale, height: bounds.height * scale)
        )
        let image = renderer.image { ctx in
            let cgCtx = ctx.cgContext
            cgCtx.saveGState()
            cgCtx.scaleBy(x: scale, y: scale)
            cgCtx.translateBy(x: 0, y: bounds.height)
            cgCtx.scaleBy(x: 1, y: -1)
            page.draw(with: .mediaBox, to: cgCtx)
            cgCtx.restoreGState()
        }
        return PDFPage(image: image)
    }

    func rotateSelectedPages() {
        guard !selectedPages.isEmpty else { return }

        var actions: [PageAction] = []

        for index in selectedPages.sorted() {
            if let page = document.pdfDocument.page(at: index) {
                let oldRotation = page.rotation
                let newRotation = (oldRotation + 90) % 360
                page.rotation = newRotation
                actions.append(.rotate(pageIndex: index, oldRotation: oldRotation, newRotation: newRotation))
            }
        }

        if !actions.isEmpty {
            record(.batch(actions))
        }
        refreshThumbnails()
    }

    // MARK: - Cut / Copy / Paste

    func cutSelectedPages() {
        guard !selectedPages.isEmpty else { return }
        guard selectedPages.count < document.pageCount else { return }

        let sortedIndices = selectedPages.sorted()
        var copiedPages: [PDFPage] = []

        for index in sortedIndices {
            if let page = document.pdfDocument.page(at: index),
               let data = page.dataRepresentation,
               let tempDoc = PDFDocument(data: data),
               let copiedPage = tempDoc.page(at: 0) {
                copiedPages.append(copiedPage)
            }
        }

        clipboard = STPageClipboard(pages: copiedPages, isCut: true)

        // Remove original pages
        var actions: [PageAction] = []
        for index in sortedIndices.reversed() {
            if let page = document.pdfDocument.page(at: index),
               let data = page.dataRepresentation {
                actions.append(.remove(pageIndex: index, pageData: data))
                document.pdfDocument.removePage(at: index)
            }
        }

        if !actions.isEmpty {
            record(.batch(actions))
        }
        selectedPages.removeAll()
        refreshThumbnails()
    }

    func copySelectedPages() {
        guard !selectedPages.isEmpty else { return }

        let sortedIndices = selectedPages.sorted()
        var copiedPages: [PDFPage] = []

        for index in sortedIndices {
            if let page = document.pdfDocument.page(at: index),
               let data = page.dataRepresentation,
               let tempDoc = PDFDocument(data: data),
               let copiedPage = tempDoc.page(at: 0) {
                copiedPages.append(copiedPage)
            }
        }

        clipboard = STPageClipboard(pages: copiedPages, isCut: false)
    }

    func paste() {
        guard let clipboard else { return }

        // Insert after the last selected page, or at the end
        let insertAfter = selectedPages.max() ?? (document.pageCount - 1)

        var actions: [PageAction] = []
        for (i, page) in clipboard.pages.enumerated() {
            let insertIndex = insertAfter + 1 + i
            // Create a fresh copy
            if let data = page.dataRepresentation,
               let tempDoc = PDFDocument(data: data),
               let freshPage = tempDoc.page(at: 0) {
                document.pdfDocument.insert(freshPage, at: insertIndex)
                actions.append(.insert(pageIndex: insertIndex, pageData: data))
            }
        }

        if !actions.isEmpty {
            record(.batch(actions))
        }

        // Clear clipboard if it was a cut
        if clipboard.isCut {
            self.clipboard = nil
        }

        selectedPages.removeAll()
        refreshThumbnails()
    }

    // MARK: - Undo / Redo

    func undo() {
        guard let action = undoStack.popLast() else { return }
        let reversed = reverseAction(action)
        applyAction(reversed, isUndo: true)
        redoStack.append(action)
        updateUndoState()
        refreshThumbnails()
    }

    func redo() {
        guard let action = redoStack.popLast() else { return }
        applyAction(action, isUndo: false)
        undoStack.append(action)
        updateUndoState()
        refreshThumbnails()
    }

    // MARK: - Private Helpers

    private func createBlankPage(size: CGSize, color: PlatformColor) -> PDFPage {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            color.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
        let page = PDFPage(image: image) ?? PDFPage()
        return page
    }

    private func record(_ action: PageAction) {
        undoStack.append(action)
        redoStack.removeAll()
        updateUndoState()
    }

    private func updateUndoState() {
        canUndo = !undoStack.isEmpty
        canRedo = !redoStack.isEmpty
    }

    private func reverseAction(_ action: PageAction) -> PageAction {
        switch action {
        case .insert(let pageIndex, let pageData):
            return .remove(pageIndex: pageIndex, pageData: pageData)
        case .remove(let pageIndex, let pageData):
            return .insert(pageIndex: pageIndex, pageData: pageData)
        case .rotate(let pageIndex, let oldRotation, let newRotation):
            return .rotate(pageIndex: pageIndex, oldRotation: newRotation, newRotation: oldRotation)
        case .move(let fromIndex, let toIndex):
            return .move(fromIndex: toIndex, toIndex: fromIndex)
        case .batch(let actions):
            return .batch(actions.reversed().map { reverseAction($0) })
        }
    }

    private func applyAction(_ action: PageAction, isUndo: Bool) {
        switch action {
        case .insert(let pageIndex, let pageData):
            if let tempDoc = PDFDocument(data: pageData),
               let page = tempDoc.page(at: 0) {
                let safeIndex = min(pageIndex, document.pdfDocument.pageCount)
                document.pdfDocument.insert(page, at: safeIndex)
            }
        case .remove(let pageIndex, _):
            if pageIndex < document.pdfDocument.pageCount {
                document.pdfDocument.removePage(at: pageIndex)
            }
        case .rotate(let pageIndex, _, let newRotation):
            if let page = document.pdfDocument.page(at: pageIndex) {
                page.rotation = newRotation
            }
        case .move(let fromIndex, let toIndex):
            if let page = document.pdfDocument.page(at: fromIndex) {
                document.pdfDocument.removePage(at: fromIndex)
                let safeIndex = min(toIndex, document.pdfDocument.pageCount)
                document.pdfDocument.insert(page, at: safeIndex)
            }
        case .batch(let actions):
            for a in actions {
                applyAction(a, isUndo: isUndo)
            }
        }
        selectedPages.removeAll()
    }

    func refreshThumbnails() {
        currentPageCount = document.pageCount
        thumbnailRefreshID = UUID()
    }
}
