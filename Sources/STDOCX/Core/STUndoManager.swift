import PDFKit

/// Tracks annotation operations for undo/redo support
@MainActor
final class STUndoManager: ObservableObject {
    
    /// A reversible annotation action
    enum Action {
        case add(annotation: PDFAnnotation, page: PDFPage)
        case remove(annotation: PDFAnnotation, page: PDFPage)
        case move(annotation: PDFAnnotation, page: PDFPage, oldBounds: CGRect)
        case replacePage(document: PDFDocument, pageIndex: Int, previousPage: PDFPage)
        case batch([Action])
    }
    
    @Published private(set) var canUndo = false
    @Published private(set) var canRedo = false
    
    private var undoStack: [Action] = []
    private var redoStack: [Action] = []
    
    /// Record an action and clear redo stack
    func record(_ action: Action) {
        undoStack.append(action)
        redoStack.removeAll()
        updateState()
    }
    
    /// Undo the last action
    func undo() {
        guard let action = undoStack.popLast() else { return }
        let reversed = reverseAction(action)
        apply(reversed)
        redoStack.append(action)
        updateState()
    }
    
    /// Redo the last undone action
    func redo() {
        guard let action = redoStack.popLast() else { return }
        apply(action)
        undoStack.append(action)
        updateState()
    }
    
    /// Clear all history
    func clear() {
        undoStack.removeAll()
        redoStack.removeAll()
        updateState()
    }
    
    private func reverseAction(_ action: Action) -> Action {
        switch action {
        case .add(let annotation, let page):
            return .remove(annotation: annotation, page: page)
        case .remove(let annotation, let page):
            return .add(annotation: annotation, page: page)
        case .move(let annotation, let page, _):
            let currentBounds = annotation.bounds
            return .move(annotation: annotation, page: page, oldBounds: currentBounds)
        case .replacePage(let document, let pageIndex, _):
            if let currentPage = document.page(at: pageIndex) {
                return .replacePage(document: document, pageIndex: pageIndex, previousPage: currentPage)
            }
            return action
        case .batch(let actions):
            return .batch(actions.reversed().map { reverseAction($0) })
        }
    }

    private func apply(_ action: Action) {
        switch action {
        case .add(let annotation, let page):
            page.addAnnotation(annotation)
        case .remove(let annotation, let page):
            page.removeAnnotation(annotation)
        case .move(let annotation, _, let oldBounds):
            annotation.bounds = oldBounds
        case .replacePage(let document, let pageIndex, let previousPage):
            document.removePage(at: pageIndex)
            document.insert(previousPage, at: pageIndex)
        case .batch(let actions):
            for action in actions {
                apply(action)
            }
        }
    }
    
    private func updateState() {
        canUndo = !undoStack.isEmpty
        canRedo = !redoStack.isEmpty
    }
}
