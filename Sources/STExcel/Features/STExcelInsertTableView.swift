import SwiftUI
import STKit

/// Sheet for creating a new table from a range
struct STExcelInsertTableView: View {
    @ObservedObject var viewModel: STExcelEditorViewModel
    let onInsert: (STExcelTable) -> Void
    let onCancel: () -> Void

    @State private var rangeText: String = ""
    @State private var hasHeaders = true
    @State private var selectedStyle: STExcelTableStyle = .blue

    var body: some View {
        NavigationView {
            List {
                Section(STExcelStrings.dataRange) {
                    TextField("e.g. A1:F10", text: $rangeText)
                        .font(.system(size: 15, design: .monospaced))
                }

                Section {
                    Toggle(STExcelStrings.myTableHasHeaders, isOn: $hasHeaders)
                }

                Section(STExcelStrings.tableStyle) {
                    LazyVGrid(columns: [
                        GridItem(.flexible()), GridItem(.flexible()),
                        GridItem(.flexible()), GridItem(.flexible()),
                    ], spacing: 10) {
                        ForEach(STExcelTableStyle.allCases) { style in
                            Button {
                                selectedStyle = style
                            } label: {
                                VStack(spacing: 2) {
                                    stylePreview(style)
                                        .frame(height: 40)
                                        .clipShape(RoundedRectangle(cornerRadius: 4))
                                    Text(style.displayName)
                                        .font(.system(size: 9))
                                        .foregroundColor(.primary)
                                }
                                .padding(4)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(selectedStyle == style ? Color.stExcelAccent : Color.clear, lineWidth: 2)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle(STExcelStrings.insertTable)
            .stNavigationBarTitleDisplayMode()
            .toolbar {
                ToolbarItem(placement: .stLeading) {
                    Button(STStrings.cancel) { onCancel() }
                }
                ToolbarItem(placement: .stTrailing) {
                    Button(STExcelStrings.insert) {
                        if let table = parseRange() {
                            onInsert(table)
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(parseRange() == nil)
                }
            }
            .onAppear {
                autoDetectRange()
            }
        }
    }

    private func autoDetectRange() {
        let sr = viewModel.selectionStartRow
        let sc = viewModel.selectionStartCol
        let er = viewModel.selectionActualEndRow
        let ec = viewModel.selectionActualEndCol

        if sr != er || sc != ec {
            // Use current selection
            rangeText = "\(STExcelSheet.columnLetter(sc))\(sr + 1):\(STExcelSheet.columnLetter(ec))\(er + 1)"
        } else if let sheet = viewModel.sheet {
            // Auto-detect data region from selected cell
            var minR = sr, maxR = sr, minC = sc, maxC = sc
            let maxScan = min(sheet.rowCount, sr + 30)
            let maxCScan = min(sheet.columnCount, sc + 15)

            for r in 0..<maxScan {
                for c in 0..<maxCScan {
                    if !sheet.cell(row: r, column: c).value.isEmpty {
                        minR = min(minR, r); maxR = max(maxR, r)
                        minC = min(minC, c); maxC = max(maxC, c)
                    }
                }
            }
            let capR = min(maxR, minR + 30)
            rangeText = "\(STExcelSheet.columnLetter(minC))\(minR + 1):\(STExcelSheet.columnLetter(maxC))\(capR + 1)"
        }
    }

    private func parseRange() -> STExcelTable? {
        let parts = rangeText.uppercased().split(separator: ":")
        guard parts.count == 2 else { return nil }

        guard let (sr, sc) = parseCellRef(String(parts[0])),
              let (er, ec) = parseCellRef(String(parts[1])) else { return nil }

        guard er >= sr && ec >= sc else { return nil }

        let tableCount = viewModel.tables.count + 1
        return STExcelTable(
            startRow: sr, startCol: sc,
            endRow: er, endCol: ec,
            style: selectedStyle,
            hasHeaders: hasHeaders,
            name: "Table\(tableCount)"
        )
    }

    private func parseCellRef(_ ref: String) -> (Int, Int)? {
        var colStr = ""
        var rowStr = ""
        for ch in ref {
            if ch.isLetter { colStr.append(ch) }
            else if ch.isNumber { rowStr.append(ch) }
        }
        guard !colStr.isEmpty, let row = Int(rowStr), row > 0 else { return nil }

        var col = 0
        for ch in colStr {
            col = col * 26 + Int(ch.asciiValue! - Character("A").asciiValue!) + 1
        }
        return (row - 1, col - 1) // 0-indexed
    }

    private func stylePreview(_ style: STExcelTableStyle) -> some View {
        VStack(spacing: 0) {
            // Header
            Rectangle().fill(style.headerColor).frame(height: 10)
            // Banded rows
            ForEach(0..<3, id: \.self) { i in
                Rectangle()
                    .fill(i.isMultiple(of: 2) ? style.bandColor : Color.stSystemBackground)
                    .frame(height: 10)
            }
        }
    }
}
