import SwiftUI

/// Table style presets
enum STExcelTableStyle: String, CaseIterable, Identifiable {
    case blue, green, orange, purple, red, gray, dark

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .blue: return STExcelStrings.styleBlue
        case .green: return STExcelStrings.styleGreen
        case .orange: return STExcelStrings.styleOrange
        case .purple: return STExcelStrings.stylePurple
        case .red: return STExcelStrings.styleRed
        case .gray: return STExcelStrings.styleGray
        case .dark: return STExcelStrings.styleDark
        }
    }

    var headerColor: Color {
        switch self {
        case .blue: return Color(red: 0.27, green: 0.51, blue: 0.71)
        case .green: return Color(red: 0.27, green: 0.63, blue: 0.28)
        case .orange: return Color(red: 0.85, green: 0.52, blue: 0.10)
        case .purple: return Color(red: 0.56, green: 0.27, blue: 0.68)
        case .red: return Color(red: 0.80, green: 0.26, blue: 0.26)
        case .gray: return Color(red: 0.50, green: 0.50, blue: 0.50)
        case .dark: return Color(red: 0.20, green: 0.20, blue: 0.25)
        }
    }

    var bandColor: Color {
        switch self {
        case .blue: return Color(red: 0.85, green: 0.91, blue: 0.96)
        case .green: return Color(red: 0.85, green: 0.94, blue: 0.85)
        case .orange: return Color(red: 0.98, green: 0.92, blue: 0.82)
        case .purple: return Color(red: 0.93, green: 0.87, blue: 0.96)
        case .red: return Color(red: 0.97, green: 0.87, blue: 0.87)
        case .gray: return Color(red: 0.93, green: 0.93, blue: 0.93)
        case .dark: return Color(red: 0.85, green: 0.85, blue: 0.88)
        }
    }
}

/// A formatted table region on the spreadsheet
struct STExcelTable: Identifiable {
    let id = UUID()
    var startRow: Int
    var startCol: Int
    var endRow: Int
    var endCol: Int
    var style: STExcelTableStyle
    var hasHeaders: Bool
    var showBandedRows: Bool
    var showBandedColumns: Bool
    var name: String

    init(
        startRow: Int, startCol: Int,
        endRow: Int, endCol: Int,
        style: STExcelTableStyle = .blue,
        hasHeaders: Bool = true,
        showBandedRows: Bool = true,
        showBandedColumns: Bool = false,
        name: String = "Table1"
    ) {
        self.startRow = startRow
        self.startCol = startCol
        self.endRow = endRow
        self.endCol = endCol
        self.style = style
        self.hasHeaders = hasHeaders
        self.showBandedRows = showBandedRows
        self.showBandedColumns = showBandedColumns
        self.name = name
    }

    /// Check if a cell is within this table
    func contains(row: Int, col: Int) -> Bool {
        row >= startRow && row <= endRow && col >= startCol && col <= endCol
    }

    func isHeaderRow(_ row: Int) -> Bool {
        hasHeaders && row == startRow
    }

    func isBandedRow(_ row: Int) -> Bool {
        guard showBandedRows else { return false }
        let dataRow = hasHeaders ? row - startRow - 1 : row - startRow
        return dataRow >= 0 && dataRow.isMultiple(of: 2)
    }

    func isBandedCol(_ col: Int) -> Bool {
        guard showBandedColumns else { return false }
        let dataCol = col - startCol
        return dataCol >= 0 && dataCol.isMultiple(of: 2)
    }

    var rangeString: String {
        "\(STExcelSheet.columnLetter(startCol))\(startRow + 1):\(STExcelSheet.columnLetter(endCol))\(endRow + 1)"
    }
}
