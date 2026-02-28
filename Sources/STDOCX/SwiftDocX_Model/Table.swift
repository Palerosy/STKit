import Foundation

/// Border style for table cells
public enum BorderStyle: String, Sendable {
    case none = "nil"
    case single = "single"
    case thick = "thick"
    case double = "double"
    case dotted = "dotted"
    case dashed = "dashed"
    case dashSmallGap = "dashSmallGap"
    case dotDash = "dotDash"
    case dotDotDash = "dotDotDash"
    case triple = "triple"
    case wave = "wave"
}

/// Border configuration for a table or cell
public struct Border: Equatable, Sendable {
    public var style: BorderStyle
    public var width: Double  // In points
    public var color: DocXColor?

    public init(style: BorderStyle = .single, width: Double = 0.5, color: DocXColor? = nil) {
        self.style = style
        self.width = width
        self.color = color
    }

    public static var none: Border { Border(style: .none, width: 0) }
    public static var single: Border { Border(style: .single, width: 0.5) }
    public static var thick: Border { Border(style: .thick, width: 1.5) }
}

/// Table borders configuration
public struct TableBorders: Equatable, Sendable {
    public var top: Border?
    public var bottom: Border?
    public var left: Border?
    public var right: Border?
    public var insideH: Border?  // Horizontal inside borders
    public var insideV: Border?  // Vertical inside borders

    public init(
        top: Border? = nil,
        bottom: Border? = nil,
        left: Border? = nil,
        right: Border? = nil,
        insideH: Border? = nil,
        insideV: Border? = nil
    ) {
        self.top = top
        self.bottom = bottom
        self.left = left
        self.right = right
        self.insideH = insideH
        self.insideV = insideV
    }

    /// All borders with the same style
    public static func all(_ border: Border) -> TableBorders {
        TableBorders(top: border, bottom: border, left: border, right: border, insideH: border, insideV: border)
    }

    public static var none: TableBorders { TableBorders() }
    public static var single: TableBorders { TableBorders.all(.single) }
}

/// Vertical alignment for table cells
public enum VerticalAlignment: String, Sendable {
    case top = "top"
    case center = "center"
    case bottom = "bottom"
}

/// A cell in a table
public class TableCell {
    /// Paragraphs in this cell
    public var paragraphs: [Paragraph]

    /// Cell width in points (nil for auto)
    public var width: Double?

    /// Background/shading color
    public var backgroundColor: DocXColor?

    /// Vertical alignment
    public var verticalAlignment: VerticalAlignment?

    /// Number of columns this cell spans (for merged cells)
    public var columnSpan: Int

    /// Number of rows this cell spans (for merged cells)
    public var rowSpan: Int

    /// Cell borders (overrides table borders)
    public var borders: TableBorders?

    public init() {
        self.paragraphs = []
        self.width = nil
        self.backgroundColor = nil
        self.verticalAlignment = nil
        self.columnSpan = 1
        self.rowSpan = 1
        self.borders = nil
    }

    /// Creates a cell with text content
    public convenience init(_ text: String, formatting: TextFormatting = .none) {
        self.init()
        addParagraph(text, formatting: formatting)
    }

    /// Adds a paragraph to the cell
    @discardableResult
    public func addParagraph(_ text: String = "", formatting: TextFormatting = .none) -> Paragraph {
        let para = Paragraph(text, formatting: formatting)
        paragraphs.append(para)
        return para
    }

    /// The text content of the cell (all paragraphs joined)
    public var text: String {
        paragraphs.map { $0.text }.joined(separator: "\n")
    }
}

/// A row in a table
public class TableRow {
    /// Cells in this row
    public var cells: [TableCell]

    /// Row height in points (nil for auto)
    public var height: Double?

    /// Whether this is a header row (repeats on each page)
    public var isHeader: Bool

    public init() {
        self.cells = []
        self.height = nil
        self.isHeader = false
    }

    /// Adds a cell with text content
    @discardableResult
    public func addCell(_ text: String = "", formatting: TextFormatting = .none) -> TableCell {
        let cell = TableCell(text, formatting: formatting)
        cells.append(cell)
        return cell
    }

    /// Adds an existing cell
    @discardableResult
    public func addCell(_ cell: TableCell) -> TableCell {
        cells.append(cell)
        return cell
    }

    /// Number of cells in this row
    public var cellCount: Int {
        cells.count
    }
}

/// Table look flags — controls which conditional formatting is applied
public struct TableLook: Equatable, Sendable {
    public var firstRow: Bool
    public var lastRow: Bool
    public var firstColumn: Bool
    public var lastColumn: Bool
    public var noHBand: Bool   // true = no horizontal banding
    public var noVBand: Bool   // true = no vertical banding

    public init(firstRow: Bool = true, lastRow: Bool = false, firstColumn: Bool = true,
                lastColumn: Bool = false, noHBand: Bool = false, noVBand: Bool = true) {
        self.firstRow = firstRow
        self.lastRow = lastRow
        self.firstColumn = firstColumn
        self.lastColumn = lastColumn
        self.noHBand = noHBand
        self.noVBand = noVBand
    }

    /// Parse from w:tblLook attributes
    public init(attributes: [String: String]) {
        self.firstRow = attributes["w:firstRow"] == "1" || attributes["firstRow"] == "1"
        self.lastRow = attributes["w:lastRow"] == "1" || attributes["lastRow"] == "1"
        self.firstColumn = attributes["w:firstColumn"] == "1" || attributes["firstColumn"] == "1"
        self.lastColumn = attributes["w:lastColumn"] == "1" || attributes["lastColumn"] == "1"
        self.noHBand = attributes["w:noHBand"] == "1" || attributes["noHBand"] == "1"
        self.noVBand = attributes["w:noVBand"] == "1" || attributes["noVBand"] == "1"
    }
}

/// A table in a Word document
public class Table {
    /// Rows in the table
    public var rows: [TableRow]

    /// Table borders
    public var borders: TableBorders

    /// Column widths in points (nil entries for auto)
    public var columnWidths: [Double?]

    /// Table width in points (nil for auto)
    public var width: Double?

    /// Table alignment
    public var alignment: ParagraphAlignment?

    /// Referenced table style name (e.g. "GridTable4-Accent1")
    public var styleName: String?

    /// Table look flags — which conditional formatting to apply
    public var tblLook: TableLook?

    /// Accessibility: Visible table caption/title
    public var accessibilityCaption: String?

    /// Accessibility: Table description for screen readers (not visible, read aloud)
    public var accessibilitySummary: String?

    public init() {
        self.rows = []
        self.borders = .single
        self.columnWidths = []
        self.width = nil
        self.alignment = nil
        self.styleName = nil
        self.tblLook = nil
        self.accessibilityCaption = nil
        self.accessibilitySummary = nil
    }

    /// Creates a table with the specified number of rows and columns
    public convenience init(rows: Int, columns: Int) {
        self.init()
        for _ in 0..<rows {
            let row = addRow()
            for _ in 0..<columns {
                row.addCell()
            }
        }
    }

    /// Adds a row to the table
    @discardableResult
    public func addRow() -> TableRow {
        let row = TableRow()
        rows.append(row)
        return row
    }

    /// Adds an existing row
    @discardableResult
    public func addRow(_ row: TableRow) -> TableRow {
        rows.append(row)
        return row
    }

    /// Gets a cell at the specified row and column indices
    public func cell(at row: Int, column: Int) -> TableCell? {
        guard row < rows.count, column < rows[row].cells.count else { return nil }
        return rows[row].cells[column]
    }

    /// Sets text in a cell at the specified position
    public func setText(_ text: String, at row: Int, column: Int, formatting: TextFormatting = .none) {
        guard let cell = cell(at: row, column: column) else { return }
        cell.paragraphs.removeAll()
        cell.addParagraph(text, formatting: formatting)
    }

    /// Number of rows
    public var rowCount: Int {
        rows.count
    }

    /// Number of columns (based on first row)
    public var columnCount: Int {
        rows.first?.cellCount ?? 0
    }
}

extension Table: CustomStringConvertible {
    public var description: String {
        "Table(\(rowCount)x\(columnCount))"
    }
}
