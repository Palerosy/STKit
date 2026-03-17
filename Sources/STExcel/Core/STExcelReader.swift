import Foundation
import SwiftUI
import ZIPFoundation

/// Reads .xlsx files using ZIPFoundation + XML parsing
enum STExcelReader {

    /// Read an xlsx file and return sheets
    static func read(url: URL) -> [STExcelSheet]? {
        guard let archive = Archive(url: url, accessMode: .read) else { return nil }

        // 1. Read shared strings
        let sharedStrings = readSharedStrings(from: archive)

        // 2. Read styles
        let styles = readStyles(from: archive)

        // 3. Read workbook to get sheet names + rIds
        let sheetEntries = readSheetEntries(from: archive)

        // 4. Read workbook rels to map rId → file path
        let rels = readWorkbookRels(from: archive)

        // 5. Read each worksheet using correct file paths
        var sheets: [STExcelSheet] = []
        for (sheetIndex, entry) in sheetEntries.enumerated() {
            let sheetPath: String
            if let target = rels[entry.rId] {
                sheetPath = target.hasPrefix("xl/") ? target : "xl/\(target)"
            } else {
                sheetPath = "xl/worksheets/sheet\(sheets.count + 1).xml"
            }
            if let ws = readWorksheet(
                path: sheetPath, from: archive,
                sharedStrings: sharedStrings, styles: styles
            ) {
                let sheet = STExcelSheet(name: entry.name, cells: ws.cells)
                sheet.mergedRegions = ws.mergedRegions
                sheet.columnWidths = ws.columnWidths
                sheet.rowHeights = ws.rowHeights
                sheet.frozenRows = ws.frozenRows
                sheet.frozenCols = ws.frozenCols

                // 6. Read embedded images for this sheet
                sheet.images = readImages(sheetIndex: sheetIndex + 1, from: archive,
                                          columnWidths: ws.columnWidths, rowHeights: ws.rowHeights)

                // 7. Read shapes
                sheet.shapes = readShapes(sheetIndex: sheetIndex + 1, from: archive,
                                          columnWidths: ws.columnWidths, rowHeights: ws.rowHeights)

                // 8. Read comments
                readComments(sheetIndex: sheetIndex + 1, from: archive, into: sheet)

                sheets.append(sheet)
            }
        }

        return sheets.isEmpty ? nil : sheets
    }

    // MARK: - Image Reading

    /// Read embedded images for a given sheet
    private static func readImages(sheetIndex: Int, from archive: Archive,
                                   columnWidths: [Int: CGFloat],
                                   rowHeights: [Int: CGFloat]) -> [STExcelEmbeddedImage] {
        // 1. Read sheet rels to find drawing reference
        let sheetRelsPath = "xl/worksheets/_rels/sheet\(sheetIndex).xml.rels"
        guard let relsData = extractData(path: sheetRelsPath, from: archive) else { return [] }

        let relsParser = SheetRelsParser()
        let relsXml = XMLParser(data: relsData)
        relsXml.delegate = relsParser
        relsXml.parse()

        guard let drawingTarget = relsParser.drawingTarget else { return [] }
        let drawingPath = drawingTarget.hasPrefix("xl/") ? drawingTarget :
                          drawingTarget.hasPrefix("../") ? "xl/" + drawingTarget.dropFirst(3) :
                          "xl/\(drawingTarget)"

        // 2. Read drawing rels to map rId → image file path
        let drawingRelsPath = drawingPath.replacingOccurrences(of: "drawings/", with: "drawings/_rels/") + ".rels"
        let imageRelMap: [String: String]
        if let drawRelsData = extractData(path: drawingRelsPath, from: archive) {
            let drawRelsParser = DrawingRelsParser()
            let drawRelsXml = XMLParser(data: drawRelsData)
            drawRelsXml.delegate = drawRelsParser
            drawRelsXml.parse()
            imageRelMap = drawRelsParser.imageTargets
        } else {
            imageRelMap = [:]
        }

        // 3. Read drawing XML to get image positions
        guard let drawingData = extractData(path: drawingPath, from: archive) else { return [] }
        let drawingParser = DrawingParser()
        let drawingXml = XMLParser(data: drawingData)
        drawingXml.delegate = drawingParser
        drawingXml.parse()

        // 4. Build images
        let defaultColWidth: CGFloat = 64
        let defaultRowHeight: CGFloat = 20
        var images: [STExcelEmbeddedImage] = []

        for entry in drawingParser.imageEntries {
            // Resolve image file path
            guard let relTarget = imageRelMap[entry.embedId] else { continue }
            let mediaPath = relTarget.hasPrefix("xl/") ? relTarget :
                            relTarget.hasPrefix("../") ? "xl/" + relTarget.dropFirst(3) :
                            "xl/\(relTarget)"

            guard let imageData = extractData(path: mediaPath, from: archive),
                  !imageData.isEmpty else { continue }

            // Convert cell anchor to absolute pixel position
            var x: CGFloat = 0
            for c in 0..<entry.fromCol {
                x += columnWidths[c] ?? defaultColWidth
            }
            x += CGFloat(entry.fromColOff) / 9525.0

            var y: CGFloat = 0
            for r in 0..<entry.fromRow {
                y += rowHeights[r] ?? defaultRowHeight
            }
            y += CGFloat(entry.fromRowOff) / 9525.0

            let width = CGFloat(entry.extCx) / 9525.0
            let height = CGFloat(entry.extCy) / 9525.0
            let aspect = height > 0 ? width / height : 1.0

            images.append(STExcelEmbeddedImage(
                imageData: imageData, x: x, y: y,
                width: width, height: height, aspectRatio: aspect
            ))
        }

        return images
    }

    // MARK: - Comment Reading

    /// Read comments from xl/commentsN.xml and apply to sheet cells
    private static func readComments(sheetIndex: Int, from archive: Archive, into sheet: STExcelSheet) {
        let path = "xl/comments\(sheetIndex).xml"
        guard let data = extractData(path: path, from: archive) else { return }

        let parser = CommentsParser()
        let xmlParser = XMLParser(data: data)
        xmlParser.delegate = parser
        xmlParser.parse()

        for entry in parser.comments {
            guard let ref = CellReference(string: entry.ref) else { continue }
            guard ref.row < sheet.rowCount, ref.col < sheet.columnCount else { continue }
            sheet.cells[ref.row][ref.col].comment = entry.text
        }
    }

    // MARK: - Shape Reading (from drawing XML)

    /// Read shapes from drawing XML for a given sheet
    private static func readShapes(sheetIndex: Int, from archive: Archive,
                                   columnWidths: [Int: CGFloat],
                                   rowHeights: [Int: CGFloat]) -> [STExcelEmbeddedShape] {
        // 1. Read sheet rels to find drawing reference
        let sheetRelsPath = "xl/worksheets/_rels/sheet\(sheetIndex).xml.rels"
        guard let relsData = extractData(path: sheetRelsPath, from: archive) else { return [] }

        let relsParser = SheetRelsParser()
        let relsXml = XMLParser(data: relsData)
        relsXml.delegate = relsParser
        relsXml.parse()

        guard let drawingTarget = relsParser.drawingTarget else { return [] }
        let drawingPath = drawingTarget.hasPrefix("xl/") ? drawingTarget :
                          drawingTarget.hasPrefix("../") ? "xl/" + drawingTarget.dropFirst(3) :
                          "xl/\(drawingTarget)"

        // 2. Read drawing XML
        guard let drawingData = extractData(path: drawingPath, from: archive) else { return [] }
        let drawingParser = DrawingParser()
        let drawingXml = XMLParser(data: drawingData)
        drawingXml.delegate = drawingParser
        drawingXml.parse()

        // 3. Build shapes from parsed entries
        let defaultColWidth: CGFloat = 64
        let defaultRowHeight: CGFloat = 20
        var shapes: [STExcelEmbeddedShape] = []

        for entry in drawingParser.shapeEntries {
            // Convert anchor to pixel position
            var x: CGFloat = 0
            for c in 0..<entry.fromCol {
                x += columnWidths[c] ?? defaultColWidth
            }
            x += CGFloat(entry.fromColOff) / 9525.0

            var y: CGFloat = 0
            for r in 0..<entry.fromRow {
                y += rowHeights[r] ?? defaultRowHeight
            }
            y += CGFloat(entry.fromRowOff) / 9525.0

            let width = CGFloat(entry.extCx) / 9525.0
            let height = CGFloat(entry.extCy) / 9525.0

            let shapeType = shapeTypeFromPreset(entry.presetGeometry)
            let fillColor = colorFromHex(entry.fillColorHex)
            let strokeColor = colorFromHex(entry.strokeColorHex)
            let strokeWidth = CGFloat(entry.lineWidth) / 12700.0
            let rotation = Double(entry.rotation) / 60000.0

            shapes.append(STExcelEmbeddedShape(
                shapeType: shapeType,
                x: x, y: y, width: width, height: height,
                fillColor: fillColor,
                strokeColor: strokeColor,
                strokeWidth: max(strokeWidth, 1),
                text: entry.text,
                rotation: rotation
            ))
        }

        return shapes
    }

    /// Map XLSX preset geometry name to our shape type
    private static func shapeTypeFromPreset(_ preset: String) -> STExcelShapeType {
        switch preset {
        case "rect": return .rectangle
        case "roundRect": return .roundedRectangle
        case "ellipse": return .circle
        case "triangle": return .triangle
        case "rtTriangle": return .rightTriangle
        case "diamond": return .diamond
        case "rightArrow": return .arrowRight
        case "leftArrow": return .arrowLeft
        case "upArrow": return .arrowUp
        case "downArrow": return .arrowDown
        case "star5": return .star
        case "hexagon": return .hexagon
        case "pentagon": return .pentagon
        case "line": return .line
        default: return .rectangle
        }
    }

    /// Convert hex string to SwiftUI Color
    private static func colorFromHex(_ hex: String) -> Color {
        guard !hex.isEmpty else { return .blue }
        let clean = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        guard clean.count == 6, let val = UInt64(clean, radix: 16) else { return .blue }
        let r = Double((val >> 16) & 0xFF) / 255.0
        let g = Double((val >> 8) & 0xFF) / 255.0
        let b = Double(val & 0xFF) / 255.0
        return Color(red: r, green: g, blue: b)
    }

    // MARK: - Sheet Entries (name + rId)

    fileprivate struct SheetEntry {
        let name: String
        let rId: String
    }

    private static func readSheetEntries(from archive: Archive) -> [SheetEntry] {
        guard let data = extractData(path: "xl/workbook.xml", from: archive) else {
            return [SheetEntry(name: "Sheet 1", rId: "rId1")]
        }
        let parser = WorkbookParser()
        let xmlParser = XMLParser(data: data)
        xmlParser.delegate = parser
        xmlParser.parse()
        return parser.sheetEntries.isEmpty
            ? [SheetEntry(name: "Sheet 1", rId: "rId1")]
            : parser.sheetEntries
    }

    // MARK: - Workbook Rels

    private static func readWorkbookRels(from archive: Archive) -> [String: String] {
        guard let data = extractData(path: "xl/_rels/workbook.xml.rels", from: archive) else { return [:] }
        let parser = RelsParser()
        let xmlParser = XMLParser(data: data)
        xmlParser.delegate = parser
        xmlParser.parse()
        return parser.relationships
    }

    // MARK: - Shared Strings

    private static func readSharedStrings(from archive: Archive) -> [String] {
        guard let data = extractData(path: "xl/sharedStrings.xml", from: archive) else { return [] }
        let parser = SharedStringsParser()
        let xmlParser = XMLParser(data: data)
        xmlParser.delegate = parser
        xmlParser.parse()
        return parser.strings
    }

    // MARK: - Theme Colors

    private static func readThemeColors(from archive: Archive) -> [Int: String] {
        guard let data = extractData(path: "xl/theme/theme1.xml", from: archive) else { return [:] }
        let parser = ThemeParser()
        let xmlParser = XMLParser(data: data)
        xmlParser.delegate = parser
        xmlParser.parse()
        return parser.themeColors
    }

    // MARK: - Styles

    private static func readStyles(from archive: Archive) -> ParsedStyles {
        let themeColors = readThemeColors(from: archive)
        guard let data = extractData(path: "xl/styles.xml", from: archive) else { return ParsedStyles() }
        let parser = StylesParser(themeColors: themeColors)
        let xmlParser = XMLParser(data: data)
        xmlParser.delegate = parser
        xmlParser.parse()
        return parser.result
    }

    // MARK: - Sheet Names (legacy, unused — see readSheetEntries)

    // MARK: - Worksheet

    fileprivate struct WorksheetResult {
        let cells: [[STExcelCell]]
        let mergedRegions: [STMergedRegion]
        let columnWidths: [Int: CGFloat]
        let rowHeights: [Int: CGFloat]
        let frozenRows: Int
        let frozenCols: Int
    }

    private static func readWorksheet(path: String, from archive: Archive,
                                      sharedStrings: [String],
                                      styles: ParsedStyles) -> WorksheetResult? {
        guard let data = extractData(path: path, from: archive) else { return nil }
        let parser = WorksheetParser(sharedStrings: sharedStrings, styles: styles)
        let xmlParser = XMLParser(data: data)
        xmlParser.delegate = parser
        xmlParser.parse()

        let maxRow = parser.cells.keys.map(\.row).max() ?? 0
        let maxCol = parser.cells.keys.map(\.col).max() ?? 0

        let rows = max(maxRow + 1, 20)
        let cols = max(maxCol + 1, 10)

        var result: [[STExcelCell]] = (0..<rows).map { _ in
            (0..<cols).map { _ in STExcelCell() }
        }

        for (ref, cell) in parser.cells {
            if ref.row < rows && ref.col < cols {
                result[ref.row][ref.col] = cell
            }
        }

        return WorksheetResult(
            cells: result,
            mergedRegions: parser.mergedRegions,
            columnWidths: parser.columnWidths,
            rowHeights: parser.rowHeights,
            frozenRows: parser.frozenRows,
            frozenCols: parser.frozenCols
        )
    }

    // MARK: - ZIP Helper

    private static func extractData(path: String, from archive: Archive) -> Data? {
        guard let entry = archive[path] else { return nil }
        var result = Data()
        _ = try? archive.extract(entry) { data in
            result.append(data)
        }
        return result.isEmpty ? nil : result
    }
}

// MARK: - Cell Reference

struct CellReference: Hashable {
    let row: Int
    let col: Int

    /// Parse "A1", "B2", "AA100" etc.
    init?(string: String) {
        var colStr = ""
        var rowStr = ""
        for char in string {
            if char.isLetter {
                colStr.append(char)
            } else if char.isNumber {
                rowStr.append(char)
            }
        }
        guard !colStr.isEmpty, let rowNum = Int(rowStr), rowNum > 0 else { return nil }

        var col = 0
        for char in colStr.uppercased() {
            col = col * 26 + Int(char.asciiValue! - 64)
        }
        self.col = col - 1
        self.row = rowNum - 1
    }

    init(row: Int, col: Int) {
        self.row = row
        self.col = col
    }

    var string: String {
        "\(STExcelSheet.columnLetter(col))\(row + 1)"
    }
}

// MARK: - Parsed Styles

struct ParsedStyles {
    var fonts: [ParsedFont] = []
    var fills: [ParsedFill] = []
    var borders: [ParsedBorder] = []
    var cellXfs: [ParsedCellXf] = []
    var numFmts: [Int: String] = [:]

    func styleFor(xfIndex: Int) -> STExcelCellStyle {
        guard xfIndex < cellXfs.count else { return STExcelCellStyle() }
        let xf = cellXfs[xfIndex]
        var style = STExcelCellStyle()

        if xf.fontId < fonts.count {
            let font = fonts[xf.fontId]
            style.fontName = font.name
            style.fontSize = font.size
            style.isBold = font.isBold
            style.isItalic = font.isItalic
            style.isUnderline = font.isUnderline
            style.isStrikethrough = font.isStrikethrough
            style.textColor = font.color
        }

        if xf.fillId < fills.count {
            style.fillColor = fills[xf.fillId].fgColor
        }

        if xf.borderId < borders.count {
            let border = borders[xf.borderId]
            style.borders = STCellBorders(
                left: border.left, right: border.right,
                top: border.top, bottom: border.bottom,
                color: border.color
            )
        }

        style.numberFormatId = xf.numFmtId
        style.numberFormatCode = numFmts[xf.numFmtId]
        style.horizontalAlignment = xf.hAlign
        style.verticalAlignment = xf.vAlign
        style.wrapText = xf.wrapText

        return style
    }
}

struct ParsedFont {
    var name: String = "Calibri"
    var size: Double = 11
    var isBold = false
    var isItalic = false
    var isUnderline = false
    var isStrikethrough = false
    var color: String? = nil
}

struct ParsedFill {
    var fgColor: String? = nil
}

struct ParsedBorder {
    var left: STBorderStyle = .none
    var right: STBorderStyle = .none
    var top: STBorderStyle = .none
    var bottom: STBorderStyle = .none
    var color: String? = nil
}

struct ParsedCellXf {
    var fontId: Int = 0
    var fillId: Int = 0
    var borderId: Int = 0
    var numFmtId: Int = 0
    var hAlign: STHorizontalAlignment = .general
    var vAlign: STVerticalAlignment = .bottom
    var wrapText: Bool = false
}

// MARK: - XML Parsers

private class SharedStringsParser: NSObject, XMLParserDelegate {
    var strings: [String] = []
    private var currentString = ""
    private var insideSI = false
    private var insideT = false

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
                qualifiedName: String?, attributes: [String: String] = [:]) {
        if elementName == "si" {
            insideSI = true
            currentString = ""
        } else if elementName == "t" && insideSI {
            insideT = true
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if insideT { currentString += string }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?,
                qualifiedName: String?) {
        if elementName == "t" {
            insideT = false
        } else if elementName == "si" {
            strings.append(currentString)
            insideSI = false
        }
    }
}

private class WorkbookParser: NSObject, XMLParserDelegate {
    var sheetEntries: [STExcelReader.SheetEntry] = []

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
                qualifiedName: String?, attributes: [String: String] = [:]) {
        if elementName == "sheet", let name = attributes["name"] {
            let rId = attributes["r:id"] ?? "rId\(sheetEntries.count + 1)"
            sheetEntries.append(STExcelReader.SheetEntry(name: name, rId: rId))
        }
    }
}

private class RelsParser: NSObject, XMLParserDelegate {
    /// rId → target path (e.g. "rId1" → "worksheets/sheet1.xml")
    var relationships: [String: String] = [:]

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
                qualifiedName: String?, attributes: [String: String] = [:]) {
        if elementName == "Relationship",
           let id = attributes["Id"],
           let target = attributes["Target"],
           target.contains("worksheets/") {
            relationships[id] = target
        }
    }
}

private class WorksheetParser: NSObject, XMLParserDelegate {
    let sharedStrings: [String]
    let styles: ParsedStyles
    var cells: [CellReference: STExcelCell] = [:]
    var mergedRegions: [STMergedRegion] = []
    var columnWidths: [Int: CGFloat] = [:]
    var rowHeights: [Int: CGFloat] = [:]
    var frozenRows: Int = 0
    var frozenCols: Int = 0

    private var currentRef: CellReference?
    private var currentType: String?
    private var currentStyleIndex: Int = 0
    private var currentValue = ""
    private var currentFormula = ""
    private var insideV = false
    private var insideF = false

    init(sharedStrings: [String], styles: ParsedStyles) {
        self.sharedStrings = sharedStrings
        self.styles = styles
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
                qualifiedName: String?, attributes: [String: String] = [:]) {
        if elementName == "pane" {
            // <pane xSplit="2" ySplit="1" topLeftCell="C2" state="frozen"/>
            if let ySplit = attributes["ySplit"], let val = Int(ySplit) { frozenRows = val }
            if let xSplit = attributes["xSplit"], let val = Int(xSplit) { frozenCols = val }
        } else if elementName == "c" {
            currentRef = attributes["r"].flatMap { CellReference(string: $0) }
            currentType = attributes["t"]
            currentStyleIndex = Int(attributes["s"] ?? "0") ?? 0
            currentValue = ""
            currentFormula = ""
        } else if elementName == "v" {
            insideV = true
            currentValue = ""
        } else if elementName == "f" {
            insideF = true
            currentFormula = ""
        } else if elementName == "mergeCell" {
            if let ref = attributes["ref"] {
                parseMergeRef(ref)
            }
        } else if elementName == "col" {
            // <col min="1" max="3" width="15.5" customWidth="1"/>
            if let minStr = attributes["min"], let maxStr = attributes["max"],
               let minCol = Int(minStr), let maxCol = Int(maxStr),
               let widthStr = attributes["width"], let width = Double(widthStr) {
                // Excel width is in character units; approximate to points (~7 pts per char)
                let pts = CGFloat(width * 7.0)
                for col in minCol...maxCol {
                    columnWidths[col - 1] = pts  // 0-indexed
                }
            }
        } else if elementName == "row" {
            // <row r="1" ht="20" customHeight="1"/>
            if let rStr = attributes["r"], let rowNum = Int(rStr),
               let htStr = attributes["ht"], let ht = Double(htStr) {
                rowHeights[rowNum - 1] = CGFloat(ht)  // 0-indexed
            }
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if insideV { currentValue += string }
        if insideF { currentFormula += string }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?,
                qualifiedName: String?) {
        if elementName == "v" {
            insideV = false
        } else if elementName == "f" {
            insideF = false
        } else if elementName == "c", let ref = currentRef {
            let displayValue: String
            if currentType == "s", let index = Int(currentValue), index < sharedStrings.count {
                displayValue = sharedStrings[index]
            } else {
                displayValue = currentValue
            }
            let style = styles.styleFor(xfIndex: currentStyleIndex)
            let formula = currentFormula.isEmpty ? nil : "=\(currentFormula)"
            cells[ref] = STExcelCell(value: displayValue, style: style, formula: formula)
        }
    }

    private func parseMergeRef(_ ref: String) {
        let parts = ref.split(separator: ":")
        guard parts.count == 2,
              let start = CellReference(string: String(parts[0])),
              let end = CellReference(string: String(parts[1])) else { return }
        mergedRegions.append(STMergedRegion(startRow: start.row, startCol: start.col,
                                            endRow: end.row, endCol: end.col))
    }
}

// MARK: - Styles Parser

// MARK: - Theme Color Resolver

private func resolveColor(attrs: [String: String], themeColors: [Int: String]) -> String? {
    // 1. Direct RGB
    if let rgb = attrs["rgb"], rgb.count >= 6 {
        let hex = rgb.count == 8 ? String(rgb.dropFirst(2)) : rgb
        return "#\(hex)"
    }
    // 2. Theme color + optional tint
    if let themeStr = attrs["theme"], let themeIdx = Int(themeStr),
       let baseHex = themeColors[themeIdx] {
        let tint = Double(attrs["tint"] ?? "0") ?? 0
        if tint == 0 { return baseHex }
        return applyTint(hex: baseHex, tint: tint)
    }
    // 3. Indexed color (legacy)
    if let idxStr = attrs["indexed"], let idx = Int(idxStr), idx < indexedColors.count {
        return indexedColors[idx]
    }
    return nil
}

private func applyTint(hex: String, tint: Double) -> String {
    let clean = hex.trimmingCharacters(in: .init(charactersIn: "#"))
    guard clean.count == 6, let val = UInt64(clean, radix: 16) else { return hex }
    var r = Double((val >> 16) & 0xFF)
    var g = Double((val >> 8) & 0xFF)
    var b = Double(val & 0xFF)
    if tint < 0 {
        r = r * (1 + tint)
        g = g * (1 + tint)
        b = b * (1 + tint)
    } else {
        r = r * (1 - tint) + 255 * tint
        g = g * (1 - tint) + 255 * tint
        b = b * (1 - tint) + 255 * tint
    }
    let ri = max(0, min(255, Int(r.rounded())))
    let gi = max(0, min(255, Int(g.rounded())))
    let bi = max(0, min(255, Int(b.rounded())))
    return String(format: "#%02X%02X%02X", ri, gi, bi)
}

/// Standard Excel indexed color table (0–63)
private let indexedColors: [String] = [
    "#000000", "#FFFFFF", "#FF0000", "#00FF00", "#0000FF", "#FFFF00", "#FF00FF", "#00FFFF",
    "#000000", "#FFFFFF", "#FF0000", "#00FF00", "#0000FF", "#FFFF00", "#FF00FF", "#00FFFF",
    "#800000", "#008000", "#000080", "#808000", "#800080", "#008080", "#C0C0C0", "#808080",
    "#9999FF", "#993366", "#FFFFCC", "#CCFFFF", "#660066", "#FF8080", "#0066CC", "#CCCCFF",
    "#000080", "#FF00FF", "#FFFF00", "#00FFFF", "#800080", "#800000", "#008080", "#0000FF",
    "#00CCFF", "#CCFFFF", "#CCFFCC", "#FFFF99", "#99CCFF", "#FF99CC", "#CC99FF", "#FFCC99",
    "#3366FF", "#33CCCC", "#99CC00", "#FFCC00", "#FF9900", "#FF6600", "#666699", "#969696",
    "#003366", "#339966", "#003300", "#333300", "#993300", "#993366", "#333399", "#333333",
]

// MARK: - Theme XML Parser

private class ThemeParser: NSObject, XMLParserDelegate {
    var themeColors: [Int: String] = [:]
    private var colorIndex = 0
    private var insideClrScheme = false
    // Theme color order: dk1(0), lt1(1), dk2(2), lt2(3), accent1-6(4-9), hlink(10), folHlink(11)
    // But Excel maps them as: 0=lt1, 1=dk1, 2=lt2, 3=dk2, 4-9=accent1-6
    private var rawColors: [String] = []

    func parser(_ parser: XMLParser, didStartElement el: String, namespaceURI: String?,
                qualifiedName: String?, attributes attrs: [String: String] = [:]) {
        if el.hasSuffix("clrScheme") { insideClrScheme = true }
        guard insideClrScheme else { return }
        // Color elements inside theme slots
        if el == "a:srgbClr" || el == "srgbClr" {
            if let val = attrs["val"] { rawColors.append("#\(val)") }
        } else if el == "a:sysClr" || el == "sysClr" {
            if let val = attrs["lastClr"] ?? attrs["val"] { rawColors.append("#\(val)") }
        }
    }

    func parser(_ parser: XMLParser, didEndElement el: String, namespaceURI: String?,
                qualifiedName: String?) {
        if el.hasSuffix("clrScheme") {
            insideClrScheme = false
            // Raw order: dk1, lt1, dk2, lt2, accent1..6, hlink, folHlink
            // Excel theme index: 0=lt1, 1=dk1, 2=lt2, 3=dk2, 4..9=accent1..6
            if rawColors.count >= 10 {
                themeColors[0] = rawColors[1]  // lt1
                themeColors[1] = rawColors[0]  // dk1
                themeColors[2] = rawColors[3]  // lt2
                themeColors[3] = rawColors[2]  // dk2
                for i in 0..<6 {               // accent1-6
                    themeColors[4 + i] = rawColors[4 + i]
                }
                if rawColors.count > 10 { themeColors[10] = rawColors[10] } // hlink
                if rawColors.count > 11 { themeColors[11] = rawColors[11] } // folHlink
            }
        }
    }
}

// MARK: - Styles Parser

private class StylesParser: NSObject, XMLParserDelegate {
    var result = ParsedStyles()
    private let themeColors: [Int: String]

    private enum Section { case none, fonts, fills, borders, cellXfs, numFmts }
    private var section: Section = .none

    private var currentFont = ParsedFont()
    private var currentFill = ParsedFill()
    private var currentBorder = ParsedBorder()
    private var currentXf = ParsedCellXf()
    private var insideBorderEdge: String? = nil
    private var insidePatternFill = false

    init(themeColors: [Int: String] = [:]) {
        self.themeColors = themeColors
        super.init()
    }

    func parser(_ parser: XMLParser, didStartElement el: String, namespaceURI: String?,
                qualifiedName: String?, attributes attrs: [String: String] = [:]) {
        switch el {
        case "fonts": section = .fonts
        case "fills": section = .fills
        case "borders": section = .borders
        case "cellXfs": section = .cellXfs
        case "numFmts": section = .numFmts
        default: break
        }

        switch section {
        case .numFmts:
            if el == "numFmt", let id = Int(attrs["numFmtId"] ?? ""), let code = attrs["formatCode"] {
                result.numFmts[id] = code
            }

        case .fonts:
            if el == "font" { currentFont = ParsedFont() }
            else if el == "b" { currentFont.isBold = true }
            else if el == "i" { currentFont.isItalic = true }
            else if el == "u" { currentFont.isUnderline = true }
            else if el == "strike" { currentFont.isStrikethrough = true }
            else if el == "sz" { currentFont.size = Double(attrs["val"] ?? "11") ?? 11 }
            else if el == "name" { currentFont.name = attrs["val"] ?? "Calibri" }
            else if el == "color" {
                currentFont.color = resolveColor(attrs: attrs, themeColors: themeColors)
            }

        case .fills:
            if el == "fill" { currentFill = ParsedFill() }
            else if el == "patternFill" { insidePatternFill = true }
            else if el == "fgColor" && insidePatternFill {
                currentFill.fgColor = resolveColor(attrs: attrs, themeColors: themeColors)
            }

        case .borders:
            if el == "border" { currentBorder = ParsedBorder() }
            else if ["left", "right", "top", "bottom"].contains(el) {
                insideBorderEdge = el
                let style = parseBorderStyle(attrs["style"])
                switch el {
                case "left": currentBorder.left = style
                case "right": currentBorder.right = style
                case "top": currentBorder.top = style
                case "bottom": currentBorder.bottom = style
                default: break
                }
            } else if el == "color" && insideBorderEdge != nil {
                currentBorder.color = resolveColor(attrs: attrs, themeColors: themeColors)
            }

        case .cellXfs:
            if el == "xf" {
                currentXf = ParsedCellXf()
                currentXf.fontId = Int(attrs["fontId"] ?? "0") ?? 0
                currentXf.fillId = Int(attrs["fillId"] ?? "0") ?? 0
                currentXf.borderId = Int(attrs["borderId"] ?? "0") ?? 0
                currentXf.numFmtId = Int(attrs["numFmtId"] ?? "0") ?? 0
            } else if el == "alignment" {
                if let h = attrs["horizontal"] {
                    currentXf.hAlign = STHorizontalAlignment(rawValue: h) ?? .general
                }
                if let v = attrs["vertical"] {
                    currentXf.vAlign = STVerticalAlignment(rawValue: v) ?? .bottom
                }
                currentXf.wrapText = attrs["wrapText"] == "1"
            }

        case .none:
            break
        }
    }

    func parser(_ parser: XMLParser, didEndElement el: String, namespaceURI: String?,
                qualifiedName: String?) {
        switch section {
        case .fonts:
            if el == "font" { result.fonts.append(currentFont) }
            if el == "fonts" { section = .none }
        case .fills:
            if el == "patternFill" { insidePatternFill = false }
            if el == "fill" { result.fills.append(currentFill) }
            if el == "fills" { section = .none }
        case .borders:
            if ["left", "right", "top", "bottom"].contains(el) { insideBorderEdge = nil }
            if el == "border" { result.borders.append(currentBorder) }
            if el == "borders" { section = .none }
        case .cellXfs:
            if el == "xf" { result.cellXfs.append(currentXf) }
            if el == "cellXfs" { section = .none }
        case .numFmts:
            if el == "numFmts" { section = .none }
        case .none:
            break
        }
    }

    private func parseBorderStyle(_ val: String?) -> STBorderStyle {
        switch val {
        case "thin": return .thin
        case "medium": return .medium
        case "thick": return .thick
        case "dashed": return .dashed
        case "dotted": return .dotted
        case "double": return .double_
        default: return .none
        }
    }
}

// MARK: - Sheet Rels Parser (finds drawing reference)

private class SheetRelsParser: NSObject, XMLParserDelegate {
    var drawingTarget: String?

    func parser(_ parser: XMLParser, didStartElement el: String, namespaceURI: String?,
                qualifiedName: String?, attributes attrs: [String: String] = [:]) {
        if el == "Relationship",
           let type = attrs["Type"], type.contains("drawing"),
           let target = attrs["Target"] {
            drawingTarget = target
        }
    }
}

// MARK: - Drawing Rels Parser (maps rId → image path)

private class DrawingRelsParser: NSObject, XMLParserDelegate {
    /// rId → target path (e.g. "rId1" → "../media/image1.png")
    var imageTargets: [String: String] = [:]

    func parser(_ parser: XMLParser, didStartElement el: String, namespaceURI: String?,
                qualifiedName: String?, attributes attrs: [String: String] = [:]) {
        if el == "Relationship",
           let id = attrs["Id"],
           let type = attrs["Type"], type.contains("image"),
           let target = attrs["Target"] {
            imageTargets[id] = target
        }
    }
}

// MARK: - Drawing Parser (reads image positions and shapes from drawing XML)

private class DrawingParser: NSObject, XMLParserDelegate {

    struct ImageEntry {
        var fromCol: Int = 0
        var fromColOff: Int = 0
        var fromRow: Int = 0
        var fromRowOff: Int = 0
        var extCx: Int = 0
        var extCy: Int = 0
        var embedId: String = ""
    }

    struct ShapeEntry {
        var fromCol: Int = 0
        var fromColOff: Int = 0
        var fromRow: Int = 0
        var fromRowOff: Int = 0
        var extCx: Int = 0
        var extCy: Int = 0
        var presetGeometry: String = "rect"
        var fillColorHex: String = ""
        var strokeColorHex: String = ""
        var lineWidth: Int = 0
        var rotation: Int = 0
        var text: String = ""
    }

    var imageEntries: [ImageEntry] = []
    var shapeEntries: [ShapeEntry] = []

    private var currentImageEntry = ImageEntry()
    private var currentShapeEntry = ShapeEntry()
    private var insideAnchor = false
    private var insideFrom = false
    private var insidePic = false
    private var insideSp = false
    private var insideSpPr = false
    private var insideLn = false
    private var insideTxBody = false
    private var hadShape = false
    private var currentElement = ""
    private var currentText = ""

    func parser(_ parser: XMLParser, didStartElement el: String, namespaceURI: String?,
                qualifiedName: String?, attributes attrs: [String: String] = [:]) {
        let local = el.components(separatedBy: ":").last ?? el

        if local == "oneCellAnchor" || local == "twoCellAnchor" {
            insideAnchor = true
            hadShape = false
            currentImageEntry = ImageEntry()
            currentShapeEntry = ShapeEntry()
        } else if local == "from" && insideAnchor {
            insideFrom = true
        } else if local == "ext" && insideAnchor && !insidePic && !insideSp {
            let cx = Int(attrs["cx"] ?? "0") ?? 0
            let cy = Int(attrs["cy"] ?? "0") ?? 0
            currentImageEntry.extCx = cx
            currentImageEntry.extCy = cy
            currentShapeEntry.extCx = cx
            currentShapeEntry.extCy = cy
        } else if local == "pic" && insideAnchor {
            insidePic = true
        } else if local == "blip" && insidePic {
            currentImageEntry.embedId = attrs["r:embed"] ?? attrs["embed"] ?? ""
        } else if local == "sp" && insideAnchor {
            insideSp = true
            hadShape = true
        } else if local == "spPr" && insideSp {
            insideSpPr = true
        } else if local == "xfrm" && insideSpPr {
            if let rot = attrs["rot"], let r = Int(rot) { currentShapeEntry.rotation = r }
        } else if local == "prstGeom" && insideSpPr {
            currentShapeEntry.presetGeometry = attrs["prst"] ?? "rect"
        } else if local == "solidFill" && insideSpPr {
            // Will capture srgbClr next
        } else if local == "srgbClr" && insideSpPr {
            if let val = attrs["val"] {
                if insideLn {
                    currentShapeEntry.strokeColorHex = val
                } else {
                    currentShapeEntry.fillColorHex = val
                }
            }
        } else if local == "ln" && insideSpPr {
            insideLn = true
            if let w = attrs["w"], let wv = Int(w) { currentShapeEntry.lineWidth = wv }
        } else if local == "txBody" && insideSp {
            insideTxBody = true
        } else if local == "t" && insideTxBody {
            currentElement = "t"
            currentText = ""
        }

        if insideFrom {
            currentElement = local
            currentText = ""
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if insideFrom { currentText += string }
        if insideTxBody && currentElement == "t" { currentText += string }
    }

    func parser(_ parser: XMLParser, didEndElement el: String, namespaceURI: String?,
                qualifiedName: String?) {
        let local = el.components(separatedBy: ":").last ?? el

        if insideFrom {
            switch local {
            case "col":
                let val = Int(currentText) ?? 0
                currentImageEntry.fromCol = val
                currentShapeEntry.fromCol = val
            case "colOff":
                let val = Int(currentText) ?? 0
                currentImageEntry.fromColOff = val
                currentShapeEntry.fromColOff = val
            case "row":
                let val = Int(currentText) ?? 0
                currentImageEntry.fromRow = val
                currentShapeEntry.fromRow = val
            case "rowOff":
                let val = Int(currentText) ?? 0
                currentImageEntry.fromRowOff = val
                currentShapeEntry.fromRowOff = val
            default: break
            }
        }

        if local == "t" && insideTxBody {
            currentShapeEntry.text += currentText
            currentElement = ""
        }
        if local == "from" { insideFrom = false }
        if local == "pic" { insidePic = false }
        if local == "ln" { insideLn = false }
        if local == "spPr" { insideSpPr = false }
        if local == "txBody" { insideTxBody = false }
        if local == "sp" { insideSp = false }
        if local == "oneCellAnchor" || local == "twoCellAnchor" {
            if !currentImageEntry.embedId.isEmpty {
                imageEntries.append(currentImageEntry)
            }
            if hadShape {
                shapeEntries.append(currentShapeEntry)
            }
            insideAnchor = false
            hadShape = false
        }
    }
}

// MARK: - Comments Parser

private class CommentsParser: NSObject, XMLParserDelegate {
    struct CommentEntry {
        var ref: String
        var text: String
    }

    var comments: [CommentEntry] = []

    private var currentRef: String?
    private var currentText = ""
    private var insideComment = false
    private var insideT = false

    func parser(_ parser: XMLParser, didStartElement el: String, namespaceURI: String?,
                qualifiedName: String?, attributes attrs: [String: String] = [:]) {
        if el == "comment" {
            insideComment = true
            currentRef = attrs["ref"]
            currentText = ""
        } else if el == "t" && insideComment {
            insideT = true
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if insideT { currentText += string }
    }

    func parser(_ parser: XMLParser, didEndElement el: String, namespaceURI: String?,
                qualifiedName: String?) {
        if el == "t" {
            insideT = false
        } else if el == "comment" {
            if let ref = currentRef, !currentText.isEmpty {
                comments.append(CommentEntry(ref: ref, text: currentText))
            }
            insideComment = false
        }
    }
}
