import SwiftUI
import PDFKit
import Combine

/// View mode for the editor
enum STViewMode {
    case textEditor      // WKWebView (default)
    case annotations     // PDF viewer + draw overlays
}

/// Main ViewModel for the PDF editor
@MainActor
final class STDOCXEditorViewModel: ObservableObject {

    let document: STDOCXDocument
    let configuration: STDOCXConfiguration
    var viewerViewModel: STDOCXViewerViewModel
    let annotationManager: STAnnotationManager
    let serializer: STAnnotationSerializer
    let webEditorViewModel: STWebEditorViewModel
    @Published var viewMode: STViewMode = .textEditor
    @Published var isAnnotationToolbarVisible = false
    @Published var activeSheet: STSheetType?
    @Published var isPageStripVisible = true

    private var cancellables = Set<AnyCancellable>()

    init(document: STDOCXDocument, configuration: STDOCXConfiguration) {
        self.document = document
        self.configuration = configuration
        self.viewerViewModel = STDOCXViewerViewModel(document: document)
        self.annotationManager = STAnnotationManager(document: document)
        self.serializer = STAnnotationSerializer(document: document)
        self.webEditorViewModel = STWebEditorViewModel(document: document)

        // Forward annotation manager changes to trigger SwiftUI view updates
        annotationManager.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)

        // Forward document changes (e.g. async PDF update for DOC files)
        document.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)

        // Forward web editor changes (page navigation state for page strip)
        webEditorViewModel.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)

        // Forward viewer changes (thumbnail strip page selection → onChange sync)
        viewerViewModel.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    /// Load DOC file content via WebKit (called for legacy DOC files that need async rendering)
    func loadDocIfNeeded() async {
        guard document.isLoading else { return }
        await document.loadDocViaWebKit()
        viewerViewModel.refreshPageCount()
    }

    /// Re-render PDF after web editor save and refresh viewer
    func refreshAfterWebEditorSave() {
        viewerViewModel.refreshPageCount()
    }

    /// Sync and re-render PDF for draw/view modes
    func prepareForDrawMode() {
        viewerViewModel.refreshPageCount()
    }

    /// Toggle annotation mode
    func toggleAnnotationMode() {
        if viewMode == .annotations {
            viewMode = .textEditor
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
