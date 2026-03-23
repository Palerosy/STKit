import Foundation
import SwiftUI
import ZIPFoundation

/// Writes sheets to .xlsx format with full feature support
enum STExcelWriter {

    @discardableResult
    static func write(sheets: [STExcelSheet], to url: URL, definedNames: [String: String] = [:]) -> Bool {
        try? FileManager.default.removeItem(at: url)
        guard let archive = Archive(url: url, accessMode: .create) else { return false }

        // Collect styles from all sheets
        let styleCollector = StyleCollector()
        for sheet in sheets {
            for row in sheet.cells {
                for cell in row where cell.style.isCustom {
                    _ = styleCollector.indexFor(style: cell.style)
                }
            }
        }

        // Collect shared strings
        var allStrings: [String] = []
        var stringIndex: [String: Int] = [:]
        for sheet in sheets {
            for row in sheet.cells {
                for cell in row where !cell.value.isEmpty && Double(cell.value) == nil && cell.formula == nil {
                    if stringIndex[cell.value] == nil {
                        stringIndex[cell.value] = allStrings.count
                        allStrings.append(cell.value)
                    }
                }
            }
        }

        // Collect image references per sheet
        var globalImageCounter = 0
        var sheetImageRefs: [[ImageRef]] = []
        for (si, sheet) in sheets.enumerated() {
            var refs: [ImageRef] = []
            for (li, img) in sheet.images.enumerated() {
                globalImageCounter += 1
                let ext = detectImageExtension(img.imageData)
                refs.append(ImageRef(sheetIndex: si, localIndex: li,
                                     globalIndex: globalImageCounter, ext: ext))
            }
            sheetImageRefs.append(refs)
        }

        // Collect chart references per sheet
        var globalChartCounter = 0
        var sheetChartRefs: [[ChartRef]] = []
        for (si, sheet) in sheets.enumerated() {
            var refs: [ChartRef] = []
            for li in 0..<sheet.charts.count {
                globalChartCounter += 1
                refs.append(ChartRef(sheetIndex: si, localIndex: li, globalIndex: globalChartCounter))
            }
            sheetChartRefs.append(refs)
        }

        // Collect table references per sheet
        var globalTableCounter = 0
        var sheetTableRefs: [[TableRef]] = []
        for (si, sheet) in sheets.enumerated() {
            var refs: [TableRef] = []
            for li in 0..<sheet.tables.count {
                globalTableCounter += 1
                refs.append(TableRef(sheetIndex: si, localIndex: li, globalIndex: globalTableCounter))
            }
            sheetTableRefs.append(refs)
        }

        // Collect DXF entries for conditional formatting
        var sheetDxfIds: [[Int?]] = []
        for sheet in sheets {
            var dxfIds: [Int?] = []
            for rule in sheet.conditionalRules {
                switch rule.ruleType {
                case .highlightCells, .topBottom, .customFormula:
                    let bgHex = rule.preset.bgColor.map { swiftUIColorToHex($0) }
                    let textColor = rule.preset.textColor
                    let textHex: String? = (textColor == .primary) ? nil : swiftUIColorToHex(textColor)
                    let borderHex = rule.preset.borderColor.map { swiftUIColorToHex($0) }
                    let dxfId = styleCollector.addDxf(bgColor: bgHex, textColor: textHex, borderColor: borderHex)
                    dxfIds.append(dxfId)
                case .dataBar, .colorScale:
                    dxfIds.append(nil)
                }
            }
            sheetDxfIds.append(dxfIds)
        }

        do {
            try addEntry(archive, "[Content_Types].xml",
                         contentTypesXML(sheetCount: sheets.count,
                                        imageRefs: sheetImageRefs,
                                        chartRefs: sheetChartRefs,
                                        tableRefs: sheetTableRefs,
                                        sheets: sheets))
            try addEntry(archive, "_rels/.rels", relsXML())
            try addEntry(archive, "xl/_rels/workbook.xml.rels",
                         workbookRelsXML(sheetCount: sheets.count))
            try addEntry(archive, "xl/workbook.xml",
                         workbookXML(sheets: sheets, definedNames: definedNames))
            try addEntry(archive, "xl/styles.xml", styleCollector.generateStylesXML())
            try addEntry(archive, "xl/sharedStrings.xml", sharedStringsXML(strings: allStrings))

            for (index, sheet) in sheets.enumerated() {
                let imageRefs = sheetImageRefs[index]
                let chartRefs = sheetChartRefs[index]
                let tableRefs = sheetTableRefs[index]
                let dxfIds = sheetDxfIds[index]
                let hasDrawing = !imageRefs.isEmpty || !sheet.shapes.isEmpty || !chartRefs.isEmpty

                let comments = collectComments(sheet: sheet)
                let hasComments = !comments.isEmpty
                let sheetRelsNeeded = hasDrawing || hasComments || !tableRefs.isEmpty

                // Compute table rId base (after drawing + comments)
                var nextRId = 1
                if hasDrawing { nextRId += 1 }
                if hasComments { nextRId += 1 }
                let tableRIdBase = nextRId

                // Worksheet XML
                let xml = worksheetXML(sheet: sheet, stringIndex: stringIndex,
                                       styleCollector: styleCollector,
                                       hasDrawing: hasDrawing,
                                       hasComments: hasComments,
                                       tableRefs: tableRefs,
                                       tableRIdBase: tableRIdBase,
                                       dxfIds: dxfIds)
                try addEntry(archive, "xl/worksheets/sheet\(index + 1).xml", xml)

                // Sheet rels
                if sheetRelsNeeded {
                    try addEntry(archive,
                                 "xl/worksheets/_rels/sheet\(index + 1).xml.rels",
                                 sheetRelsXML(sheetIndex: index,
                                              hasDrawing: hasDrawing,
                                              hasComments: hasComments,
                                              tableRefs: tableRefs))
                }

                // Drawing (images + shapes + charts)
                if hasDrawing {
                    try addEntry(archive,
                                 "xl/drawings/_rels/drawing\(index + 1).xml.rels",
                                 drawingRelsXML(imageRefs: imageRefs, chartRefs: chartRefs))
                    try addEntry(archive,
                                 "xl/drawings/drawing\(index + 1).xml",
                                 drawingXML(sheet: sheet, imageRefs: imageRefs, chartRefs: chartRefs))
                    for ref in imageRefs {
                        let img = sheet.images[ref.localIndex]
                        try addBinaryEntry(archive,
                                           "xl/media/image\(ref.globalIndex).\(ref.ext)",
                                           img.imageData)
                    }
                }

                // Charts
                for ref in chartRefs {
                    let chart = sheet.charts[ref.localIndex]
                    try addEntry(archive,
                                 "xl/charts/chart\(ref.globalIndex).xml",
                                 chartXML(chart: chart, sheetName: sheet.name))
                }

                // Tables
                for ref in tableRefs {
                    let table = sheet.tables[ref.localIndex]
                    try addEntry(archive,
                                 "xl/tables/table\(ref.globalIndex).xml",
                                 tableXML(table: table, sheet: sheet, tableIndex: ref.globalIndex))
                }

                // Comments
                if hasComments {
                    try addEntry(archive,
                                 "xl/comments\(index + 1).xml",
                                 commentsXML(comments: comments))
                }
            }

            return true
        } catch {
            print("[STExcel] Write failed: \(error)")
            return false
        }
    }

    // MARK: - Helpers

    private struct ImageRef {
        let sheetIndex: Int
        let localIndex: Int
        let globalIndex: Int
        let ext: String
    }

    private struct ChartRef {
        let sheetIndex: Int
        let localIndex: Int
        let globalIndex: Int
    }

    private struct TableRef {
        let sheetIndex: Int
        let localIndex: Int
        let globalIndex: Int
    }

    private static func addEntry(_ archive: Archive, _ path: String, _ content: String) throws {
        let data = Data(content.utf8)
        try archive.addEntry(with: path, type: .file,
                             uncompressedSize: Int64(data.count),
                             provider: { _, _ in data })
    }

    private static func addBinaryEntry(_ archive: Archive, _ path: String, _ data: Data) throws {
        try archive.addEntry(with: path, type: .file,
                             uncompressedSize: Int64(data.count),
                             provider: { _, _ in data })
    }

    private static func detectImageExtension(_ data: Data) -> String {
        guard data.count > 4 else { return "png" }
        let bytes = [UInt8](data.prefix(4))
        if bytes[0] == 0xFF && bytes[1] == 0xD8 { return "jpeg" }
        return "png"
    }

    #if canImport(UIKit)
    private static func swiftUIColorToHex(_ color: Color) -> String {
        let uiColor = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
    #else
    private static func swiftUIColorToHex(_ color: Color) -> String {
        return "4472C4"
    }
    #endif

    // MARK: - Content Types

    private static func contentTypesXML(sheetCount: Int, imageRefs: [[ImageRef]],
                                        chartRefs: [[ChartRef]] = [],
                                        tableRefs: [[TableRef]] = [],
                                        sheets: [STExcelSheet] = []) -> String {
        let allImgRefs = imageRefs.flatMap { $0 }
        let hasJpeg = allImgRefs.contains { $0.ext == "jpeg" }
        let hasPng = allImgRefs.contains { $0.ext == "png" }

        var xml = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
        <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
        <Default Extension="xml" ContentType="application/xml"/>
        """
        if hasPng { xml += "<Default Extension=\"png\" ContentType=\"image/png\"/>" }
        if hasJpeg { xml += "<Default Extension=\"jpeg\" ContentType=\"image/jpeg\"/>" }

        xml += "<Override PartName=\"/xl/workbook.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml\"/>"
        xml += "<Override PartName=\"/xl/styles.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml\"/>"
        xml += "<Override PartName=\"/xl/sharedStrings.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.spreadsheetml.sharedStrings+xml\"/>"

        for i in 1...sheetCount {
            xml += "<Override PartName=\"/xl/worksheets/sheet\(i).xml\" ContentType=\"application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml\"/>"
        }

        // Drawings
        for (si, refs) in imageRefs.enumerated() {
            let hasShapes = si < sheets.count && !sheets[si].shapes.isEmpty
            let hasCharts = si < chartRefs.count && !chartRefs[si].isEmpty
            if !refs.isEmpty || hasShapes || hasCharts {
                xml += "<Override PartName=\"/xl/drawings/drawing\(si + 1).xml\" ContentType=\"application/vnd.openxmlformats-officedocument.drawing+xml\"/>"
            }
        }

        // Charts
        for refs in chartRefs {
            for ref in refs {
                xml += "<Override PartName=\"/xl/charts/chart\(ref.globalIndex).xml\" ContentType=\"application/vnd.openxmlformats-officedocument.drawingml.chart+xml\"/>"
            }
        }

        // Tables
        for refs in tableRefs {
            for ref in refs {
                xml += "<Override PartName=\"/xl/tables/table\(ref.globalIndex).xml\" ContentType=\"application/vnd.openxmlformats-officedocument.spreadsheetml.table+xml\"/>"
            }
        }

        // Comments
        for (si, sheet) in sheets.enumerated() {
            let hasComments = sheet.cells.contains(where: { row in row.contains(where: { $0.comment != nil && !$0.comment!.isEmpty }) })
            if hasComments {
                xml += "<Override PartName=\"/xl/comments\(si + 1).xml\" ContentType=\"application/vnd.openxmlformats-officedocument.spreadsheetml.comments+xml\"/>"
            }
        }

        xml += "</Types>"
        return xml
    }

    // MARK: - Rels

    private static func relsXML() -> String {
        """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
        <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
        </Relationships>
        """
    }

    private static func workbookRelsXML(sheetCount: Int) -> String {
        var xml = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
        <Relationship Id="rId\(sheetCount + 1)" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
        <Relationship Id="rId\(sheetCount + 2)" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/sharedStrings" Target="sharedStrings.xml"/>
        """
        for i in 1...sheetCount {
            xml += "<Relationship Id=\"rId\(i)\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet\" Target=\"worksheets/sheet\(i).xml\"/>"
        }
        xml += "</Relationships>"
        return xml
    }

    // MARK: - Sheet Rels (sheet → drawing, comments, tables)

    private static func sheetRelsXML(sheetIndex: Int, hasDrawing: Bool, hasComments: Bool,
                                     tableRefs: [TableRef] = []) -> String {
        var xml = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
        """
        var rId = 1
        if hasDrawing {
            xml += "<Relationship Id=\"rId\(rId)\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/drawing\" Target=\"../drawings/drawing\(sheetIndex + 1).xml\"/>"
            rId += 1
        }
        if hasComments {
            xml += "<Relationship Id=\"rId\(rId)\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/comments\" Target=\"../comments\(sheetIndex + 1).xml\"/>"
            rId += 1
        }
        for ref in tableRefs {
            xml += "<Relationship Id=\"rId\(rId)\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/table\" Target=\"../tables/table\(ref.globalIndex).xml\"/>"
            rId += 1
        }
        xml += "</Relationships>"
        return xml
    }

    // MARK: - Comments

    private struct CellComment {
        let ref: String
        let text: String
    }

    private static func collectComments(sheet: STExcelSheet) -> [CellComment] {
        var comments: [CellComment] = []
        for (rowIndex, row) in sheet.cells.enumerated() {
            for (colIndex, cell) in row.enumerated() {
                if let comment = cell.comment, !comment.isEmpty {
                    let ref = "\(STExcelSheet.columnLetter(colIndex))\(rowIndex + 1)"
                    comments.append(CellComment(ref: ref, text: comment))
                }
            }
        }
        return comments
    }

    private static func commentsXML(comments: [CellComment]) -> String {
        var xml = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <comments xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
        <authors><author>Author</author></authors>
        <commentList>
        """
        for comment in comments {
            xml += "<comment ref=\"\(comment.ref)\" authorId=\"0\"><text><r><t>\(escapeXML(comment.text))</t></r></text></comment>"
        }
        xml += "</commentList></comments>"
        return xml
    }

    // MARK: - Drawing Rels (drawing → images + charts)

    private static func drawingRelsXML(imageRefs: [ImageRef], chartRefs: [ChartRef] = []) -> String {
        var xml = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
        """
        for (i, ref) in imageRefs.enumerated() {
            xml += "<Relationship Id=\"rId\(i + 1)\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/image\" Target=\"../media/image\(ref.globalIndex).\(ref.ext)\"/>"
        }
        let chartRIdBase = imageRefs.count + 1
        for (i, ref) in chartRefs.enumerated() {
            xml += "<Relationship Id=\"rId\(chartRIdBase + i)\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/chart\" Target=\"../charts/chart\(ref.globalIndex).xml\"/>"
        }
        xml += "</Relationships>"
        return xml
    }

    // MARK: - Workbook

    private static func workbookXML(sheets: [STExcelSheet], definedNames: [String: String] = [:]) -> String {
        var xml = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
        <sheets>
        """
        for (index, sheet) in sheets.enumerated() {
            xml += "<sheet name=\"\(escapeXML(sheet.name))\" sheetId=\"\(index + 1)\" r:id=\"rId\(index + 1)\"/>"
        }
        xml += "</sheets>"
        if !definedNames.isEmpty {
            xml += "<definedNames>"
            for (name, refersTo) in definedNames {
                xml += "<definedName name=\"\(escapeXML(name))\">\(escapeXML(refersTo))</definedName>"
            }
            xml += "</definedNames>"
        }
        xml += "</workbook>"
        return xml
    }

    // MARK: - Shared Strings

    private static func sharedStringsXML(strings: [String]) -> String {
        var xml = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <sst xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" count="\(strings.count)" uniqueCount="\(strings.count)">
        """
        for str in strings {
            xml += "<si><t>\(escapeXML(str))</t></si>"
        }
        xml += "</sst>"
        return xml
    }

    // MARK: - Worksheet

    private static func worksheetXML(sheet: STExcelSheet, stringIndex: [String: Int],
                                     styleCollector: StyleCollector,
                                     hasDrawing: Bool,
                                     hasComments: Bool = false,
                                     tableRefs: [TableRef] = [],
                                     tableRIdBase: Int = 1,
                                     dxfIds: [Int?] = []) -> String {
        var xml = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
        """

        // Frozen panes
        if sheet.frozenRows > 0 || sheet.frozenCols > 0 {
            let topLeft = "\(STExcelSheet.columnLetter(sheet.frozenCols))\(sheet.frozenRows + 1)"
            var paneAttrs = ""
            if sheet.frozenCols > 0 { paneAttrs += " xSplit=\"\(sheet.frozenCols)\"" }
            if sheet.frozenRows > 0 { paneAttrs += " ySplit=\"\(sheet.frozenRows)\"" }
            paneAttrs += " topLeftCell=\"\(topLeft)\" state=\"frozen\""
            xml += "<sheetViews><sheetView tabSelected=\"1\" workbookViewId=\"0\"><pane\(paneAttrs)/></sheetView></sheetViews>"
        }

        // Column widths
        if !sheet.columnWidths.isEmpty {
            xml += "<cols>"
            for col in sheet.columnWidths.keys.sorted() {
                let pts = sheet.columnWidths[col]!
                let excelWidth = pts / 7.0
                xml += "<col min=\"\(col + 1)\" max=\"\(col + 1)\" width=\"\(String(format: "%.2f", excelWidth))\" customWidth=\"1\"/>"
            }
            xml += "</cols>"
        }

        // Dimension — write the extent of actual content, not the full in-memory grid.
        // This prevents the reader from re-inflating empty trailing rows/cols on reload.
        var lastContentRow = 0
        var lastContentCol = 0
        for (r, row) in sheet.cells.enumerated() {
            for (c, cell) in row.enumerated() {
                if !cell.value.isEmpty || cell.style.isCustom || cell.formula != nil {
                    lastContentRow = max(lastContentRow, r)
                    lastContentCol = max(lastContentCol, c)
                }
            }
        }
        // Also include merged regions — clamped to actual cells bounds
        let maxValidRow = sheet.rowCount - 1
        let maxValidCol = sheet.columnCount - 1
        for region in sheet.mergedRegions {
            lastContentRow = max(lastContentRow, min(region.endRow, maxValidRow))
            lastContentCol = max(lastContentCol, min(region.endCol, maxValidCol))
        }
        let dimRef = "A1:\(STExcelSheet.columnLetter(lastContentCol))\(lastContentRow + 1)"
        xml += "<dimension ref=\"\(dimRef)\"/>"

        // Sheet data
        xml += "<sheetData>"

        for (rowIndex, row) in sheet.cells.enumerated() {
            let hasData = row.contains(where: { !$0.value.isEmpty || $0.style.isCustom })
            let hasCustomHeight = sheet.rowHeights[rowIndex] != nil
            let isGrouped = sheet.groupedRows.contains(rowIndex)
            let isHidden = sheet.hiddenRows.contains(rowIndex) || sheet.collapsedGroups.contains(rowIndex)

            guard hasData || hasCustomHeight || isGrouped || isHidden else { continue }

            var rowAttrs = "r=\"\(rowIndex + 1)\""
            if let ht = sheet.rowHeights[rowIndex] {
                rowAttrs += " ht=\"\(String(format: "%.2f", ht))\" customHeight=\"1\""
            }
            if isGrouped { rowAttrs += " outlineLevel=\"1\"" }
            if isHidden { rowAttrs += " hidden=\"1\"" }

            xml += "<row \(rowAttrs)>"
            for (colIndex, cell) in row.enumerated() {
                guard !cell.value.isEmpty || cell.style.isCustom else { continue }
                let ref = "\(STExcelSheet.columnLetter(colIndex))\(rowIndex + 1)"
                let styleIdx = cell.style.isCustom ? styleCollector.indexFor(style: cell.style) : 0

                let sAttr = styleIdx > 0 ? " s=\"\(styleIdx)\"" : ""

                if let formula = cell.formula {
                    let cleanFormula = formula.hasPrefix("=") ? String(formula.dropFirst()) : formula
                    if let numVal = Double(cell.value) {
                        xml += "<c r=\"\(ref)\"\(sAttr)><f>\(escapeXML(cleanFormula))</f><v>\(numVal)</v></c>"
                    } else {
                        xml += "<c r=\"\(ref)\"\(sAttr)><f>\(escapeXML(cleanFormula))</f></c>"
                    }
                } else if let numVal = Double(cell.value) {
                    xml += "<c r=\"\(ref)\"\(sAttr)><v>\(numVal)</v></c>"
                } else if cell.value.isEmpty {
                    xml += "<c r=\"\(ref)\"\(sAttr)/>"
                } else if let sIndex = stringIndex[cell.value] {
                    xml += "<c r=\"\(ref)\" t=\"s\"\(sAttr)><v>\(sIndex)</v></c>"
                }
            }
            xml += "</row>"
        }

        xml += "</sheetData>"

        // Sheet protection
        if sheet.isProtected {
            xml += "<sheetProtection sheet=\"1\" objects=\"1\" scenarios=\"1\"/>"
        }

        // Auto-filter (from tables with headers)
        if let firstTable = sheet.tables.first, firstTable.hasHeaders {
            xml += "<autoFilter ref=\"\(firstTable.rangeString)\"/>"
        }

        // Merge cells — skip regions that reference rows/cols beyond the actual grid
        let validMerges = sheet.mergedRegions.filter {
            $0.startRow < sheet.rowCount && $0.startCol < sheet.columnCount
        }
        if !validMerges.isEmpty {
            xml += "<mergeCells count=\"\(validMerges.count)\">"
            for region in validMerges {
                let clampedEndRow = min(region.endRow, sheet.rowCount - 1)
                let clampedEndCol = min(region.endCol, sheet.columnCount - 1)
                let startRef = "\(STExcelSheet.columnLetter(region.startCol))\(region.startRow + 1)"
                let endRef = "\(STExcelSheet.columnLetter(clampedEndCol))\(clampedEndRow + 1)"
                xml += "<mergeCell ref=\"\(startRef):\(endRef)\"/>"
            }
            xml += "</mergeCells>"
        }

        // Conditional formatting
        for (i, rule) in sheet.conditionalRules.enumerated() {
            let sqref = rule.rangeString
            xml += "<conditionalFormatting sqref=\"\(sqref)\">"

            switch rule.ruleType {
            case .highlightCells:
                let dxfId = (i < dxfIds.count ? dxfIds[i] : nil) ?? 0
                let (cfType, cfOperator) = cfTypeAndOperator(for: rule.condition)
                var ruleAttrs = "type=\"\(cfType)\" dxfId=\"\(dxfId)\" priority=\"\(i + 1)\""
                if !cfOperator.isEmpty { ruleAttrs += " operator=\"\(cfOperator)\"" }
                if rule.condition == .textContains {
                    ruleAttrs += " text=\"\(escapeXML(rule.value1))\""
                }
                xml += "<cfRule \(ruleAttrs)>"
                if rule.condition.needsValue1 && rule.condition != .duplicates && rule.condition != .uniqueValues {
                    xml += "<formula>\(escapeXML(rule.value1))</formula>"
                }
                if rule.condition.needsValue2 {
                    xml += "<formula>\(escapeXML(rule.value2))</formula>"
                }
                xml += "</cfRule>"

            case .topBottom:
                let dxfId = (i < dxfIds.count ? dxfIds[i] : nil) ?? 0
                var ruleAttrs = "type=\"top10\" dxfId=\"\(dxfId)\" priority=\"\(i + 1)\" rank=\"\(rule.rankCount)\""
                if rule.rank == .bottom || rule.rank == .belowAverage { ruleAttrs += " bottom=\"1\"" }
                if rule.rankIsPercent { ruleAttrs += " percent=\"1\"" }
                if rule.rank == .aboveAverage || rule.rank == .belowAverage {
                    xml += "<cfRule type=\"aboveAverage\" dxfId=\"\(dxfId)\" priority=\"\(i + 1)\""
                    if rule.rank == .belowAverage { xml += " aboveAverage=\"0\"" }
                    xml += "/>"
                } else {
                    xml += "<cfRule \(ruleAttrs)/>"
                }

            case .customFormula:
                let dxfId = (i < dxfIds.count ? dxfIds[i] : nil) ?? 0
                xml += "<cfRule type=\"expression\" dxfId=\"\(dxfId)\" priority=\"\(i + 1)\">"
                let formula = rule.formula.hasPrefix("=") ? String(rule.formula.dropFirst()) : rule.formula
                xml += "<formula>\(escapeXML(formula))</formula>"
                xml += "</cfRule>"

            case .dataBar:
                xml += "<cfRule type=\"dataBar\" priority=\"\(i + 1)\">"
                xml += "<dataBar>"
                xml += "<cfvo type=\"min\"/><cfvo type=\"max\"/>"
                xml += "<color rgb=\"FF\(swiftUIColorToHex(rule.barColor.color))\"/>"
                xml += "</dataBar>"
                xml += "</cfRule>"

            case .colorScale:
                xml += "<cfRule type=\"colorScale\" priority=\"\(i + 1)\">"
                xml += "<colorScale>"
                xml += "<cfvo type=\"min\"/><cfvo type=\"percentile\" val=\"50\"/><cfvo type=\"max\"/>"
                xml += "<color rgb=\"FF\(swiftUIColorToHex(rule.colorScale.lowColor))\"/>"
                xml += "<color rgb=\"FF\(swiftUIColorToHex(rule.colorScale.midColor))\"/>"
                xml += "<color rgb=\"FF\(swiftUIColorToHex(rule.colorScale.highColor))\"/>"
                xml += "</colorScale>"
                xml += "</cfRule>"
            }

            xml += "</conditionalFormatting>"
        }

        // Data validations
        let validations = groupDataValidations(sheet.dataValidations)
        if !validations.isEmpty {
            xml += "<dataValidations count=\"\(validations.count)\">"
            for (sqref, rule) in validations {
                let typeStr = rule.xlsxType
                if typeStr == "none" { continue }
                if typeStr == "list" {
                    let listStr = "\"" + rule.listValues.joined(separator: ",") + "\""
                    xml += "<dataValidation type=\"list\" allowBlank=\"1\" showInputMessage=\"1\" showErrorMessage=\"1\" sqref=\"\(sqref)\">"
                    xml += "<formula1>\(escapeXML(listStr))</formula1>"
                    xml += "</dataValidation>"
                } else {
                    xml += "<dataValidation type=\"\(typeStr)\" allowBlank=\"1\" showInputMessage=\"1\" showErrorMessage=\"1\" sqref=\"\(sqref)\">"
                    if !rule.minValue.isEmpty { xml += "<formula1>\(escapeXML(rule.minValue))</formula1>" }
                    if !rule.maxValue.isEmpty { xml += "<formula2>\(escapeXML(rule.maxValue))</formula2>" }
                    xml += "</dataValidation>"
                }
            }
            xml += "</dataValidations>"
        }

        // Drawing reference
        if hasDrawing {
            xml += "<drawing r:id=\"rId1\"/>"
        }

        // Table parts
        if !tableRefs.isEmpty {
            xml += "<tableParts count=\"\(tableRefs.count)\">"
            for (i, _) in tableRefs.enumerated() {
                xml += "<tablePart r:id=\"rId\(tableRIdBase + i)\"/>"
            }
            xml += "</tableParts>"
        }

        xml += "</worksheet>"
        return xml
    }

    /// Map condition to XLSX cfRule type and operator
    private static func cfTypeAndOperator(for condition: STExcelCFCondition) -> (type: String, op: String) {
        switch condition {
        case .greaterThan: return ("cellIs", "greaterThan")
        case .lessThan: return ("cellIs", "lessThan")
        case .between: return ("cellIs", "between")
        case .equalTo: return ("cellIs", "equal")
        case .notEqualTo: return ("cellIs", "notEqual")
        case .textContains: return ("containsText", "containsText")
        case .textNotContains: return ("notContainsText", "notContains")
        case .duplicates: return ("duplicateValues", "")
        case .uniqueValues: return ("uniqueValues", "")
        }
    }

    /// Group per-cell validation rules into range-based validations for XLSX
    private static func groupDataValidations(_ rules: [String: STExcelDataValidation]) -> [(String, STExcelDataValidation)] {
        // Group identical rules and merge their cell refs into sqref
        var groups: [String: (STExcelDataValidation, [String])] = [:]
        for (key, rule) in rules {
            let parts = key.split(separator: ",")
            guard parts.count == 2, let r = Int(parts[0]), let c = Int(parts[1]) else { continue }
            let cellRef = "\(STExcelSheet.columnLetter(c))\(r + 1)"
            let groupKey = "\(rule.type)|\(rule.minValue)|\(rule.maxValue)|\(rule.listValues.joined(separator: ","))"
            if var existing = groups[groupKey] {
                existing.1.append(cellRef)
                groups[groupKey] = existing
            } else {
                groups[groupKey] = (rule, [cellRef])
            }
        }
        return groups.values.map { (rule, refs) in
            (refs.joined(separator: " "), rule)
        }
    }

    // MARK: - Chart XML

    private static func chartXML(chart: STExcelEmbeddedChart, sheetName: String) -> String {
        let safeSheetName = sheetName.contains(" ") ? "'\(sheetName)'" : sheetName

        // Map subtype to chart element
        let chartElement: String
        var barDir = ""
        var grouping = "clustered"

        switch chart.subtype.category {
        case .column:
            chartElement = "c:barChart"
            barDir = "col"
            if chart.subtype.isStacked { grouping = "stacked" }
            else if chart.subtype.isPercentStacked { grouping = "percentStacked" }
        case .bar:
            chartElement = "c:barChart"
            barDir = "bar"
            if chart.subtype.isStacked { grouping = "stacked" }
            else if chart.subtype.isPercentStacked { grouping = "percentStacked" }
        case .line, .lineWithMarkers:
            chartElement = "c:lineChart"
            grouping = "standard"
        case .area:
            chartElement = "c:areaChart"
            if chart.subtype.isStacked { grouping = "stacked" }
            else if chart.subtype.isPercentStacked { grouping = "percentStacked" }
            else { grouping = "standard" }
        case .pie:
            switch chart.subtype {
            case .pie3D: chartElement = "c:pie3DChart"
            case .doughnut: chartElement = "c:doughnutChart"
            default: chartElement = "c:pieChart"
            }
        case .scatter:
            chartElement = "c:scatterChart"
        default:
            chartElement = "c:barChart"
            barDir = "col"
        }

        let isPie = chartElement.contains("pie") || chartElement == "c:doughnutChart"
        let isScatter = chartElement == "c:scatterChart"

        // Data range
        let catCol = chart.dataStartCol
        let catStartRow = chart.dataStartRow + 1  // assume first row is headers
        let catColLetter = STExcelSheet.columnLetter(catCol)

        var xml = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <c:chartSpace xmlns:c="http://schemas.openxmlformats.org/drawingml/2006/chart" xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
        <c:chart>
        """

        // Title
        if !chart.title.isEmpty {
            xml += "<c:title><c:tx><c:rich><a:bodyPr/><a:lstStyle/><a:p><a:r><a:rPr lang=\"en-US\" sz=\"1200\"/><a:t>\(escapeXML(chart.title))</a:t></a:r></a:p></c:rich></c:tx><c:overlay val=\"0\"/></c:title>"
        }
        xml += "<c:autoTitleDeleted val=\"\(chart.title.isEmpty ? "1" : "0")\"/>"

        xml += "<c:plotArea><c:layout/>"

        // Chart type element
        xml += "<\(chartElement)>"
        if chartElement == "c:barChart" {
            xml += "<c:barDir val=\"\(barDir)\"/><c:grouping val=\"\(grouping)\"/>"
        } else if !isPie && !isScatter {
            xml += "<c:grouping val=\"\(grouping)\"/>"
        }
        if isScatter {
            let style = chart.subtype == .scatterSmooth ? "smoothMarker" : "lineMarker"
            xml += "<c:scatterStyle val=\"\(style)\"/>"
        }
        xml += "<c:varyColors val=\"\(isPie ? "1" : "0")\"/>"

        // Series
        let numSeries = max(0, chart.dataEndCol - chart.dataStartCol)
        for si in 0..<numSeries {
            let serCol = chart.dataStartCol + 1 + si
            guard serCol <= chart.dataEndCol else { break }
            let serColLetter = STExcelSheet.columnLetter(serCol)

            xml += "<c:ser><c:idx val=\"\(si)\"/><c:order val=\"\(si)\"/>"
            // Series name from header
            xml += "<c:tx><c:strRef><c:f>\(safeSheetName)!$\(serColLetter)$\(chart.dataStartRow + 1)</c:f></c:strRef></c:tx>"

            // Categories / X values
            if isScatter {
                xml += "<c:xVal><c:numRef><c:f>\(safeSheetName)!$\(catColLetter)$\(catStartRow + 1):$\(catColLetter)$\(chart.dataEndRow + 1)</c:f></c:numRef></c:xVal>"
                xml += "<c:yVal><c:numRef><c:f>\(safeSheetName)!$\(serColLetter)$\(catStartRow + 1):$\(serColLetter)$\(chart.dataEndRow + 1)</c:f></c:numRef></c:yVal>"
            } else {
                xml += "<c:cat><c:strRef><c:f>\(safeSheetName)!$\(catColLetter)$\(catStartRow + 1):$\(catColLetter)$\(chart.dataEndRow + 1)</c:f></c:strRef></c:cat>"
                xml += "<c:val><c:numRef><c:f>\(safeSheetName)!$\(serColLetter)$\(catStartRow + 1):$\(serColLetter)$\(chart.dataEndRow + 1)</c:f></c:numRef></c:val>"
            }

            // Smooth line
            if chart.subtype == .lineSmooth || chart.subtype == .lineMarkersSmooth || chart.subtype == .scatterSmooth {
                xml += "<c:smooth val=\"1\"/>"
            }

            xml += "</c:ser>"
        }

        if chartElement == "c:doughnutChart" { xml += "<c:holeSize val=\"50\"/>" }
        xml += "</\(chartElement)>"

        // Axes
        if !isPie {
            if isScatter {
                xml += "<c:valAx><c:axId val=\"1\"/><c:scaling><c:orientation val=\"minMax\"/></c:scaling><c:delete val=\"\(chart.showAxisLabels ? "0" : "1")\"/><c:axPos val=\"b\"/><c:crossAx val=\"2\"/></c:valAx>"
                xml += "<c:valAx><c:axId val=\"2\"/><c:scaling><c:orientation val=\"minMax\"/></c:scaling><c:delete val=\"\(chart.showAxisLabels ? "0" : "1")\"/><c:axPos val=\"l\"/><c:crossAx val=\"1\"/></c:valAx>"
            } else {
                xml += "<c:catAx><c:axId val=\"1\"/><c:scaling><c:orientation val=\"minMax\"/></c:scaling><c:delete val=\"\(chart.showAxisLabels ? "0" : "1")\"/><c:axPos val=\"b\"/><c:crossAx val=\"2\"/></c:catAx>"
                xml += "<c:valAx><c:axId val=\"2\"/><c:scaling><c:orientation val=\"minMax\"/></c:scaling><c:delete val=\"\(chart.showAxisLabels ? "0" : "1")\"/><c:axPos val=\"l\"/><c:crossAx val=\"1\"/></c:valAx>"
            }
        }

        xml += "</c:plotArea>"

        if chart.showLegend {
            xml += "<c:legend><c:legendPos val=\"b\"/></c:legend>"
        }

        xml += "<c:plotVisOnly val=\"1\"/>"
        xml += "</c:chart></c:chartSpace>"
        return xml
    }

    // MARK: - Table XML

    private static func tableXML(table: STExcelTable, sheet: STExcelSheet, tableIndex: Int) -> String {
        let ref = table.rangeString
        let colCount = table.endCol - table.startCol + 1

        let styleName = tableStyleName(table.style)

        var xml = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <table xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" id="\(tableIndex)" name="\(escapeXML(table.name))" displayName="\(escapeXML(table.name))" ref="\(ref)" totalsRowShown="0">
        """

        if table.hasHeaders {
            xml += "<autoFilter ref=\"\(ref)\"/>"
        }

        xml += "<tableColumns count=\"\(colCount)\">"
        for c in 0..<colCount {
            let colIdx = table.startCol + c
            // Use header cell value as column name, or default
            let colName: String
            if table.hasHeaders && table.startRow < sheet.rowCount && colIdx < sheet.columnCount {
                let val = sheet.cells[table.startRow][colIdx].value
                colName = val.isEmpty ? "Column\(c + 1)" : val
            } else {
                colName = "Column\(c + 1)"
            }
            xml += "<tableColumn id=\"\(c + 1)\" name=\"\(escapeXML(colName))\"/>"
        }
        xml += "</tableColumns>"

        xml += "<tableStyleInfo name=\"\(styleName)\" showFirstColumn=\"0\" showLastColumn=\"0\" showRowStripes=\"\(table.showBandedRows ? "1" : "0")\" showColumnStripes=\"\(table.showBandedColumns ? "1" : "0")\"/>"
        xml += "</table>"
        return xml
    }

    private static func tableStyleName(_ style: STExcelTableStyle) -> String {
        switch style {
        case .blue: return "TableStyleMedium2"
        case .green: return "TableStyleMedium7"
        case .orange: return "TableStyleMedium3"
        case .purple: return "TableStyleMedium8"
        case .red: return "TableStyleMedium4"
        case .gray: return "TableStyleMedium1"
        case .dark: return "TableStyleDark1"
        }
    }

    // MARK: - Drawing XML (images + shapes + charts)

    private static func drawingXML(sheet: STExcelSheet, imageRefs: [ImageRef],
                                   chartRefs: [ChartRef] = []) -> String {
        var xml = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <xdr:wsDr xmlns:xdr="http://schemas.openxmlformats.org/drawingml/2006/spreadsheetDrawing" xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:c="http://schemas.openxmlformats.org/drawingml/2006/chart">
        """

        // Must match grid rendering defaults (STExcelConfiguration)
        // so computeAnchor converts grid coordinates back to cell anchors correctly
        let defaultColWidth: CGFloat = 100
        let defaultRowHeight: CGFloat = 40
        var nextId = 2

        // Images
        for (i, ref) in imageRefs.enumerated() {
            let img = sheet.images[ref.localIndex]
            let anchor = computeAnchor(x: img.x, y: img.y,
                                       columnWidths: sheet.columnWidths,
                                       rowHeights: sheet.rowHeights,
                                       defaultColWidth: defaultColWidth,
                                       defaultRowHeight: defaultRowHeight)
            let cx = Int(img.width * 9525)
            let cy = Int(img.height * 9525)

            xml += "<xdr:oneCellAnchor>"
            xml += "<xdr:from><xdr:col>\(anchor.col)</xdr:col><xdr:colOff>\(anchor.colOff)</xdr:colOff><xdr:row>\(anchor.row)</xdr:row><xdr:rowOff>\(anchor.rowOff)</xdr:rowOff></xdr:from>"
            xml += "<xdr:ext cx=\"\(cx)\" cy=\"\(cy)\"/>"
            xml += "<xdr:pic>"
            xml += "<xdr:nvPicPr><xdr:cNvPr id=\"\(nextId)\" name=\"Picture \(i + 1)\"/><xdr:cNvPicPr><a:picLocks noChangeAspect=\"1\"/></xdr:cNvPicPr></xdr:nvPicPr>"
            xml += "<xdr:blipFill><a:blip r:embed=\"rId\(i + 1)\"/><a:stretch><a:fillRect/></a:stretch></xdr:blipFill>"
            xml += "<xdr:spPr><a:xfrm><a:off x=\"0\" y=\"0\"/><a:ext cx=\"\(cx)\" cy=\"\(cy)\"/></a:xfrm><a:prstGeom prst=\"rect\"><a:avLst/></a:prstGeom></xdr:spPr>"
            xml += "</xdr:pic>"
            xml += "<xdr:clientData/>"
            xml += "</xdr:oneCellAnchor>"
            nextId += 1
        }

        // Shapes
        for (i, shape) in sheet.shapes.enumerated() {
            let anchor = computeAnchor(x: shape.x, y: shape.y,
                                       columnWidths: sheet.columnWidths,
                                       rowHeights: sheet.rowHeights,
                                       defaultColWidth: defaultColWidth,
                                       defaultRowHeight: defaultRowHeight)
            let cx = Int(shape.width * 9525)
            let cy = Int(shape.height * 9525)
            let fillHex = shape.fillColorHex
            let strokeHex = shape.strokeColorHex
            let lineWidth = Int(shape.strokeWidth * 12700)
            let presetGeom = shape.xlsxPresetGeometry

            xml += "<xdr:oneCellAnchor>"
            xml += "<xdr:from><xdr:col>\(anchor.col)</xdr:col><xdr:colOff>\(anchor.colOff)</xdr:colOff><xdr:row>\(anchor.row)</xdr:row><xdr:rowOff>\(anchor.rowOff)</xdr:rowOff></xdr:from>"
            xml += "<xdr:ext cx=\"\(cx)\" cy=\"\(cy)\"/>"
            xml += "<xdr:sp>"
            xml += "<xdr:nvSpPr><xdr:cNvPr id=\"\(nextId)\" name=\"Shape \(i + 1)\"/><xdr:cNvSpPr/></xdr:nvSpPr>"
            xml += "<xdr:spPr>"
            xml += "<a:xfrm"
            if shape.rotation != 0 { xml += " rot=\"\(Int(shape.rotation * 60000))\"" }
            xml += "><a:off x=\"0\" y=\"0\"/><a:ext cx=\"\(cx)\" cy=\"\(cy)\"/></a:xfrm>"
            xml += "<a:prstGeom prst=\"\(presetGeom)\"><a:avLst/></a:prstGeom>"
            xml += "<a:solidFill><a:srgbClr val=\"\(fillHex)\"/></a:solidFill>"
            xml += "<a:ln w=\"\(lineWidth)\"><a:solidFill><a:srgbClr val=\"\(strokeHex)\"/></a:solidFill>"
            if shape.shapeType == .dashedLine { xml += "<a:prstDash val=\"dash\"/>" }
            xml += "</a:ln>"
            xml += "</xdr:spPr>"
            if !shape.text.isEmpty {
                xml += "<xdr:txBody><a:bodyPr vertOverflow=\"clip\" horzOverflow=\"clip\" wrap=\"square\" rtlCol=\"0\" anchor=\"ctr\"/><a:lstStyle/><a:p><a:pPr algn=\"ctr\"/><a:r><a:rPr lang=\"en-US\" sz=\"1100\"/><a:t>\(escapeXML(shape.text))</a:t></a:r></a:p></xdr:txBody>"
            }
            xml += "</xdr:sp>"
            xml += "<xdr:clientData/>"
            xml += "</xdr:oneCellAnchor>"
            nextId += 1
        }

        // Charts (as graphicFrame)
        let chartRIdBase = imageRefs.count + 1
        for (i, ref) in chartRefs.enumerated() {
            let chart = sheet.charts[ref.localIndex]
            let anchor = computeAnchor(x: chart.x, y: chart.y,
                                       columnWidths: sheet.columnWidths,
                                       rowHeights: sheet.rowHeights,
                                       defaultColWidth: defaultColWidth,
                                       defaultRowHeight: defaultRowHeight)
            let cx = Int(chart.width * 9525)
            let cy = Int(chart.height * 9525)
            let rId = chartRIdBase + i

            xml += "<xdr:oneCellAnchor>"
            xml += "<xdr:from><xdr:col>\(anchor.col)</xdr:col><xdr:colOff>\(anchor.colOff)</xdr:colOff><xdr:row>\(anchor.row)</xdr:row><xdr:rowOff>\(anchor.rowOff)</xdr:rowOff></xdr:from>"
            xml += "<xdr:ext cx=\"\(cx)\" cy=\"\(cy)\"/>"
            xml += "<xdr:graphicFrame macro=\"\">"
            xml += "<xdr:nvGraphicFramePr><xdr:cNvPr id=\"\(nextId)\" name=\"Chart \(i + 1)\"/><xdr:cNvGraphicFramePr/></xdr:nvGraphicFramePr>"
            xml += "<xdr:xfrm><a:off x=\"0\" y=\"0\"/><a:ext cx=\"\(cx)\" cy=\"\(cy)\"/></xdr:xfrm>"
            xml += "<a:graphic><a:graphicData uri=\"http://schemas.openxmlformats.org/drawingml/2006/chart\">"
            xml += "<c:chart r:id=\"rId\(rId)\"/>"
            xml += "</a:graphicData></a:graphic>"
            xml += "</xdr:graphicFrame>"
            xml += "<xdr:clientData/>"
            xml += "</xdr:oneCellAnchor>"
            nextId += 1
        }

        xml += "</xdr:wsDr>"
        return xml
    }

    /// Convert absolute pixel position to cell anchor + offset in EMU
    private static func computeAnchor(x: CGFloat, y: CGFloat,
                                      columnWidths: [Int: CGFloat],
                                      rowHeights: [Int: CGFloat],
                                      defaultColWidth: CGFloat,
                                      defaultRowHeight: CGFloat)
        -> (col: Int, colOff: Int, row: Int, rowOff: Int) {
        var remaining = x
        var col = 0
        while remaining > 0 && col < 16384 {
            let cw = columnWidths[col] ?? defaultColWidth
            if remaining < cw { break }
            remaining -= cw
            col += 1
        }
        let colOff = Int(max(0, remaining) * 9525)

        remaining = y
        var row = 0
        while remaining > 0 && row < 1048576 {
            // Clamp row height like grid does — small Excel heights are rendered as defaultRowHeight
            let rawRh = rowHeights[row] ?? defaultRowHeight
            let rh = rawRh < defaultRowHeight ? defaultRowHeight : rawRh
            if remaining < rh { break }
            remaining -= rh
            row += 1
        }
        let rowOff = Int(max(0, remaining) * 9525)

        return (col, colOff, row, rowOff)
    }

    private static func escapeXML(_ str: String) -> String {
        str.replacingOccurrences(of: "&", with: "&amp;")
           .replacingOccurrences(of: "<", with: "&lt;")
           .replacingOccurrences(of: ">", with: "&gt;")
           .replacingOccurrences(of: "\"", with: "&quot;")
    }
}

// MARK: - Style Collector

private class StyleCollector {
    private var fonts: [FontKey] = [FontKey()]
    private var fontIndex: [FontKey: Int] = [FontKey(): 0]

    private var fills: [FillKey] = [FillKey(color: nil), FillKey(color: "gray125")]
    private var fillIndex: [FillKey: Int] = [FillKey(color: nil): 0, FillKey(color: "gray125"): 1]

    private var borders: [BorderKey] = [BorderKey()]
    private var borderIndex: [BorderKey: Int] = [BorderKey(): 0]

    private var xfs: [XfKey] = [XfKey()]
    private var xfIndex: [XfKey: Int] = [XfKey(): 0]

    private var numFmts: [Int: String] = [:]

    // DXF entries for conditional formatting
    private struct DxfEntry {
        var bgColor: String?
        var textColor: String?
        var borderColor: String?
    }
    private var dxfs: [DxfEntry] = []

    func indexFor(style: STExcelCellStyle) -> Int {
        let fk = FontKey(style: style)
        let fontId = fontIndex[fk] ?? {
            let id = fonts.count
            fonts.append(fk)
            fontIndex[fk] = id
            return id
        }()

        let flk = FillKey(color: style.fillColor)
        let fillId = fillIndex[flk] ?? {
            let id = fills.count
            fills.append(flk)
            fillIndex[flk] = id
            return id
        }()

        let bk = BorderKey(borders: style.borders)
        let borderId = borderIndex[bk] ?? {
            let id = borders.count
            borders.append(bk)
            borderIndex[bk] = id
            return id
        }()

        if style.numberFormatId >= 164, let code = style.numberFormatCode {
            numFmts[style.numberFormatId] = code
        }

        let xf = XfKey(fontId: fontId, fillId: fillId, borderId: borderId,
                        numFmtId: style.numberFormatId,
                        hAlign: style.horizontalAlignment, vAlign: style.verticalAlignment,
                        wrapText: style.wrapText)

        return xfIndex[xf] ?? {
            let id = xfs.count
            xfs.append(xf)
            xfIndex[xf] = id
            return id
        }()
    }

    func addDxf(bgColor: String?, textColor: String?, borderColor: String?) -> Int {
        let id = dxfs.count
        dxfs.append(DxfEntry(bgColor: bgColor, textColor: textColor, borderColor: borderColor))
        return id
    }

    func generateStylesXML() -> String {
        var xml = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
        """

        if !numFmts.isEmpty {
            xml += "<numFmts count=\"\(numFmts.count)\">"
            for (id, code) in numFmts.sorted(by: { $0.key < $1.key }) {
                xml += "<numFmt numFmtId=\"\(id)\" formatCode=\"\(escapeXML(code))\"/>"
            }
            xml += "</numFmts>"
        }

        xml += "<fonts count=\"\(fonts.count)\">"
        for f in fonts {
            xml += "<font>"
            if f.isBold { xml += "<b/>" }
            if f.isItalic { xml += "<i/>" }
            if f.isUnderline { xml += "<u/>" }
            if f.isStrikethrough { xml += "<strike/>" }
            xml += "<sz val=\"\(f.size)\"/>"
            if let color = f.color {
                let hex = color.hasPrefix("#") ? String(color.dropFirst()) : color
                xml += "<color rgb=\"FF\(hex)\"/>"
            }
            xml += "<name val=\"\(escapeXML(f.name))\"/>"
            xml += "</font>"
        }
        xml += "</fonts>"

        xml += "<fills count=\"\(fills.count)\">"
        for f in fills {
            if f.color == nil {
                xml += "<fill><patternFill patternType=\"none\"/></fill>"
            } else if f.color == "gray125" {
                xml += "<fill><patternFill patternType=\"gray125\"/></fill>"
            } else {
                let hex = f.color!.hasPrefix("#") ? String(f.color!.dropFirst()) : f.color!
                xml += "<fill><patternFill patternType=\"solid\"><fgColor rgb=\"FF\(hex)\"/></patternFill></fill>"
            }
        }
        xml += "</fills>"

        xml += "<borders count=\"\(borders.count)\">"
        for b in borders {
            xml += "<border>"
            xml += borderEdgeXML("left", b.left)
            xml += borderEdgeXML("right", b.right)
            xml += borderEdgeXML("top", b.top)
            xml += borderEdgeXML("bottom", b.bottom)
            xml += "<diagonal/>"
            xml += "</border>"
        }
        xml += "</borders>"

        xml += "<cellXfs count=\"\(xfs.count)\">"
        for xf in xfs {
            let hasAlignment = xf.hAlign != .general || xf.vAlign != .bottom || xf.wrapText
            var attrs = "numFmtId=\"\(xf.numFmtId)\" fontId=\"\(xf.fontId)\" fillId=\"\(xf.fillId)\" borderId=\"\(xf.borderId)\""
            if xf.fontId > 0 { attrs += " applyFont=\"1\"" }
            if xf.fillId > 0 { attrs += " applyFill=\"1\"" }
            if xf.borderId > 0 { attrs += " applyBorder=\"1\"" }
            if hasAlignment { attrs += " applyAlignment=\"1\"" }

            if hasAlignment {
                var alAttrs = ""
                if xf.hAlign != .general { alAttrs += " horizontal=\"\(xf.hAlign.rawValue)\"" }
                if xf.vAlign != .bottom { alAttrs += " vertical=\"\(xf.vAlign.rawValue)\"" }
                if xf.wrapText { alAttrs += " wrapText=\"1\"" }
                xml += "<xf \(attrs)><alignment\(alAttrs)/></xf>"
            } else {
                xml += "<xf \(attrs)/>"
            }
        }
        xml += "</cellXfs>"

        // DXF entries for conditional formatting
        if !dxfs.isEmpty {
            xml += "<dxfs count=\"\(dxfs.count)\">"
            for dxf in dxfs {
                xml += "<dxf>"
                if let tc = dxf.textColor {
                    let hex = tc.hasPrefix("#") ? String(tc.dropFirst()) : tc
                    xml += "<font><color rgb=\"FF\(hex)\"/></font>"
                }
                if let bg = dxf.bgColor {
                    let hex = bg.hasPrefix("#") ? String(bg.dropFirst()) : bg
                    xml += "<fill><patternFill><bgColor rgb=\"FF\(hex)\"/></patternFill></fill>"
                }
                if let bc = dxf.borderColor {
                    let hex = bc.hasPrefix("#") ? String(bc.dropFirst()) : bc
                    xml += "<border><left style=\"thin\"><color rgb=\"FF\(hex)\"/></left><right style=\"thin\"><color rgb=\"FF\(hex)\"/></right><top style=\"thin\"><color rgb=\"FF\(hex)\"/></top><bottom style=\"thin\"><color rgb=\"FF\(hex)\"/></bottom></border>"
                }
                xml += "</dxf>"
            }
            xml += "</dxfs>"
        }

        xml += "</styleSheet>"
        return xml
    }

    private func borderEdgeXML(_ edge: String, _ style: STBorderStyle) -> String {
        if style == .none { return "<\(edge)/>" }
        let xlStyle: String
        switch style {
        case .thin: xlStyle = "thin"
        case .medium: xlStyle = "medium"
        case .thick: xlStyle = "thick"
        case .dashed: xlStyle = "dashed"
        case .dotted: xlStyle = "dotted"
        case .double_: xlStyle = "double"
        case .none: xlStyle = ""
        }
        return "<\(edge) style=\"\(xlStyle)\"><color auto=\"1\"/></\(edge)>"
    }

    private func escapeXML(_ str: String) -> String {
        str.replacingOccurrences(of: "&", with: "&amp;")
           .replacingOccurrences(of: "<", with: "&lt;")
           .replacingOccurrences(of: ">", with: "&gt;")
           .replacingOccurrences(of: "\"", with: "&quot;")
    }
}

// MARK: - Style Keys

private struct FontKey: Hashable {
    var name: String = "Calibri"
    var size: Double = 11
    var isBold = false
    var isItalic = false
    var isUnderline = false
    var isStrikethrough = false
    var color: String? = nil

    init() {}
    init(style: STExcelCellStyle) {
        self.name = style.fontName
        self.size = style.fontSize
        self.isBold = style.isBold
        self.isItalic = style.isItalic
        self.isUnderline = style.isUnderline
        self.isStrikethrough = style.isStrikethrough
        self.color = style.textColor
    }
}

private struct FillKey: Hashable {
    var color: String?
}

private struct BorderKey: Hashable {
    var left: STBorderStyle = .none
    var right: STBorderStyle = .none
    var top: STBorderStyle = .none
    var bottom: STBorderStyle = .none

    init() {}
    init(borders: STCellBorders) {
        self.left = borders.left
        self.right = borders.right
        self.top = borders.top
        self.bottom = borders.bottom
    }
}

private struct XfKey: Hashable {
    var fontId: Int = 0
    var fillId: Int = 0
    var borderId: Int = 0
    var numFmtId: Int = 0
    var hAlign: STHorizontalAlignment = .general
    var vAlign: STVerticalAlignment = .bottom
    var wrapText: Bool = false
}
