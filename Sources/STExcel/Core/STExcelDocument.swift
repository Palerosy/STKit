import Foundation
import STKit

/// Represents a spreadsheet document with multiple sheets
public final class STExcelDocument: STDocument {

    /// All sheets in the workbook
    public private(set) var sheets: [STExcelSheet]

    /// Currently active sheet index
    public var activeSheetIndex: Int = 0

    /// The active sheet
    public var activeSheet: STExcelSheet {
        sheets[activeSheetIndex]
    }

    public let sourceURL: URL?
    public let title: String

    public var plainText: String {
        activeSheet.toCSV()
    }

    // MARK: - Init

    /// Create from an xlsx URL
    public init?(url: URL, title: String? = nil) {
        guard let parsed = STExcelReader.read(url: url) else { return nil }
        self.sheets = parsed
        self.sourceURL = url
        self.title = title ?? url.deletingPathExtension().lastPathComponent
    }

    /// Create a blank spreadsheet
    public init(title: String = "Untitled", rows: Int = 100, columns: Int = 26) {
        self.sheets = [STExcelSheet(name: "Sheet 1", rows: rows, columns: columns)]
        self.sourceURL = nil
        self.title = title
    }

    /// Get document statistics
    public var stats: STDocumentStats {
        let text = activeSheet.toCSV()
        return STDocumentStats(from: text)
    }

    // MARK: - Save

    /// Save as xlsx
    @discardableResult
    public func save(to url: URL) -> Bool {
        STExcelWriter.write(sheets: sheets, to: url)
    }

    /// Export as CSV
    @discardableResult
    public func exportAsCSV(to url: URL) -> Bool {
        do {
            try activeSheet.toCSV().write(to: url, atomically: true, encoding: .utf8)
            return true
        } catch {
            return false
        }
    }
}

/// Represents a single sheet in a workbook
public class STExcelSheet: Identifiable, ObservableObject {
    public let id = UUID()
    public var name: String

    /// 2D array of cell values [row][column]
    @Published public var cells: [[STExcelCell]]

    /// Number of rows
    public var rowCount: Int { cells.count }

    /// Number of columns
    public var columnCount: Int { cells.first?.count ?? 0 }

    public init(name: String, rows: Int = 100, columns: Int = 26) {
        self.name = name
        self.cells = (0..<rows).map { _ in
            (0..<columns).map { _ in STExcelCell() }
        }
    }

    public init(name: String, cells: [[STExcelCell]]) {
        self.name = name
        self.cells = cells
    }

    /// Get cell value
    public func cell(row: Int, column: Int) -> STExcelCell {
        guard row < rowCount, column < columnCount else { return STExcelCell() }
        return cells[row][column]
    }

    /// Set cell value
    public func setCell(row: Int, column: Int, value: String) {
        guard row < rowCount, column < columnCount else { return }
        cells[row][column].value = value
    }

    /// Convert to CSV string
    public func toCSV(separator: String = ",") -> String {
        cells.map { row in
            row.map { cell in
                let val = cell.value
                if val.contains(separator) || val.contains("\"") || val.contains("\n") {
                    return "\"\(val.replacingOccurrences(of: "\"", with: "\"\""))\""
                }
                return val
            }.joined(separator: separator)
        }.joined(separator: "\n")
    }

    /// Column header letter (A, B, C, ... Z, AA, AB, ...)
    public static func columnLetter(_ index: Int) -> String {
        var result = ""
        var n = index
        repeat {
            result = String(UnicodeScalar(65 + (n % 26))!) + result
            n = n / 26 - 1
        } while n >= 0
        return result
    }
}

/// Represents a single cell in a spreadsheet
public struct STExcelCell {
    public var value: String
    public var isBold: Bool
    public var isNumeric: Bool

    public init(value: String = "", isBold: Bool = false) {
        self.value = value
        self.isBold = isBold
        self.isNumeric = Double(value) != nil
    }
}
