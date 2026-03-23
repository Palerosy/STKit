import SwiftUI
import Combine
import STKit

/// Central bridge between ribbon actions and document model
@MainActor
final class STExcelEditorViewModel: ObservableObject {

    // MARK: - Document

    weak var document: STExcelDocument?
    var sheet: STExcelSheet? { document?.activeSheet }

    // MARK: - Selection

    @Published var selectedRow: Int? = nil
    @Published var selectedCol: Int? = nil
    @Published var selectionEndRow: Int? = nil
    @Published var selectionEndCol: Int? = nil
    @Published var isEditing: Bool = false
    @Published var editingValue: String = ""
    /// Function waiting to be inserted after a sheet dismisses
    /// - (name, isRangeFunction) — range functions use insertAutoFormula, others use syntax template
    var pendingFunction: (name: String, isRange: Bool)? = nil

    /// Whether a range (multi-cell) is selected
    var hasRangeSelection: Bool {
        guard let sr = selectedRow, let sc = selectedCol,
              let er = selectionEndRow, let ec = selectionEndCol else { return false }
        return sr != er || sc != ec
    }

    var selectionStartRow: Int { selectedRow ?? 0 }
    var selectionStartCol: Int { selectedCol ?? 0 }
    var selectionActualEndRow: Int { selectionEndRow ?? selectedRow ?? 0 }
    var selectionActualEndCol: Int { selectionEndCol ?? selectedCol ?? 0 }

    // MARK: - Current Style (reflects selection)

    @Published var currentStyle: STExcelCellStyle = STExcelCellStyle()

    // MARK: - Settings

    /// Direction to move after pressing Enter
    enum EnterDirection: String, CaseIterable {
        case down, right, stay
    }
    @Published var enterDirection: EnterDirection = .down
    @Published var autoCalculate: Bool = true

    // MARK: - View Settings

    @Published var showGridlines: Bool = true
    @Published var showHeadings: Bool = true
    @Published var showFormulaBar: Bool = true
    @Published var frozenRows: Int = 0
    @Published var frozenCols: Int = 0

    // MARK: - Zoom

    @Published var zoomScale: CGFloat = 1.0

    /// Incremented on sort/filter to force grid re-render (LazyVStack cache workaround)
    @Published var gridRefreshId: Int = 0

    // MARK: - Column/Row Sizing

    /// Per-column custom widths (col index → width). Missing = default width from config.
    @Published var columnWidths: [Int: CGFloat] = [:]
    /// Per-row custom heights (row index → height). Missing = default height from config.
    @Published var rowHeights: [Int: CGFloat] = [:]

    /// Tooltip shown during column/row resize
    @Published var resizeTooltip: String? = nil
    @Published var resizeTooltipPosition: CGPoint = .zero

    func columnWidth(for col: Int, default defaultWidth: CGFloat) -> CGFloat {
        columnWidths[col] ?? defaultWidth
    }

    func rowHeight(for row: Int, default defaultHeight: CGFloat) -> CGFloat {
        guard let h = rowHeights[row] else { return defaultHeight }
        // Clamp Excel's tiny default rows (~15pt) to app minimum so they're readable
        return h < defaultHeight ? defaultHeight : h
    }

    // MARK: - Performance Caches

    /// Cached conditional format numeric values per rule ID — avoids O(n²) per cell
    private var cfNumericCache: [UUID: [Double]] = [:]
    private var cfValueCountCache: [UUID: [String: Int]] = [:]
    /// Cached merged region lookup — avoids O(n) linear search per cell
    private(set) var mergedRegionMap: [Int: [Int: STMergedRegion]] = [:]

    /// Invalidate all per-sheet caches (call on sheet switch or data change)
    func invalidatePerformanceCaches() {
        cfNumericCache.removeAll()
        cfValueCountCache.removeAll()
        buildMergedRegionMap()
        print("📊 [STExcel] invalidatePerformanceCaches — mergedRegions: \(mergedRegionMap.count) rows indexed")
    }

    /// Build spatial index for merged regions
    func buildMergedRegionMap() {
        mergedRegionMap.removeAll()
        guard let sheet = sheet else { return }
        for region in sheet.mergedRegions {
            for r in region.startRow...region.endRow {
                if mergedRegionMap[r] == nil { mergedRegionMap[r] = [:] }
                for c in region.startCol...region.endCol {
                    mergedRegionMap[r]?[c] = region
                }
            }
        }
    }

    /// O(1) merged region lookup
    func cachedMergedRegion(row: Int, col: Int) -> STMergedRegion? {
        mergedRegionMap[row]?[col]
    }

    /// X offset for a given column (sum of all previous column widths)
    func columnOffset(for col: Int, default defaultWidth: CGFloat) -> CGFloat {
        var x: CGFloat = 0
        for c in 0..<col {
            x += columnWidths[c] ?? defaultWidth
        }
        return x
    }

    /// Y offset for a given row (sum of all previous row heights)
    func rowOffset(for row: Int, default defaultHeight: CGFloat) -> CGFloat {
        var y: CGFloat = 0
        for r in 0..<row {
            if hiddenRows.contains(r) { continue }
            y += rowHeight(for: r, default: defaultHeight)
        }
        return y
    }

    // MARK: - Embedded Charts

    @Published var charts: [STExcelEmbeddedChart] = []
    @Published var selectedChartId: UUID? = nil

    var selectedChart: STExcelEmbeddedChart? {
        charts.first { $0.id == selectedChartId }
    }

    func addChart(_ chart: STExcelEmbeddedChart) {
        charts.append(chart)
        selectedChartId = chart.id
        hasUnsavedChanges = true
        objectWillChange.send()
    }

    func updateChart(_ chart: STExcelEmbeddedChart) {
        if let idx = charts.firstIndex(where: { $0.id == chart.id }) {
            charts[idx] = chart
            hasUnsavedChanges = true
            objectWillChange.send()
        }
    }

    func deleteSelectedChart() {
        guard let id = selectedChartId else { return }
        charts.removeAll { $0.id == id }
        selectedChartId = nil
        hasUnsavedChanges = true
        objectWillChange.send()
    }

    func deselectChart() {
        selectedChartId = nil
    }

    // MARK: - Embedded Images

    @Published var images: [STExcelEmbeddedImage] = []
    @Published var selectedImageId: UUID? = nil

    var selectedImage: STExcelEmbeddedImage? {
        images.first { $0.id == selectedImageId }
    }

    func addImage(_ image: STExcelEmbeddedImage) {
        images.append(image)
        selectedImageId = image.id
        selectedChartId = nil
        hasUnsavedChanges = true
        objectWillChange.send()
    }

    func updateImage(_ image: STExcelEmbeddedImage) {
        if let idx = images.firstIndex(where: { $0.id == image.id }) {
            images[idx] = image
            hasUnsavedChanges = true
            objectWillChange.send()
        }
    }

    func deleteSelectedImage() {
        guard let id = selectedImageId else { return }
        images.removeAll { $0.id == id }
        selectedImageId = nil
        hasUnsavedChanges = true
        objectWillChange.send()
    }

    // MARK: - Embedded Shapes

    @Published var shapes: [STExcelEmbeddedShape] = []
    @Published var selectedShapeId: UUID? = nil

    var selectedShape: STExcelEmbeddedShape? {
        shapes.first { $0.id == selectedShapeId }
    }

    func addShape(_ shape: STExcelEmbeddedShape) {
        shapes.append(shape)
        selectedShapeId = shape.id
        selectedChartId = nil
        selectedImageId = nil
        hasUnsavedChanges = true
        objectWillChange.send()
    }

    func updateShape(_ shape: STExcelEmbeddedShape) {
        if let idx = shapes.firstIndex(where: { $0.id == shape.id }) {
            shapes[idx] = shape
            hasUnsavedChanges = true
            objectWillChange.send()
        }
    }

    func deleteSelectedShape() {
        guard let id = selectedShapeId else { return }
        shapes.removeAll { $0.id == id }
        selectedShapeId = nil
        hasUnsavedChanges = true
        objectWillChange.send()
    }

    // MARK: - Tables

    @Published var tables: [STExcelTable] = []
    @Published var selectedTableId: UUID? = nil

    var selectedTable: STExcelTable? {
        tables.first { $0.id == selectedTableId }
    }

    func addTable(_ table: STExcelTable) {
        tables.append(table)
        selectedTableId = table.id
        selectedChartId = nil
        selectedImageId = nil
        selectedShapeId = nil
        hasUnsavedChanges = true
        gridRefreshId += 1
        objectWillChange.send()
    }

    func updateTable(_ table: STExcelTable) {
        if let idx = tables.firstIndex(where: { $0.id == table.id }) {
            tables[idx] = table
            hasUnsavedChanges = true
            gridRefreshId += 1
            objectWillChange.send()
        }
    }

    func deleteSelectedTable() {
        guard let id = selectedTableId else { return }
        tables.removeAll { $0.id == id }
        selectedTableId = nil
        hasUnsavedChanges = true
        gridRefreshId += 1
        objectWillChange.send()
    }

    /// Returns the table that covers a given cell, if any
    func table(at row: Int, col: Int) -> STExcelTable? {
        tables.first { $0.contains(row: row, col: col) }
    }

    // MARK: - Conditional Formatting

    @Published var conditionalRules: [STExcelConditionalRule] = []

    func addConditionalRule(_ rule: STExcelConditionalRule) {
        conditionalRules.append(rule)
        hasUnsavedChanges = true
        objectWillChange.send()
    }

    func removeConditionalRule(_ id: UUID) {
        conditionalRules.removeAll { $0.id == id }
        hasUnsavedChanges = true
        objectWillChange.send()
    }

    func clearConditionalRules(for range: (sr: Int, sc: Int, er: Int, ec: Int)? = nil) {
        if let r = range {
            conditionalRules.removeAll { $0.startRow == r.sr && $0.startCol == r.sc && $0.endRow == r.er && $0.endCol == r.ec }
        } else {
            conditionalRules.removeAll()
        }
        hasUnsavedChanges = true
        objectWillChange.send()
    }

    /// Evaluate conditional formatting for a cell — returns (bgColor, textColor, borderColor, barPercent)?
    /// Track CF call count for performance logging
    private var cfCallCount = 0
    private var cfLastLogTime: CFAbsoluteTime = 0

    func conditionalFormat(row: Int, col: Int) -> (bg: Color?, text: Color?, border: Color?, bar: (Double, Color)?, scaleBg: Color?)? {
        guard let sheet = sheet else { return nil }
        if conditionalRules.isEmpty { return nil }
        cfCallCount += 1
        let now = CFAbsoluteTimeGetCurrent()
        if now - cfLastLogTime > 2.0 {
            print("⚡ [STExcel] conditionalFormat called \(cfCallCount) times in last 2s, rules: \(conditionalRules.count)")
            cfCallCount = 0
            cfLastLogTime = now
        }
        let cellValue = sheet.cell(row: row, column: col).value

        for rule in conditionalRules {
            guard rule.contains(row: row, col: col) else { continue }

            switch rule.ruleType {
            case .highlightCells:
                if evaluateHighlight(rule, cellValue: cellValue, sheet: sheet) {
                    return (rule.preset.bgColor, rule.preset.textColor == .primary ? nil : rule.preset.textColor, rule.preset.borderColor, nil, nil)
                }

            case .topBottom:
                if evaluateTopBottom(rule, row: row, col: col, sheet: sheet) {
                    return (rule.preset.bgColor, rule.preset.textColor == .primary ? nil : rule.preset.textColor, rule.preset.borderColor, nil, nil)
                }

            case .customFormula:
                if evaluateCustomFormula(rule, row: row, col: col, sheet: sheet) {
                    return (rule.preset.bgColor, rule.preset.textColor == .primary ? nil : rule.preset.textColor, rule.preset.borderColor, nil, nil)
                }

            case .dataBar:
                if let pct = evaluateDataBar(rule, row: row, col: col, sheet: sheet) {
                    return (nil, nil, nil, (pct, rule.barColor.color), nil)
                }

            case .colorScale:
                if let color = evaluateColorScale(rule, row: row, col: col, sheet: sheet) {
                    return (nil, nil, nil, nil, color)
                }
            }
        }
        return nil
    }

    private func evaluateCustomFormula(_ rule: STExcelConditionalRule, row: Int, col: Int, sheet: STExcelSheet) -> Bool {
        var formula = rule.formula.trimmingCharacters(in: .whitespaces)
        if formula.hasPrefix("=") { formula = String(formula.dropFirst()) }
        guard !formula.isEmpty else { return false }

        // Adjust cell references relative to rule origin
        let rowOffset = row - rule.startRow
        let colOffset = col - rule.startCol
        let adjusted = adjustCellReferences(formula, rowOffset: rowOffset, colOffset: colOffset)

        // Try comparison first (handles >, <, >=, <=, <>, =)
        let comparisonOps = [">=", "<=", "<>", "!=", ">", "<"]
        for op in comparisonOps {
            if adjusted.contains(op) {
                return STExcelFormulaEngine.evaluateComparison(adjusted, in: sheet)
            }
        }
        // Fall back to general evaluation
        let result = STExcelFormulaEngine.evaluate("=" + adjusted, in: sheet)
        // Truthy: non-zero number or "TRUE"
        if let num = Double(result) { return num != 0 }
        return result.uppercased() == "TRUE"
    }

    /// Shift cell references like A1 by row/col offset for custom formula evaluation
    private func adjustCellReferences(_ formula: String, rowOffset: Int, colOffset: Int) -> String {
        // Simple regex: match cell refs like A1, AB12, etc.
        let pattern = "([A-Z]+)(\\d+)"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return formula }

        var result = formula
        let matches = regex.matches(in: formula, range: NSRange(formula.startIndex..., in: formula)).reversed()
        for match in matches {
            guard let colRange = Range(match.range(at: 1), in: formula),
                  let rowRange = Range(match.range(at: 2), in: formula),
                  let origRow = Int(formula[rowRange]) else { continue }

            let colStr = String(formula[colRange])
            // Convert column letters to number
            var colNum = 0
            for ch in colStr {
                guard let ascii = ch.asciiValue, let aVal = Character("A").asciiValue else { continue }
                colNum = colNum * 26 + Int(ascii - aVal) + 1
            }
            let newCol = colNum + colOffset
            let newRow = origRow + rowOffset
            guard newCol >= 1 && newRow >= 1 else { continue }

            let newColStr = STExcelSheet.columnLetter(newCol - 1)
            let fullRange = match.range(at: 0)
            guard let swiftRange = Range(fullRange, in: result) else { continue }
            result.replaceSubrange(swiftRange, with: "\(newColStr)\(newRow)")
        }
        return result
    }

    private func evaluateHighlight(_ rule: STExcelConditionalRule, cellValue: String, sheet: STExcelSheet) -> Bool {
        let numVal = Double(cellValue)
        let v1 = Double(rule.value1)
        let v2 = Double(rule.value2)

        switch rule.condition {
        case .greaterThan:
            guard let n = numVal, let t = v1 else { return false }
            return n > t
        case .lessThan:
            guard let n = numVal, let t = v1 else { return false }
            return n < t
        case .between:
            guard let n = numVal, let lo = v1, let hi = v2 else { return false }
            return n >= lo && n <= hi
        case .equalTo:
            return cellValue == rule.value1 || (numVal != nil && numVal == v1)
        case .notEqualTo:
            return cellValue != rule.value1 && (numVal == nil || numVal != v1)
        case .textContains:
            return cellValue.localizedCaseInsensitiveContains(rule.value1)
        case .textNotContains:
            return !cellValue.localizedCaseInsensitiveContains(rule.value1)
        case .duplicates:
            let counts = cachedValueCounts(for: rule, sheet: sheet)
            return (counts[cellValue] ?? 0) > 1
        case .uniqueValues:
            let counts = cachedValueCounts(for: rule, sheet: sheet)
            return (counts[cellValue] ?? 0) == 1
        }
    }

    private func evaluateTopBottom(_ rule: STExcelConditionalRule, row: Int, col: Int, sheet: STExcelSheet) -> Bool {
        let values = collectNumericValues(rule, sheet: sheet)
        guard !values.isEmpty else { return false }
        let cellVal = Double(sheet.cell(row: row, column: col).value) ?? 0

        switch rule.rank {
        case .top:
            let sorted = values.sorted(by: >)
            let count = rule.rankIsPercent ? max(1, values.count * rule.rankCount / 100) : rule.rankCount
            let threshold = sorted[min(count - 1, sorted.count - 1)]
            return cellVal >= threshold
        case .bottom:
            let sorted = values.sorted()
            let count = rule.rankIsPercent ? max(1, values.count * rule.rankCount / 100) : rule.rankCount
            let threshold = sorted[min(count - 1, sorted.count - 1)]
            return cellVal <= threshold
        case .aboveAverage:
            let avg = values.reduce(0, +) / Double(values.count)
            return cellVal > avg
        case .belowAverage:
            let avg = values.reduce(0, +) / Double(values.count)
            return cellVal < avg
        }
    }

    private func evaluateDataBar(_ rule: STExcelConditionalRule, row: Int, col: Int, sheet: STExcelSheet) -> Double? {
        let values = collectNumericValues(rule, sheet: sheet)
        guard let minV = values.min(), let maxV = values.max(), maxV > minV else { return nil }
        guard let cellVal = Double(sheet.cell(row: row, column: col).value) else { return nil }
        return max(0, min(1, (cellVal - minV) / (maxV - minV)))
    }

    private func evaluateColorScale(_ rule: STExcelConditionalRule, row: Int, col: Int, sheet: STExcelSheet) -> Color? {
        let values = collectNumericValues(rule, sheet: sheet)
        guard let minV = values.min(), let maxV = values.max(), maxV > minV else { return nil }
        guard let cellVal = Double(sheet.cell(row: row, column: col).value) else { return nil }
        let pct = max(0, min(1, (cellVal - minV) / (maxV - minV)))

        let cs = rule.colorScale
        if pct < 0.5 {
            let t = pct * 2
            return interpolateColor(cs.lowColor, cs.midColor, t: t)
        } else {
            let t = (pct - 0.5) * 2
            return interpolateColor(cs.midColor, cs.highColor, t: t)
        }
    }

    /// Cached value frequency counts for duplicates/uniqueValues (avoids O(n²) per cell)
    private func cachedValueCounts(for rule: STExcelConditionalRule, sheet: STExcelSheet) -> [String: Int] {
        if let cached = cfValueCountCache[rule.id] { return cached }
        var counts: [String: Int] = [:]
        for r in rule.startRow...min(rule.endRow, sheet.rowCount - 1) {
            for c in rule.startCol...min(rule.endCol, sheet.columnCount - 1) {
                let val = sheet.cell(row: r, column: c).value
                counts[val, default: 0] += 1
            }
        }
        cfValueCountCache[rule.id] = counts
        return counts
    }

    private func collectNumericValues(_ rule: STExcelConditionalRule, sheet: STExcelSheet) -> [Double] {
        if let cached = cfNumericCache[rule.id] { return cached }
        var values: [Double] = []
        for r in rule.startRow...min(rule.endRow, sheet.rowCount - 1) {
            for c in rule.startCol...min(rule.endCol, sheet.columnCount - 1) {
                if let v = Double(sheet.cell(row: r, column: c).value) {
                    values.append(v)
                }
            }
        }
        cfNumericCache[rule.id] = values
        return values
    }

    private func interpolateColor(_ c1: Color, _ c2: Color, t: Double) -> Color {
        let p1 = PlatformColor(c1)
        let p2 = PlatformColor(c2)
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        p1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        p2.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        let ct = CGFloat(t)
        return Color(red: Double(r1 + (r2 - r1) * ct), green: Double(g1 + (g2 - g1) * ct), blue: Double(b1 + (b2 - b1) * ct))
    }

    // MARK: - Undo/Redo

    private var undoStack: [STExcelUndoAction] = []
    private var redoStack: [STExcelUndoAction] = []
    @Published var canUndo: Bool = false
    @Published var canRedo: Bool = false

    @Published var hasUnsavedChanges: Bool = false

    init() {}

    // MARK: - Batch Sheet Sync

    /// Update all sheet-related properties at once when switching sheets.
    /// All assignments happen synchronously within one RunLoop tick,
    /// so SwiftUI coalesces them into a single view update.
    func batchSyncSheet(
        rowHeights: [Int: CGFloat],
        columnWidths: [Int: CGFloat],
        images: [STExcelEmbeddedImage],
        shapes: [STExcelEmbeddedShape],
        frozenRows: Int,
        frozenCols: Int,
        charts: [STExcelEmbeddedChart],
        tables: [STExcelTable],
        conditionalRules: [STExcelConditionalRule],
        isSheetProtected: Bool,
        hiddenRows: Set<Int>,
        groupedRows: Set<Int>,
        collapsedGroups: Set<Int>,
        validationRules: [String: ValidationRule],
        definedNames: [String: String]
    ) {
        self.rowHeights = rowHeights
        self.columnWidths = columnWidths
        self.images = images
        self.shapes = shapes
        self.frozenRows = frozenRows
        self.frozenCols = frozenCols
        self.charts = charts
        self.tables = tables
        self.conditionalRules = conditionalRules
        self.isSheetProtected = isSheetProtected
        self.hiddenRows = hiddenRows
        self.groupedRows = groupedRows
        self.collapsedGroups = collapsedGroups
        self.validationRules = validationRules
        self.definedNames = definedNames

        // Rebuild performance caches for the new sheet
        invalidatePerformanceCaches()
    }

    // MARK: - Selection Updates

    func selectCell(row: Int, col: Int) {
        selectedRow = row
        selectedCol = col
        selectionEndRow = row
        selectionEndCol = col
        updateCurrentStyle()
    }

    func extendSelection(toRow: Int, toCol: Int) {
        selectionEndRow = toRow
        selectionEndCol = toCol
    }

    func updateCurrentStyle() {
        guard let sheet, let row = selectedRow, let col = selectedCol else { return }
        currentStyle = sheet.cell(row: row, column: col).style
    }

    // MARK: - Cell Editing

    /// Returns true if the selected cell is protected (sheet protected + cell locked)
    var isSelectedCellProtected: Bool {
        guard isSheetProtected, let sheet, let row = selectedRow, let col = selectedCol else { return false }
        return sheet.cell(row: row, column: col).style.isLocked
    }

    func commitEdit() {
        guard let sheet, let row = selectedRow, let col = selectedCol else { return }
        // Bounds check to prevent index-out-of-range crashes
        guard row >= 0, col >= 0, row < sheet.cells.count, col < sheet.cells[row].count else {
            isEditing = false
            return
        }
        // Block editing if sheet is protected and cell is locked
        if isSheetProtected && sheet.cell(row: row, column: col).style.isLocked {
            isEditing = false
            return
        }
        let cell = sheet.cell(row: row, column: col)
        let oldValue = cell.value
        let oldFormula = cell.formula

        if editingValue.hasPrefix("=") {
            // Store as formula + pre-evaluate so grid never calls formula engine during scroll
            let newFormula = editingValue
            if oldFormula != newFormula {
                sheet.cells[row][col].formula = newFormula
                let evaluated = STExcelFormulaEngine.evaluate(newFormula, in: sheet)
                sheet.cells[row][col].value = evaluated
                pushUndo(.setCellValue(row: row, col: col, oldValue: oldValue, newValue: evaluated))
                hasUnsavedChanges = true
            }
        } else {
            // Store as plain value, clear any existing formula
            if oldValue != editingValue || oldFormula != nil {
                sheet.cells[row][col].formula = nil
                sheet.setCell(row: row, column: col, value: editingValue)
                pushUndo(.setCellValue(row: row, col: col, oldValue: oldValue, newValue: editingValue))
                hasUnsavedChanges = true
            }
        }
        isEditing = false

        // Move cursor based on enterDirection setting
        switch enterDirection {
        case .down:
            if row + 1 < sheet.rowCount {
                selectCell(row: row + 1, col: col)
            }
        case .right:
            if col + 1 < sheet.columnCount {
                selectCell(row: row, col: col + 1)
            }
        case .stay:
            break
        }
    }

    func cancelEdit() {
        editingValue = ""
        isEditing = false
    }

    /// Set the selected cell's value directly (used by Link, etc.)
    func setCellValue(_ value: String) {
        guard let sheet, let row = selectedRow, let col = selectedCol else { return }
        if isSheetProtected && sheet.cell(row: row, column: col).style.isLocked { return }
        let oldValue = sheet.cell(row: row, column: col).value
        if oldValue != value {
            pushUndo(.setCellValue(row: row, col: col, oldValue: oldValue, newValue: value))
            sheet.setCell(row: row, column: col, value: value)
            hasUnsavedChanges = true
            editingValue = value
            objectWillChange.send()
        }
    }

    // MARK: - Formatting Actions

    func toggleBold() { applyStyleChange { $0.isBold.toggle() } }
    func toggleItalic() { applyStyleChange { $0.isItalic.toggle() } }
    func toggleUnderline() { applyStyleChange { $0.isUnderline.toggle() } }
    func toggleStrikethrough() { applyStyleChange { $0.isStrikethrough.toggle() } }
    func toggleWrapText() { applyStyleChange { $0.wrapText.toggle() } }

    func setFontName(_ name: String) { applyStyleChange { $0.fontName = name } }
    func setFontSize(_ size: Double) { applyStyleChange { $0.fontSize = size } }
    func increaseFontSize() { applyStyleChange { $0.fontSize = min($0.fontSize + 1, 72) } }
    func decreaseFontSize() { applyStyleChange { $0.fontSize = max($0.fontSize - 1, 6) } }

    func setTextColor(_ hex: String) {
        if hex == "none" {
            applyStyleChange { $0.textColor = nil }
        } else {
            applyStyleChange { $0.textColor = hex }
        }
    }

    func setFillColor(_ hex: String) {
        if hex == "none" {
            applyStyleChange { $0.fillColor = nil }
        } else {
            applyStyleChange { $0.fillColor = hex }
        }
    }

    func setHorizontalAlignment(_ align: STHorizontalAlignment) {
        applyStyleChange { $0.horizontalAlignment = align }
    }

    func setVerticalAlignment(_ align: STVerticalAlignment) {
        applyStyleChange { $0.verticalAlignment = align }
    }

    func setBorders(_ borders: STCellBorders) {
        applyStyleChange { $0.borders = borders }
    }

    func setBorderColor(_ hex: String?) {
        applyStyleChange { $0.borders.color = hex }
    }

    func setIndent(_ value: Int) {
        applyStyleChange { $0.indent = max(0, value) }
    }

    func increaseIndent() {
        applyStyleChange { $0.indent = min($0.indent + 1, 15) }
    }

    func decreaseIndent() {
        applyStyleChange { $0.indent = max($0.indent - 1, 0) }
    }

    func toggleLocked() { applyStyleChange { $0.isLocked.toggle() } }
    func toggleHidden() { applyStyleChange { $0.isHidden.toggle() } }

    func setNumberFormat(_ format: STNumberFormat) {
        setNumberFormatCode(formatId: format.rawValue, code: format.formatCode)
    }

    func setNumberFormatCode(formatId: Int, code: String) {
        guard let sheet else { return }
        let sr = min(selectionStartRow, selectionActualEndRow)
        let sc = min(selectionStartCol, selectionActualEndCol)
        let er = max(selectionStartRow, selectionActualEndRow)
        let ec = max(selectionStartCol, selectionActualEndCol)

        var changes: [(row: Int, col: Int, oldStyle: STExcelCellStyle, newStyle: STExcelCellStyle)] = []
        for r in sr...er {
            for c in sc...ec {
                guard r < sheet.rowCount, c < sheet.columnCount else { continue }
                let oldStyle = sheet.cells[r][c].style
                var newStyle = oldStyle
                newStyle.numberFormatId = formatId
                newStyle.numberFormatCode = code
                if oldStyle != newStyle {
                    sheet.cells[r][c].style = newStyle
                    changes.append((r, c, oldStyle, newStyle))
                }
            }
        }

        if !changes.isEmpty {
            pushUndo(.setRangeStyle(changes: changes))
            hasUnsavedChanges = true
            objectWillChange.send()
        }
        updateCurrentStyle()
    }

    private func applyStyleChange(_ transform: (inout STExcelCellStyle) -> Void) {
        guard let sheet else { return }
        let sr = min(selectionStartRow, selectionActualEndRow)
        let sc = min(selectionStartCol, selectionActualEndCol)
        let er = max(selectionStartRow, selectionActualEndRow)
        let ec = max(selectionStartCol, selectionActualEndCol)

        var changes: [(row: Int, col: Int, oldStyle: STExcelCellStyle, newStyle: STExcelCellStyle)] = []
        for r in sr...er {
            for c in sc...ec {
                guard r < sheet.rowCount, c < sheet.columnCount else { continue }
                // Skip protected+locked cells
                if isSheetProtected && sheet.cells[r][c].style.isLocked { continue }
                let oldStyle = sheet.cells[r][c].style
                var newStyle = oldStyle
                transform(&newStyle)
                if oldStyle != newStyle {
                    sheet.cells[r][c].style = newStyle
                    changes.append((r, c, oldStyle, newStyle))
                }
            }
        }

        if !changes.isEmpty {
            pushUndo(.setRangeStyle(changes: changes))
            hasUnsavedChanges = true
            objectWillChange.send()
        }
        updateCurrentStyle()
    }

    // MARK: - Row/Column Operations

    func insertRow() {
        guard let sheet, let row = selectedRow else { return }
        sheet.insertRow(at: row)
        pushUndo(.insertRow(at: row))
        hasUnsavedChanges = true
        gridRefreshId += 1
        objectWillChange.send()
        print("⚠️ [STExcel] insertRow called at \(row) — now \(sheet.rowCount) rows")
    }

    func deleteRow() {
        guard let sheet, let row = selectedRow, sheet.rowCount > 1 else { return }
        guard row >= 0, row < sheet.cells.count else { return }
        let cells = sheet.cells[row]
        sheet.deleteRow(at: row)
        pushUndo(.deleteRow(at: row, cells: cells))
        hasUnsavedChanges = true
        if let sr = selectedRow, sr >= sheet.rowCount { selectedRow = sheet.rowCount - 1 }
        gridRefreshId += 1
        objectWillChange.send()
    }

    func insertColumn() {
        guard let sheet, let col = selectedCol else { return }
        sheet.insertColumn(at: col)
        pushUndo(.insertColumn(at: col))
        hasUnsavedChanges = true
        gridRefreshId += 1
        objectWillChange.send()
    }

    func deleteColumn() {
        guard let sheet, let col = selectedCol, sheet.columnCount > 1 else { return }
        guard col >= 0, col < sheet.columnCount else { return }
        let cells = sheet.cells.compactMap { row in col < row.count ? row[col] : nil }
        sheet.deleteColumn(at: col)
        pushUndo(.deleteColumn(at: col, cells: cells))
        hasUnsavedChanges = true
        if let sc = selectedCol, sc >= sheet.columnCount { selectedCol = sheet.columnCount - 1 }
        gridRefreshId += 1
        objectWillChange.send()
    }

    // MARK: - Append / Remove Last Row & Column

    func appendRow() {
        guard let sheet else { return }
        let newRow = (0..<sheet.columnCount).map { _ in STExcelCell() }
        sheet.cells.append(newRow)
        hasUnsavedChanges = true
        gridRefreshId += 1
        objectWillChange.send()
        print("⚠️ [STExcel] appendRow called — now \(sheet.rowCount) rows", Thread.callStackSymbols.prefix(8).joined(separator: "\n"))
    }

    func appendColumn() {
        guard let sheet else { return }
        for r in 0..<sheet.rowCount {
            sheet.cells[r].append(STExcelCell())
        }
        hasUnsavedChanges = true
        gridRefreshId += 1
        objectWillChange.send()
        print("⚠️ [STExcel] appendColumn called — now \(sheet.columnCount) cols", Thread.callStackSymbols.prefix(8).joined(separator: "\n"))
    }

    func deleteLastRow() {
        guard let sheet, sheet.rowCount > 1 else { return }
        sheet.cells.removeLast()
        hasUnsavedChanges = true
        if let sr = selectedRow, sr >= sheet.rowCount { selectedRow = sheet.rowCount - 1 }
        gridRefreshId += 1
        objectWillChange.send()
    }

    func deleteLastColumn() {
        guard let sheet, sheet.columnCount > 1 else { return }
        for r in 0..<sheet.rowCount {
            sheet.cells[r].removeLast()
        }
        hasUnsavedChanges = true
        if let sc = selectedCol, sc >= sheet.columnCount { selectedCol = sheet.columnCount - 1 }
        gridRefreshId += 1
        objectWillChange.send()
    }

    // MARK: - Merge

    func mergeCells() {
        guard let sheet, hasRangeSelection else { return }
        let sr = min(selectionStartRow, selectionActualEndRow)
        let sc = min(selectionStartCol, selectionActualEndCol)
        let er = max(selectionStartRow, selectionActualEndRow)
        let ec = max(selectionStartCol, selectionActualEndCol)
        let region = STMergedRegion(startRow: sr, startCol: sc, endRow: er, endCol: ec)
        sheet.mergeCells(startRow: sr, startCol: sc, endRow: er, endCol: ec)
        pushUndo(.mergeCells(region: region))
        hasUnsavedChanges = true
        objectWillChange.send()
    }

    func unmergeCells() {
        guard let sheet, let row = selectedRow, let col = selectedCol,
              let region = sheet.mergedRegion(for: row, col: col) else { return }
        sheet.unmergeCells(row: row, col: col)
        pushUndo(.unmergeCells(region: region))
        hasUnsavedChanges = true
        objectWillChange.send()
    }

    /// Check if selection is currently merged
    var isSelectionMerged: Bool {
        guard let sheet, let row = selectedRow, let col = selectedCol else { return false }
        return sheet.mergedRegion(for: row, col: col) != nil
    }

    // MARK: - Clipboard

    func cut() {
        guard let sheet else { return }
        let sr = min(selectionStartRow, selectionActualEndRow)
        let sc = min(selectionStartCol, selectionActualEndCol)
        let er = max(selectionStartRow, selectionActualEndRow)
        let ec = max(selectionStartCol, selectionActualEndCol)
        STExcelClipboard.shared.cut(from: sheet, startRow: sr, startCol: sc, endRow: er, endCol: ec)
        hasUnsavedChanges = true
        objectWillChange.send()
    }

    func copy() {
        guard let sheet else { return }
        let sr = min(selectionStartRow, selectionActualEndRow)
        let sc = min(selectionStartCol, selectionActualEndCol)
        let er = max(selectionStartRow, selectionActualEndRow)
        let ec = max(selectionStartCol, selectionActualEndCol)
        STExcelClipboard.shared.copy(from: sheet, startRow: sr, startCol: sc, endRow: er, endCol: ec)
    }

    func paste() {
        guard let sheet, let row = selectedRow, let col = selectedCol else { return }
        STExcelClipboard.shared.paste(to: sheet, atRow: row, atCol: col)
        hasUnsavedChanges = true
        objectWillChange.send()
    }

    // MARK: - Comments

    func addComment(_ text: String) {
        guard let sheet, let row = selectedRow, let col = selectedCol else { return }
        let old = sheet.cells[row][col].comment
        sheet.cells[row][col].comment = text
        pushUndo(.setCellComment(row: row, col: col, oldComment: old, newComment: text))
        hasUnsavedChanges = true
    }

    func deleteComment() {
        guard let sheet, let row = selectedRow, let col = selectedCol else { return }
        let old = sheet.cells[row][col].comment
        sheet.cells[row][col].comment = nil
        pushUndo(.setCellComment(row: row, col: col, oldComment: old, newComment: nil))
        hasUnsavedChanges = true
    }

    var currentComment: String? {
        guard let sheet, let row = selectedRow, let col = selectedCol else { return nil }
        return sheet.cells[row][col].comment
    }

    // MARK: - Sheet Protection

    @Published var isSheetProtected: Bool = false

    func protectSheet() {
        isSheetProtected = true
        objectWillChange.send()
    }

    func unprotectSheet() {
        isSheetProtected = false
        objectWillChange.send()
    }

    // MARK: - Sort

    /// Multi-level sort with hasHeaders and caseSensitive options
    func sortMultiLevel(levels: [(col: Int, ascending: Bool)], hasHeaders: Bool, caseSensitive: Bool) {
        guard let sheet, !levels.isEmpty else { return }
        guard sheet.rowCount > 1 else { return }

        // Clear any active filter before sorting
        hiddenRows.removeAll()
        isFilterActive = false
        filterColumn = nil
        filterValue = nil

        // Separate header row if applicable
        let headerRows: [[STExcelCell]]
        let dataRows: [[STExcelCell]]
        if hasHeaders {
            headerRows = [sheet.cells[0]]
            dataRows = Array(sheet.cells.dropFirst())
        } else {
            headerRows = []
            dataRows = sheet.cells
        }

        // Separate empty rows (empty in primary sort column) — push to end
        let primaryCol = levels[0].col
        let nonEmpty = dataRows.filter { primaryCol < $0.count && !$0[primaryCol].value.isEmpty }
        let empty = dataRows.filter { primaryCol >= $0.count || $0[primaryCol].value.isEmpty }

        let sorted = nonEmpty.sorted { a, b in
            for level in levels {
                let col = level.col
                guard col < a.count, col < b.count else { continue }
                let va = a[col].value
                let vb = b[col].value
                if va == vb { continue }

                // Numeric comparison
                if let na = Double(va), let nb = Double(vb) {
                    if na == nb { continue }
                    return level.ascending ? na < nb : na > nb
                }

                // String comparison
                let result: ComparisonResult
                if caseSensitive {
                    result = va.compare(vb)
                } else {
                    result = va.localizedCaseInsensitiveCompare(vb)
                }
                if result == .orderedSame { continue }
                return level.ascending ? result == .orderedAscending : result == .orderedDescending
            }
            return false
        }

        sheet.cells = headerRows + sorted + empty
        hasUnsavedChanges = true
        gridRefreshId += 1
        objectWillChange.send()
    }

    /// Quick sort ascending on selected column (used by other features)
    func sortAscending() {
        guard let col = selectedCol else { return }
        sortMultiLevel(levels: [(col, true)], hasHeaders: true, caseSensitive: false)
    }

    /// Quick sort descending on selected column
    func sortDescending() {
        guard let col = selectedCol else { return }
        sortMultiLevel(levels: [(col, false)], hasHeaders: true, caseSensitive: false)
    }

    /// Sort by fill color on selected column
    func sortByColor() {
        guard let sheet, let col = selectedCol else { return }
        guard sheet.rowCount > 1 else { return }
        let header = sheet.cells[0]
        let dataRows = Array(sheet.cells.dropFirst())
        let sorted = dataRows.sorted { a, b in
            let ca = col < a.count ? (a[col].style.fillColor ?? "") : ""
            let cb = col < b.count ? (b[col].style.fillColor ?? "") : ""
            return ca < cb
        }
        sheet.cells = [header] + sorted
        hasUnsavedChanges = true
        gridRefreshId += 1
        objectWillChange.send()
    }

    // MARK: - Filter

    @Published var isFilterActive: Bool = false
    @Published var hiddenRows: Set<Int> = []
    @Published var filterColumn: Int? = nil
    @Published var filterValue: String? = nil

    func toggleFilter() {
        isFilterActive.toggle()
        if !isFilterActive {
            hiddenRows.removeAll()
            filterColumn = nil
            filterValue = nil
        }
        gridRefreshId += 1
        objectWillChange.send()
    }

    func reapplyFilter() {
        guard let sheet, let col = selectedCol else { return }
        guard let row = selectedRow else { return }
        isFilterActive = true
        filterColumn = col
        filterValue = sheet.cell(row: row, column: col).value
        hiddenRows.removeAll()
        // Row 0 = header, never hide
        for r in 1..<sheet.rowCount {
            if sheet.cell(row: r, column: col).value != filterValue {
                hiddenRows.insert(r)
            }
        }
        // Move selection to first visible data row
        if let firstVisible = (1..<sheet.rowCount).first(where: { !hiddenRows.contains($0) }) {
            selectedRow = firstVisible
            selectionEndRow = firstVisible
        }
        gridRefreshId += 1
        objectWillChange.send()
    }

    // MARK: - Data Validation

    /// Validation rules: cellRef → rule
    struct ValidationRule {
        var type: Int  // 0=Any, 1=WholeNumber, 2=Decimal, 3=List, 4=Date, 5=TextLength
        var min: String
        var max: String
        var list: [String]
    }

    @Published var validationRules: [String: ValidationRule] = [:]  // "row,col" → rule
    @Published var invalidCells: Set<String> = []  // "row,col" cells that failed validation

    func setDataValidation(type: Int, min minVal: String, max maxVal: String, list: String) {
        guard selectedRow != nil, let col = selectedCol else { return }
        let sr = Swift.min(selectionStartRow, selectionActualEndRow)
        let er = Swift.max(selectionStartRow, selectionActualEndRow)
        let sc = Swift.min(selectionStartCol, selectionActualEndCol)
        let ec = Swift.max(selectionStartCol, selectionActualEndCol)

        let listItems = list.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        let rule = ValidationRule(type: type, min: minVal, max: maxVal, list: listItems)

        for r in sr...er {
            for c in sc...ec {
                validationRules["\(r),\(c)"] = rule
            }
        }
        hasUnsavedChanges = true
        objectWillChange.send()
    }

    func clearDataValidation() {
        guard selectedRow != nil else { return }
        let sr = min(selectionStartRow, selectionActualEndRow)
        let er = max(selectionStartRow, selectionActualEndRow)
        let sc = min(selectionStartCol, selectionActualEndCol)
        let ec = max(selectionStartCol, selectionActualEndCol)
        for r in sr...er {
            for c in sc...ec {
                validationRules.removeValue(forKey: "\(r),\(c)")
                invalidCells.remove("\(r),\(c)")
            }
        }
        objectWillChange.send()
    }

    func circleInvalidData() {
        guard let sheet else { return }
        invalidCells.removeAll()
        for (key, rule) in validationRules {
            let parts = key.split(separator: ",")
            guard parts.count == 2, let r = Int(parts[0]), let c = Int(parts[1]) else { continue }
            let value = sheet.cell(row: r, column: c).value
            if !validateCell(value: value, rule: rule) {
                invalidCells.insert(key)
            }
        }
        gridRefreshId += 1
        objectWillChange.send()
    }

    private func validateCell(value: String, rule: ValidationRule) -> Bool {
        if rule.type == 0 { return true }  // Any
        if value.isEmpty { return true }  // Empty is always valid
        switch rule.type {
        case 1: // Whole Number
            guard let n = Int(value) else { return false }
            if let lo = Int(rule.min), n < lo { return false }
            if let hi = Int(rule.max), n > hi { return false }
            return true
        case 2: // Decimal
            guard let n = Double(value) else { return false }
            if let lo = Double(rule.min), n < lo { return false }
            if let hi = Double(rule.max), n > hi { return false }
            return true
        case 3: // List
            return rule.list.contains(value)
        case 5: // Text Length
            let len = value.count
            if let lo = Int(rule.min), len < lo { return false }
            if let hi = Int(rule.max), len > hi { return false }
            return true
        default: return true
        }
    }

    // MARK: - Group/Ungroup

    @Published var groupedRows: Set<Int> = []
    @Published var collapsedGroups: Set<Int> = []

    func groupRows() {
        guard selectedRow != nil else { return }
        let sr = min(selectionStartRow, selectionActualEndRow)
        let er = max(selectionStartRow, selectionActualEndRow)
        for r in sr...er {
            groupedRows.insert(r)
        }
        objectWillChange.send()
    }

    func ungroupRows() {
        guard selectedRow != nil else { return }
        let sr = min(selectionStartRow, selectionActualEndRow)
        let er = max(selectionStartRow, selectionActualEndRow)
        for r in sr...er {
            groupedRows.remove(r)
            collapsedGroups.remove(r)
        }
        objectWillChange.send()
    }

    func showDetail() {
        guard selectedRow != nil else { return }
        let sr = min(selectionStartRow, selectionActualEndRow)
        let er = max(selectionStartRow, selectionActualEndRow)
        for r in sr...er {
            collapsedGroups.remove(r)
            hiddenRows.remove(r)
        }
        gridRefreshId += 1
        objectWillChange.send()
    }

    func hideDetail() {
        guard selectedRow != nil else { return }
        let sr = min(selectionStartRow, selectionActualEndRow)
        let er = max(selectionStartRow, selectionActualEndRow)
        for r in sr...er {
            if groupedRows.contains(r) {
                collapsedGroups.insert(r)
                hiddenRows.insert(r)
            }
        }
        gridRefreshId += 1
        objectWillChange.send()
    }

    // MARK: - Subtotal

    func insertSubtotal(function: String) {
        guard let sheet, let col = selectedCol else { return }
        // Find last non-empty row in selected column (skip header row 0)
        var endRow = sheet.rowCount - 1
        while endRow > 1 && sheet.cell(row: endRow, column: col).value.isEmpty { endRow -= 1 }
        guard endRow > 0 else { return }

        let colLetter = STExcelSheet.columnLetter(col)
        // Range starts from row 2 (skip header row 1)
        let formula = "=\(function)(\(colLetter)2:\(colLetter)\(endRow + 1))"

        // Insert a new row below data for the subtotal
        let targetRow = endRow + 1
        if targetRow >= sheet.rowCount {
            // Add a new row
            let newRow = (0..<sheet.columnCount).map { _ in STExcelCell() }
            sheet.cells.append(newRow)
        }
        sheet.cells[targetRow][col].formula = formula
        sheet.cells[targetRow][col].value = ""
        sheet.cells[targetRow][col].style.isBold = true

        // Add a label in the first column
        if col > 0 {
            sheet.cells[targetRow][0].value = "\(function) Total"
            sheet.cells[targetRow][0].style.isBold = true
        }

        hasUnsavedChanges = true
        gridRefreshId += 1
        objectWillChange.send()
    }

    func removeAllGroupsAndSubtotals() {
        guard let sheet else { return }
        groupedRows.removeAll()
        collapsedGroups.removeAll()
        // Remove rows that contain subtotal formulas
        for r in (0..<sheet.rowCount).reversed() {
            let hasSubtotalFormula = sheet.cells[r].contains { cell in
                guard let f = cell.formula?.uppercased() else { return false }
                return f.hasPrefix("=SUM(") || f.hasPrefix("=COUNT(") || f.hasPrefix("=AVERAGE(")
                    || f.hasPrefix("=MAX(") || f.hasPrefix("=MIN(")
            }
            let isLabelRow = sheet.cells[r].first?.value.hasSuffix("Total") == true
            if hasSubtotalFormula || isLabelRow {
                // Clear the subtotal row instead of removing (to preserve row count)
                for c in 0..<sheet.cells[r].count {
                    sheet.cells[r][c] = STExcelCell()
                }
            }
        }
        // Also unhide any hidden rows from groups
        for r in hiddenRows {
            if !isFilterActive || filterColumn == nil {
                hiddenRows.remove(r)
            }
        }
        hasUnsavedChanges = true
        gridRefreshId += 1
        objectWillChange.send()
    }

    // MARK: - Text to Columns

    func textToColumns(delimiter: String) {
        guard let sheet, selectedRow != nil, let col = selectedCol else { return }
        let sr = min(selectionStartRow, selectionActualEndRow)
        let er = max(selectionStartRow, selectionActualEndRow)
        for r in sr...er {
            let value = sheet.cell(row: r, column: col).value
            let parts = value.components(separatedBy: delimiter)
            for (i, part) in parts.enumerated() {
                let targetCol = col + i
                guard targetCol < sheet.columnCount else { break }
                sheet.cells[r][targetCol].value = part.trimmingCharacters(in: .whitespaces)
            }
        }
        hasUnsavedChanges = true
        objectWillChange.send()
    }

    // MARK: - Defined Names

    @Published var definedNames: [String: String] = [:]

    func defineName(_ name: String, refersTo: String) {
        definedNames[name] = refersTo
    }

    func removeName(_ name: String) {
        definedNames.removeValue(forKey: name)
    }

    // MARK: - Auto Formula

    /// Insert a formula (SUM, AVERAGE, etc.) into the formula bar for editing.
    /// - If a range is selected → uses that range (e.g. =SUM(A11:E20))
    /// - If single cell → auto-detects continuous data range above
    /// Does NOT commit — the user sees the formula and can edit before confirming with ✓.
    func insertAutoFormula(_ function: String) {
        guard let sheet, let row = selectedRow, let col = selectedCol else { return }

        let formula: String

        if hasRangeSelection {
            // Use the selected range
            let sr = min(selectionStartRow, selectionActualEndRow)
            let sc = min(selectionStartCol, selectionActualEndCol)
            let er = max(selectionStartRow, selectionActualEndRow)
            let ec = max(selectionStartCol, selectionActualEndCol)

            let startRef = "\(STExcelSheet.columnLetter(sc))\(sr + 1)"
            let endRef = "\(STExcelSheet.columnLetter(ec))\(er + 1)"
            formula = "=\(function)(\(startRef):\(endRef))"

            // Move cursor to cell below the range to put the result there
            let resultRow = min(er + 1, sheet.rowCount - 1)
            selectCell(row: resultRow, col: sc)
        } else {
            // Auto-detect: find continuous data range above current cell
            var startRow = row - 1
            while startRow >= 0 {
                let cell = sheet.cell(row: startRow, column: col)
                if cell.value.isEmpty && cell.formula == nil { break }
                startRow -= 1
            }
            startRow += 1

            let colLetter = STExcelSheet.columnLetter(col)
            if startRow < row {
                formula = "=\(function)(\(colLetter)\(startRow + 1):\(colLetter)\(row))"
            } else {
                // No data above — empty template for user to fill in
                formula = "=\(function)()"
            }
        }

        // Put formula in formula bar and enter editing mode (don't commit yet)
        editingValue = formula
        isEditing = true
    }

    // MARK: - Shift Cells

    func shiftCellsRight() {
        guard let sheet, let row = selectedRow, let col = selectedCol else { return }
        sheet.cells[row].insert(STExcelCell(), at: col)
        if sheet.cells[row].count > sheet.columnCount {
            sheet.cells[row].removeLast()
        }
        hasUnsavedChanges = true
        objectWillChange.send()
    }

    func shiftCellsDown() {
        guard let sheet, let row = selectedRow, let col = selectedCol else { return }
        for r in stride(from: sheet.rowCount - 1, through: row + 1, by: -1) {
            sheet.cells[r][col] = sheet.cells[r - 1][col]
        }
        sheet.cells[row][col] = STExcelCell()
        hasUnsavedChanges = true
        objectWillChange.send()
    }

    func shiftCellsLeft() {
        guard let sheet, let row = selectedRow, let col = selectedCol else { return }
        guard col < sheet.columnCount else { return }
        sheet.cells[row].remove(at: col)
        sheet.cells[row].append(STExcelCell())
        hasUnsavedChanges = true
        objectWillChange.send()
    }

    func shiftCellsUp() {
        guard let sheet, let row = selectedRow, let col = selectedCol else { return }
        for r in row..<(sheet.rowCount - 1) {
            sheet.cells[r][col] = sheet.cells[r + 1][col]
        }
        sheet.cells[sheet.rowCount - 1][col] = STExcelCell()
        hasUnsavedChanges = true
        objectWillChange.send()
    }

    // MARK: - Sheet Operations

    func deleteSheet() {
        guard let document, document.sheets.count > 1 else { return }
        document.removeSheet(at: document.activeSheetIndex)
        hasUnsavedChanges = true
        objectWillChange.send()
    }

    func addNewSheet() {
        guard let document else { return }
        document.addSheet()
        document.activeSheetIndex = document.sheets.count - 1
        hasUnsavedChanges = true
        objectWillChange.send()
    }

    // MARK: - View Controls

    func toggleFreezePanes() {
        if frozenRows > 0 || frozenCols > 0 {
            frozenRows = 0
            frozenCols = 0
        } else {
            frozenRows = (selectedRow ?? 0) + 1
            frozenCols = (selectedCol ?? 0) + 1
        }
    }

    func selectAll() {
        guard let sheet else { return }
        selectedRow = 0
        selectedCol = 0
        selectionEndRow = sheet.rowCount - 1
        selectionEndCol = sheet.columnCount - 1
    }

    // MARK: - Go To Cell

    func goToCell(_ ref: String) {
        guard let cellRef = CellReference(string: ref) else { return }
        selectCell(row: cellRef.row, col: cellRef.col)
    }

    // MARK: - Cell Reference String

    var cellReferenceString: String {
        guard let row = selectedRow, let col = selectedCol else { return "" }
        return "\(STExcelSheet.columnLetter(col))\(row + 1)"
    }

    // MARK: - Undo / Redo

    private func pushUndo(_ action: STExcelUndoAction) {
        undoStack.append(action)
        redoStack.removeAll()
        canUndo = true
        canRedo = false
    }

    func undo() {
        guard let action = undoStack.popLast(), let sheet else { return }
        performReverse(action, on: sheet)
        redoStack.append(action)
        canUndo = !undoStack.isEmpty
        canRedo = true
        hasUnsavedChanges = true
        objectWillChange.send()
    }

    func redo() {
        guard let action = redoStack.popLast(), let sheet else { return }
        performForward(action, on: sheet)
        undoStack.append(action)
        canUndo = true
        canRedo = !redoStack.isEmpty
        hasUnsavedChanges = true
        objectWillChange.send()
    }

    private func performReverse(_ action: STExcelUndoAction, on sheet: STExcelSheet) {
        switch action {
        case .setCellValue(let r, let c, let oldVal, _):
            sheet.setCell(row: r, column: c, value: oldVal)
        case .setCellStyle(let r, let c, let oldStyle, _):
            sheet.setCellStyle(row: r, column: c, style: oldStyle)
        case .setRangeStyle(let changes):
            for change in changes {
                sheet.setCellStyle(row: change.row, column: change.col, style: change.oldStyle)
            }
        case .insertRow(let at):
            sheet.deleteRow(at: at)
        case .deleteRow(let at, let cells):
            sheet.cells.insert(cells, at: at)
        case .insertColumn(let at):
            sheet.deleteColumn(at: at)
        case .deleteColumn(let at, let cells):
            for (r, cell) in cells.enumerated() where r < sheet.rowCount {
                sheet.cells[r].insert(cell, at: at)
            }
        case .mergeCells(let region):
            sheet.unmergeCells(row: region.startRow, col: region.startCol)
        case .unmergeCells(let region):
            sheet.mergeCells(startRow: region.startRow, startCol: region.startCol,
                            endRow: region.endRow, endCol: region.endCol)
        case .setCellComment(let r, let c, let old, _):
            sheet.cells[r][c].comment = old
        case .batch(let actions):
            for a in actions.reversed() { performReverse(a, on: sheet) }
        }
    }

    private func performForward(_ action: STExcelUndoAction, on sheet: STExcelSheet) {
        switch action {
        case .setCellValue(let r, let c, _, let newVal):
            sheet.setCell(row: r, column: c, value: newVal)
        case .setCellStyle(let r, let c, _, let newStyle):
            sheet.setCellStyle(row: r, column: c, style: newStyle)
        case .setRangeStyle(let changes):
            for change in changes {
                sheet.setCellStyle(row: change.row, column: change.col, style: change.newStyle)
            }
        case .insertRow(let at):
            sheet.insertRow(at: at)
        case .deleteRow(let at, _):
            sheet.deleteRow(at: at)
        case .insertColumn(let at):
            sheet.insertColumn(at: at)
        case .deleteColumn(let at, _):
            sheet.deleteColumn(at: at)
        case .mergeCells(let region):
            sheet.mergeCells(startRow: region.startRow, startCol: region.startCol,
                            endRow: region.endRow, endCol: region.endCol)
        case .unmergeCells(let region):
            sheet.unmergeCells(row: region.startRow, col: region.startCol)
        case .setCellComment(let r, let c, _, let new):
            sheet.cells[r][c].comment = new
        case .batch(let actions):
            for a in actions { performForward(a, on: sheet) }
        }
    }
}
