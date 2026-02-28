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
    lazy var pageEditorViewModel = STPageEditorViewModel(document: document)

    @Published var viewMode: STViewMode = .viewer
    @Published var isAnnotationToolbarVisible = false
    @Published var activeSheet: STSheetType?
    @Published var isPageStripVisible = true

    // Ribbon state
    @Published var ribbonSelectedTab: STPDFRibbonTab = .view
    @Published var isRibbonCollapsed = false

    private var cancellables = Set<AnyCancellable>()

    init(document: STPDFDocument, configuration: STPDFConfiguration, openInPageEditor: Bool = false) {
        self.document = document
        self.configuration = configuration
        self.viewerViewModel = STPDFViewerViewModel(document: document)
        self.annotationManager = STAnnotationManager(document: document)
        self.serializer = STAnnotationSerializer(document: document)

        if openInPageEditor {
            viewMode = .documentEditor
        }

        // Forward annotation manager changes to trigger SwiftUI view updates
        annotationManager.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
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
