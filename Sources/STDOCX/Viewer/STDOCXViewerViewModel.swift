import SwiftUI
import PDFKit

/// Which sheet is currently presented — using a single enum prevents
/// the SwiftUI bug where multiple `.sheet(isPresented:)` modifiers
/// cause sheets to reopen after dismissal.
enum STSheetType: String, Identifiable {
    case thumbnails
    case search
    case outline
    case settings
    case wordCount

    var id: String { rawValue }
}

/// ViewModel for the PDF viewer
@MainActor
final class STDOCXViewerViewModel: ObservableObject {

    let document: STDOCXDocument

    @Published var currentPageIndex: Int = 0
    @Published var isBookmarkListVisible = false

    var totalPages: Int {
        document.pageCount
    }

    /// Current page label (e.g., "3 / 15")
    var pageLabel: String {
        "\(currentPageIndex + 1) / \(totalPages)"
    }

    init(document: STDOCXDocument) {
        self.document = document
    }

    func goToPage(_ index: Int) {
        guard index >= 0 && index < totalPages else { return }
        currentPageIndex = index
    }

    func nextPage() {
        goToPage(currentPageIndex + 1)
    }

    func previousPage() {
        goToPage(currentPageIndex - 1)
    }

    /// Refresh after page count changes (e.g. page editor operations)
    func refreshPageCount() {
        if currentPageIndex >= totalPages {
            currentPageIndex = max(0, totalPages - 1)
        }
        objectWillChange.send()
    }
}
