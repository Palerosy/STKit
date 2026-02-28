import PDFKit
import Combine

/// Handles saving annotated PDFs with auto-save support
@MainActor
final class STAnnotationSerializer: ObservableObject {
    
    private let document: STPDFDocument
    private var autoSaveTimer: AnyCancellable?
    private var autoSaveInterval: TimeInterval
    
    @Published private(set) var isSaving = false
    @Published private(set) var lastSaveDate: Date?
    
    init(document: STPDFDocument, autoSaveInterval: TimeInterval = 30.0) {
        self.document = document
        self.autoSaveInterval = autoSaveInterval
    }
    
    /// Start auto-save timer
    func startAutoSave() {
        autoSaveTimer = Timer.publish(every: autoSaveInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.save()
            }
    }
    
    /// Stop auto-save timer
    func stopAutoSave() {
        autoSaveTimer?.cancel()
        autoSaveTimer = nil
    }
    
    /// Save the document
    func save() {
        guard !isSaving else { return }
        isSaving = true
        
        document.save()
        lastSaveDate = Date()
        isSaving = false
    }
}
