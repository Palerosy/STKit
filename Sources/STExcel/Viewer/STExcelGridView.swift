import SwiftUI

/// The spreadsheet grid — renders cells in a scrollable 2D grid
public struct STExcelGridView: View {
    @ObservedObject var sheet: STExcelSheet
    let configuration: STExcelConfiguration
    let isEditable: Bool

    @State private var selectedRow: Int? = nil
    @State private var selectedCol: Int? = nil
    @State private var editingValue: String = ""
    @State private var isEditing = false

    public init(sheet: STExcelSheet, configuration: STExcelConfiguration = .default, isEditable: Bool = true) {
        self.sheet = sheet
        self.configuration = configuration
        self.isEditable = isEditable
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Formula / cell value bar
            if isEditable, let row = selectedRow, let col = selectedCol {
                cellValueBar(row: row, col: col)
                Divider()
            }

            // Grid
            ScrollView([.horizontal, .vertical], showsIndicators: true) {
                LazyVStack(alignment: .leading, spacing: 0, pinnedViews: []) {
                    // Column headers
                    columnHeaders

                    // Data rows
                    ForEach(0..<min(sheet.rowCount, 200), id: \.self) { row in
                        dataRow(row)
                    }
                }
            }
        }
    }

    // MARK: - Cell Value Bar

    private func cellValueBar(row: Int, col: Int) -> some View {
        HStack(spacing: 8) {
            Text("\(STExcelSheet.columnLetter(col))\(row + 1)")
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 50)

            Rectangle()
                .fill(Color(.separator))
                .frame(width: 1, height: 20)

            if isEditing {
                TextField("", text: $editingValue, onCommit: {
                    sheet.setCell(row: row, column: col, value: editingValue)
                    isEditing = false
                })
                .font(.system(size: 14))
                .textFieldStyle(.plain)
            } else {
                Text(sheet.cell(row: row, column: col).value)
                    .font(.system(size: 14))
                    .lineLimit(1)
                Spacer()
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemBackground))
    }

    // MARK: - Column Headers

    private var columnHeaders: some View {
        HStack(spacing: 0) {
            // Corner cell (empty)
            Rectangle()
                .fill(configuration.headerBackgroundColor)
                .frame(width: configuration.rowHeaderWidth, height: configuration.columnHeaderHeight)
                .overlay(
                    Rectangle().stroke(configuration.gridLineColor, lineWidth: 0.5)
                )

            ForEach(0..<min(sheet.columnCount, 50), id: \.self) { col in
                Text(STExcelSheet.columnLetter(col))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(width: configuration.columnWidth, height: configuration.columnHeaderHeight)
                    .background(
                        selectedCol == col
                            ? configuration.selectionColor.opacity(0.15)
                            : configuration.headerBackgroundColor
                    )
                    .overlay(
                        Rectangle().stroke(configuration.gridLineColor, lineWidth: 0.5)
                    )
            }
        }
    }

    // MARK: - Data Row

    private func dataRow(_ row: Int) -> some View {
        HStack(spacing: 0) {
            // Row number
            Text("\(row + 1)")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: configuration.rowHeaderWidth, height: configuration.rowHeight)
                .background(
                    selectedRow == row
                        ? configuration.selectionColor.opacity(0.15)
                        : configuration.headerBackgroundColor
                )
                .overlay(
                    Rectangle().stroke(configuration.gridLineColor, lineWidth: 0.5)
                )

            // Cells
            ForEach(0..<min(sheet.columnCount, 50), id: \.self) { col in
                cellView(row: row, col: col)
            }
        }
    }

    // MARK: - Cell

    private func cellView(row: Int, col: Int) -> some View {
        let cell = sheet.cell(row: row, column: col)
        let isSelected = selectedRow == row && selectedCol == col

        return Text(cell.value)
            .font(.system(size: 13, weight: cell.isBold ? .bold : .regular))
            .lineLimit(1)
            .frame(width: configuration.columnWidth, height: configuration.rowHeight, alignment: cell.isNumeric ? .trailing : .leading)
            .padding(.horizontal, 6)
            .background(
                isSelected
                    ? configuration.selectionColor.opacity(0.1)
                    : configuration.cellBackgroundColor
            )
            .overlay(
                Group {
                    if isSelected {
                        Rectangle()
                            .stroke(configuration.selectionColor, lineWidth: 2)
                    } else {
                        Rectangle()
                            .stroke(configuration.gridLineColor, lineWidth: 0.5)
                    }
                }
            )
            .contentShape(Rectangle())
            .onTapGesture {
                selectedRow = row
                selectedCol = col
                editingValue = cell.value
                if isEditable {
                    isEditing = true
                }
            }
    }
}
