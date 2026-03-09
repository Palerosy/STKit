import Foundation
import ZIPFoundation

/// Writes sheets to .xlsx format
enum STExcelWriter {

    @discardableResult
    static func write(sheets: [STExcelSheet], to url: URL) -> Bool {
        // Remove existing file
        try? FileManager.default.removeItem(at: url)

        guard let archive = Archive(url: url, accessMode: .create) else { return false }

        do {
            // [Content_Types].xml
            try archive.addEntry(with: "[Content_Types].xml", type: .file,
                                 uncompressedSize: Int64(contentTypesXML(sheetCount: sheets.count).utf8.count),
                                 provider: { position, size in
                Data(contentTypesXML(sheetCount: sheets.count).utf8)
            })

            // _rels/.rels
            let relsXML = relsXML()
            try archive.addEntry(with: "_rels/.rels", type: .file,
                                 uncompressedSize: Int64(relsXML.utf8.count),
                                 provider: { _, _ in Data(relsXML.utf8) })

            // xl/_rels/workbook.xml.rels
            let wbRelsXML = workbookRelsXML(sheetCount: sheets.count)
            try archive.addEntry(with: "xl/_rels/workbook.xml.rels", type: .file,
                                 uncompressedSize: Int64(wbRelsXML.utf8.count),
                                 provider: { _, _ in Data(wbRelsXML.utf8) })

            // xl/workbook.xml
            let wbXML = workbookXML(sheets: sheets)
            try archive.addEntry(with: "xl/workbook.xml", type: .file,
                                 uncompressedSize: Int64(wbXML.utf8.count),
                                 provider: { _, _ in Data(wbXML.utf8) })

            // xl/styles.xml
            let stylesXML = stylesXML()
            try archive.addEntry(with: "xl/styles.xml", type: .file,
                                 uncompressedSize: Int64(stylesXML.utf8.count),
                                 provider: { _, _ in Data(stylesXML.utf8) })

            // Collect all shared strings
            var allStrings: [String] = []
            var stringIndex: [String: Int] = [:]
            for sheet in sheets {
                for row in sheet.cells {
                    for cell in row where !cell.value.isEmpty && Double(cell.value) == nil {
                        if stringIndex[cell.value] == nil {
                            stringIndex[cell.value] = allStrings.count
                            allStrings.append(cell.value)
                        }
                    }
                }
            }

            // xl/sharedStrings.xml
            let ssXML = sharedStringsXML(strings: allStrings)
            try archive.addEntry(with: "xl/sharedStrings.xml", type: .file,
                                 uncompressedSize: Int64(ssXML.utf8.count),
                                 provider: { _, _ in Data(ssXML.utf8) })

            // xl/worksheets/sheet{n}.xml
            for (index, sheet) in sheets.enumerated() {
                let sheetXML = worksheetXML(sheet: sheet, stringIndex: stringIndex)
                try archive.addEntry(with: "xl/worksheets/sheet\(index + 1).xml", type: .file,
                                     uncompressedSize: Int64(sheetXML.utf8.count),
                                     provider: { _, _ in Data(sheetXML.utf8) })
            }

            return true
        } catch {
            print("[STExcel] Write failed: \(error)")
            return false
        }
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
            xml += """
            <Override PartName="/xl/worksheets/sheet\(i).xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
            """
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
            xml += """
            <Relationship Id="rId\(i)" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet\(i).xml"/>
            """
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
            let escapedName = sheet.name.replacingOccurrences(of: "&", with: "&amp;")
                .replacingOccurrences(of: "<", with: "&lt;")
                .replacingOccurrences(of: ">", with: "&gt;")
                .replacingOccurrences(of: "\"", with: "&quot;")
            xml += "<sheet name=\"\(escapedName)\" sheetId=\"\(index + 1)\" r:id=\"rId\(index + 1)\"/>"
        }
        xml += "</sheets></workbook>"
        return xml
    }

    private static func stylesXML() -> String {
        """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
        <fonts count="1"><font><sz val="11"/><name val="Calibri"/></font></fonts>
        <fills count="2"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill></fills>
        <borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>
        <cellXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellXfs>
        </styleSheet>
        """
    }

    private static func sharedStringsXML(strings: [String]) -> String {
        var xml = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <sst xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" count="\(strings.count)" uniqueCount="\(strings.count)">
        """
        for str in strings {
            let escaped = str.replacingOccurrences(of: "&", with: "&amp;")
                .replacingOccurrences(of: "<", with: "&lt;")
                .replacingOccurrences(of: ">", with: "&gt;")
            xml += "<si><t>\(escaped)</t></si>"
        }
        xml += "</sst>"
        return xml
    }

    private static func worksheetXML(sheet: STExcelSheet, stringIndex: [String: Int]) -> String {
        var xml = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
        <sheetData>
        """

        for (rowIndex, row) in sheet.cells.enumerated() {
            let hasData = row.contains(where: { !$0.value.isEmpty })
            guard hasData else { continue }

            xml += "<row r=\"\(rowIndex + 1)\">"
            for (colIndex, cell) in row.enumerated() {
                guard !cell.value.isEmpty else { continue }
                let ref = "\(STExcelSheet.columnLetter(colIndex))\(rowIndex + 1)"

                if let numVal = Double(cell.value) {
                    // Numeric cell
                    xml += "<c r=\"\(ref)\"><v>\(numVal)</v></c>"
                } else if let sIndex = stringIndex[cell.value] {
                    // Shared string cell
                    xml += "<c r=\"\(ref)\" t=\"s\"><v>\(sIndex)</v></c>"
                }
            }
            xml += "</row>"
        }

        xml += "</sheetData></worksheet>"
        return xml
    }
}
