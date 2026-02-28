import Foundation
@_implementationOnly import ZIPFoundation

/// Error types for ZIP writing operations
public enum ZIPWriterError: Error, LocalizedError {
    case creationFailed(String)
    case writeFailed(String)
    case invalidPath(String)

    public var errorDescription: String? {
        switch self {
        case .creationFailed(let detail):
            return "Failed to create ZIP archive: \(detail)"
        case .writeFailed(let detail):
            return "Failed to write to ZIP archive: \(detail)"
        case .invalidPath(let path):
            return "Invalid path: \(path)"
        }
    }
}

/// Creates .docx (ZIP) files with the required structure
public class ZIPWriter {

    public init() {}

    /// Creates a .docx file with the provided file contents
    /// - Parameters:
    ///   - url: Destination URL for the .docx file
    ///   - contents: Dictionary mapping entry paths to their data
    public func createDocX(at url: URL, contents: [String: Data]) throws {
        // Remove existing file if present
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }

        // Create archive
        let archive: Archive
        do {
            archive = try Archive(url: url, accessMode: .create)
        } catch {
            throw ZIPWriterError.creationFailed("Could not create archive at \(url.path): \(error.localizedDescription)")
        }

        // Sort entries to ensure directories are created in order
        let sortedPaths = contents.keys.sorted()

        for path in sortedPaths {
            guard let data = contents[path] else { continue }

            do {
                try archive.addEntry(
                    with: path,
                    type: .file,
                    uncompressedSize: Int64(data.count),
                    compressionMethod: .deflate,
                    provider: { position, size in
                        let start = Int(position)
                        let end = min(start + size, data.count)
                        return data.subdata(in: start..<end)
                    }
                )
            } catch {
                throw ZIPWriterError.writeFailed("Failed to add entry '\(path)': \(error.localizedDescription)")
            }
        }
    }
}
