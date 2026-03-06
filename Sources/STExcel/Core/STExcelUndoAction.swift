import Foundation

/// Represents a single undoable action in the spreadsheet
enum STExcelUndoAction {
    case setCellValue(row: Int, col: Int, oldValue: String, newValue: String)
    case setCellStyle(row: Int, col: Int, oldStyle: STExcelCellStyle, newStyle: STExcelCellStyle)
    case setRangeStyle(changes: [(row: Int, col: Int, oldStyle: STExcelCellStyle, newStyle: STExcelCellStyle)])
    case insertRow(at: Int)
    case deleteRow(at: Int, cells: [STExcelCell])
    case insertColumn(at: Int)
    case deleteColumn(at: Int, cells: [STExcelCell])
    case mergeCells(region: STMergedRegion)
    case unmergeCells(region: STMergedRegion)
    case setCellComment(row: Int, col: Int, oldComment: String?, newComment: String?)
    case batch([STExcelUndoAction])
}
