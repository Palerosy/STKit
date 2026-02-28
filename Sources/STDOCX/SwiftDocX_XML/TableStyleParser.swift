import Foundation

/// Conditional formatting type for table style properties
enum TableStyleConditionType: String {
    case wholeTable = "wholeTable"    // Whole table defaults
    case firstRow = "firstRow"        // Header row
    case lastRow = "lastRow"          // Total/footer row
    case firstCol = "firstCol"        // First column
    case lastCol = "lastCol"          // Last column
    case band1Horz = "band1Horz"     // Odd rows (banded)
    case band2Horz = "band2Horz"     // Even rows (banded)
    case band1Vert = "band1Vert"     // Odd columns
    case band2Vert = "band2Vert"     // Even columns
    case neCell = "neCell"            // Top-right cell
    case nwCell = "nwCell"            // Top-left cell
    case seCell = "seCell"            // Bottom-right cell
    case swCell = "swCell"            // Bottom-left cell
}

/// Conditional formatting for a table style region
struct TableStyleCondition {
    var cellShading: DocXColor?       // Cell background fill
    var textColor: DocXColor?         // Text/run color
    var bold: Bool?                   // Text bold override
    var borders: TableBorders?        // Border overrides
}

/// Parsed table style definition from styles.xml
struct TableStyleDefinition {
    var styleId: String               // e.g. "GridTable4-Accent1"
    var name: String?                 // e.g. "Grid Table 4 - Accent 1"
    var basedOn: String?              // Parent style ID
    var conditions: [TableStyleConditionType: TableStyleCondition] = [:]
    var tableBorders: TableBorders?   // Default borders from tblPr
}

/// Parses styles.xml to extract table style definitions
class TableStyleParser {

    /// Optional theme color scheme for resolving theme references
    var themeColors: ThemeColorScheme?

    /// Parse styles.xml data and return table style definitions keyed by styleId
    func parse(_ data: Data) -> [String: TableStyleDefinition] {
        let delegate = StylesXMLDelegate(themeColors: themeColors)
        let parser = XMLParser(data: data)
        parser.delegate = delegate
        parser.shouldProcessNamespaces = true
        parser.parse()
        return delegate.tableStyles
    }
}

// MARK: - SAX Delegate

private class StylesXMLDelegate: NSObject, XMLParserDelegate {

    var tableStyles: [String: TableStyleDefinition] = [:]
    let themeColors: ThemeColorScheme?

    init(themeColors: ThemeColorScheme?) {
        self.themeColors = themeColors
        super.init()
    }

    // State tracking
    private var inTableStyle = false
    private var currentStyle: TableStyleDefinition?

    // tblStylePr (conditional formatting region)
    private var inTblStylePr = false
    private var currentConditionType: TableStyleConditionType?
    private var currentCondition: TableStyleCondition?

    // Property tracking within tblStylePr
    private var inTcPr = false    // Cell properties
    private var inRPr = false     // Run properties
    private var inTblPr = false   // Table properties (whole table defaults)
    private var inTblBorders = false

    // Temp border storage
    private var currentBorders = TableBorders()

    func parser(_ parser: XMLParser, didStartElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?,
                attributes attributeDict: [String: String] = [:]) {

        let local = stripNS(elementName)

        switch local {
        case "style":
            let type = attr(attributeDict, "type")
            let styleId = attr(attributeDict, "styleId")
            if type == "table", let styleId {
                inTableStyle = true
                currentStyle = TableStyleDefinition(styleId: styleId)
            }

        case "name" where inTableStyle && !inTblStylePr:
            if let val = attr(attributeDict, "val") {
                currentStyle?.name = val
            }

        case "basedOn" where inTableStyle && !inTblStylePr:
            if let val = attr(attributeDict, "val") {
                currentStyle?.basedOn = val
            }

        // Table-level properties (default borders)
        case "tblPr" where inTableStyle && !inTblStylePr:
            inTblPr = true
            currentBorders = TableBorders()

        case "tblBorders" where inTblPr || (inTblStylePr && inTcPr):
            inTblBorders = true
            currentBorders = TableBorders()

        case "top" where inTblBorders:
            currentBorders.top = parseBorder(attributeDict)
        case "bottom" where inTblBorders:
            currentBorders.bottom = parseBorder(attributeDict)
        case "left" where inTblBorders, "start" where inTblBorders:
            currentBorders.left = parseBorder(attributeDict)
        case "right" where inTblBorders, "end" where inTblBorders:
            currentBorders.right = parseBorder(attributeDict)
        case "insideH" where inTblBorders:
            currentBorders.insideH = parseBorder(attributeDict)
        case "insideV" where inTblBorders:
            currentBorders.insideV = parseBorder(attributeDict)

        // Conditional formatting region
        case "tblStylePr" where inTableStyle:
            if let typeStr = attr(attributeDict, "type"),
               let condType = TableStyleConditionType(rawValue: typeStr) {
                inTblStylePr = true
                currentConditionType = condType
                currentCondition = TableStyleCondition()
            }

        // Cell properties within conditional formatting
        case "tcPr" where inTblStylePr:
            inTcPr = true
            currentBorders = TableBorders()

        // Cell shading (background color)
        case "shd" where inTcPr:
            if let fill = attr(attributeDict, "fill"), fill != "auto", DocXColor(hex: fill) != nil {
                currentCondition?.cellShading = DocXColor(hex: fill)
            } else if let themeFill = attr(attributeDict, "themeFill"), let tc = themeColors {
                let tint = attr(attributeDict, "themeFillTint")
                let shade = attr(attributeDict, "themeFillShade")
                currentCondition?.cellShading = tc.resolve(themeName: themeFill, themeTint: tint, themeShade: shade)
            }

        // Cell borders within conditional formatting
        case "tcBorders" where inTcPr:
            inTblBorders = true
            currentBorders = TableBorders()

        // Run properties within conditional formatting
        case "rPr" where inTblStylePr:
            inRPr = true

        case "color" where inRPr && inTblStylePr:
            if let val = attr(attributeDict, "val"), val != "auto", DocXColor(hex: val) != nil {
                currentCondition?.textColor = DocXColor(hex: val)
            } else if let themeColor = attr(attributeDict, "themeColor"), let tc = themeColors {
                let tint = attr(attributeDict, "themeTint")
                let shade = attr(attributeDict, "themeShade")
                currentCondition?.textColor = tc.resolve(themeName: themeColor, themeTint: tint, themeShade: shade)
            }

        case "b" where inRPr && inTblStylePr:
            if let val = attr(attributeDict, "val"), val == "0" || val == "false" {
                currentCondition?.bold = false
            } else {
                currentCondition?.bold = true
            }

        default:
            break
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?) {

        let local = stripNS(elementName)

        switch local {
        case "style" where inTableStyle:
            if var style = currentStyle {
                // Store as wholeTable condition from tblPr borders
                if let borders = style.tableBorders {
                    if style.conditions[.wholeTable] == nil {
                        style.conditions[.wholeTable] = TableStyleCondition()
                    }
                    style.conditions[.wholeTable]?.borders = borders
                }
                tableStyles[style.styleId] = style
            }
            inTableStyle = false
            currentStyle = nil

        case "tblPr" where inTableStyle && !inTblStylePr:
            inTblPr = false

        case "tblBorders" where inTblBorders:
            if inTblPr && !inTblStylePr {
                // Table-level default borders
                currentStyle?.tableBorders = currentBorders
            } else if inTcPr && inTblStylePr {
                // Condition-level cell borders
                currentCondition?.borders = currentBorders
            }
            inTblBorders = false

        case "tblStylePr" where inTblStylePr:
            if let condType = currentConditionType, let condition = currentCondition {
                currentStyle?.conditions[condType] = condition
            }
            inTblStylePr = false
            currentConditionType = nil
            currentCondition = nil
            inTcPr = false
            inRPr = false

        case "tcPr" where inTcPr:
            // If cell borders were parsed, assign them
            if currentBorders.top != nil || currentBorders.bottom != nil ||
               currentBorders.left != nil || currentBorders.right != nil {
                currentCondition?.borders = currentBorders
            }
            inTcPr = false

        case "tcBorders" where inTblBorders && inTcPr:
            inTblBorders = false

        case "rPr" where inRPr:
            inRPr = false

        default:
            break
        }
    }

    // MARK: - Helpers

    private func stripNS(_ name: String) -> String {
        if let i = name.lastIndex(of: ":") { return String(name[name.index(after: i)...]) }
        return name
    }

    private func attr(_ attrs: [String: String], _ localName: String) -> String? {
        if let v = attrs["w:\(localName)"] { return v }
        if let v = attrs[localName] { return v }
        for (key, value) in attrs {
            if let i = key.lastIndex(of: ":"), String(key[key.index(after: i)...]) == localName {
                return value
            }
        }
        return nil
    }

    private func parseBorder(_ attrs: [String: String]) -> Border {
        let styleStr = attr(attrs, "val") ?? "single"
        let style = BorderStyle(rawValue: styleStr) ?? .single
        var width: Double = 0.5
        if let sz = attr(attrs, "sz"), let val = Double(sz) {
            width = val / 8.0
        }
        var color: DocXColor?
        if let colorStr = attr(attrs, "color"), colorStr != "auto" {
            color = DocXColor(hex: colorStr)
        }
        if color == nil, let themeColor = attr(attrs, "themeColor"), let tc = themeColors {
            let tint = attr(attrs, "themeTint")
            let shade = attr(attrs, "themeShade")
            color = tc.resolve(themeName: themeColor, themeTint: tint, themeShade: shade)
        }
        return Border(style: style, width: width, color: color)
    }
}
