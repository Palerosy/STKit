import Foundation
import ZIPFoundation

/// Writes sheets to .xlsx format with full style support
enum STExcelWriter {

    @discardableResult
    static func write(sheets: [STExcelSheet], to url: URL) -> Bool {
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

        do {
            try addEntry(archive, "[Content_Types].xml", contentTypesXML(sheetCount: sheets.count))
            try addEntry(archive, "_rels/.rels", relsXML())
            try addEntry(archive, "xl/_rels/workbook.xml.rels", workbookRelsXML(sheetCount: sheets.count))
            try addEntry(archive, "xl/workbook.xml", workbookXML(sheets: sheets))
            try addEntry(archive, "xl/styles.xml", styleCollector.generateStylesXML())
            try addEntry(archive, "xl/sharedStrings.xml", sharedStringsXML(strings: allStrings))

            for (index, sheet) in sheets.enumerated() {
                let xml = worksheetXML(sheet: sheet, stringIndex: stringIndex, styleCollector: styleCollector)
                try addEntry(archive, "xl/worksheets/sheet\(index + 1).xml", xml)
            }

            return true
        } catch {
            print("[STExcel] Write failed: \(error)")
            return false
        }
    }

    private static func addEntry(_ archive: Archive, _ path: String, _ content: String) throws {
        let data = Data(content.utf8)
        try archive.addEntry(with: path, type: .file,
                             uncompressedSize: Int64(data.count),
                             provider: { _, _ in data })
    }

    // MARK: - XML Generation

    private static func contentTypesXML(sheetCount: Int) -> String {
        var xml = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
        <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
        <Default Extension="xml" ContentType="application/xml"/>
        <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
        <Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
        <Override PartName="/xl/sharedStrings.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sharedStrings+xml"/>
        """
        for i in 1...sheetCount {
            xml += "<Override PartName=\"/xl/worksheets/sheet\(i).xml\" ContentType=\"application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml\"/>"
        }
        xml += "</Types>"
        return xml
    }

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

    private static func workbookXML(sheets: [STExcelSheet]) -> String {
        var xml = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
        <sheets>
        """
        for (index, sheet) in sheets.enumerated() {
            xml += "<sheet name=\"\(escapeXML(sheet.name))\" sheetId=\"\(index + 1)\" r:id=\"rId\(index + 1)\"/>"
        }
        xml += "</sheets></workbook>"
        return xml
    }

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

    private static func worksheetXML(sheet: STExcelSheet, stringIndex: [String: Int],
                                     styleCollector: StyleCollector) -> String {
        var xml = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
        <sheetData>
        """

        for (rowIndex, row) in sheet.cells.enumerated() {
            let hasData = row.contains(where: { !$0.value.isEmpty || $0.style.isCustom })
            guard hasData else { continue }

            xml += "<row r=\"\(rowIndex + 1)\">"
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

        // Merge cells
        if !sheet.mergedRegions.isEmpty {
            xml += "<mergeCells count=\"\(sheet.mergedRegions.count)\">"
            for region in sheet.mergedRegions {
                let startRef = "\(STExcelSheet.columnLetter(region.startCol))\(region.startRow + 1)"
                let endRef = "\(STExcelSheet.columnLetter(region.endCol))\(region.endRow + 1)"
                xml += "<mergeCell ref=\"\(startRef):\(endRef)\"/>"
            }
            xml += "</mergeCells>"
        }

        xml += "</worksheet>"
        return xml
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
