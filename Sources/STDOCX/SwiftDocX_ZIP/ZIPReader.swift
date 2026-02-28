import Foundation
@_implementationOnly import ZIPFoundation

/// Error types for ZIP reading operations
public enum ZIPReaderError: Error, LocalizedError {
    case fileNotFound(String)
    case invalidArchive(String)
    case extractionFailed(String)
    case entryNotFound(String)

    public var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):
            return "File not found: \(path)"
        case .invalidArchive(let detail):
            return "Invalid ZIP archive: \(detail)"
        case .extractionFailed(let detail):
            return "Extraction failed: \(detail)"
        case .entryNotFound(let name):
            return "Entry not found in archive: \(name)"
        }
    }
}

/// Reads and extracts contents from .docx (ZIP) files
public class ZIPReader {

    public init() {}

    /// Reads data from a specific entry in the ZIP archive
    public func readEntry(at url: URL, entryPath: String) throws -> Data {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw ZIPReaderError.fileNotFound(url.path)
        }

        let archive: Archive
        do {
            archive = try Archive(url: url, accessMode: .read)
        } catch {
            throw ZIPReaderError.invalidArchive("Could not open archive at \(url.path): \(error.localizedDescription)")
        }

        guard let entry = archive[entryPath] else {
            throw ZIPReaderError.entryNotFound(entryPath)
        }

        var data = Data()
        do {
            _ = try archive.extract(entry) { chunk in
                data.append(chunk)
            }
        } catch {
            throw ZIPReaderError.extractionFailed(error.localizedDescription)
        }

        return data
    }

    /// Lists all entries in the ZIP archive
    public func listEntries(at url: URL) throws -> [String] {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw ZIPReaderError.fileNotFound(url.path)
        }

        let archive: Archive
        do {
            archive = try Archive(url: url, accessMode: .read)
        } catch {
            throw ZIPReaderError.invalidArchive("Could not open archive at \(url.path): \(error.localizedDescription)")
        }

        return archive.map { $0.path }
    }

    /// Checks if an entry exists in the archive
    public func entryExists(at url: URL, entryPath: String) throws -> Bool {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw ZIPReaderError.fileNotFound(url.path)
        }

        let archive: Archive
        do {
            archive = try Archive(url: url, accessMode: .read)
        } catch {
            throw ZIPReaderError.invalidArchive("Could not open archive at \(url.path): \(error.localizedDescription)")
        }

        return archive[entryPath] != nil
    }
}
