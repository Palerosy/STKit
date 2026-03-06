import Foundation

/// Internal clipboard for cut/copy/paste operations
class STExcelClipboard {
    static let shared = STExcelClipboard()

    enum Operation { case copy, cut }

    struct CopiedData {
        let cells: [[STExcelCell]]
        let operation: Operation
        let sourceRow: Int
        let sourceCol: Int
    }

    var data: CopiedData?

    func copy(from sheet: STExcelSheet, startRow: Int, startCol: Int, endRow: Int, endCol: Int) {
        var cells: [[STExcelCell]] = []
        for r in startRow...endRow {
            var row: [STExcelCell] = []
            for c in startCol...endCol {
                row.append(sheet.cell(row: r, column: c))
            }
            cells.append(row)
        }
        data = CopiedData(cells: cells, operation: .copy, sourceRow: startRow, sourceCol: startCol)
    }

    func cut(from sheet: STExcelSheet, startRow: Int, startCol: Int, endRow: Int, endCol: Int) {
        copy(from: sheet, startRow: startRow, startCol: startCol, endRow: endRow, endCol: endCol)
        data = CopiedData(cells: data!.cells, operation: .cut, sourceRow: startRow, sourceCol: startCol)
        // Clear source cells
        for r in startRow...endRow {
            for c in startCol...endCol {
                sheet.setCell(row: r, column: c, value: "")
                sheet.setCellStyle(row: r, column: c, style: STExcelCellStyle())
            }
        }
    }

    func paste(to sheet: STExcelSheet, atRow: Int, atCol: Int) {
        guard let data = data else { return }
        for (ri, row) in data.cells.enumerated() {
            for (ci, cell) in row.enumerated() {
                let targetRow = atRow + ri
                let targetCol = atCol + ci
                guard targetRow < sheet.rowCount, targetCol < sheet.columnCount else { continue }
                sheet.cells[targetRow][targetCol] = cell
            }
        }
    }
}
