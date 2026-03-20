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
    @Published var hasUnsavedChanges = false
    @Published var showPaywall = false

    /// Original file data for revert (discard changes)
    private(set) var originalFileData: Data?

    private var cancellables = Set<AnyCancellable>()

    init(document: STDOCXDocument, configuration: STDOCXConfiguration) {
        self.document = document
        self.configuration = configuration
        self.viewerViewModel = STDOCXViewerViewModel(document: document)
        self.annotationManager = STAnnotationManager(document: document)
        self.serializer = STAnnotationSerializer(document: document)
        self.webEditorViewModel = STWebEditorViewModel(document: document)

        // Store original file data for revert
        if let url = document.url {
            self.originalFileData = try? Data(contentsOf: url)
        }

        // Track content dirty flag for unsaved changes
        webEditorViewModel.$isContentDirty
            .removeDuplicates()
            .sink { [weak self] dirty in self?.hasUnsavedChanges = dirty }
            .store(in: &cancellables)

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

    /// Revert the document to its original state (discard all changes)
    func revertToOriginal() {
        guard let url = document.url else { return }

        // Remove the _st_edited.html cache from the DOCX ZIP so
        // next open renders from the original document.xml
        do {
            let zipReader = ZIPReader()
            var entries = try zipReader.readAllEntries(at: url)
            if entries.removeValue(forKey: "_st_edited.html") != nil {
                let zipWriter = ZIPWriter()
                try zipWriter.createDocX(at: url, contents: entries)
            }
        } catch {
            // Fallback: overwrite with original data
            if let data = originalFileData {
                try? data.write(to: url)
            }
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
