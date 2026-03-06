import SwiftUI
import Charts
import STKit

/// The spreadsheet grid — renders cells in a scrollable 2D grid with formatting support
public struct STExcelGridView: View {
    @ObservedObject var sheet: STExcelSheet
    let configuration: STExcelConfiguration
    let isEditable: Bool
    @ObservedObject var editorViewModel: STExcelEditorViewModel
    var ribbonViewModel: STExcelRibbonViewModel?

    @FocusState private var isFormulaBarFocused: Bool
    @GestureState private var chartDragOffset: CGSize = .zero
    @GestureState private var imageDragOffset: CGSize = .zero
    @GestureState private var imageResizeDelta: CGSize = .zero
    @GestureState private var shapeDragOffset: CGSize = .zero
    @GestureState private var shapeResizeDelta: CGSize = .zero
    @State private var scrollOffset: CGPoint = .zero

    init(sheet: STExcelSheet, configuration: STExcelConfiguration = .default,
         isEditable: Bool = true, editorViewModel: STExcelEditorViewModel,
         ribbonViewModel: STExcelRibbonViewModel? = nil) {
        self.sheet = sheet
        self.configuration = configuration
        self.isEditable = isEditable
        self.editorViewModel = editorViewModel
        self.ribbonViewModel = ribbonViewModel
    }

    private var zoom: CGFloat {
        max(0.25, min(editorViewModel.zoomScale, 4.0))
    }

    // Zoomed dimension helpers
    private func zColW(_ col: Int) -> CGFloat {
        editorViewModel.columnWidth(for: col, default: configuration.columnWidth) * zoom
    }
    private func zRowH(_ row: Int) -> CGFloat {
        editorViewModel.rowHeight(for: row, default: configuration.rowHeight) * zoom
    }
    private var zHeaderW: CGFloat { (editorViewModel.showHeadings ? configuration.rowHeaderWidth : 0) * zoom }
    private var zHeaderH: CGFloat { (editorViewModel.showHeadings ? configuration.columnHeaderHeight : 0) * zoom }

    public var body: some View {
        VStack(spacing: 0) {
            // Formula / cell value bar
            if isEditable && editorViewModel.showFormulaBar,
               let row = editorViewModel.selectedRow, let col = editorViewModel.selectedCol {
                cellValueBar(row: row, col: col)
                Divider()
            }

            // Grid + zoom controls
            ZStack(alignment: .bottomTrailing) {
                ScrollViewReader { scrollProxy in
                    ScrollView([.horizontal, .vertical], showsIndicators: true) {
                        ZStack(alignment: .topLeading) {
                            LazyVStack(alignment: .leading, spacing: 0, pinnedViews: []) {
                                // Column headers
                                if editorViewModel.showHeadings {
                                    columnHeaders
                                }

                                // Data rows — use gridRefreshId to force re-render after sort/filter
                                ForEach(Array(0..<sheet.rowCount), id: \.self) { row in
                                    if !editorViewModel.hiddenRows.contains(row) {
                                        dataRow(row)
                                    }
                                }
                                .id(editorViewModel.gridRefreshId)
                            }

                            // Selection overlay with drag handles
                            if isEditable, editorViewModel.selectedRow != nil, editorViewModel.selectedChartId == nil {
                                selectionOverlay
                            }

                            // Invisible anchor at top-left for zoom scroll reset
                            Color.clear
                                .frame(width: 1, height: 1)
                                .id("grid-top-left")

                            // Track scroll offset for chart overlay positioning
                            GeometryReader { geo in
                                Color.clear.preference(
                                    key: ScrollOffsetKey.self,
                                    value: CGPoint(
                                        x: geo.frame(in: .named("gridScroll")).minX,
                                        y: geo.frame(in: .named("gridScroll")).minY
                                    )
                                )
                            }
                            .frame(width: 1, height: 1)
                        }
                        .frame(
                            width: totalGridWidth,
                            height: totalGridHeight,
                            alignment: .topLeading
                        )
                    }
                    .coordinateSpace(name: "gridScroll")
                    .onPreferenceChange(ScrollOffsetKey.self) { newOffset in
                        withTransaction(Transaction(animation: nil)) {
                            scrollOffset = newOffset
                        }
                    }
                    .onChange(of: editorViewModel.zoomScale) { _ in
                        withAnimation(.easeOut(duration: 0.2)) {
                            scrollProxy.scrollTo("grid-top-left", anchor: .topLeading)
                        }
                    }
                }

                // Charts overlay — OUTSIDE ScrollView, no gesture conflict with scroll
                chartOverlay
                    .clipped()
                    .transaction { $0.animation = nil }

                // Images overlay — same pattern as charts
                imageOverlay
                    .clipped()
                    .transaction { $0.animation = nil }

                // Shapes overlay
                shapeOverlay
                    .clipped()
                    .transaction { $0.animation = nil }

                // Zoom controls — floating bottom-right
                zoomControls
                    .padding(12)

                // Resize tooltip overlay
                if let tooltip = editorViewModel.resizeTooltip {
                    resizeTooltipView(tooltip)
                }
            }
        }
        .onChange(of: editorViewModel.selectedChartId) { chartId in
            if chartId != nil {
                ribbonViewModel?.activateChartTab()
            } else {
                ribbonViewModel?.deactivateChartTab()
            }
        }
        .onChange(of: editorViewModel.selectedShapeId) { shapeId in
            if shapeId != nil {
                ribbonViewModel?.activateShapeTab()
            } else {
                ribbonViewModel?.deactivateShapeTab()
            }
        }
        .onChange(of: editorViewModel.selectedTableId) { tableId in
            if tableId != nil {
                ribbonViewModel?.activateTableTab()
            } else {
                ribbonViewModel?.deactivateTableTab()
            }
        }
        .onChange(of: editorViewModel.isEditing) { editing in
            if editing {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isFormulaBarFocused = true
                }
            } else {
                isFormulaBarFocused = false
            }
        }
    }

    // MARK: - Zoom Controls (floating)

    private var zoomControls: some View {
        HStack(spacing: 0) {
            Button {
                editorViewModel.zoomScale = max(0.25, editorViewModel.zoomScale - 0.25)
            } label: {
                Image(systemName: "minus")
                    .font(.system(size: 14, weight: .bold))
                    .frame(width: 36, height: 36)
            }

            Text("\(Int(zoom * 100))%")
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .frame(width: 48)

            Button {
                editorViewModel.zoomScale = min(4.0, editorViewModel.zoomScale + 0.25)
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .bold))
                    .frame(width: 36, height: 36)
            }
        }
        .foregroundColor(.primary)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.12), radius: 4, x: 0, y: 2)
        )
    }

    // MARK: - Grid Dimensions

    private var totalGridWidth: CGFloat {
        let cols = min(sheet.columnCount, 50)
        var w: CGFloat = zHeaderW
        for c in 0..<cols { w += zColW(c) }
        // Ensure charts/images fit within scrollable area
        for chart in editorViewModel.charts {
            let chartRight = (chart.x + chart.width) * zoom + 20
            w = max(w, chartRight)
        }
        for img in editorViewModel.images {
            let imgRight = (img.x + img.width) * zoom + 20
            w = max(w, imgRight)
        }
        for shape in editorViewModel.shapes {
            let shapeRight = (shape.x + shape.width) * zoom + 20
            w = max(w, shapeRight)
        }
        return w
    }

    private var totalGridHeight: CGFloat {
        let rows = sheet.rowCount
        var h: CGFloat = zHeaderH
        for r in 0..<rows {
            if editorViewModel.hiddenRows.contains(r) { continue }
            h += zRowH(r)
        }
        // Ensure charts/images/shapes fit within scrollable area
        for chart in editorViewModel.charts {
            let chartBottom = (chart.y + chart.height) * zoom + 20
            h = max(h, chartBottom)
        }
        for img in editorViewModel.images {
            let imgBottom = (img.y + img.height) * zoom + 20
            h = max(h, imgBottom)
        }
        for shape in editorViewModel.shapes {
            let shapeBottom = (shape.y + shape.height) * zoom + 20
            h = max(h, shapeBottom)
        }
        return h
    }

    // MARK: - Resize Tooltip

    private func resizeTooltipView(_ text: String) -> some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Text(text)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.black.opacity(0.85))
                    )
                Spacer()
            }
            Spacer()
        }
        .allowsHitTesting(false)
    }

    // MARK: - Cell Value Bar

    private func cellValueBar(row: Int, col: Int) -> some View {
        HStack(spacing: 8) {
            Text(editorViewModel.cellReferenceString)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 50)

            Rectangle()
                .fill(Color.stSeparator)
                .frame(width: 1, height: 20)

            if editorViewModel.isEditing {
                TextField("", text: $editorViewModel.editingValue, onCommit: {
                    editorViewModel.commitEdit()
                })
                .font(.system(size: 14))
                .textFieldStyle(.plain)
                .focused($isFormulaBarFocused)

                // Confirm / Cancel buttons
                Button {
                    editorViewModel.commitEdit()
                } label: {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.stExcelAccent)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)

                Button {
                    editorViewModel.cancelEdit()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.red)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
            } else {
                let cell = sheet.cell(row: row, column: col)
                Text(cell.formula ?? cell.value)
                    .font(.system(size: 14))
                    .lineLimit(1)
                Spacer()
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.stSecondarySystemBackground)
    }

    // MARK: - Column Headers

    private var columnHeaders: some View {
        HStack(spacing: 0) {
            // Corner cell
            Rectangle()
                .fill(configuration.headerBackgroundColor)
                .frame(width: zHeaderW, height: zHeaderH)
                .overlay(Rectangle().stroke(configuration.gridLineColor, lineWidth: 0.5))

            ForEach(0..<min(sheet.columnCount, 50), id: \.self) { col in
                let colW = zColW(col)
                ZStack(alignment: .trailing) {
                    Text(STExcelSheet.columnLetter(col))
                        .font(.system(size: max(8, 12 * zoom), weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(width: colW, height: zHeaderH)
                        .background(
                            isColumnSelected(col)
                                ? configuration.selectionColor.opacity(0.15)
                                : configuration.headerBackgroundColor
                        )
                        .overlay(Rectangle().stroke(configuration.gridLineColor, lineWidth: 0.5))

                    // Column resize drag handle
                    if isEditable {
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: 8, height: zHeaderH)
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 1)
                                    .onChanged { value in
                                        let currentW = editorViewModel.columnWidth(for: col, default: configuration.columnWidth)
                                        let newW = max(30, currentW + value.translation.width / zoom)
                                        editorViewModel.columnWidths[col] = newW
                                        let wCm = newW / 96.0 * 2.54
                                        editorViewModel.resizeTooltip = String(format: "Width: %.2f cm", wCm)
                                    }
                                    .onEnded { _ in
                                        editorViewModel.resizeTooltip = nil
                                    }
                            )
                    }
                }
            }
        }
    }

    // MARK: - Data Row

    private func dataRow(_ row: Int) -> some View {
        let rowH = zRowH(row)
        return HStack(spacing: 0) {
            // Row number with resize handle + group indicator
            if editorViewModel.showHeadings {
                ZStack(alignment: .bottom) {
                    HStack(spacing: 0) {
                        // Group indicator bar
                        if editorViewModel.groupedRows.contains(row) {
                            Rectangle()
                                .fill(Color.stExcelAccent)
                                .frame(width: max(2, 3 * zoom))
                        }
                        Text("\(row + 1)")
                            .font(.system(size: max(8, 12 * zoom), weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .frame(width: zHeaderW, height: rowH)
                    .background(
                        isRowSelected(row)
                            ? configuration.selectionColor.opacity(0.15)
                            : editorViewModel.groupedRows.contains(row)
                                ? Color.stExcelAccent.opacity(0.08)
                                : configuration.headerBackgroundColor
                    )
                    .overlay(Rectangle().stroke(configuration.gridLineColor, lineWidth: 0.5))

                    // Row resize drag handle
                    if isEditable {
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: zHeaderW, height: 8)
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 1)
                                    .onChanged { value in
                                        let currentH = editorViewModel.rowHeight(for: row, default: configuration.rowHeight)
                                        let newH = max(16, currentH + value.translation.height / zoom)
                                        editorViewModel.rowHeights[row] = newH
                                        let hCm = newH / 96.0 * 2.54
                                        editorViewModel.resizeTooltip = String(format: "Height: %.2f cm", hCm)
                                    }
                                    .onEnded { _ in
                                        editorViewModel.resizeTooltip = nil
                                    }
                            )
                    }
                }
            }

            // Cells
            ForEach(0..<min(sheet.columnCount, 50), id: \.self) { col in
                cellView(row: row, col: col, rowH: rowH)
            }
        }
    }

    // MARK: - Cell

    private func cellView(row: Int, col: Int, rowH: CGFloat) -> some View {
        let cell = sheet.cell(row: row, column: col)
        let style = cell.style
        let isSelected = isCellSelected(row: row, col: col)
        let isInRange = isCellInRange(row: row, col: col)
        let colW = zColW(col)

        // Compute display value (prefer cached value from xlsx, evaluate only if empty)
        let rawValue: String
        if !cell.value.isEmpty {
            rawValue = cell.value
        } else if let formula = cell.formula {
            rawValue = STExcelFormulaEngine.evaluate(formula, in: sheet)
        } else {
            rawValue = cell.value
        }
        let displayValue = Self.applyNumberFormat(rawValue, style: style)

        // Check if cell is part of a merged region but not the origin
        let mergedRegion = sheet.mergedRegion(for: row, col: col)
        let isMergedNonOrigin = mergedRegion != nil &&
            (mergedRegion!.startRow != row || mergedRegion!.startCol != col)

        if isMergedNonOrigin {
            return AnyView(Color.clear.frame(width: 0, height: 0))
        }

        // Cell width/height (expanded for merged cells, zoomed)
        let cellWidth = mergedRegion.map { region in
            var w: CGFloat = 0
            for c in region.startCol...region.endCol { w += zColW(c) }
            return w
        } ?? colW

        let cellHeight = mergedRegion.map { region in
            var h: CGFloat = 0
            for r in region.startRow...region.endRow { h += zRowH(r) }
            return h
        } ?? rowH

        // Merged cell spanning multiple rows should not inflate the HStack
        let spansMultipleRows = mergedRegion.map { $0.endRow > row } ?? false

        // Alignment
        let hAlign: Alignment
        switch style.horizontalAlignment {
        case .left: hAlign = .leading
        case .center: hAlign = .center
        case .right: hAlign = .trailing
        case .justify: hAlign = .leading
        case .general: hAlign = cell.isNumeric ? .trailing : .leading
        }

        // Conditional formatting result
        let cfResult = editorViewModel.conditionalFormat(row: row, col: col)

        // Background color — CF > table > cell style
        let bgColor: Color
        if let cfBg = cfResult?.bg {
            bgColor = cfBg
        } else if let cfScale = cfResult?.scaleBg {
            bgColor = cfScale
        } else if let hex = style.fillColor, let c = Color(hex: hex) {
            bgColor = c
        } else if let tbl = editorViewModel.table(at: row, col: col) {
            if tbl.isHeaderRow(row) {
                bgColor = tbl.style.headerColor
            } else if tbl.isBandedRow(row) {
                bgColor = tbl.style.bandColor
            } else {
                bgColor = configuration.cellBackgroundColor
            }
        } else {
            bgColor = configuration.cellBackgroundColor
        }

        // Text color — CF > table > cell style
        let textColor: Color
        if let cfText = cfResult?.text {
            textColor = cfText
        } else if let hex = style.textColor, let c = Color(hex: hex) {
            textColor = c
        } else if let tbl = editorViewModel.table(at: row, col: col), tbl.isHeaderRow(row) {
            textColor = .white
        } else {
            textColor = .primary
        }

        // Font (zoomed) — table headers are bold
        let isTableHeader = editorViewModel.table(at: row, col: col)?.isHeaderRow(row) == true
        let fontSize = max(6, CGFloat(style.fontSize) * zoom)
        let isBold = style.isBold || isTableHeader
        var font: Font = .system(size: fontSize)
        if isBold && style.isItalic {
            font = .system(size: fontSize, weight: .bold).italic()
        } else if isBold {
            font = .system(size: fontSize, weight: .bold)
        } else if style.isItalic {
            font = .system(size: fontSize).italic()
        }

        return AnyView(
            Text(displayValue)
                .font(font)
                .underline(style.isUnderline)
                .strikethrough(style.isStrikethrough)
                .foregroundColor(textColor)
                .lineLimit(style.wrapText ? nil : 1)
                .padding(.horizontal, max(2, 4 * zoom))
                .frame(width: cellWidth, height: cellHeight, alignment: hAlign)
                .clipped()
                .background(bgColor)
                .background(
                    isSelected ? configuration.selectionColor.opacity(0.1) :
                    isInRange ? configuration.selectionColor.opacity(0.05) :
                    Color.clear
                )
                .overlay(cellBorderOverlay(style: style, isSelected: isSelected))
                // Data bar overlay
                .overlay(alignment: .leading) {
                    if let (pct, barColor) = cfResult?.bar {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(barColor.opacity(0.3))
                            .frame(width: max(0, cellWidth * CGFloat(pct)), height: cellHeight - 4)
                            .overlay(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(barColor.opacity(0.7))
                                    .frame(width: max(0, cellWidth * CGFloat(pct)), height: cellHeight - 4)
                            }
                            .padding(.leading, 2)
                            .allowsHitTesting(false)
                    }
                }
                // CF border
                .overlay {
                    if let cfBorder = cfResult?.border {
                        Rectangle().stroke(cfBorder, lineWidth: 1.5)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture(count: 2) {
                    // Double tap = direct keyboard focus on formula bar
                    if isEditable && !(editorViewModel.isSheetProtected && cell.style.isLocked) {
                        editorViewModel.selectCell(row: row, col: col)
                        editorViewModel.editingValue = cell.formula ?? cell.value
                        editorViewModel.isEditing = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isFormulaBarFocused = true
                        }
                    }
                }
                .onTapGesture(count: 1) {
                    // Single tap = select + start editing
                    if editorViewModel.isEditing {
                        editorViewModel.commitEdit()
                    }
                    if editorViewModel.selectedChartId != nil {
                        editorViewModel.selectedChartId = nil
                    }
                    editorViewModel.selectedImageId = nil
                    editorViewModel.selectedShapeId = nil
                    // Select table if cell is in one
                    if let tbl = editorViewModel.table(at: row, col: col) {
                        editorViewModel.selectedTableId = tbl.id
                    } else {
                        editorViewModel.selectedTableId = nil
                    }
                    editorViewModel.selectCell(row: row, col: col)
                    editorViewModel.editingValue = cell.formula ?? cell.value
                    if isEditable && !(editorViewModel.isSheetProtected && cell.style.isLocked) {
                        editorViewModel.isEditing = true
                    }
                }
                // Comment indicator
                .overlay(alignment: .topTrailing) {
                    if cell.comment != nil {
                        Triangle()
                            .fill(Color.red)
                            .frame(width: max(4, 8 * zoom), height: max(4, 8 * zoom))
                    }
                }
                // Invalid data circle (Data Validation)
                .overlay {
                    if editorViewModel.invalidCells.contains("\(row),\(col)") {
                        Ellipse()
                            .stroke(Color.red, lineWidth: max(1, 2 * zoom))
                            .padding(max(1, 2 * zoom))
                    }
                }
                // For merged cells spanning multiple rows, constrain layout height
                // to current row only — prevents HStack row inflation while allowing
                // visual content to overflow into subsequent rows
                .frame(height: spansMultipleRows ? rowH : nil, alignment: .topLeading)
                .zIndex(spansMultipleRows ? 1 : 0)
        )
    }

    // MARK: - Border Overlay

    @ViewBuilder
    private func cellBorderOverlay(style: STExcelCellStyle, isSelected: Bool) -> some View {
        if isSelected {
            Rectangle().stroke(configuration.selectionColor, lineWidth: 2)
        } else if editorViewModel.showGridlines {
            if style.borders.hasAny {
                Canvas { context, size in
                    let borderColor = Color.primary.opacity(0.8)
                    if style.borders.left != .none {
                        var path = Path()
                        path.move(to: CGPoint(x: 0, y: 0))
                        path.addLine(to: CGPoint(x: 0, y: size.height))
                        context.stroke(path, with: .color(borderColor),
                                       lineWidth: borderWidth(style.borders.left))
                    }
                    if style.borders.right != .none {
                        var path = Path()
                        path.move(to: CGPoint(x: size.width, y: 0))
                        path.addLine(to: CGPoint(x: size.width, y: size.height))
                        context.stroke(path, with: .color(borderColor),
                                       lineWidth: borderWidth(style.borders.right))
                    }
                    if style.borders.top != .none {
                        var path = Path()
                        path.move(to: CGPoint(x: 0, y: 0))
                        path.addLine(to: CGPoint(x: size.width, y: 0))
                        context.stroke(path, with: .color(borderColor),
                                       lineWidth: borderWidth(style.borders.top))
                    }
                    if style.borders.bottom != .none {
                        var path = Path()
                        path.move(to: CGPoint(x: 0, y: size.height))
                        path.addLine(to: CGPoint(x: size.width, y: size.height))
                        context.stroke(path, with: .color(borderColor),
                                       lineWidth: borderWidth(style.borders.bottom))
                    }
                }
            } else {
                Rectangle().stroke(configuration.gridLineColor, lineWidth: 0.5)
            }
        }
    }

    private func borderWidth(_ style: STBorderStyle) -> CGFloat {
        switch style {
        case .none: return 0
        case .thin: return 1
        case .medium: return 1.5
        case .thick: return 2
        case .dashed, .dotted: return 1
        case .double_: return 2
        }
    }

    // MARK: - Selection Overlay with Drag Handles

    @ViewBuilder
    private var selectionOverlay: some View {
        let sr = min(editorViewModel.selectionStartRow, editorViewModel.selectionActualEndRow)
        let sc = min(editorViewModel.selectionStartCol, editorViewModel.selectionActualEndCol)
        let er = max(editorViewModel.selectionStartRow, editorViewModel.selectionActualEndRow)
        let ec = max(editorViewModel.selectionStartCol, editorViewModel.selectionActualEndCol)

        let x = zHeaderW + editorViewModel.columnOffset(for: sc, default: configuration.columnWidth) * zoom
        let y = zHeaderH + editorViewModel.rowOffset(for: sr, default: configuration.rowHeight) * zoom

        let selW: CGFloat = {
            var total: CGFloat = 0
            for c in sc...ec { total += zColW(c) }
            return total
        }()
        let selH: CGFloat = {
            var total: CGFloat = 0
            for r in sr...er {
                if editorViewModel.hiddenRows.contains(r) { continue }
                total += zRowH(r)
            }
            return total
        }()

        Rectangle()
            .fill(configuration.selectionColor.opacity(0.08))
            .overlay(
                Rectangle()
                    .stroke(configuration.selectionColor, style: StrokeStyle(lineWidth: 2, dash: [6, 3]))
            )
            .frame(width: selW, height: selH)
            .overlay(alignment: .topLeading) {
                selectionHandle
                    .offset(x: -7, y: -7)
                    .gesture(topLeftDragGesture(sr: sr, sc: sc, er: er, ec: ec))
            }
            .overlay(alignment: .bottomTrailing) {
                selectionHandle
                    .offset(x: 7, y: 7)
                    .gesture(bottomRightDragGesture(sr: sr, sc: sc, er: er, ec: ec))
            }
            .offset(x: x, y: y)
            .allowsHitTesting(true)
    }

    private func topLeftDragGesture(sr: Int, sc: Int, er: Int, ec: Int) -> some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { value in
                let avgColW = zColW(sc)
                let avgRowH = zRowH(sr)
                let dCol = Int(value.translation.width / avgColW)
                let dRow = Int(value.translation.height / avgRowH)
                let newRow = max(0, min(sr + dRow, er))
                let newCol = max(0, min(sc + dCol, ec))
                editorViewModel.selectedRow = newRow
                editorViewModel.selectedCol = newCol
            }
    }

    private func bottomRightDragGesture(sr: Int, sc: Int, er: Int, ec: Int) -> some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { value in
                let avgColW = zColW(ec)
                let avgRowH = zRowH(er)
                let dCol = Int(value.translation.width / avgColW)
                let dRow = Int(value.translation.height / avgRowH)
                let newRow = max(sr, min(er + dRow, sheet.rowCount - 1))
                let newCol = max(sc, min(ec + dCol, sheet.columnCount - 1))
                editorViewModel.selectionEndRow = newRow
                editorViewModel.selectionEndCol = newCol
            }
    }

    private var selectionHandle: some View {
        Circle()
            .fill(configuration.selectionColor)
            .frame(width: 14, height: 14)
            .overlay(Circle().stroke(Color.white, lineWidth: 2))
            .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
    }

    // MARK: - Chart Overlay (outside ScrollView — no gesture conflict)

    private var chartOverlay: some View {
        ZStack(alignment: .topLeading) {
            // Invisible fill so ZStack takes full size; passes touches through
            Color.clear.contentShape(Rectangle()).allowsHitTesting(false)

            ForEach(editorViewModel.charts) { chart in
                chartOverlayItem(chart)
            }
        }
    }

    private func chartOverlayItem(_ chart: STExcelEmbeddedChart) -> some View {
        let isSelected = chart.id == editorViewModel.selectedChartId
        let cw = chart.width * zoom
        let ch = chart.height * zoom
        let ox = chart.x * zoom + scrollOffset.x
        let oy = chart.y * zoom + scrollOffset.y
        let dragX = isSelected ? chartDragOffset.width : 0
        let dragY = isSelected ? chartDragOffset.height : 0

        return ZStack(alignment: .topTrailing) {
            // Chart content
            ZStack {
                embeddedChartContent(chart)
                    .frame(width: cw, height: ch)
                    .drawingGroup()
                    .background(Color.stSystemBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(isSelected ? Color.stExcelAccent : Color.stSeparator,
                                    lineWidth: isSelected ? 2.5 : 1)
                    )
                    .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 1)

                if isSelected {
                    chartResizeHandles(chart, cw: cw, ch: ch)
                }
            }

            // Delete button (top-right)
            if isSelected {
                Button {
                    editorViewModel.deleteSelectedChart()
                    ribbonViewModel?.deactivateChartTab()
                } label: {
                    Image(systemName: "trash.circle.fill")
                        .font(.system(size: 28))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, Color.red)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                }
                .offset(x: 8, y: -8)
            }
        }
        .frame(width: cw, height: ch)
        // Size tooltip below chart
        .overlay(alignment: .bottom) {
            if isSelected {
                Text(chart.sizeTooltip)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.black.opacity(0.8)))
                    .offset(y: 28)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if editorViewModel.selectedChartId == chart.id {
                editorViewModel.selectedChartId = nil
            } else {
                editorViewModel.selectedChartId = chart.id
                ribbonViewModel?.activateChartTab()
            }
        }
        // Gesture BEFORE offset — so gesture coordinate space is NOT affected by .offset()
        .if(isSelected) { view in
            view.gesture(
                DragGesture(minimumDistance: 20, coordinateSpace: .global)
                    .updating($chartDragOffset) { value, state, _ in
                        state = value.translation
                    }
                    .onEnded { value in
                        if var c = editorViewModel.charts.first(where: { $0.id == chart.id }) {
                            c.x = max(0, chart.x + value.translation.width / zoom)
                            c.y = max(0, chart.y + value.translation.height / zoom)
                            editorViewModel.updateChart(c)
                        }
                    }
            )
        }
        // Offset AFTER gesture — view moves visually but gesture coord space stays stable
        .offset(x: ox + dragX, y: oy + dragY)
    }

    // MARK: - Shape Overlay

    private var shapeOverlay: some View {
        ZStack(alignment: .topLeading) {
            Color.clear.contentShape(Rectangle()).allowsHitTesting(false)
            ForEach(editorViewModel.shapes) { shape in
                shapeOverlayItem(shape)
            }
        }
    }

    private func shapeOverlayItem(_ shape: STExcelEmbeddedShape) -> some View {
        let isSelected = shape.id == editorViewModel.selectedShapeId
        let rw = isSelected ? shapeResizeDelta.width * zoom : 0
        let rh = isSelected ? shapeResizeDelta.height * zoom : 0
        let sw = max(20 * zoom, shape.width * zoom + rw)
        let sh = max(20 * zoom, shape.height * zoom + rh)
        let ox = shape.x * zoom + scrollOffset.x
        let oy = shape.y * zoom + scrollOffset.y
        let dragX = isSelected ? shapeDragOffset.width : 0
        let dragY = isSelected ? shapeDragOffset.height : 0

        return shapeContent(shape)
            .frame(width: sw, height: sh)
            .drawingGroup()
            .overlay(
                RoundedRectangle(cornerRadius: 1)
                    .stroke(isSelected ? Color.stExcelAccent : Color.clear,
                            lineWidth: isSelected ? 2 : 0)
            )
            // Bottom-right: proportional resize
            .overlay(alignment: .bottomTrailing) {
                if isSelected {
                    Color.clear.frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                        .overlay(
                            Circle()
                                .fill(Color.stExcelAccent)
                                .frame(width: 16, height: 16)
                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        )
                        .highPriorityGesture(
                            DragGesture(coordinateSpace: .global)
                                .updating($shapeResizeDelta) { value, state, _ in
                                    state = CGSize(
                                        width: value.translation.width / zoom,
                                        height: value.translation.height / zoom
                                    )
                                }
                                .onEnded { value in
                                    if var s = editorViewModel.shapes.first(where: { $0.id == shape.id }) {
                                        s.width = max(20, shape.width + value.translation.width / zoom)
                                        s.height = max(20, shape.height + value.translation.height / zoom)
                                        editorViewModel.updateShape(s)
                                    }
                                }
                        )
                        .offset(x: 14, y: 14)
                }
            }
            // Delete button — top-left
            .overlay(alignment: .topLeading) {
                if isSelected {
                    Button {
                        editorViewModel.deleteSelectedShape()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, Color.red)
                            .shadow(color: .black.opacity(0.4), radius: 2, x: 0, y: 1)
                    }
                    .offset(x: -12, y: -12)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if editorViewModel.selectedShapeId == shape.id {
                    // Tapping already-selected shape deselects it
                    editorViewModel.selectedShapeId = nil
                } else {
                    editorViewModel.selectedShapeId = shape.id
                    editorViewModel.selectedChartId = nil
                    editorViewModel.selectedImageId = nil
                }
            }
            .if(isSelected) { view in
                view.gesture(
                    DragGesture(minimumDistance: 20, coordinateSpace: .global)
                        .updating($shapeDragOffset) { value, state, _ in
                            state = value.translation
                        }
                        .onEnded { value in
                            if var s = editorViewModel.shapes.first(where: { $0.id == shape.id }) {
                                s.x = max(0, shape.x + value.translation.width / zoom)
                                s.y = max(0, shape.y + value.translation.height / zoom)
                                editorViewModel.updateShape(s)
                            }
                        }
                )
            }
            .offset(x: ox + dragX, y: oy + dragY)
    }

    @ViewBuilder
    private func shapeContent(_ shape: STExcelEmbeddedShape) -> some View {
        switch shape.shapeType {
        case .rectangle:
            Rectangle()
                .fill(shape.fillColor)
                .overlay(Rectangle().stroke(shape.strokeColor, lineWidth: shape.strokeWidth))
        case .roundedRectangle:
            RoundedRectangle(cornerRadius: 8)
                .fill(shape.fillColor)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(shape.strokeColor, lineWidth: shape.strokeWidth))
        case .circle:
            Circle()
                .fill(shape.fillColor)
                .overlay(Circle().stroke(shape.strokeColor, lineWidth: shape.strokeWidth))
        case .oval:
            Ellipse()
                .fill(shape.fillColor)
                .overlay(Ellipse().stroke(shape.strokeColor, lineWidth: shape.strokeWidth))
        case .triangle:
            STExcelTriangleShape()
                .fill(shape.fillColor)
                .overlay(STExcelTriangleShape().stroke(shape.strokeColor, lineWidth: shape.strokeWidth))
        case .rightTriangle:
            STExcelRightTriangleShape()
                .fill(shape.fillColor)
                .overlay(STExcelRightTriangleShape().stroke(shape.strokeColor, lineWidth: shape.strokeWidth))
        case .diamond:
            STExcelDiamondShape()
                .fill(shape.fillColor)
                .overlay(STExcelDiamondShape().stroke(shape.strokeColor, lineWidth: shape.strokeWidth))
        case .arrowRight:
            STExcelArrowShape(direction: .right)
                .fill(shape.fillColor)
                .overlay(STExcelArrowShape(direction: .right).stroke(shape.strokeColor, lineWidth: shape.strokeWidth))
        case .arrowLeft:
            STExcelArrowShape(direction: .left)
                .fill(shape.fillColor)
                .overlay(STExcelArrowShape(direction: .left).stroke(shape.strokeColor, lineWidth: shape.strokeWidth))
        case .arrowUp:
            STExcelArrowShape(direction: .up)
                .fill(shape.fillColor)
                .overlay(STExcelArrowShape(direction: .up).stroke(shape.strokeColor, lineWidth: shape.strokeWidth))
        case .arrowDown:
            STExcelArrowShape(direction: .down)
                .fill(shape.fillColor)
                .overlay(STExcelArrowShape(direction: .down).stroke(shape.strokeColor, lineWidth: shape.strokeWidth))
        case .star:
            STExcelStarShape()
                .fill(shape.fillColor)
                .overlay(STExcelStarShape().stroke(shape.strokeColor, lineWidth: shape.strokeWidth))
        case .hexagon:
            STExcelHexagonShape()
                .fill(shape.fillColor)
                .overlay(STExcelHexagonShape().stroke(shape.strokeColor, lineWidth: shape.strokeWidth))
        case .pentagon:
            STExcelPentagonShape()
                .fill(shape.fillColor)
                .overlay(STExcelPentagonShape().stroke(shape.strokeColor, lineWidth: shape.strokeWidth))
        case .line:
            Rectangle()
                .fill(shape.strokeColor)
                .frame(height: max(shape.strokeWidth, 2))
        case .dashedLine:
            STExcelDashedLineShape()
                .stroke(shape.strokeColor, style: StrokeStyle(lineWidth: max(shape.strokeWidth, 2), dash: [8, 5]))
        }
    }

    // MARK: - Image Overlay

    private var imageOverlay: some View {
        ZStack(alignment: .topLeading) {
            Color.clear.contentShape(Rectangle()).allowsHitTesting(false)

            ForEach(editorViewModel.images) { img in
                imageOverlayItem(img)
            }
        }
    }

    private func imageOverlayItem(_ img: STExcelEmbeddedImage) -> some View {
        let isSelected = img.id == editorViewModel.selectedImageId
        // Live resize delta (only visual, model updated on gesture end)
        let rw = isSelected ? imageResizeDelta.width * zoom : 0
        let rh = isSelected ? imageResizeDelta.height * zoom : 0
        let iw = max(40 * zoom, img.width * zoom + rw)
        let ih = max(40 * zoom, img.height * zoom + rh)
        let ox = img.x * zoom + scrollOffset.x
        let oy = img.y * zoom + scrollOffset.y
        let dragX = isSelected ? imageDragOffset.width : 0
        let dragY = isSelected ? imageDragOffset.height : 0

        return STExcelCachedImageView(data: img.imageData)
            .frame(width: iw, height: ih)
            .clipped()
            .drawingGroup()
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(isSelected ? Color.stExcelAccent : Color.clear,
                            lineWidth: isSelected ? 2.5 : 0)
            )
            .shadow(color: .black.opacity(isSelected ? 0.15 : 0.05), radius: 2, x: 0, y: 1)
            // Bottom-right: proportional resize
            .overlay(alignment: .bottomTrailing) {
                if isSelected {
                    Color.clear.frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                        .overlay(
                            Circle()
                                .fill(Color.stExcelAccent)
                                .frame(width: 16, height: 16)
                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        )
                        .highPriorityGesture(
                            DragGesture(coordinateSpace: .global)
                                .updating($imageResizeDelta) { value, state, _ in
                                    let dw = value.translation.width / zoom
                                    let newW = max(40, img.width + dw)
                                    state = CGSize(
                                        width: newW - img.width,
                                        height: (newW / max(img.aspectRatio, 0.1)) - img.height
                                    )
                                }
                                .onEnded { value in
                                    if var i = editorViewModel.images.first(where: { $0.id == img.id }) {
                                        let newW = max(40, img.width + value.translation.width / zoom)
                                        i.width = newW
                                        i.height = newW / max(img.aspectRatio, 0.1)
                                        editorViewModel.updateImage(i)
                                    }
                                }
                        )
                        .offset(x: 14, y: 14)
                }
            }
            // Right edge: width only
            .overlay(alignment: .trailing) {
                if isSelected {
                    Color.clear.frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                        .overlay(
                            Circle()
                                .fill(Color.stExcelAccent.opacity(0.7))
                                .frame(width: 12, height: 12)
                                .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                        )
                        .highPriorityGesture(
                            DragGesture(coordinateSpace: .global)
                                .updating($imageResizeDelta) { value, state, _ in
                                    state = CGSize(width: value.translation.width / zoom, height: 0)
                                }
                                .onEnded { value in
                                    if var i = editorViewModel.images.first(where: { $0.id == img.id }) {
                                        i.width = max(40, img.width + value.translation.width / zoom)
                                        editorViewModel.updateImage(i)
                                    }
                                }
                        )
                        .offset(x: 14)
                }
            }
            // Bottom edge: height only
            .overlay(alignment: .bottom) {
                if isSelected {
                    Color.clear.frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                        .overlay(
                            Circle()
                                .fill(Color.stExcelAccent.opacity(0.7))
                                .frame(width: 12, height: 12)
                                .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                        )
                        .highPriorityGesture(
                            DragGesture(coordinateSpace: .global)
                                .updating($imageResizeDelta) { value, state, _ in
                                    state = CGSize(width: 0, height: value.translation.height / zoom)
                                }
                                .onEnded { value in
                                    if var i = editorViewModel.images.first(where: { $0.id == img.id }) {
                                        i.height = max(40, img.height + value.translation.height / zoom)
                                        editorViewModel.updateImage(i)
                                    }
                                }
                        )
                        .offset(y: 14)
                }
            }
            // Delete button — top-left outside
            .overlay(alignment: .topLeading) {
                if isSelected {
                    Button {
                        editorViewModel.deleteSelectedImage()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, Color.red)
                            .shadow(color: .black.opacity(0.4), radius: 2, x: 0, y: 1)
                    }
                    .offset(x: -12, y: -12)
                }
            }
            // Size tooltip below
            .overlay(alignment: .bottom) {
                if isSelected {
                    let wCm = (img.width + (isSelected ? imageResizeDelta.width : 0)) / 96.0 * 2.54
                    let hCm = (img.height + (isSelected ? imageResizeDelta.height : 0)) / 96.0 * 2.54
                    Text(String(format: "Width: %.2f cm\nHeight: %.2f cm", max(0, wCm), max(0, hCm)))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color.black.opacity(0.8)))
                        .offset(y: 32)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if editorViewModel.selectedImageId == img.id {
                    editorViewModel.selectedImageId = nil
                } else {
                    editorViewModel.selectedImageId = img.id
                    editorViewModel.selectedChartId = nil
                }
            }
            .if(isSelected) { view in
                view.gesture(
                    DragGesture(minimumDistance: 20, coordinateSpace: .global)
                        .updating($imageDragOffset) { value, state, _ in
                            state = value.translation
                        }
                        .onEnded { value in
                            if var i = editorViewModel.images.first(where: { $0.id == img.id }) {
                                i.x = max(0, img.x + value.translation.width / zoom)
                                i.y = max(0, img.y + value.translation.height / zoom)
                                editorViewModel.updateImage(i)
                            }
                        }
                )
            }
            .offset(x: ox + dragX, y: oy + dragY)
    }

    // MARK: - Chart Resize Handles

    private func chartResizeHandles(_ chart: STExcelEmbeddedChart, cw: CGFloat, ch: CGFloat) -> some View {
        ZStack {
            // Bottom-right handle
            Circle()
                .fill(Color.stExcelAccent)
                .frame(width: 14, height: 14)
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                .offset(x: cw / 2, y: ch / 2)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if var c = editorViewModel.charts.first(where: { $0.id == chart.id }) {
                                c.width = max(120, chart.width + value.translation.width / zoom)
                                c.height = max(80, chart.height + value.translation.height / zoom)
                                editorViewModel.updateChart(c)
                            }
                        }
                )

            // Top-left handle
            Circle()
                .fill(Color.stExcelAccent)
                .frame(width: 14, height: 14)
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                .offset(x: -cw / 2, y: -ch / 2)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if var c = editorViewModel.charts.first(where: { $0.id == chart.id }) {
                                let dw = -value.translation.width / zoom
                                let dh = -value.translation.height / zoom
                                let newW = max(120, chart.width + dw)
                                let newH = max(80, chart.height + dh)
                                c.x = chart.x - (newW - chart.width)
                                c.y = chart.y - (newH - chart.height)
                                c.width = newW
                                c.height = newH
                                editorViewModel.updateChart(c)
                            }
                        }
                )

            // Side handles
            Circle()
                .fill(Color.stExcelAccent.opacity(0.7))
                .frame(width: 10, height: 10)
                .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                .offset(x: cw / 2, y: 0)
            Circle()
                .fill(Color.stExcelAccent.opacity(0.7))
                .frame(width: 10, height: 10)
                .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                .offset(x: -cw / 2, y: 0)
            Circle()
                .fill(Color.stExcelAccent.opacity(0.7))
                .frame(width: 10, height: 10)
                .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                .offset(x: 0, y: ch / 2)
            Circle()
                .fill(Color.stExcelAccent.opacity(0.7))
                .frame(width: 10, height: 10)
                .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                .offset(x: 0, y: -ch / 2)
        }
    }

    @ViewBuilder
    private func embeddedChartContent(_ chart: STExcelEmbeddedChart) -> some View {
        let data = loadChartData(chart)
        let colors = chart.colorTheme.colors

        VStack(spacing: 2) {
            if !chart.title.isEmpty {
                Text(chart.title)
                    .font(.system(size: 11, weight: .semibold))
                    .lineLimit(1)
                    .padding(.top, 4)
            }

            if !data.isEmpty {
                Chart(data) { point in
                    switch chart.subtype.category {
                    case .column, .all:
                        BarMark(x: .value("X", point.label), y: .value("Y", point.value))
                            .foregroundStyle(by: .value("S", point.series))
                    case .bar:
                        BarMark(x: .value("Y", point.value), y: .value("X", point.label))
                            .foregroundStyle(by: .value("S", point.series))
                    case .line, .lineWithMarkers:
                        LineMark(x: .value("X", point.label), y: .value("Y", point.value))
                            .foregroundStyle(by: .value("S", point.series))
                    case .area:
                        AreaMark(x: .value("X", point.label), y: .value("Y", point.value))
                            .foregroundStyle(by: .value("S", point.series))
                            .opacity(0.6)
                    case .scatter:
                        PointMark(x: .value("X", point.label), y: .value("Y", point.value))
                            .foregroundStyle(by: .value("S", point.series))
                    case .pie:
                        BarMark(x: .value("X", point.label), y: .value("Y", point.value))
                            .foregroundStyle(by: .value("S", point.series))
                    }
                }
                .chartForegroundStyleScale(range: colors)
                .chartLegend(chart.showLegend ? .visible : .hidden)
                .chartXAxis {
                    if chart.showAxisLabels {
                        AxisMarks { _ in AxisValueLabel().font(.system(size: 7)) }
                    } else {
                        AxisMarks(values: [Double]()) { _ in }
                    }
                }
                .chartYAxis {
                    if chart.showGridlines {
                        AxisMarks { _ in AxisGridLine(); AxisValueLabel().font(.system(size: 7)) }
                    } else {
                        AxisMarks(values: [Double]()) { _ in }
                    }
                }
                .padding(6)
            } else {
                Text("No data")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private func loadChartData(_ chart: STExcelEmbeddedChart) -> [STExcelChartDataPoint] {
        let sr = chart.dataStartRow
        let sc = chart.dataStartCol
        let er = min(chart.dataEndRow, chart.dataStartRow + 15) // Cap at 15 data rows for readability
        let ec = chart.dataEndCol

        guard sr <= er, sc <= ec else { return [] }

        var points: [STExcelChartDataPoint] = []

        if sc == ec {
            for r in sr...er {
                let cell = sheet.cell(row: r, column: sc)
                if let num = Double(cell.value) {
                    points.append(STExcelChartDataPoint(label: "Row \(r+1)", value: num, series: "Data"))
                }
            }
        } else if ec == sc + 1 {
            for r in sr...er {
                let label = sheet.cell(row: r, column: sc).value
                if let num = Double(sheet.cell(row: r, column: ec).value) {
                    points.append(STExcelChartDataPoint(label: label.isEmpty ? "Row \(r+1)" : label, value: num, series: "Data"))
                }
            }
        } else {
            let firstRowIsHeader = Double(sheet.cell(row: sr, column: sc + 1).value) == nil
            let dataStartRow = firstRowIsHeader ? sr + 1 : sr
            for c in (sc + 1)...ec {
                let seriesName = firstRowIsHeader
                    ? (sheet.cell(row: sr, column: c).value.isEmpty ? STExcelSheet.columnLetter(c) : sheet.cell(row: sr, column: c).value)
                    : STExcelSheet.columnLetter(c)
                for r in dataStartRow...er {
                    let label = sheet.cell(row: r, column: sc).value
                    if let num = Double(sheet.cell(row: r, column: c).value) {
                        points.append(STExcelChartDataPoint(label: label.isEmpty ? "Row \(r+1)" : label, value: num, series: seriesName))
                    }
                }
            }
            if points.isEmpty {
                for c in sc...ec {
                    if let num = Double(sheet.cell(row: sr, column: c).value) {
                        points.append(STExcelChartDataPoint(label: STExcelSheet.columnLetter(c), value: num, series: "Data"))
                    }
                }
            }
        }
        return points
    }

    // MARK: - Number Format

    /// Public accessor for print/export to apply number formatting
    static func formatForPrint(_ value: String, style: STExcelCellStyle) -> String {
        applyNumberFormat(value, style: style)
    }

    private static func applyNumberFormat(_ value: String, style: STExcelCellStyle) -> String {
        guard style.numberFormatId != 0 else { return value }

        let format = STNumberFormat(rawValue: style.numberFormatId)
        let code = style.numberFormatCode ?? format?.formatCode ?? "General"
        guard code != "General" else { return value }

        // 1) Try direct Double parse
        // 2) If fails, try extracting a number from text (strip currency, %, commas, etc.)
        // 3) For date/time formats, also try parsing text dates/times

        let isDateTimeCode = Self.isDateTimeFormatCode(code)
        let isDateTimeFormat = format == .date || format == .time

        // --- Direct numeric ---
        if let num = Double(value) {
            if isDateTimeCode || isDateTimeFormat {
                return formatDateSerial(num, code: code)
            }
            return applyNumericFormat(num, format: format, code: code)
        }

        // --- Text date/time parsing ---
        if isDateTimeCode || isDateTimeFormat {
            // Try parsing as time text first (e.g. "14:30", "2:30 PM")
            if let date = parseTextTime(value) {
                return formatDate(date, code: code)
            }
            // Try parsing as date text (e.g. "15/10/2017", "Oct 15, 2017")
            if let date = parseTextDate(value) {
                return formatDate(date, code: code)
            }
        }

        // --- Extract number from text (strip $, €, £, ¥, ₺, %, commas, spaces) ---
        if let num = parseTextNumber(value) {
            if isDateTimeCode || isDateTimeFormat {
                return formatDateSerial(num, code: code)
            }
            return applyNumericFormat(num, format: format, code: code)
        }

        return value
    }

    /// Check if a format code is date/time related
    private static func isDateTimeFormatCode(_ code: String) -> Bool {
        let c = code.lowercased()
        // Look for date/time tokens but exclude currency codes like "#,##0.00"
        return c.contains("yy") || c.contains("mmm") || c.contains("dd") ||
               c.contains("hh") || c.contains("ss") || c.contains("am/pm") ||
               (c.contains("d") && c.contains("m")) ||
               (c.contains("m") && c.contains("y"))
    }

    /// Apply a numeric format given a parsed number
    private static func applyNumericFormat(_ num: Double, format: STNumberFormat?, code: String) -> String {
        // Special formats (postcode, phone, SSN) — check first
        if format == .special || code.contains("[<=") || isSpecialPatternCode(code) {
            return formatSpecial(num, code: code)
        }

        // Fraction
        if code.contains("?/") || code.contains("#/") || format == .fraction {
            return formatFraction(num, code: code.contains("?/") || code.contains("#/") ? code : "# ?/?")
        }

        // Percent
        if code.hasSuffix("%") || format == .percent {
            return formatNumber(num, code: code.hasSuffix("%") ? code : "0.00%")
        }

        // Scientific
        if code.contains("E+") || code.contains("E-") || format == .scientific {
            if code.contains("E+") || code.contains("E-") {
                return formatNumber(num, code: code)
            }
            if num == 0 { return "0.00E+00" }
            return String(format: "%.2fE+%02d", num / pow(10, floor(log10(abs(num)))), Int(floor(log10(abs(num)))))
        }

        // Accounting
        if code.contains("_(") || format == .accounting {
            return formatNumber(num, code: code.contains("_(") ? code : "_($* #,##0.00_)")
        }

        // Currency / Number / General — route to formatNumber
        if code.contains("#") || code.contains("0") {
            return formatNumber(num, code: code)
        }

        // Fallback by format type
        switch format {
        case .currency:
            return formatNumber(num, code: "$#,##0.00")
        case .number:
            return formatNumber(num, code: "#,##0.00")
        case .text, .general, .none:
            return formatNumber(num, code: code)
        default:
            return formatNumber(num, code: code)
        }
    }

    /// Check if a code is a special pattern (zero-padded with dashes, not a regular number format)
    private static func isSpecialPatternCode(_ code: String) -> Bool {
        // SSN: 000-00-0000, Postcode: 00000, etc.
        let stripped = code.replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
        // If code is all zeros (with dashes) → special zero-pad format
        if !stripped.isEmpty && stripped.allSatisfy({ $0 == "0" }) && code.contains("-") {
            return true
        }
        // Pure zero-pad without thousands: "00000" but not "#,##0"
        if !code.contains("#") && !code.contains(",") && !code.contains(".") &&
           code.filter({ $0 == "0" }).count >= 3 && code.contains("0") {
            return true
        }
        return false
    }

    /// Extract a numeric value from text that contains currency symbols, commas, percent signs, etc.
    /// Examples: "$1,234.56" → 1234.56, "1.234,56" → 1234.56, "15%" → 0.15, "€ 500" → 500
    private static func parseTextNumber(_ text: String) -> Double? {
        var s = text.trimmingCharacters(in: .whitespaces)
        guard !s.isEmpty else { return nil }

        // Track if percent
        let hasPercent = s.hasSuffix("%")
        if hasPercent { s = String(s.dropLast()).trimmingCharacters(in: .whitespaces) }

        // Strip known currency symbols and whitespace around them
        let currencies = ["$", "€", "£", "¥", "₺", "₹", "₩", "CHF", "kr", "R$", "zł"]
        for sym in currencies {
            if s.hasPrefix(sym) { s = String(s.dropFirst(sym.count)).trimmingCharacters(in: .whitespaces) }
            if s.hasSuffix(sym) { s = String(s.dropLast(sym.count)).trimmingCharacters(in: .whitespaces) }
        }

        // Strip accounting parens for negative: (1,234.56) → -1234.56
        let isNegativeParen = s.hasPrefix("(") && s.hasSuffix(")")
        if isNegativeParen {
            s = String(s.dropFirst().dropLast()).trimmingCharacters(in: .whitespaces)
        }

        // Handle negative sign
        let isNegative = s.hasPrefix("-") || isNegativeParen
        if s.hasPrefix("-") || s.hasPrefix("+") { s = String(s.dropFirst()) }

        // Strip spaces and underscores
        s = s.replacingOccurrences(of: " ", with: "")
        s = s.replacingOccurrences(of: "_", with: "")

        // Determine decimal separator: if both , and . exist:
        //   - If comma is after last dot → European (1.234,56)
        //   - If dot is after last comma → US (1,234.56)
        let lastDot = s.lastIndex(of: ".")
        let lastComma = s.lastIndex(of: ",")

        if let ld = lastDot, let lc = lastComma {
            if lc > ld {
                // European: dots are thousands, comma is decimal
                s = s.replacingOccurrences(of: ".", with: "")
                s = s.replacingOccurrences(of: ",", with: ".")
            } else {
                // US: commas are thousands, dot is decimal
                s = s.replacingOccurrences(of: ",", with: "")
            }
        } else if lastComma != nil && lastDot == nil {
            // Only commas — check if single comma with 2 digits after (likely decimal)
            let parts = s.components(separatedBy: ",")
            if parts.count == 2 && (parts[1].count == 1 || parts[1].count == 2) {
                s = s.replacingOccurrences(of: ",", with: ".")
            } else {
                // Thousands separator
                s = s.replacingOccurrences(of: ",", with: "")
            }
        } else if lastDot != nil && lastComma == nil {
            // Only dots — keep as-is (standard decimal)
        }

        guard let num = Double(s) else { return nil }
        var result = isNegative ? -num : num
        if hasPercent { result /= 100.0 }
        return result
    }

    /// Try to parse text as a time (e.g. "14:30", "2:30 PM", "14:30:45")
    private static func parseTextTime(_ text: String) -> Date? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        let formats = [
            "HH:mm:ss", "HH:mm", "H:mm:ss", "H:mm",
            "hh:mm:ss a", "hh:mm a", "h:mm:ss a", "h:mm a",
            "HH.mm.ss", "HH.mm"
        ]
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        for fmt in formats {
            df.dateFormat = fmt
            if let date = df.date(from: trimmed) {
                return date
            }
        }
        return nil
    }

    /// Try to parse a text string as a date using common formats
    private static func parseTextDate(_ text: String) -> Date? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        let formats = [
            "dd/MM/yyyy", "MM/dd/yyyy", "yyyy-MM-dd", "dd-MM-yyyy", "MM-dd-yyyy",
            "dd.MM.yyyy", "MM.dd.yyyy", "yyyy/MM/dd",
            "d/M/yyyy", "M/d/yyyy", "d-M-yyyy", "M-d-yyyy", "d.M.yyyy",
            "dd/MM/yy", "MM/dd/yy", "d/M/yy",
            "dd MMM yyyy", "d MMM yyyy", "MMM dd, yyyy", "MMMM dd, yyyy",
            "dd-MMM-yyyy", "dd-MMM-yy", "d-MMM-yy",
            "MMM d, yyyy", "MMMM d, yyyy",
            "yyyy-MM-dd'T'HH:mm:ss", "yyyy-MM-dd HH:mm:ss",
            "dd/MM/yyyy HH:mm", "MM/dd/yyyy HH:mm"
        ]
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        for fmt in formats {
            df.dateFormat = fmt
            if let date = df.date(from: trimmed) {
                return date
            }
        }
        return nil
    }

    /// Format a Date using an Excel-style format code
    private static func formatDate(_ date: Date, code: String) -> String {
        let df = DateFormatter()
        var fmt = code
            .replacingOccurrences(of: "yyyy", with: "yyyy")
            .replacingOccurrences(of: "yy", with: "yy")
            .replacingOccurrences(of: "mmmm", with: "MMMM")
            .replacingOccurrences(of: "mmm", with: "MMM")
            .replacingOccurrences(of: "mm", with: "MM")
            .replacingOccurrences(of: "dddd", with: "EEEE")
            .replacingOccurrences(of: "dd", with: "dd")
        if !fmt.contains("dd") { fmt = fmt.replacingOccurrences(of: "d", with: "d") }
        // Time components
        fmt = fmt.replacingOccurrences(of: "hh", with: "HH")
            .replacingOccurrences(of: "ss", with: "ss")
            .replacingOccurrences(of: "AM/PM", with: "a")
            .replacingOccurrences(of: "am/pm", with: "a")
        df.dateFormat = fmt
        return df.string(from: date)
    }

    private static func formatNumber(_ num: Double, code: String) -> String {
        // Parse format code for common patterns
        var code = code

        // Pre-process: strip _x (space-width) escape pairs and handle \x (literal char)
        code = stripFormatEscapes(code)

        // Handle percent
        if code.hasSuffix("%") {
            let inner = String(code.dropLast())
            let decimals = inner.components(separatedBy: ".").last?.count ?? 0
            return String(format: "%.\(decimals)f%%", num * (code.contains("0%") || code.contains("#%") ? 100 : 1))
        }

        // Handle scientific notation
        if code.contains("E+") || code.contains("E-") {
            let decimals = code.components(separatedBy: ".").dropFirst().first?.prefix(while: { $0 == "0" }).count ?? 2
            return String(format: "%.\(decimals)E", num)
        }

        // Strip accounting wrappers FIRST (before currency detection)
        code = code.replacingOccurrences(of: "* ", with: "")

        // Handle negative format sections: "pos;neg" — use first section for positive
        if code.contains(";") {
            let sections = code.components(separatedBy: ";")
            code = num < 0 ? (sections.count > 1 ? sections[1] : sections[0]) : sections[0]
            // If negative section wraps in parens, handle it
            if num < 0 && code.contains("(") && code.contains(")") {
                code = code.replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "")
                let result = formatNumber(abs(num), code: code)
                return "(\(result))"
            }
        }

        // Extract currency/text from quoted strings, [$...] brackets, and bare symbols
        var prefix = ""
        var suffix = ""
        code = extractCurrencyAndText(from: code, prefix: &prefix, suffix: &suffix)

        // Strip any remaining formatting chars
        code = code.trimmingCharacters(in: .whitespaces)

        // Detect 1000 separator
        let useThousands = code.contains(",")

        // Detect decimal places
        let parts = code.components(separatedBy: ".")
        let decimals = parts.count > 1 ? parts[1].filter({ $0 == "0" || $0 == "#" }).count : 0

        let formatter = NumberFormatter()
        formatter.numberStyle = useThousands ? .decimal : .none
        formatter.minimumFractionDigits = decimals
        formatter.maximumFractionDigits = decimals

        let formatted = formatter.string(from: NSNumber(value: num)) ?? "\(num)"

        return "\(prefix)\(formatted)\(suffix)"
    }

    /// Strip _x (space-width of char x) and \x (literal char x) escape sequences from format code
    private static func stripFormatEscapes(_ code: String) -> String {
        var result = ""
        var i = code.startIndex
        while i < code.endIndex {
            let c = code[i]
            if c == "_" {
                // _x = skip both chars (space equal to width of x)
                i = code.index(after: i)
                if i < code.endIndex { i = code.index(after: i) }
            } else if c == "\\" {
                // \x = literal character x — keep x
                i = code.index(after: i)
                if i < code.endIndex {
                    result.append(code[i])
                    i = code.index(after: i)
                }
            } else {
                result.append(c)
                i = code.index(after: i)
            }
        }
        return result
    }

    /// Extract currency symbols and quoted text from format code, returning the numeric pattern
    private static func extractCurrencyAndText(from code: String, prefix: inout String, suffix: inout String) -> String {
        var numericPart = ""
        var foundNumeric = false
        var i = code.startIndex

        while i < code.endIndex {
            let c = code[i]

            if c == "\"" {
                // Quoted string — extract text between quotes
                let start = code.index(after: i)
                if let end = code[start...].firstIndex(of: "\"") {
                    let text = String(code[start..<end])
                    if foundNumeric { suffix += text } else { prefix += text }
                    i = code.index(after: end)
                    continue
                }
                i = code.index(after: i)
            } else if c == "[" {
                // [$€-407] locale currency or [Red] color — find closing bracket
                if let end = code[i...].firstIndex(of: "]") {
                    let bracket = String(code[code.index(after: i)..<end])
                    if bracket.hasPrefix("$") {
                        // Locale currency: [$€-407] → extract "€"
                        let currency = String(bracket.dropFirst().prefix(while: { $0 != "-" }))
                        if foundNumeric { suffix += currency } else { prefix += currency }
                    }
                    // Skip [Red], [<=999], etc.
                    i = code.index(after: end)
                    continue
                }
                i = code.index(after: i)
            } else if "#0.,?/".contains(c) {
                foundNumeric = true
                numericPart.append(c)
                i = code.index(after: i)
            } else if c == "%" {
                numericPart.append(c)
                i = code.index(after: i)
            } else {
                // Check for bare currency symbols
                let remaining = String(code[i...])
                var matched = false
                for sym in ["$", "€", "£", "¥", "₺", "₹", "₩"] {
                    if remaining.hasPrefix(sym) {
                        if foundNumeric { suffix += sym } else { prefix += sym }
                        i = code.index(i, offsetBy: sym.count)
                        matched = true
                        break
                    }
                }
                if !matched {
                    // Keep other chars in numeric part (E, +, -, space, etc.)
                    numericPart.append(c)
                    i = code.index(after: i)
                }
            }
        }

        return numericPart
    }

    /// Format special patterns: postcode, SSN, phone number
    private static func formatSpecial(_ num: Double, code: String) -> String {
        let intVal = Int(num)

        // Conditional format: [<=9999999]###-####;(###) ###-####
        if code.contains("[<=") {
            let sections = code.components(separatedBy: ";")
            for section in sections {
                if section.contains("[<=") {
                    // Parse condition
                    if let start = section.firstIndex(of: "="),
                       let end = section.firstIndex(of: "]") {
                        let threshold = Int(section[section.index(after: start)..<end]) ?? 0
                        if intVal <= threshold {
                            let pattern = String(section[section.index(after: end)...])
                            return applyDigitPattern(intVal, pattern: pattern)
                        }
                    }
                } else if !section.contains("[") {
                    // Default section (no condition)
                    return applyDigitPattern(intVal, pattern: section)
                }
            }
            // Fallback to last section
            if let last = sections.last {
                let cleaned = last.replacingOccurrences(of: "[Red]", with: "")
                return applyDigitPattern(intVal, pattern: cleaned)
            }
        }

        // Zero-padded pattern: 00000, 000-00-0000
        return applyDigitPattern(intVal, pattern: code)
    }

    /// Apply a digit pattern like "###-####" or "000-00-0000" to an integer
    private static func applyDigitPattern(_ value: Int, pattern: String) -> String {
        let absVal = abs(value)

        // Count how many digit placeholders (0 or #) exist in pattern
        let digitCount = pattern.filter({ $0 == "0" || $0 == "#" }).count
        guard digitCount > 0 else { return "\(value)" }

        // Convert number to digit string, zero-pad if pattern uses '0'
        let zeroCount = pattern.filter({ $0 == "0" }).count
        var digits = String(absVal)
        while digits.count < zeroCount {
            digits = "0" + digits
        }
        // If still shorter than total placeholders and using #, don't pad further
        while digits.count < digitCount {
            digits = " " + digits
        }

        // Now map digits into pattern positions (right to left)
        var result = ""
        var digitIndex = digits.count - 1
        for ch in pattern.reversed() {
            if ch == "0" || ch == "#" {
                if digitIndex >= 0 {
                    result = String(digits[digits.index(digits.startIndex, offsetBy: digitIndex)]) + result
                    digitIndex -= 1
                } else {
                    result = (ch == "0" ? "0" : "") + result
                }
            } else {
                result = String(ch) + result
            }
        }

        // Prepend any remaining digits
        while digitIndex >= 0 {
            result = String(digits[digits.index(digits.startIndex, offsetBy: digitIndex)]) + result
            digitIndex -= 1
        }

        return value < 0 ? "-\(result)" : result
    }

    private static func formatDateSerial(_ num: Double, code: String) -> String {
        let serial = Int(num)
        guard serial > 0 && serial < 2958466 else { return "\(Int(num))" }
        var components = DateComponents()
        components.day = serial - 1
        let calendar = Calendar(identifier: .gregorian)
        guard let baseDate = calendar.date(from: DateComponents(year: 1900, month: 1, day: 1)),
              let date = calendar.date(byAdding: components, to: baseDate) else { return "\(Int(num))" }
        let df = DateFormatter()
        // Convert Excel format to DateFormatter format
        var fmt = code
            .replacingOccurrences(of: "yyyy", with: "yyyy")
            .replacingOccurrences(of: "yy", with: "yy")
            .replacingOccurrences(of: "mmmm", with: "MMMM")
            .replacingOccurrences(of: "mmm", with: "MMM")
            .replacingOccurrences(of: "mm", with: "MM")
            .replacingOccurrences(of: "dddd", with: "EEEE")
            .replacingOccurrences(of: "dd", with: "dd")
        // Single d/m
        if !fmt.contains("dd") { fmt = fmt.replacingOccurrences(of: "d", with: "d") }
        df.dateFormat = fmt
        return df.string(from: date)
    }

    private static func formatTimeSerial(_ num: Double) -> String {
        let totalSeconds = Int(num * 86400)
        let h = totalSeconds / 3600
        let m = (totalSeconds % 3600) / 60
        let s = totalSeconds % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }

    private static func formatFraction(_ num: Double, code: String) -> String {
        let whole = Int(num)
        let frac = abs(num - Double(whole))
        if frac < 0.0001 { return "\(whole)" }

        // Detect denominator from code (e.g. "# ?/2" → 2, "# ?/?" → auto)
        let parts = code.components(separatedBy: "/")
        if parts.count == 2, let denom = Int(parts[1].trimmingCharacters(in: .whitespaces).filter(\.isNumber)) , denom > 0 {
            let numer = Int(round(frac * Double(denom)))
            if numer == 0 { return "\(whole)" }
            if whole == 0 { return "\(numer)/\(denom)" }
            return "\(whole) \(numer)/\(denom)"
        }

        // Auto fraction: find best approximation
        let maxDenom = code.contains("???") ? 999 : (code.contains("??") ? 99 : 9)
        var bestN = 0, bestD = 1, bestErr = Double.infinity
        for d in 1...maxDenom {
            let n = Int(round(frac * Double(d)))
            let err = abs(frac - Double(n) / Double(d))
            if err < bestErr { bestN = n; bestD = d; bestErr = err }
            if err < 0.0001 { break }
        }
        if bestN == 0 { return "\(whole)" }
        if whole == 0 { return "\(bestN)/\(bestD)" }
        return "\(whole) \(bestN)/\(bestD)"
    }

    // MARK: - Selection Helpers

    private func isCellSelected(row: Int, col: Int) -> Bool {
        editorViewModel.selectedRow == row && editorViewModel.selectedCol == col
    }

    private func isCellInRange(row: Int, col: Int) -> Bool {
        guard editorViewModel.hasRangeSelection else { return false }
        let sr = min(editorViewModel.selectionStartRow, editorViewModel.selectionActualEndRow)
        let sc = min(editorViewModel.selectionStartCol, editorViewModel.selectionActualEndCol)
        let er = max(editorViewModel.selectionStartRow, editorViewModel.selectionActualEndRow)
        let ec = max(editorViewModel.selectionStartCol, editorViewModel.selectionActualEndCol)
        return row >= sr && row <= er && col >= sc && col <= ec
    }

    private func isRowSelected(_ row: Int) -> Bool {
        guard let sr = editorViewModel.selectedRow else { return false }
        let er = editorViewModel.selectionActualEndRow
        let minR = min(sr, er)
        let maxR = max(sr, er)
        return row >= minR && row <= maxR
    }

    private func isColumnSelected(_ col: Int) -> Bool {
        guard let sc = editorViewModel.selectedCol else { return false }
        let ec = editorViewModel.selectionActualEndCol
        let minC = min(sc, ec)
        let maxC = max(sc, ec)
        return col >= minC && col <= maxC
    }
}

// MARK: - Scroll Offset Tracking

private struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGPoint = .zero
    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {
        value = nextValue()
    }
}

// MARK: - Conditional View Modifier

private extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Cached Image View

/// Caches UIImage from Data so it's not re-decoded every frame during drag/scroll
private struct STExcelCachedImageView: View {
    let data: Data

    #if canImport(UIKit)
    @State private var uiImage: UIImage?
    #endif

    var body: some View {
        #if canImport(UIKit)
        Group {
            if let uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Color.gray.opacity(0.2)
            }
        }
        .onAppear {
            if uiImage == nil {
                uiImage = UIImage(data: data)
            }
        }
        #else
        Color.gray.opacity(0.2)
        #endif
    }
}

// MARK: - Comment Triangle

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}
