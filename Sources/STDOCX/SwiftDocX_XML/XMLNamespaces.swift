import Foundation

/// OOXML namespace constants for Word documents
public enum XMLNamespaces {
    // Main document namespaces
    public static let wordprocessingML = "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
    public static let relationships = "http://schemas.openxmlformats.org/officeDocument/2006/relationships"
    public static let contentTypes = "http://schemas.openxmlformats.org/package/2006/content-types"
    public static let coreProperties = "http://schemas.openxmlformats.org/package/2006/metadata/core-properties"
    public static let extendedProperties = "http://schemas.openxmlformats.org/officeDocument/2006/extended-properties"
    public static let drawingML = "http://schemas.openxmlformats.org/drawingml/2006/main"
    public static let drawingMLPicture = "http://schemas.openxmlformats.org/drawingml/2006/picture"
    public static let drawingMLWordprocessing = "http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"
    public static let drawingMLChart = "http://schemas.openxmlformats.org/drawingml/2006/chart"
    public static let chartML = "http://schemas.openxmlformats.org/drawingml/2006/chart"

    // Relationship types
    public static let relationshipDocument = "http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument"
    public static let relationshipStyles = "http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles"
    public static let relationshipSettings = "http://schemas.openxmlformats.org/officeDocument/2006/relationships/settings"
    public static let relationshipFontTable = "http://schemas.openxmlformats.org/officeDocument/2006/relationships/fontTable"
    public static let relationshipTheme = "http://schemas.openxmlformats.org/officeDocument/2006/relationships/theme"
    public static let relationshipImage = "http://schemas.openxmlformats.org/officeDocument/2006/relationships/image"
    public static let relationshipHyperlink = "http://schemas.openxmlformats.org/officeDocument/2006/relationships/hyperlink"
    public static let relationshipChart = "http://schemas.openxmlformats.org/officeDocument/2006/relationships/chart"
    public static let relationshipCoreProperties = "http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties"

    // Content types
    public static let contentTypeDocument = "application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"
    public static let contentTypeStyles = "application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"
    public static let contentTypeSettings = "application/vnd.openxmlformats-officedocument.wordprocessingml.settings+xml"
    public static let contentTypeFontTable = "application/vnd.openxmlformats-officedocument.wordprocessingml.fontTable+xml"
    public static let contentTypeRelationships = "application/vnd.openxmlformats-package.relationships+xml"
    public static let contentTypeCoreProperties = "application/vnd.openxmlformats-package.core-properties+xml"
    public static let contentTypeChart = "application/vnd.openxmlformats-officedocument.drawingml.chart+xml"
}

/// XML element and attribute names for WordprocessingML
public enum WordML {
    // Document structure
    public static let document = "w:document"
    public static let body = "w:body"

    // Paragraph
    public static let paragraph = "w:p"
    public static let paragraphProperties = "w:pPr"
    public static let justification = "w:jc"
    public static let spacing = "w:spacing"
    public static let indentation = "w:ind"

    // Run (text segment)
    public static let run = "w:r"
    public static let runProperties = "w:rPr"
    public static let text = "w:t"

    // Text formatting
    public static let bold = "w:b"
    public static let italic = "w:i"
    public static let underline = "w:u"
    public static let strike = "w:strike"
    public static let color = "w:color"
    public static let highlight = "w:highlight"
    public static let font = "w:rFonts"
    public static let fontSize = "w:sz"
    public static let fontSizeCs = "w:szCs"
    public static let vertAlign = "w:vertAlign"
    public static let caps = "w:caps"
    public static let smallCaps = "w:smallCaps"

    // Attributes
    public static let val = "w:val"
    public static let ascii = "w:ascii"
    public static let hAnsi = "w:hAnsi"
    public static let cs = "w:cs"
    public static let before = "w:before"
    public static let after = "w:after"
    public static let line = "w:line"
    public static let left = "w:left"
    public static let right = "w:right"
    public static let firstLine = "w:firstLine"
    public static let hanging = "w:hanging"
    public static let xmlSpace = "xml:space"
}
