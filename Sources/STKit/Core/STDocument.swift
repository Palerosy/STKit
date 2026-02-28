import Foundation

/// Protocol that all STKit document types conform to
public protocol STDocument {
    /// The URL the document was loaded from (if any)
    var sourceURL: URL? { get }

    /// Display title for the document
    var title: String { get }

    /// Plain text content of the document
    var plainText: String { get }

    /// Word count
    var wordCount: Int { get }

    /// Character count (excluding spaces)
    var characterCount: Int { get }
}

/// Default implementations for common computed properties
public extension STDocument {
    var wordCount: Int {
        plainText.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).count
    }

    var characterCount: Int {
        plainText.filter { !$0.isWhitespace && !$0.isNewline }.count
    }
}

/// Statistics for a document
public struct STDocumentStats {
    public let words: Int
    public let characters: Int
    public let charactersWithSpaces: Int
    public let paragraphs: Int
    public let lines: Int

    public init(words: Int, characters: Int, charactersWithSpaces: Int, paragraphs: Int, lines: Int) {
        self.words = words
        self.characters = characters
        self.charactersWithSpaces = charactersWithSpaces
        self.paragraphs = paragraphs
        self.lines = lines
    }

    public init(from text: String) {
        self.words = text.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).count
        self.characters = text.filter { !$0.isWhitespace && !$0.isNewline }.count
        self.charactersWithSpaces = text.count
        self.paragraphs = text.components(separatedBy: .newlines).filter { !$0.isEmpty }.count
        self.lines = text.components(separatedBy: .newlines).count
    }
}
