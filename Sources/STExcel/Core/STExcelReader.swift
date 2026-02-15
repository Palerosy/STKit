import Foundation
import ZIPFoundation

/// Reads .xlsx files using ZIPFoundation + XML parsing
enum STExcelReader {

    /// Read an xlsx file and return sheets
    static func read(url: URL) -> [STExcelSheet]? {
        guard let archive = Archive(url: url, accessMode: .read) else { return nil }

        // 1. Read shared strings
        let sharedStrings = readSharedStrings(from: archive)

        // 2. Read workbook to get sheet names
        let sheetNames = readSheetNames(from: archive)

        // 3. Read each worksheet
        var sheets: [STExcelSheet] = []
        for (index, name) in sheetNames.enumerated() {
            let sheetPath = "xl/worksheets/sheet\(index + 1).xml"
            if let cells = readWorksheet(path: sheetPath, from: archive, sharedStrings: sharedStrings) {
                sheets.append(STExcelSheet(name: name, cells: cells))
            }
        }

        return sheets.isEmpty ? nil : sheets
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

    // MARK: - Sheet Names

    private static func readSheetNames(from archive: Archive) -> [String] {
        guard let data = extractData(path: "xl/workbook.xml", from: archive) else { return ["Sheet 1"] }
        let parser = WorkbookParser()
        let xmlParser = XMLParser(data: data)
        xmlParser.delegate = parser
        xmlParser.parse()
        return parser.sheetNames.isEmpty ? ["Sheet 1"] : parser.sheetNames
    }

    // MARK: - Worksheet

    private static func readWorksheet(path: String, from archive: Archive, sharedStrings: [String]) -> [[STExcelCell]]? {
        guard let data = extractData(path: path, from: archive) else { return nil }
        let parser = WorksheetParser(sharedStrings: sharedStrings)
        let xmlParser = XMLParser(data: data)
        xmlParser.delegate = parser
        xmlParser.parse()

        guard !parser.cells.isEmpty else { return nil }

        // Convert sparse cells to 2D array
        let maxRow = parser.cells.keys.map(\.row).max() ?? 0
        let maxCol = parser.cells.keys.map(\.col).max() ?? 0

        // Ensure minimum size
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

        return result
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
}

// MARK: - XML Parsers

private class SharedStringsParser: NSObject, XMLParserDelegate {
    var strings: [String] = []
    private var currentString = ""
    private var insideSI = false
    private var insideT = false

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName: String?, attributes: [String: String] = [:]) {
        if elementName == "si" {
            insideSI = true
            currentString = ""
        } else if elementName == "t" && insideSI {
            insideT = true
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if insideT {
            currentString += string
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName: String?) {
        if elementName == "t" {
            insideT = false
        } else if elementName == "si" {
            strings.append(currentString)
            insideSI = false
        }
    }
}

private class WorkbookParser: NSObject, XMLParserDelegate {
    var sheetNames: [String] = []

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName: String?, attributes: [String: String] = [:]) {
        if elementName == "sheet", let name = attributes["name"] {
            sheetNames.append(name)
        }
    }
}

private class WorksheetParser: NSObject, XMLParserDelegate {
    let sharedStrings: [String]
    var cells: [CellReference: STExcelCell] = [:]

    private var currentRef: CellReference?
    private var currentType: String?
    private var currentValue = ""
    private var insideV = false

    init(sharedStrings: [String]) {
        self.sharedStrings = sharedStrings
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName: String?, attributes: [String: String] = [:]) {
        if elementName == "c" {
            currentRef = attributes["r"].flatMap { CellReference(string: $0) }
            currentType = attributes["t"]
            currentValue = ""
        } else if elementName == "v" {
            insideV = true
            currentValue = ""
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if insideV {
            currentValue += string
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName: String?) {
        if elementName == "v" {
            insideV = false
        } else if elementName == "c", let ref = currentRef {
            let displayValue: String
            if currentType == "s", let index = Int(currentValue), index < sharedStrings.count {
                displayValue = sharedStrings[index]
            } else {
                displayValue = currentValue
            }
            cells[ref] = STExcelCell(value: displayValue)
        }
    }
}
