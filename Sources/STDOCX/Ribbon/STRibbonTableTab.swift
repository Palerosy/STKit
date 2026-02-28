import SwiftUI
import STKit

/// Table tab content — Row/Column operations, Cell color, Border color, Table Style
/// Appears contextually when cursor is inside a table
struct STRibbonTableTab: View {
    @ObservedObject var webEditorViewModel: STWebEditorViewModel

    @State private var showCellColorPicker = false
    @State private var showBorderColorPicker = false
    @State private var showTableStylePicker = false

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 2) {
                // Table Style (restyle whole table)
                STRibbonToolButton(
                    iconName: "paintpalette",
                    label: STStrings.ribbonTableStyle
                ) {
                    showTableStylePicker = true
                }
                .sheet(isPresented: $showTableStylePicker) {
                    STTableStylePickerView(mode: .restyle) { style in
                        webEditorViewModel.setTableThemeColor(
                            headerBg: style.headerHex,
                            stripeBg: style.stripeHex,
                            borderColor: style.borderHex
                        )
                    }
                    .stPresentationDetents([.medium])
                    .stPresentationDragIndicator(.visible)
                }

                STRibbonSeparator()

                // Add Row
                STRibbonToolButton(
                    iconName: "plus.rectangle.on.rectangle",
                    label: STStrings.ribbonAddRow
                ) {
                    webEditorViewModel.addTableRow()
                }

                // Delete Row
                STRibbonToolButton(
                    iconName: "minus.rectangle",
                    label: STStrings.ribbonDeleteRow
                ) {
                    webEditorViewModel.deleteTableRow()
                }

                STRibbonSeparator()

                // Add Column
                STRibbonToolButton(
                    iconName: "rectangle.split.1x2",
                    label: STStrings.ribbonAddColumn
                ) {
                    webEditorViewModel.addTableColumn()
                }

                // Delete Column
                STRibbonToolButton(
                    iconName: "rectangle.split.2x1",
                    label: STStrings.ribbonDeleteColumn
                ) {
                    webEditorViewModel.deleteTableColumn()
                }

                STRibbonSeparator()

                // Cell Background Color
                STRibbonToolButton(
                    iconName: "paintbrush",
                    label: STStrings.ribbonCellColor
                ) {
                    showCellColorPicker.toggle()
                }
                .popover(isPresented: $showCellColorPicker) {
                    STColorPickerPopover(
                        title: STStrings.ribbonCellColor,
                        colors: STColorPresets.textColors,
                        showNone: true
                    ) { hex in
                        if hex == "none" {
                            webEditorViewModel.setCellBackgroundColor("transparent")
                        } else {
                            webEditorViewModel.setCellBackgroundColor(hex)
                        }
                        showCellColorPicker = false
                    }
                }

                // Cell Border Color
                STRibbonToolButton(
                    iconName: "square.dashed",
                    label: STStrings.ribbonBorderColor
                ) {
                    showBorderColorPicker.toggle()
                }
                .popover(isPresented: $showBorderColorPicker) {
                    STColorPickerPopover(
                        title: STStrings.ribbonBorderColor,
                        colors: STColorPresets.textColors,
                        showNone: false
                    ) { hex in
                        webEditorViewModel.setCellBorderColor(hex)
                        showBorderColorPicker = false
                    }
                }
            }
            .padding(.horizontal, 8)
        }
    }
}
