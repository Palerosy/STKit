import SwiftUI
import STKit

/// Format tab — Cell Font, Cell Border, Lock Cell, Cell Style, Cell Size, Clear
/// (matches competitor ribbon: 6 tall labeled buttons)
struct STExcelRibbonFormatTab: View {
    @ObservedObject var viewModel: STExcelEditorViewModel
    @State private var showFormatCells = false
    @State private var showFormatCellsBorder = false
    @State private var showCellSize = false
    @State private var showCellStyle = false
    @State private var showNumberFormatPicker = false
    @State private var showConditionalFormat = false

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 2) {
                // Cell Font → opens Format Cells on Cell tab
                STExcelRibbonToolButton(iconName: "textformat.abc", label: STExcelStrings.cellFont) {
                    showFormatCells = true
                }
                .sheet(isPresented: $showFormatCells) {
                    STExcelFormatCellsView(viewModel: viewModel, initialTab: 0)
                        .stPresentationDetents([.large])
                }

                // Cell Border → opens Format Cells on Border tab
                STExcelRibbonToolButton(iconName: "square.grid.3x3", label: STExcelStrings.cellBorder) {
                    showFormatCellsBorder = true
                }
                .sheet(isPresented: $showFormatCellsBorder) {
                    STExcelFormatCellsView(viewModel: viewModel, initialTab: 1)
                        .stPresentationDetents([.large])
                }

                // Lock Cell — toggle
                STExcelRibbonToolButton(
                    iconName: viewModel.currentStyle.isLocked ? "lock.fill" : "lock.open",
                    label: STExcelStrings.lockCell,
                    isActive: viewModel.currentStyle.isLocked
                ) {
                    viewModel.toggleLocked()
                }

                // Cell Style
                STExcelRibbonToolButton(iconName: "paintbrush", label: STExcelStrings.cellStyle) {
                    showCellStyle = true
                }
                .sheet(isPresented: $showCellStyle) {
                    STExcelCellStylePicker(viewModel: viewModel)
                        .stPresentationDetents([.medium])
                }

                // Cell Size
                STExcelRibbonToolButton(iconName: "arrow.up.left.and.arrow.down.right", label: STExcelStrings.cellSize) {
                    showCellSize = true
                }
                .sheet(isPresented: $showCellSize) {
                    STExcelCellSizeView(viewModel: viewModel)
                        .stPresentationDetents([.height(340)])
                }

                // Clear
                STExcelRibbonToolButton(iconName: "xmark.circle", label: STExcelStrings.clear) {
                    guard let sheet = viewModel.sheet, viewModel.selectedRow != nil, viewModel.selectedCol != nil else { return }
                    let sr = min(viewModel.selectionStartRow, viewModel.selectionActualEndRow)
                    let sc = min(viewModel.selectionStartCol, viewModel.selectionActualEndCol)
                    let er = max(viewModel.selectionStartRow, viewModel.selectionActualEndRow)
                    let ec = max(viewModel.selectionStartCol, viewModel.selectionActualEndCol)
                    for r in sr...er {
                        for c in sc...ec {
                            guard r < sheet.rowCount, c < sheet.columnCount else { continue }
                            sheet.cells[r][c] = STExcelCell()
                        }
                    }
                    viewModel.hasUnsavedChanges = true
                    viewModel.updateCurrentStyle()
                }

                STExcelRibbonSeparator()

                // Number Format (quick access)
                STExcelRibbonToolButton(iconName: "number", label: STExcelStrings.numberFormat) {
                    showNumberFormatPicker = true
                }
                .sheet(isPresented: $showNumberFormatPicker) {
                    STExcelNumberFormatPicker(
                        onSelect: { format in
                            viewModel.setNumberFormat(format)
                            showNumberFormatPicker = false
                        },
                        onSelectCode: { formatId, code in
                            viewModel.setNumberFormatCode(formatId: formatId, code: code)
                            showNumberFormatPicker = false
                        }
                    )
                    .stPresentationDetents([.large])
                }

                // Conditional Formatting
                STExcelRibbonToolButton(iconName: "wand.and.stars", label: STExcelStrings.conditionalFormat) {
                    showConditionalFormat = true
                }
                .sheet(isPresented: $showConditionalFormat) {
                    STExcelConditionalFormatView(viewModel: viewModel) {
                        showConditionalFormat = false
                    }
                }
            }
            .padding(.horizontal, 8)
        }
    }
}

// MARK: - Cell Size Sheet

struct STExcelCellSizeView: View {
    @ObservedObject var viewModel: STExcelEditorViewModel
    @Environment(\.dismiss) private var dismiss

    // Points to cm conversion (1 pt ≈ 0.0353 cm)
    private let ptToCm: CGFloat = 0.0353

    private var selectedRow: Int? { viewModel.selectedRow }
    private var selectedCol: Int? { viewModel.selectedCol }

    private var currentRowHeight: CGFloat {
        guard let row = selectedRow else { return 40 }
        return viewModel.rowHeight(for: row, default: 40)
    }

    private var currentColWidth: CGFloat {
        guard let col = selectedCol else { return 100 }
        return viewModel.columnWidth(for: col, default: 100)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Spacer()
                Text(STExcelStrings.cellSize)
                    .font(.headline)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)

            VStack(spacing: 16) {
                // Row Height
                HStack {
                    Text(STExcelStrings.rowHeight)
                    Spacer()
                    Text(String(format: "%.2f cm", currentRowHeight * ptToCm))
                        .foregroundColor(.stExcelAccent)
                        .font(.system(size: 15))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.15))
                        .cornerRadius(6)
                    HStack(spacing: 0) {
                        Button { adjustRowHeight(-5) } label: {
                            Image(systemName: "minus").font(.system(size: 14)).frame(width: 36, height: 32)
                        }
                        Divider().frame(height: 24)
                        Button { adjustRowHeight(5) } label: {
                            Image(systemName: "plus").font(.system(size: 14)).frame(width: 36, height: 32)
                        }
                    }
                    .foregroundColor(.primary)
                    .background(Color.gray.opacity(0.15))
                    .cornerRadius(8)
                }
                .padding(.horizontal, 20)

                // Auto-Fit Row Height
                Button {
                    autoFitRowHeight()
                } label: {
                    Text(STExcelStrings.autoFitRow)
                        .font(.system(size: 16, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.gray.opacity(0.15))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                }
                .padding(.horizontal, 20)

                // Column Width
                HStack {
                    Text(STExcelStrings.columnWidth)
                    Spacer()
                    Text(String(format: "%.2f cm", currentColWidth * ptToCm))
                        .foregroundColor(.stExcelAccent)
                        .font(.system(size: 15))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.15))
                        .cornerRadius(6)
                    HStack(spacing: 0) {
                        Button { adjustColWidth(-10) } label: {
                            Image(systemName: "minus").font(.system(size: 14)).frame(width: 36, height: 32)
                        }
                        Divider().frame(height: 24)
                        Button { adjustColWidth(10) } label: {
                            Image(systemName: "plus").font(.system(size: 14)).frame(width: 36, height: 32)
                        }
                    }
                    .foregroundColor(.primary)
                    .background(Color.gray.opacity(0.15))
                    .cornerRadius(8)
                }
                .padding(.horizontal, 20)

                // Auto-Fit Column Width
                Button {
                    autoFitColWidth()
                } label: {
                    Text(STExcelStrings.autoFitColumn)
                        .font(.system(size: 16, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.gray.opacity(0.15))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                }
                .padding(.horizontal, 20)
            }

            Spacer()
        }
    }

    private func adjustRowHeight(_ delta: CGFloat) {
        guard let row = selectedRow else { return }
        let current = viewModel.rowHeight(for: row, default: 40)
        let newHeight = max(15, current + delta)
        viewModel.rowHeights[row] = newHeight
        viewModel.hasUnsavedChanges = true
    }

    private func adjustColWidth(_ delta: CGFloat) {
        guard let col = selectedCol else { return }
        let current = viewModel.columnWidth(for: col, default: 100)
        let newWidth = max(20, current + delta)
        viewModel.columnWidths[col] = newWidth
        viewModel.hasUnsavedChanges = true
    }

    private func autoFitRowHeight() {
        guard let row = selectedRow else { return }
        // Estimate based on content: default 40, if wrap text increase
        let style = viewModel.currentStyle
        let height: CGFloat = style.wrapText ? 60 : max(style.fontSize * 1.5, 30)
        viewModel.rowHeights[row] = height
        viewModel.hasUnsavedChanges = true
    }

    private func autoFitColWidth() {
        guard let col = selectedCol, let sheet = viewModel.sheet else { return }
        // Scan column for longest content
        var maxLen = 0
        for r in 0..<sheet.rowCount {
            let val = sheet.cell(row: r, column: col).value
            if val.count > maxLen { maxLen = val.count }
        }
        let width = max(50, CGFloat(maxLen) * 8 + 20)
        viewModel.columnWidths[col] = min(width, 500)
        viewModel.hasUnsavedChanges = true
    }
}
