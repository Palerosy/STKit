import Foundation

/// Parsed paragraph style definition from styles.xml
struct ParagraphStyleDefinition {
    var styleId: String               // e.g. "Title", "Heading1", "BodyContactInfo"
    var name: String?                 // Display name
    var basedOn: String?              // Parent style ID for inheritance

    // Run-level defaults (rPr)
    var bold: Bool?
    var italic: Bool?
    var underline: UnderlineStyle?
    var strikethrough: Bool?
    var color: DocXColor?
    var font: Font?
    var fontSize: Double?             // In points
    var allCaps: Bool?
    var smallCaps: Bool?

    // Paragraph-level defaults (pPr)
    var alignment: ParagraphAlignment?
    var spacingBefore: Double?
    var spacingAfter: Double?
    var lineSpacing: Double?
    var indentLeft: Double?
    var indentRight: Double?
    var indentFirstLine: Double?
    var backgroundColor: DocXColor?
    var borders: ParagraphBorders?
}

/// Parses styles.xml to extract paragraph style definitions
class ParagraphStyleParser {

    /// Optional theme color scheme for resolving theme references
    var themeColors: ThemeColorScheme?

    /// Parse styles.xml data and return paragraph style definitions keyed by styleId
    func parse(_ data: Data) -> [String: ParagraphStyleDefinition] {
        let delegate = ParagraphStylesXMLDelegate(themeColors: themeColors)
        let parser = XMLParser(data: data)
        parser.delegate = delegate
        parser.shouldProcessNamespaces = true
        parser.parse()
        return delegate.paragraphStyles
    }
}

// MARK: - SAX Delegate

private class ParagraphStylesXMLDelegate: NSObject, XMLParserDelegate {

    var paragraphStyles: [String: ParagraphStyleDefinition] = [:]
    let themeColors: ThemeColorScheme?

    init(themeColors: ThemeColorScheme?) {
        self.themeColors = themeColors
        super.init()
    }

    // State tracking
    private var inParagraphStyle = false
    private var currentStyle: ParagraphStyleDefinition?

    // Property contexts
    private var inRPr = false       // Run properties (default text formatting)
    private var inPPr = false       // Paragraph properties
    private var inPBdr = false      // Paragraph borders
    private var inSpacing = false

    // Temp border storage
    private var currentBorders = ParagraphBorders()

    func parser(_ parser: XMLParser, didStartElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?,
                attributes attributeDict: [String: String] = [:]) {

        let local = stripNS(elementName)

        switch local {
        case "style":
            let type = attr(attributeDict, "type")
            let styleId = attr(attributeDict, "styleId")
            if type == "paragraph", let styleId {
                inParagraphStyle = true
                currentStyle = ParagraphStyleDefinition(styleId: styleId)
            }

        case "name" where inParagraphStyle && !inRPr:
            if let val = attr(attributeDict, "val") {
                currentStyle?.name = val
            }

        case "basedOn" where inParagraphStyle:
            if let val = attr(attributeDict, "val") {
                currentStyle?.basedOn = val
            }

        // Paragraph properties
        case "pPr" where inParagraphStyle && !inRPr:
            inPPr = true

        case "jc" where inPPr:
            if let val = attr(attributeDict, "val") {
                currentStyle?.alignment = ParagraphAlignment(rawValue: val)
            }

        case "spacing" where inPPr:
            if let before = attr(attributeDict, "before"), let v = Int(before) {
                currentStyle?.spacingBefore = Double(v) / 20.0
            }
            if let after = attr(attributeDict, "after"), let v = Int(after) {
                currentStyle?.spacingAfter = Double(v) / 20.0
            }
            if let line = attr(attributeDict, "line"), let v = Int(line) {
                currentStyle?.lineSpacing = Double(v) / 240.0
            }

        case "ind" where inPPr:
            if let left = attr(attributeDict, "left"), let v = Int(left) {
                currentStyle?.indentLeft = Double(v) / 20.0
            }
            if let right = attr(attributeDict, "right"), let v = Int(right) {
                currentStyle?.indentRight = Double(v) / 20.0
            }
            if let firstLine = attr(attributeDict, "firstLine"), let v = Int(firstLine) {
                currentStyle?.indentFirstLine = Double(v) / 20.0
            }
            if let hanging = attr(attributeDict, "hanging"), let v = Int(hanging) {
                currentStyle?.indentFirstLine = -Double(v) / 20.0
            }

        // Paragraph shading
        case "shd" where inPPr && !inRPr:
            if let fill = attr(attributeDict, "fill"), fill != "auto", DocXColor(hex: fill) != nil {
                currentStyle?.backgroundColor = DocXColor(hex: fill)
            } else if let themeFill = attr(attributeDict, "themeFill"), let tc = themeColors {
                let tint = attr(attributeDict, "themeFillTint")
                let shade = attr(attributeDict, "themeFillShade")
                currentStyle?.backgroundColor = tc.resolve(themeName: themeFill, themeTint: tint, themeShade: shade)
            }

        // Paragraph borders
        case "pBdr" where inPPr:
            inPBdr = true
            currentBorders = ParagraphBorders()

        case "top" where inPBdr:
            currentBorders.top = parseBorder(attributeDict)
        case "bottom" where inPBdr:
            currentBorders.bottom = parseBorder(attributeDict)
        case "left" where inPBdr, "start" where inPBdr:
            currentBorders.left = parseBorder(attributeDict)
        case "right" where inPBdr, "end" where inPBdr:
            currentBorders.right = parseBorder(attributeDict)

        // Run properties (default text formatting for the style)
        case "rPr" where inParagraphStyle:
            inRPr = true

        case "b" where inRPr && inParagraphStyle:
            if let val = attr(attributeDict, "val"), val == "0" || val == "false" {
                currentStyle?.bold = false
            } else {
                currentStyle?.bold = true
            }

        case "i" where inRPr && inParagraphStyle:
            if let val = attr(attributeDict, "val"), val == "0" || val == "false" {
                currentStyle?.italic = false
            } else {
                currentStyle?.italic = true
            }

        case "u" where inRPr && inParagraphStyle:
            if let val = attr(attributeDict, "val") {
                if val != "none" {
                    currentStyle?.underline = UnderlineStyle(rawValue: val) ?? .single
                }
            } else {
                currentStyle?.underline = .single
            }

        case "strike" where inRPr && inParagraphStyle:
            if let val = attr(attributeDict, "val"), val == "0" || val == "false" {
                currentStyle?.strikethrough = false
            } else {
                currentStyle?.strikethrough = true
            }

        case "color" where inRPr && inParagraphStyle:
            if let val = attr(attributeDict, "val"), val != "auto", DocXColor(hex: val) != nil {
                currentStyle?.color = DocXColor(hex: val)
            } else if let themeColor = attr(attributeDict, "themeColor"), let tc = themeColors {
                let tint = attr(attributeDict, "themeTint")
                let shade = attr(attributeDict, "themeShade")
                currentStyle?.color = tc.resolve(themeName: themeColor, themeTint: tint, themeShade: shade)
            }

        case "rFonts" where inRPr && inParagraphStyle:
            if let ascii = attr(attributeDict, "ascii") {
                currentStyle?.font = Font(name: ascii)
            } else if let hAnsi = attr(attributeDict, "hAnsi") {
                currentStyle?.font = Font(name: hAnsi)
            }

        case "sz" where inRPr && inParagraphStyle:
            if let val = attr(attributeDict, "val"), let halfPts = Int(val) {
                currentStyle?.fontSize = Double(halfPts) / 2.0
            }

        case "caps" where inRPr && inParagraphStyle:
            if let val = attr(attributeDict, "val"), val == "0" || val == "false" {
                currentStyle?.allCaps = false
            } else {
                currentStyle?.allCaps = true
            }

        case "smallCaps" where inRPr && inParagraphStyle:
            if let val = attr(attributeDict, "val"), val == "0" || val == "false" {
                currentStyle?.smallCaps = false
            } else {
                currentStyle?.smallCaps = true
            }

        default:
            break
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?) {

        let local = stripNS(elementName)

        switch local {
        case "style" where inParagraphStyle:
            if var style = currentStyle {
                // Assign borders if any were parsed
                if currentBorders.top != nil || currentBorders.bottom != nil ||
                   currentBorders.left != nil || currentBorders.right != nil {
                    style.borders = currentBorders
                }
                paragraphStyles[style.styleId] = style
            }
            inParagraphStyle = false
            currentStyle = nil
            inRPr = false
            inPPr = false
            inPBdr = false

        case "pPr" where inPPr:
            inPPr = false

        case "pBdr" where inPBdr:
            inPBdr = false

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
