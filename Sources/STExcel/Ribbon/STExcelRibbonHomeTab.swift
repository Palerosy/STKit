import SwiftUI
import STKit

/// Home tab — 2-row compact icon grid + AutoSum, Insert, Delete, Go to Cell (matches competitor layout)
struct STExcelRibbonHomeTab: View {
    @ObservedObject var viewModel: STExcelEditorViewModel

    @State private var showTextColorPicker = false
    @State private var showFillColorPicker = false
    @State private var showBorderPicker = false
    @State private var showGoToCellAlert = false
    @State private var goToCellRef = ""

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                // Section 1: 2-row compact icon grid
                compactIconGrid

                STExcelRibbonSeparator()

                // Section 2: Tall labeled buttons
                autoSumButton
                insertButton
                deleteButton
                goToCellButton

                STExcelRibbonSeparator()

                // Section 3: More formatting (scrollable)
                moreFormattingSection
            }
            .padding(.horizontal, 8)
        }
    }

    // MARK: - Compact 2-Row Icon Grid

    private var compactIconGrid: some View {
        VStack(spacing: 2) {
            HStack(spacing: 2) {
                compactButton(icon: "text.alignleft",
                              active: viewModel.currentStyle.horizontalAlignment == .left) {
                    viewModel.setHorizontalAlignment(.left)
                }
                compactButton(icon: "line.3.horizontal.decrease") {
                    viewModel.sortAscending()
                }
                compactButton(icon: "dollarsign") {
                    viewModel.setNumberFormat(.currency)
                }
                compactButton(icon: "bold",
                              active: viewModel.currentStyle.isBold) {
                    viewModel.toggleBold()
                }
                compactButton(icon: "italic",
                              active: viewModel.currentStyle.isItalic) {
                    viewModel.toggleItalic()
                }
                compactButton(icon: "underline",
                              active: viewModel.currentStyle.isUnderline) {
                    viewModel.toggleUnderline()
                }
            }
            HStack(spacing: 2) {
                compactButton(icon: "text.aligncenter",
                              active: viewModel.currentStyle.horizontalAlignment == .center) {
                    viewModel.setHorizontalAlignment(.center)
                }
                compactButton(icon: "tablecells") {
                    viewModel.insertRow()
                }
                compactButton(icon: "percent") {
                    viewModel.setNumberFormat(.percent)
                }
                compactButton(icon: "strikethrough",
                              active: viewModel.currentStyle.isStrikethrough) {
                    viewModel.toggleStrikethrough()
                }
                // Fill color
                compactButton(icon: "paintbrush.fill") {
                    showFillColorPicker.toggle()
                }
                .popover(isPresented: $showFillColorPicker) {
                    STExcelColorPicker(
                        title: STExcelStrings.fillColor,
                        colors: STExcelColorPresets.fillColors,
                        showNone: true
                    ) { hex in
                        viewModel.setFillColor(hex)
                        showFillColorPicker = false
                    }
                }
                // Text color
                compactButton(icon: "paintpalette") {
                    showTextColorPicker.toggle()
                }
                .popover(isPresented: $showTextColorPicker) {
                    STExcelColorPicker(
                        title: STStrings.ribbonTextColor,
                        colors: STExcelColorPresets.textColors,
                        showNone: false
                    ) { hex in
                        viewModel.setTextColor(hex)
                        showTextColorPicker = false
                    }
                }
            }
        }
    }

    // MARK: - AutoSum Button (with dropdown)

    private var autoSumButton: some View {
        Menu {
            Button(STExcelStrings.sum) { viewModel.insertAutoFormula("SUM") }
            Button(STExcelStrings.average) { viewModel.insertAutoFormula("AVERAGE") }
            Button(STExcelStrings.count) { viewModel.insertAutoFormula("COUNT") }
            Button(STExcelStrings.max) { viewModel.insertAutoFormula("MAX") }
            Button(STExcelStrings.min) { viewModel.insertAutoFormula("MIN") }
        } label: {
            VStack(spacing: 2) {
                Image(systemName: "sum")
                    .font(.system(size: 17, weight: .medium))
                    .frame(width: 24, height: 24)
                Text(STExcelStrings.autoSum)
                    .font(.system(size: 9, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundColor(.primary)
            .frame(width: 52, height: 50)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Insert Button (with dropdown)

    private var insertButton: some View {
        Menu {
            Section(STExcelStrings.insertOptions) {
                Button(STExcelStrings.shiftCellsRight) { viewModel.shiftCellsRight() }
                Button(STExcelStrings.shiftCellsDown) { viewModel.shiftCellsDown() }
                Divider()
                Button(STExcelStrings.entireRow) { viewModel.insertRow() }
                Button(STExcelStrings.entireColumn) { viewModel.insertColumn() }
                Divider()
                Button(STExcelStrings.rows) { viewModel.insertRow() }
                Button(STExcelStrings.columns) { viewModel.insertColumn() }
                Button(STExcelStrings.worksheet) { viewModel.addNewSheet() }
            }
        } label: {
            VStack(spacing: 2) {
                Image(systemName: "tablecells.badge.ellipsis")
                    .font(.system(size: 17, weight: .medium))
                    .frame(width: 24, height: 24)
                Text(STExcelStrings.insert)
                    .font(.system(size: 9, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundColor(.primary)
            .frame(width: 52, height: 50)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Delete Button (with dropdown)

    private var deleteButton: some View {
        Menu {
            Section(STExcelStrings.deleteOptions) {
                Button(STExcelStrings.shiftCellsLeft) { viewModel.shiftCellsLeft() }
                Button(STExcelStrings.shiftCellsUp) { viewModel.shiftCellsUp() }
                Divider()
                Button(STExcelStrings.entireRow) { viewModel.deleteRow() }
                Button(STExcelStrings.entireColumn) { viewModel.deleteColumn() }
                Divider()
                Button(STExcelStrings.rows) { viewModel.deleteRow() }
                Button(STExcelStrings.columns) { viewModel.deleteColumn() }
                Button(STExcelStrings.worksheet, role: .destructive) { viewModel.deleteSheet() }
            }
        } label: {
            VStack(spacing: 2) {
                Image(systemName: "tablecells.badge.ellipsis")
                    .font(.system(size: 17, weight: .medium))
                    .frame(width: 24, height: 24)
                Text(STExcelStrings.delete)
                    .font(.system(size: 9, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundColor(.primary)
            .frame(width: 52, height: 50)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Go to Cell

    private var goToCellButton: some View {
        STExcelRibbonToolButton(iconName: "arrow.right.doc.on.clipboard", label: STExcelStrings.goToCell) {
            showGoToCellAlert = true
        }
        .alert(STExcelStrings.goToCell, isPresented: $showGoToCellAlert) {
            TextField("A1", text: $goToCellRef)
                #if os(iOS)
                .textInputAutocapitalization(.characters)
                #endif
            Button(STStrings.cancel, role: .cancel) { goToCellRef = "" }
            Button(STExcelStrings.go) {
                if !goToCellRef.isEmpty {
                    viewModel.goToCell(goToCellRef)
                    goToCellRef = ""
                }
            }
        } message: {
            Text("Enter cell coordinates:")
        }
    }

    // MARK: - More Formatting Section

    private var moreFormattingSection: some View {
        HStack(spacing: 2) {
            // Clipboard
            STExcelRibbonToolButton(iconName: "doc.on.clipboard", label: STStrings.ribbonPaste) {
                viewModel.paste()
            }
            STExcelRibbonToolButton(iconName: "scissors", label: STExcelStrings.cut) {
                viewModel.cut()
            }
            STExcelRibbonToolButton(iconName: "doc.on.doc", label: STExcelStrings.copy) {
                viewModel.copy()
            }

            STExcelRibbonSeparator()

            // Font size
            STExcelRibbonToolButton(
                iconName: "plus.circle",
                label: "\(Int(viewModel.currentStyle.fontSize))"
            ) {
                viewModel.increaseFontSize()
            }
            STExcelRibbonToolButton(iconName: "minus.circle", label: STStrings.ribbonFontSize) {
                viewModel.decreaseFontSize()
            }

            STExcelRibbonSeparator()

            // Align right
            STExcelRibbonToolButton(
                iconName: "text.alignright",
                label: STStrings.ribbonAlignRight,
                isActive: viewModel.currentStyle.horizontalAlignment == .right
            ) {
                viewModel.setHorizontalAlignment(.right)
            }

            // Wrap Text
            STExcelRibbonToolButton(
                iconName: "text.word.spacing",
                label: STExcelStrings.wrapText,
                isActive: viewModel.currentStyle.wrapText
            ) {
                viewModel.toggleWrapText()
            }

            // Merge
            STExcelRibbonToolButton(
                iconName: "rectangle.arrowtriangle.2.outward",
                label: STExcelStrings.merge,
                isActive: viewModel.isSelectionMerged
            ) {
                if viewModel.isSelectionMerged {
                    viewModel.unmergeCells()
                } else {
                    viewModel.mergeCells()
                }
            }

            STExcelRibbonSeparator()

            // Borders
            STExcelRibbonToolButton(iconName: "square.dashed", label: STExcelStrings.borders) {
                showBorderPicker.toggle()
            }
            .popover(isPresented: $showBorderPicker) {
                STExcelBorderPicker { borders in
                    viewModel.setBorders(borders)
                    showBorderPicker = false
                }
            }
        }
    }

    // MARK: - Compact Icon Button Helper

    private func compactButton(icon: String, active: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(active ? .white : .primary)
                .frame(width: 36, height: 24)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(active ? Color.stExcelAccent : Color.clear)
                )
        }
        .buttonStyle(.plain)
    }
}
