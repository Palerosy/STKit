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

    /// Defined names (workbook level)
    var definedNames: [String: String] = [:]

    public var plainText: String {
        activeSheet.toCSV()
    }

    // MARK: - Init

    /// Create from an xlsx or csv URL
    /// Tries XLSX first (regardless of extension), falls back to CSV/TSV parsing.
    /// This allows files originally imported as CSV but later saved as XLSX to reopen correctly.
    public init?(url: URL, title: String? = nil) {
        // 1. Try XLSX parse first (works for any extension if content is XLSX)
        if let parsed = STExcelReader.read(url: url) {
            self.sheets = parsed
        }
        // 2. Fall back to CSV/TSV text parsing
        else if let text = try? String(contentsOf: url, encoding: .utf8),
                !text.isEmpty,
                text.utf8.count < 50_000_000 {
            let ext = url.pathExtension.lowercased()
            let separator: Character = ext == "tsv" ? "\t" : ","
            let rows = text.components(separatedBy: .newlines).filter { !$0.isEmpty }
            var cells: [[STExcelCell]] = []
            var maxCols = 0
            for row in rows {
                let values = STExcelDocument.parseCSVRow(row, separator: separator)
                maxCols = max(maxCols, values.count)
                cells.append(values.map { STExcelCell(value: $0) })
            }
            // Pad rows to uniform column count
            for i in 0..<cells.count {
                while cells[i].count < maxCols {
                    cells[i].append(STExcelCell(value: ""))
                }
            }
            let sheet = STExcelSheet(name: "Sheet 1", cells: cells)
            self.sheets = [sheet]
        } else {
            return nil
        }
        self.sourceURL = url
        self.title = title ?? url.deletingPathExtension().lastPathComponent
    }

    /// Parse a single CSV row handling quoted fields
    private static func parseCSVRow(_ row: String, separator: Character) -> [String] {
        var fields: [String] = []
        var current = ""
        var inQuotes = false
        var i = row.startIndex
        while i < row.endIndex {
            let c = row[i]
            if inQuotes {
                if c == "\"" {
                    let next = row.index(after: i)
                    if next < row.endIndex && row[next] == "\"" {
                        current.append("\"")
                        i = row.index(after: next)
                        continue
                    } else {
                        inQuotes = false
                    }
                } else {
                    current.append(c)
                }
            } else {
                if c == "\"" {
                    inQuotes = true
                } else if c == separator {
                    fields.append(current)
                    current = ""
                } else {
                    current.append(c)
                }
            }
            i = row.index(after: i)
        }
        fields.append(current)
        return fields
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

    // MARK: - Sheet Management

    /// Add a new empty sheet
    public func addSheet(name: String? = nil) {
        let sheetName = name ?? "Sheet \(sheets.count + 1)"
        let cols = sheets.first?.columnCount ?? 26
        sheets.append(STExcelSheet(name: sheetName, rows: 100, columns: cols))
    }

    /// Remove sheet at index
    public func removeSheet(at index: Int) {
        guard sheets.count > 1, index < sheets.count else { return }
        sheets.remove(at: index)
        if activeSheetIndex >= sheets.count {
            activeSheetIndex = sheets.count - 1
        }
    }

    /// Rename sheet at index
    public func renameSheet(at index: Int, to name: String) {
        guard index < sheets.count else { return }
        sheets[index].name = name
    }

    /// Duplicate sheet at index
    public func duplicateSheet(at index: Int) {
        guard index < sheets.count else { return }
        let source = sheets[index]
        let newCells = source.cells.map { row in row.map { $0 } }
        let copy = STExcelSheet(name: "\(source.name) (2)", cells: newCells)
        copy.mergedRegions = source.mergedRegions
        copy.columnWidths = source.columnWidths
        copy.rowHeights = source.rowHeights
        copy.images = source.images
        copy.shapes = source.shapes
        copy.frozenRows = source.frozenRows
        copy.frozenCols = source.frozenCols
        copy.charts = source.charts
        copy.tables = source.tables
        copy.conditionalRules = source.conditionalRules
        copy.dataValidations = source.dataValidations
        copy.isProtected = source.isProtected
        copy.hiddenRows = source.hiddenRows
        copy.groupedRows = source.groupedRows
        copy.collapsedGroups = source.collapsedGroups
        sheets.insert(copy, at: index + 1)
    }

    /// Move sheet from one index to another
    public func moveSheet(from source: Int, to destination: Int) {
        guard source < sheets.count, destination <= sheets.count, source != destination else { return }
        let sheet = sheets.remove(at: source)
        let insertAt = destination > source ? destination - 1 : destination
        sheets.insert(sheet, at: insertAt)
        activeSheetIndex = insertAt
    }

    // MARK: - Save

    /// Save as xlsx
    @discardableResult
    public func save(to url: URL) -> Bool {
        STExcelWriter.write(sheets: sheets, to: url, definedNames: definedNames)
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

    /// Merged cell regions
    public var mergedRegions: [STMergedRegion] = []

    /// Column widths (index → width in points); nil means default
    public var columnWidths: [Int: CGFloat] = [:]

    /// Row heights (index → height in points); nil means default
    public var rowHeights: [Int: CGFloat] = [:]

    /// Embedded images on this sheet
    public var images: [STExcelEmbeddedImage] = []

    /// Embedded shapes on this sheet
    public var shapes: [STExcelEmbeddedShape] = []

    /// Frozen rows (pane split)
    public var frozenRows: Int = 0
    /// Frozen columns (pane split)
    public var frozenCols: Int = 0

    /// Embedded charts on this sheet
    var charts: [STExcelEmbeddedChart] = []

    /// Formatted tables
    var tables: [STExcelTable] = []

    /// Conditional formatting rules
    var conditionalRules: [STExcelConditionalRule] = []

    /// Data validation rules keyed by "row,col"
    var dataValidations: [String: STExcelDataValidation] = [:]

    /// Sheet protection
    var isProtected: Bool = false

    /// Auto-filter hidden rows
    var hiddenRows: Set<Int> = []

    /// Row grouping
    var groupedRows: Set<Int> = []
    var collapsedGroups: Set<Int> = []

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
        guard row >= 0, column >= 0, row < cells.count, column < cells[row].count else { return STExcelCell() }
        return cells[row][column]
    }

    /// Set cell value
    public func setCell(row: Int, column: Int, value: String) {
        guard row >= 0, column >= 0, row < cells.count, column < cells[row].count else { return }
        cells[row][column].value = value
    }

    /// Set cell style
    public func setCellStyle(row: Int, column: Int, style: STExcelCellStyle) {
        guard row >= 0, column >= 0, row < cells.count, column < cells[row].count else { return }
        cells[row][column].style = style
    }

    /// Apply style to a range of cells
    public func applyStyleToRange(startRow: Int, startCol: Int, endRow: Int, endCol: Int,
                                  transform: (inout STExcelCellStyle) -> Void) {
        for r in max(0, startRow)...min(endRow, rowCount - 1) {
            guard r < cells.count else { continue }
            for c in max(0, startCol)...min(endCol, cells[r].count - 1) {
                transform(&cells[r][c].style)
            }
        }
    }

    /// Merge cells in a range
    public func mergeCells(startRow: Int, startCol: Int, endRow: Int, endCol: Int) {
        let region = STMergedRegion(startRow: startRow, startCol: startCol,
                                    endRow: endRow, endCol: endCol)
        // Remove overlapping merges
        mergedRegions.removeAll { existing in
            existing.contains(row: startRow, col: startCol) ||
            region.contains(row: existing.startRow, col: existing.startCol)
        }
        mergedRegions.append(region)
    }

    /// Unmerge cells containing the given position
    public func unmergeCells(row: Int, col: Int) {
        mergedRegions.removeAll { $0.contains(row: row, col: col) }
    }

    /// Find the merged region containing a cell, if any
    public func mergedRegion(for row: Int, col: Int) -> STMergedRegion? {
        mergedRegions.first { $0.contains(row: row, col: col) }
    }

    // MARK: - Row/Column Operations

    /// Insert a row at the given index
    public func insertRow(at index: Int) {
        guard index <= rowCount else { return }
        let newRow = (0..<columnCount).map { _ in STExcelCell() }
        cells.insert(newRow, at: index)
        // Shift merged regions
        mergedRegions = mergedRegions.map { region in
            if region.startRow >= index {
                return STMergedRegion(startRow: region.startRow + 1, startCol: region.startCol,
                                      endRow: region.endRow + 1, endCol: region.endCol)
            } else if region.endRow >= index {
                return STMergedRegion(startRow: region.startRow, startCol: region.startCol,
                                      endRow: region.endRow + 1, endCol: region.endCol)
            }
            return region
        }
    }

    /// Delete a row at the given index
    public func deleteRow(at index: Int) {
        guard index < rowCount, rowCount > 1 else { return }
        cells.remove(at: index)
        mergedRegions = mergedRegions.compactMap { region in
            if region.startRow == index && region.endRow == index { return nil }
            var sr = region.startRow, er = region.endRow
            if sr > index { sr -= 1 }
            if er >= index { er = max(sr, er - 1) }
            return STMergedRegion(startRow: sr, startCol: region.startCol,
                                  endRow: er, endCol: region.endCol)
        }
    }

    /// Insert a column at the given index
    public func insertColumn(at index: Int) {
        guard index <= columnCount else { return }
        for r in 0..<rowCount {
            cells[r].insert(STExcelCell(), at: index)
        }
        mergedRegions = mergedRegions.map { region in
            if region.startCol >= index {
                return STMergedRegion(startRow: region.startRow, startCol: region.startCol + 1,
                                      endRow: region.endRow, endCol: region.endCol + 1)
            } else if region.endCol >= index {
                return STMergedRegion(startRow: region.startRow, startCol: region.startCol,
                                      endRow: region.endRow, endCol: region.endCol + 1)
            }
            return region
        }
    }

    /// Delete a column at the given index
    public func deleteColumn(at index: Int) {
        guard index < columnCount, columnCount > 1 else { return }
        for r in 0..<rowCount {
            cells[r].remove(at: index)
        }
        mergedRegions = mergedRegions.compactMap { region in
            if region.startCol == index && region.endCol == index { return nil }
            var sc = region.startCol, ec = region.endCol
            if sc > index { sc -= 1 }
            if ec >= index { ec = max(sc, ec - 1) }
            return STMergedRegion(startRow: region.startRow, startCol: sc,
                                  endRow: region.endRow, endCol: ec)
        }
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

    /// Parse column letter to index (A=0, B=1, ..., AA=26)
    public static func columnIndex(_ letter: String) -> Int {
        var col = 0
        for char in letter.uppercased() {
            guard let ascii = char.asciiValue else { continue }
            col = col * 26 + Int(ascii) - 64
        }
        return col - 1
    }
}

/// Data validation rule for cells
struct STExcelDataValidation {
    var type: Int  // 0=Any, 1=WholeNumber, 2=Decimal, 3=List, 4=Date, 5=TextLength
    var minValue: String = ""
    var maxValue: String = ""
    var listValues: [String] = []

    var xlsxType: String {
        switch type {
        case 1: return "whole"
        case 2: return "decimal"
        case 3: return "list"
        case 4: return "date"
        case 5: return "textLength"
        default: return "none"
        }
    }
}

/// Represents a single cell in a spreadsheet
public struct STExcelCell {
    public var value: String
    public var style: STExcelCellStyle
    public var formula: String?    // e.g. "=SUM(A1:A5)", nil = no formula
    public var comment: String?    // cell comment/note

    /// Backward-compatible computed properties
    public var isBold: Bool {
        get { style.isBold }
        set { style.isBold = newValue }
    }

    public var isNumeric: Bool {
        Double(value) != nil
    }

    public init(value: String = "", isBold: Bool = false) {
        self.value = value
        self.style = STExcelCellStyle()
        self.style.isBold = isBold
        self.formula = nil
        self.comment = nil
    }

    public init(value: String, style: STExcelCellStyle, formula: String? = nil, comment: String? = nil) {
        self.value = value
        self.style = style
        self.formula = formula
        self.comment = comment
    }
}
