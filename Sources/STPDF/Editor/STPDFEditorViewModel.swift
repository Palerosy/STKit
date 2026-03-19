import SwiftUI
import PDFKit
import Combine

/// View mode for the editor
enum STViewMode {
    case viewer
    case annotations
    case documentEditor
}

/// Main ViewModel for the PDF editor
@MainActor
final class STPDFEditorViewModel: ObservableObject {

    let document: STPDFDocument
    let configuration: STPDFConfiguration
    var viewerViewModel: STPDFViewerViewModel
    let annotationManager: STAnnotationManager
    let serializer: STAnnotationSerializer
    let pageEditorViewModel: STPageEditorViewModel

    @Published var viewMode: STViewMode = .viewer
    @Published var isAnnotationToolbarVisible = false
    @Published var activeSheet: STSheetType?
    @Published var isPageStripVisible = true

    // Ribbon state
    @Published var ribbonSelectedTab: STPDFRibbonTab = .view
    @Published var isRibbonCollapsed = false
    @Published var hasUnsavedChanges = false
    @Published var showPaywall = false
    @Published var isSaving = false

    /// Backup of original PDF data for discard/revert
    private(set) var originalPDFData: Data?

    private var cancellables = Set<AnyCancellable>()

    init(document: STPDFDocument, configuration: STPDFConfiguration, openInPageEditor: Bool = false) {
        self.document = document
        self.configuration = configuration
        self.viewerViewModel = STPDFViewerViewModel(document: document)
        self.annotationManager = STAnnotationManager(document: document)
        self.serializer = STAnnotationSerializer(document: document)
        self.pageEditorViewModel = STPageEditorViewModel(document: document)
        self.originalPDFData = document.pdfDocument.dataRepresentation()

        if openInPageEditor {
            viewMode = .documentEditor
        }

        // Forward annotation manager changes to trigger SwiftUI view updates
        annotationManager.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)

        // Track annotation changes → set hasUnsavedChanges
        annotationManager.undoManager.$canUndo
            .removeDuplicates()
            .filter { $0 }
            .sink { [weak self] _ in
                self?.hasUnsavedChanges = true
            }
            .store(in: &cancellables)

        // Track page editor changes → set hasUnsavedChanges
        pageEditorViewModel.$canUndo
            .removeDuplicates()
            .filter { $0 }
            .sink { [weak self] _ in
                self?.hasUnsavedChanges = true
            }
            .store(in: &cancellables)
    }

    /// Toggle annotation mode
    func toggleAnnotationMode() {
        if viewMode == .annotations {
            viewMode = .viewer
            isAnnotationToolbarVisible = false
            annotationManager.deactivate()
        } else {
            viewMode = .annotations
            isAnnotationToolbarVisible = true
            serializer.startAutoSave()
        }
    }

    /// Enter annotation mode and activate a specific tool
    func activateAnnotationTool(_ tool: STAnnotationType) {
        if viewMode != .annotations {
            viewMode = .annotations
            isAnnotationToolbarVisible = true
            serializer.startAutoSave()
        }
        annotationManager.setTool(tool)
    }

    /// Revert document to its original state (before any edits)
    func revertToOriginal() {
        guard let data = originalPDFData,
              let freshDoc = PDFDocument(data: data),
              let url = document.url else { return }

        // Remove all current pages
        while document.pdfDocument.pageCount > 0 {
            document.pdfDocument.removePage(at: 0)
        }
        // Re-insert from backup
        for i in 0..<freshDoc.pageCount {
            if let page = freshDoc.page(at: i) {
                document.pdfDocument.insert(page, at: i)
            }
        }
        // Write reverted document back to disk (overwrite any auto-saved changes)
        document.pdfDocument.write(to: url)
    }

    /// Save document with a progress overlay. Shows spinner, gives SwiftUI
    /// one run loop cycle to render it, then performs the (blocking) save.
    func saveAsync(completion: @escaping () -> Void) {
        isSaving = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [self] in
            document.save()
            serializer.save()
            isSaving = false
            completion()
        }
    }

    /// Revert document with a progress overlay.
    func revertAsync(completion: @escaping () -> Void) {
        isSaving = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [self] in
            serializer.stopAutoSave()
            revertToOriginal()
            isSaving = false
            completion()
        }
    }

    /// Highlight a search selection on the PDFView, then clear after delay
    func highlightSearchResult(_ selection: PDFSelection) {
        guard let pdfView = annotationManager.pdfView else { return }
        selection.color = .yellow
        pdfView.highlightedSelections = [selection]
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            pdfView.highlightedSelections = nil
        }
    }
}
