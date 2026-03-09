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

    /// Remove a sheet at the given index
    public func removeSheet(at index: Int) {
        guard sheets.count > 1, index < sheets.count else { return }
        sheets.remove(at: index)
        if activeSheetIndex >= sheets.count {
            activeSheetIndex = sheets.count - 1
        }
    }

    /// Add a new blank sheet
    public func addSheet() {
        let name = "Sheet \(sheets.count + 1)"
        sheets.append(STExcelSheet(name: name))
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

    /// Set cell style
    public func setCellStyle(row: Int, column: Int, style: STExcelCellStyle) {
        guard row < rowCount, column < columnCount else { return }
        cells[row][column].style = style
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

    // MARK: - Merged Regions

    public var mergedRegions: [STMergedRegion] = []

    /// Merge cells in the given range
    public func mergeCells(startRow: Int, startCol: Int, endRow: Int, endCol: Int) {
        let region = STMergedRegion(startRow: startRow, startCol: startCol, endRow: endRow, endCol: endCol)
        mergedRegions.append(region)
    }

    /// Unmerge cells at the given position
    public func unmergeCells(row: Int, col: Int) {
        mergedRegions.removeAll { $0.contains(row: row, col: col) }
    }

    /// Get the merged region containing the given cell, if any
    public func mergedRegion(for row: Int, col: Int) -> STMergedRegion? {
        mergedRegions.first { $0.contains(row: row, col: col) }
    }

    // MARK: - Row Operations

    /// Insert a blank row at the given index
    public func insertRow(at index: Int) {
        guard index <= rowCount else { return }
        let newRow = (0..<columnCount).map { _ in STExcelCell() }
        cells.insert(newRow, at: index)
    }

    /// Delete the row at the given index
    public func deleteRow(at index: Int) {
        guard index < rowCount, rowCount > 1 else { return }
        cells.remove(at: index)
    }

    // MARK: - Column Operations

    /// Insert a blank column at the given index
    public func insertColumn(at index: Int) {
        guard index <= columnCount else { return }
        for r in 0..<rowCount {
            cells[r].insert(STExcelCell(), at: index)
        }
    }

    /// Delete the column at the given index
    public func deleteColumn(at index: Int) {
        guard index < columnCount, columnCount > 1 else { return }
        for r in 0..<rowCount {
            cells[r].remove(at: index)
        }
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
    public var formula: String?
    public var comment: String?
    public var style: STExcelCellStyle = STExcelCellStyle()

    public init(value: String = "", isBold: Bool = false, formula: String? = nil, comment: String? = nil) {
        self.value = value
        self.isBold = isBold
        self.isNumeric = Double(value) != nil
        self.formula = formula
        self.comment = comment
    }
}
