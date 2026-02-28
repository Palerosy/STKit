import Foundation
import STKit

/// Represents a plain text document
public final class STTXTDocument: STDocument {

    /// The text content
    public var text: String

    public let sourceURL: URL?
    public let title: String

    public var plainText: String { text }

    // MARK: - Init

    /// Create from a URL
    public init?(url: URL, title: String? = nil, encoding: String.Encoding = .utf8) {
        guard let content = try? String(contentsOf: url, encoding: encoding) else { return nil }
        self.text = content
        self.sourceURL = url
        self.title = title ?? url.deletingPathExtension().lastPathComponent
    }

    /// Create blank
    public init(title: String = "Untitled", text: String = "") {
        self.text = text
        self.sourceURL = nil
        self.title = title
    }

    /// Get stats
    public var stats: STDocumentStats {
        STDocumentStats(from: text)
    }

    // MARK: - Save

    @discardableResult
    public func save(to url: URL, encoding: String.Encoding = .utf8) -> Bool {
        do {
            try text.write(to: url, atomically: true, encoding: encoding)
            return true
        } catch {
            return false
        }
    }
}
