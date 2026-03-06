import SwiftUI
import STKit

/// Table contextual ribbon tab — appears when a table cell is selected
struct STExcelRibbonTableTab: View {
    @ObservedObject var viewModel: STExcelEditorViewModel

    @State private var showStylePicker = false

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 2) {
                // Header Row toggle
                STExcelRibbonToolButton(
                    iconName: "rectangle.topthird.inset.filled",
                    label: STExcelStrings.headerRow,
                    isActive: viewModel.selectedTable?.hasHeaders == true
                ) {
                    if var t = viewModel.selectedTable {
                        t.hasHeaders.toggle()
                        viewModel.updateTable(t)
                    }
                }

                // Banded Rows toggle
                STExcelRibbonToolButton(
                    iconName: "rectangle.split.3x1",
                    label: STExcelStrings.bandedRows,
                    isActive: viewModel.selectedTable?.showBandedRows == true
                ) {
                    if var t = viewModel.selectedTable {
                        t.showBandedRows.toggle()
                        viewModel.updateTable(t)
                    }
                }

                // Banded Columns toggle
                STExcelRibbonToolButton(
                    iconName: "rectangle.split.1x2",
                    label: STExcelStrings.bandedCols,
                    isActive: viewModel.selectedTable?.showBandedColumns == true
                ) {
                    if var t = viewModel.selectedTable {
                        t.showBandedColumns.toggle()
                        viewModel.updateTable(t)
                    }
                }

                STExcelRibbonSeparator()

                // Style picker
                ForEach(STExcelTableStyle.allCases) { style in
                    Button {
                        if var t = viewModel.selectedTable {
                            t.style = style
                            viewModel.updateTable(t)
                        }
                    } label: {
                        VStack(spacing: 1) {
                            VStack(spacing: 0) {
                                Rectangle().fill(style.headerColor).frame(width: 30, height: 8)
                                Rectangle().fill(style.bandColor).frame(width: 30, height: 6)
                                Rectangle().fill(Color.stSystemBackground).frame(width: 30, height: 6)
                                Rectangle().fill(style.bandColor).frame(width: 30, height: 6)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                            .overlay(
                                RoundedRectangle(cornerRadius: 3)
                                    .stroke(viewModel.selectedTable?.style == style ? Color.stExcelAccent : Color.stSeparator,
                                            lineWidth: viewModel.selectedTable?.style == style ? 2 : 0.5)
                            )
                            Text(style.displayName)
                                .font(.system(size: 8))
                                .foregroundColor(.primary)
                        }
                        .frame(width: 36, height: 50)
                    }
                    .buttonStyle(.plain)
                }

                STExcelRibbonSeparator()

                // Delete table
                STExcelRibbonToolButton(iconName: "trash", label: STExcelStrings.delete) {
                    viewModel.deleteSelectedTable()
                }
            }
            .padding(.horizontal, 8)
        }
    }
}
