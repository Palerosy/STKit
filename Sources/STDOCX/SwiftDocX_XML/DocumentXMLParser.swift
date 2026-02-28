import Foundation

/// Error types for XML parsing
public enum DocumentXMLParserError: Error, LocalizedError {
    case invalidXML(String)
    case missingElement(String)
    case parsingFailed(String)

    public var errorDescription: String? {
        switch self {
        case .invalidXML(let detail):
            return "Invalid XML: \(detail)"
        case .missingElement(let element):
            return "Missing required element: \(element)"
        case .parsingFailed(let detail):
            return "Parsing failed: \(detail)"
        }
    }
}

/// Parses Word document XML content using SAX-style XMLParser (iOS compatible)
public class DocumentXMLParser {

    public init() {}

    /// Parses document.xml content and returns document elements (paragraphs and tables)
    public func parseDocumentXML(_ xmlData: Data) throws -> [DocumentElement] {
        return try parseDocumentXML(xmlData, relationships: [:])
    }

    /// Parses document.xml with relationship info for chart detection
    func parseDocumentXML(_ xmlData: Data, relationships: [String: DocumentRelationship], themeColors: ThemeColorScheme? = nil) throws -> [DocumentElement] {
        let delegate = DocXMLParserDelegate(relationships: relationships, themeColors: themeColors)
        let parser = XMLParser(data: xmlData)
        parser.delegate = delegate
        parser.shouldProcessNamespaces = true

        guard parser.parse() else {
            let errorDesc = parser.parserError?.localizedDescription ?? "Unknown"
            throw DocumentXMLParserError.invalidXML(errorDesc)
        }

        return delegate.elements
    }

    /// Legacy method: Parses document.xml and returns only paragraphs
    public func parseParagraphs(_ xmlData: Data) throws -> [Paragraph] {
        let elements = try parseDocumentXML(xmlData)
        return elements.compactMap { element in
            if case .paragraph(let p) = element { return p }
            return nil
        }
    }
}

// MARK: - SAX Parser Delegate

private class DocXMLParserDelegate: NSObject, XMLParserDelegate {

    var elements: [DocumentElement] = []
    private let relationships: [String: DocumentRelationship]
    private let themeColors: ThemeColorScheme?

    init(relationships: [String: DocumentRelationship] = [:], themeColors: ThemeColorScheme? = nil) {
        self.relationships = relationships
        self.themeColors = themeColors
        super.init()
    }

    // Body state
    private var inBody = false

    // Paragraph state
    private var inParagraph = false
    private var inRun = false
    private var inRunProperties = false
    private var inParagraphProperties = false
    private var inText = false

    // Current paragraph builders
    private var currentParagraph: Paragraph?
    private var currentRunText = ""
    private var currentFormatting = TextFormatting()
    private var currentAlignment: ParagraphAlignment?
    private var currentSpacing = ParagraphSpacing()
    private var currentIndentation = ParagraphIndentation()
    private var currentHeadingLevel: HeadingLevel?
    private var currentListType: ListType?
    private var currentListLevel: Int = 0
    private var currentNumId: Int?

    // Text accumulator
    private var textBuffer = ""

    // Table state
    private var inTable = false
    private var inTableProperties = false
    private var inTableBorders = false
    private var inTableGrid = false
    private var inTableRow = false
    private var inTableRowProperties = false
    private var inTableCell = false
    private var inTableCellProperties = false
    private var inCellBorders = false

    // Current table builders
    private var currentTable: Table?
    private var currentRow: TableRow?
    private var currentCell: TableCell?
    private var currentTableBorders = TableBorders()
    private var currentCellBorders = TableBorders()
    private var gridColumns: [Double] = []

    // Track vMerge state for row span calculation
    private var vMergeRestart = false
    private var vMergeContinue = false

    // Paragraph property state
    private var inParagraphBorders = false
    private var currentParagraphBorders = ParagraphBorders()

    // Drawing/Chart/Image state
    private var inDrawing = false
    private var drawingWidthEmu: Int?
    private var drawingHeightEmu: Int?
    private var inGraphicData = false
    private var graphicDataIsChart = false
    private var chartRelId: String?
    private var imageRelId: String?

    // MARK: - XMLParserDelegate

    func parser(_ parser: XMLParser, didStartElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?,
                attributes attributeDict: [String: String] = [:]) {

        let localName = stripNamespace(elementName)

        switch localName {
        case "body":
            inBody = true

        // MARK: Table elements
        case "tbl" where inBody:
            inTable = true
            currentTable = Table()
            currentTableBorders = TableBorders()
            gridColumns = []

        case "tblPr" where inTable && !inTableRow:
            inTableProperties = true

        case "tblBorders" where inTableProperties:
            inTableBorders = true

        case "top" where inTableBorders:
            currentTableBorders.top = parseBorder(attributeDict)
        case "bottom" where inTableBorders:
            currentTableBorders.bottom = parseBorder(attributeDict)
        case "left" where inTableBorders, "start" where inTableBorders:
            currentTableBorders.left = parseBorder(attributeDict)
        case "right" where inTableBorders, "end" where inTableBorders:
            currentTableBorders.right = parseBorder(attributeDict)
        case "insideH" where inTableBorders:
            currentTableBorders.insideH = parseBorder(attributeDict)
        case "insideV" where inTableBorders:
            currentTableBorders.insideV = parseBorder(attributeDict)

        // Cell borders
        case "top" where inCellBorders:
            currentCellBorders.top = parseBorder(attributeDict)
        case "bottom" where inCellBorders:
            currentCellBorders.bottom = parseBorder(attributeDict)
        case "left" where inCellBorders, "start" where inCellBorders:
            currentCellBorders.left = parseBorder(attributeDict)
        case "right" where inCellBorders, "end" where inCellBorders:
            currentCellBorders.right = parseBorder(attributeDict)

        case "tblW" where inTableProperties:
            if let w = attrValue(attributeDict, localName: "w"), let val = Double(w) {
                let type = attrValue(attributeDict, localName: "type") ?? "dxa"
                if type == "dxa" {
                    currentTable?.width = val / 20.0  // twips → points
                } else if type == "pct" {
                    // pct: 5000 = 100% of page content width (~468pt for letter)
                    currentTable?.width = (val / 5000.0) * 468.0
                }
            }

        case "tblStyle" where inTableProperties:
            if let val = attrValue(attributeDict, localName: "val") {
                currentTable?.styleName = val
            }

        case "tblLook" where inTableProperties:
            currentTable?.tblLook = TableLook(attributes: attributeDict)

        case "jc" where inTableProperties:
            if let val = attrValue(attributeDict, localName: "val") {
                currentTable?.alignment = ParagraphAlignment(rawValue: val)
            }

        case "tblGrid" where inTable && !inTableRow:
            inTableGrid = true

        case "gridCol" where inTableGrid:
            if let w = attrValue(attributeDict, localName: "w"), let val = Double(w) {
                gridColumns.append(val / 20.0)  // twips → points
            }

        case "tr" where inTable:
            inTableRow = true
            currentRow = TableRow()

        case "trPr" where inTableRow && !inTableCell:
            inTableRowProperties = true

        case "trHeight" where inTableRowProperties:
            if let val = attrValue(attributeDict, localName: "val"), let v = Double(val) {
                currentRow?.height = v / 20.0  // twips → points
            }

        case "tblHeader" where inTableRowProperties:
            currentRow?.isHeader = true

        case "tc" where inTableRow:
            inTableCell = true
            currentCell = TableCell()
            currentCellBorders = TableBorders()
            vMergeRestart = false
            vMergeContinue = false

        case "tcPr" where inTableCell:
            inTableCellProperties = true

        case "tcW" where inTableCellProperties:
            if let w = attrValue(attributeDict, localName: "w"), let val = Double(w) {
                let type = attrValue(attributeDict, localName: "type") ?? "dxa"
                if type == "dxa" {
                    currentCell?.width = val / 20.0  // twips → points
                } else if type == "pct" {
                    // pct: 5000 = 100% of table width (~468pt for full-width table)
                    currentCell?.width = (val / 5000.0) * 468.0
                }
            }

        case "gridSpan" where inTableCellProperties:
            if let val = attrValue(attributeDict, localName: "val"), let span = Int(val) {
                currentCell?.columnSpan = span
            }

        case "vMerge" where inTableCellProperties:
            if let val = attrValue(attributeDict, localName: "val"), val == "restart" {
                vMergeRestart = true
            } else {
                // No val or val="continue" means this cell is merged from above
                vMergeContinue = true
            }

        case "shd" where inTableCellProperties:
            if let fill = attrValue(attributeDict, localName: "fill"), fill != "auto", DocXColor(hex: fill) != nil {
                currentCell?.backgroundColor = DocXColor(hex: fill)
            } else if let themeFill = attrValue(attributeDict, localName: "themeFill"), let tc = themeColors {
                let tint = attrValue(attributeDict, localName: "themeFillTint")
                let shade = attrValue(attributeDict, localName: "themeFillShade")
                currentCell?.backgroundColor = tc.resolve(themeName: themeFill, themeTint: tint, themeShade: shade)
            }

        case "vAlign" where inTableCellProperties:
            if let val = attrValue(attributeDict, localName: "val") {
                currentCell?.verticalAlignment = VerticalAlignment(rawValue: val)
            }

        case "tcBorders" where inTableCellProperties:
            inCellBorders = true

        // MARK: Paragraph elements
        case "p" where inBody:
            inParagraph = true
            currentParagraph = Paragraph()
            currentAlignment = nil
            currentSpacing = ParagraphSpacing()
            currentIndentation = ParagraphIndentation()
            currentHeadingLevel = nil
            currentListType = nil
            currentListLevel = 0
            currentNumId = nil

        case "pPr" where inParagraph:
            inParagraphProperties = true

        case "pStyle" where inParagraphProperties:
            if let val = attrValue(attributeDict, localName: "val") {
                parseHeadingStyle(val)
            }

        case "numPr" where inParagraphProperties:
            break // Container element, children ilvl/numId will set list info

        case "ilvl" where inParagraphProperties:
            if let val = attrValue(attributeDict, localName: "val"), let level = Int(val) {
                currentListLevel = level
            }

        case "numId" where inParagraphProperties:
            if let val = attrValue(attributeDict, localName: "val"), let numId = Int(val) {
                currentNumId = numId
                // numId > 0 means it's a list item. We'll default to bullet;
                // proper detection requires numbering.xml which we skip for now.
                // numId == 1 is typically bullet, numId >= 2 is numbered in many templates.
                if numId > 0 {
                    currentListType = (numId == 1) ? .bullet : .numbered
                }
            }

        case "jc" where inParagraphProperties:
            if let val = attrValue(attributeDict, localName: "val") {
                currentAlignment = ParagraphAlignment(rawValue: val)
            }

        case "spacing" where inParagraphProperties:
            if let before = attrValue(attributeDict, localName: "before"), let v = Int(before) {
                currentSpacing.before = Double(v) / 20.0
            }
            if let after = attrValue(attributeDict, localName: "after"), let v = Int(after) {
                currentSpacing.after = Double(v) / 20.0
            }
            if let line = attrValue(attributeDict, localName: "line"), let v = Int(line) {
                currentSpacing.lineSpacing = Double(v) / 240.0
            }

        case "ind" where inParagraphProperties:
            if let left = attrValue(attributeDict, localName: "left"), let v = Int(left) {
                currentIndentation.left = Double(v) / 20.0
            }
            if let right = attrValue(attributeDict, localName: "right"), let v = Int(right) {
                currentIndentation.right = Double(v) / 20.0
            }
            if let firstLine = attrValue(attributeDict, localName: "firstLine"), let v = Int(firstLine) {
                currentIndentation.firstLine = Double(v) / 20.0
            }
            if let hanging = attrValue(attributeDict, localName: "hanging"), let v = Int(hanging) {
                currentIndentation.firstLine = -Double(v) / 20.0
            }

        // Paragraph shading (background color)
        case "shd" where inParagraphProperties && !inTableCellProperties:
            if let fill = attrValue(attributeDict, localName: "fill"), fill != "auto", DocXColor(hex: fill) != nil {
                currentParagraph?.backgroundColor = DocXColor(hex: fill)
            } else if let themeFill = attrValue(attributeDict, localName: "themeFill"), let tc = themeColors {
                let tint = attrValue(attributeDict, localName: "themeFillTint")
                let shade = attrValue(attributeDict, localName: "themeFillShade")
                currentParagraph?.backgroundColor = tc.resolve(themeName: themeFill, themeTint: tint, themeShade: shade)
            }

        // Paragraph borders
        case "pBdr" where inParagraphProperties:
            inParagraphBorders = true
            currentParagraphBorders = ParagraphBorders()

        case "top" where inParagraphBorders:
            currentParagraphBorders.top = parseBorder(attributeDict)
        case "bottom" where inParagraphBorders:
            currentParagraphBorders.bottom = parseBorder(attributeDict)
        case "left" where inParagraphBorders, "start" where inParagraphBorders:
            currentParagraphBorders.left = parseBorder(attributeDict)
        case "right" where inParagraphBorders, "end" where inParagraphBorders:
            currentParagraphBorders.right = parseBorder(attributeDict)

        // MARK: Run elements
        case "r" where inParagraph:
            inRun = true
            currentRunText = ""
            currentFormatting = TextFormatting()

        case "rPr" where inRun:
            inRunProperties = true

        case "b" where inRunProperties:
            if let val = attrValue(attributeDict, localName: "val"), val == "0" || val == "false" {
                currentFormatting.bold = false
            } else {
                currentFormatting.bold = true
            }

        case "i" where inRunProperties:
            if let val = attrValue(attributeDict, localName: "val"), val == "0" || val == "false" {
                currentFormatting.italic = false
            } else {
                currentFormatting.italic = true
            }

        case "u" where inRunProperties:
            if let val = attrValue(attributeDict, localName: "val") {
                if val != "none" {
                    currentFormatting.underline = UnderlineStyle(rawValue: val) ?? .single
                }
            } else {
                currentFormatting.underline = .single
            }

        case "strike" where inRunProperties:
            if let val = attrValue(attributeDict, localName: "val"), val == "0" || val == "false" {
                currentFormatting.strikethrough = false
            } else {
                currentFormatting.strikethrough = true
            }

        case "color" where inRunProperties:
            if let val = attrValue(attributeDict, localName: "val"), val != "auto" {
                currentFormatting.color = DocXColor(hex: val)
            }

        case "highlight" where inRunProperties:
            if let val = attrValue(attributeDict, localName: "val") {
                currentFormatting.highlight = HighlightColor(rawValue: val)
            }

        case "rFonts" where inRunProperties:
            if let ascii = attrValue(attributeDict, localName: "ascii") {
                currentFormatting.font = Font(name: ascii)
            }

        case "sz" where inRunProperties:
            if let val = attrValue(attributeDict, localName: "val"), let halfPts = Int(val) {
                currentFormatting.fontSize = Double(halfPts) / 2.0
            }

        case "caps" where inRunProperties:
            if let val = attrValue(attributeDict, localName: "val"), val == "0" || val == "false" {
                currentFormatting.allCaps = false
            } else {
                currentFormatting.allCaps = true
            }

        case "smallCaps" where inRunProperties:
            if let val = attrValue(attributeDict, localName: "val"), val == "0" || val == "false" {
                currentFormatting.smallCaps = false
            } else {
                currentFormatting.smallCaps = true
            }

        case "vertAlign" where inRunProperties:
            if let val = attrValue(attributeDict, localName: "val") {
                if val == "superscript" {
                    currentFormatting.superscript = true
                } else if val == "subscript" {
                    currentFormatting.subscriptText = true
                }
            }

        case "t" where inRun:
            inText = true
            textBuffer = ""

        case "br" where inRun:
            // Line break within a run
            currentRunText += "\n"

        case "tab" where inRun:
            currentRunText += "\t"

        // MARK: Drawing / Chart / Image detection
        case "drawing" where inRun || inParagraph:
            inDrawing = true
            drawingWidthEmu = nil
            drawingHeightEmu = nil
            chartRelId = nil
            imageRelId = nil
            graphicDataIsChart = false

        case "extent" where inDrawing:
            if let cx = attributeDict["cx"], let cxVal = Int(cx) {
                drawingWidthEmu = cxVal
            }
            if let cy = attributeDict["cy"], let cyVal = Int(cy) {
                drawingHeightEmu = cyVal
            }

        case "graphicData" where inDrawing:
            inGraphicData = true
            // Check if URI indicates a chart
            let uri = attributeDict["uri"] ?? ""
            graphicDataIsChart = uri.contains("chart")

        case "chart" where inGraphicData && graphicDataIsChart:
            // <c:chart r:id="rIdN"/> — extract the relationship ID
            for (key, value) in attributeDict {
                if stripNamespace(key) == "id" {
                    chartRelId = value
                }
            }

        case "blip" where inDrawing:
            // <a:blip r:embed="rIdN"/> — inline image relationship ID
            for (key, value) in attributeDict {
                if stripNamespace(key) == "embed" {
                    imageRelId = value
                }
            }

        default:
            break
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if inText {
            textBuffer += string
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?) {

        let localName = stripNamespace(elementName)

        switch localName {
        case "body":
            inBody = false

        // MARK: Table end elements
        case "tbl" where inTable:
            if let table = currentTable {
                table.borders = currentTableBorders
                table.columnWidths = gridColumns.map { Optional($0) }
                elements.append(.table(table))
            }
            inTable = false
            currentTable = nil

        case "tblPr":
            inTableProperties = false

        case "tblBorders":
            inTableBorders = false

        case "tblGrid":
            inTableGrid = false

        case "tr" where inTableRow:
            if let row = currentRow {
                currentTable?.rows.append(row)
            }
            inTableRow = false
            currentRow = nil
            inTableRowProperties = false

        case "trPr":
            inTableRowProperties = false

        case "tc" where inTableCell:
            if let cell = currentCell {
                // Apply cell borders if any were set
                if currentCellBorders.top != nil || currentCellBorders.bottom != nil ||
                   currentCellBorders.left != nil || currentCellBorders.right != nil {
                    cell.borders = currentCellBorders
                }
                // Skip vertically merged continuation cells
                if !vMergeContinue {
                    currentRow?.cells.append(cell)
                }
            }
            inTableCell = false
            currentCell = nil
            inTableCellProperties = false

        case "tcPr":
            inTableCellProperties = false

        case "tcBorders":
            inCellBorders = false

        // MARK: Paragraph end
        case "p" where inParagraph:
            if let para = currentParagraph {
                para.alignment = currentAlignment
                para.spacing = currentSpacing
                para.indentation = currentIndentation
                para.headingLevel = currentHeadingLevel
                para.listType = currentListType
                para.listLevel = currentListLevel

                if inTableCell {
                    // Paragraph inside a table cell
                    currentCell?.paragraphs.append(para)
                } else {
                    // Top-level paragraph
                    elements.append(.paragraph(para))
                }
            }
            inParagraph = false
            currentParagraph = nil

        case "pPr":
            inParagraphProperties = false
            inParagraphBorders = false

        case "pBdr" where inParagraphBorders:
            if currentParagraphBorders.top != nil || currentParagraphBorders.bottom != nil ||
               currentParagraphBorders.left != nil || currentParagraphBorders.right != nil {
                currentParagraph?.borders = currentParagraphBorders
            }
            inParagraphBorders = false

        case "r" where inRun:
            if let para = currentParagraph {
                let run = Run(text: currentRunText, formatting: currentFormatting)
                para.runs.append(run)
            }
            inRun = false

        case "rPr":
            inRunProperties = false

        case "t" where inText:
            currentRunText += textBuffer
            inText = false
            textBuffer = ""

        // MARK: Drawing / Chart end elements
        case "graphicData" where inGraphicData:
            inGraphicData = false

        case "drawing" where inDrawing:
            if graphicDataIsChart, let relId = chartRelId {
                // Emit a chart placeholder element — DocumentReader will resolve it
                let chart = Chart()
                chart.relationshipId = relId
                // Convert EMU to points (1 inch = 914400 EMU, 1 inch = 72 points)
                if let cx = drawingWidthEmu {
                    chart.width = Double(cx) * 72.0 / 914400.0
                }
                if let cy = drawingHeightEmu {
                    chart.height = Double(cy) * 72.0 / 914400.0
                }
                elements.append(.chart(chart))
                // If this was inside a paragraph, discard the paragraph wrapper
                // since charts are standalone elements
                currentParagraph = nil
            } else if let relId = imageRelId {
                // Inline image — create placeholder run; DocumentReader will fill in data
                let image = DocImage(data: Data(), fileExtension: "png")
                image.relationshipId = relId
                if let cx = drawingWidthEmu {
                    image.width = Double(cx) * 72.0 / 914400.0
                }
                if let cy = drawingHeightEmu {
                    image.height = Double(cy) * 72.0 / 914400.0
                }
                let run = Run(text: "")
                run.image = image
                currentParagraph?.runs.append(run)
            }
            inDrawing = false
            graphicDataIsChart = false
            chartRelId = nil
            imageRelId = nil

        default:
            break
        }
    }

    // MARK: - Helpers

    /// Strip namespace prefix: "w:body" → "body", "body" → "body"
    private func stripNamespace(_ name: String) -> String {
        if let colonIndex = name.lastIndex(of: ":") {
            return String(name[name.index(after: colonIndex)...])
        }
        return name
    }

    /// Get attribute value, trying both "w:val" and "val" forms
    private func attrValue(_ attrs: [String: String], localName: String) -> String? {
        if let val = attrs["w:\(localName)"] { return val }
        if let val = attrs[localName] { return val }
        for (key, value) in attrs {
            if stripNamespace(key) == localName { return value }
        }
        return nil
    }

    /// Parse heading level from pStyle value
    private func parseHeadingStyle(_ style: String) {
        let lowered = style.lowercased()
        // Common styles: "Heading1", "heading 1", "Heading2", etc.
        if lowered.hasPrefix("heading") {
            let numStr = lowered.replacingOccurrences(of: "heading", with: "")
                .trimmingCharacters(in: .whitespaces)
            if let level = Int(numStr), level >= 1, level <= 6 {
                currentHeadingLevel = HeadingLevel(rawValue: level)
            }
        }
        // Also check for list styles
        if lowered.contains("listparagraph") || lowered.contains("list paragraph") {
            // List paragraph style — the actual type comes from numPr
            if currentListType == nil {
                currentListType = .bullet
            }
        }
    }

    /// Parse a border element from attributes
    private func parseBorder(_ attrs: [String: String]) -> Border {
        let styleStr = attrValue(attrs, localName: "val") ?? "single"
        let style = BorderStyle(rawValue: styleStr) ?? .single

        var width: Double = 0.5
        if let sz = attrValue(attrs, localName: "sz"), let val = Double(sz) {
            width = val / 8.0  // eighths of a point → points
        }

        var color: DocXColor?
        if let colorStr = attrValue(attrs, localName: "color"), colorStr != "auto" {
            color = DocXColor(hex: colorStr)
        }
        // Resolve theme colors for borders
        if color == nil, let themeColor = attrValue(attrs, localName: "themeColor"), let tc = themeColors {
            let tint = attrValue(attrs, localName: "themeTint")
            let shade = attrValue(attrs, localName: "themeShade")
            color = tc.resolve(themeName: themeColor, themeTint: tint, themeShade: shade)
        }

        return Border(style: style, width: width, color: color)
    }
}
