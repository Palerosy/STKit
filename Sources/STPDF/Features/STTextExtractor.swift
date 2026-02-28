import PDFKit
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif
import STKit

/// Utility for extracting text from PDF documents
public enum STTextExtractor {

    /// Extract all text from a document
    public static func extractFullText(from document: PDFDocument) -> String {
        var text = ""
        for i in 0..<document.pageCount {
            if let pageText = document.page(at: i)?.string {
                if !text.isEmpty { text += "\n\n" }
                text += pageText
            }
        }
        return text
    }

    /// Extract text from a specific page
    public static func extractText(from document: PDFDocument, page index: Int) -> String? {
        document.page(at: index)?.string
    }

    /// Save extracted text to a temporary .txt file and return the URL
    public static func saveAsTextFile(from document: PDFDocument, title: String) -> URL? {
        let text = extractFullText(from: document)
        guard !text.isEmpty else { return nil }

        let fileName = "\(title).txt"
        guard let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else { return nil }
        let fileURL = cacheDir.appendingPathComponent(fileName)

        do {
            try text.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            return nil
        }
    }
}
