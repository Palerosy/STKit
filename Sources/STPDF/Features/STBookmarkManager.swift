import Foundation

/// Manages page bookmarks for documents, persisted per document URL
@MainActor
final class STBookmarkManager: ObservableObject {

    @Published var bookmarks: Set<Int> = []

    private let documentKey: String

    init(documentURL: URL?) {
        self.documentKey = documentURL?.lastPathComponent ?? "unknown"
        loadBookmarks()
    }

    func isBookmarked(_ pageIndex: Int) -> Bool {
        bookmarks.contains(pageIndex)
    }

    func toggleBookmark(_ pageIndex: Int) {
        if bookmarks.contains(pageIndex) {
            bookmarks.remove(pageIndex)
        } else {
            bookmarks.insert(pageIndex)
        }
        saveBookmarks()
    }

    var sortedBookmarks: [Int] {
        bookmarks.sorted()
    }

    // MARK: - Persistence

    private var storageKey: String {
        "STPDFKit_bookmarks_\(documentKey)"
    }

    private func loadBookmarks() {
        if let array = UserDefaults.standard.array(forKey: storageKey) as? [Int] {
            bookmarks = Set(array)
        }
    }

    private func saveBookmarks() {
        UserDefaults.standard.set(Array(bookmarks), forKey: storageKey)
    }
}
