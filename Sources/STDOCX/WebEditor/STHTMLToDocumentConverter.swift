import Foundation
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif
import STKit

/// Converts JSON document structure (from JS getDocumentStructure()) back to SwiftDocX Document model
enum STHTMLToDocumentConverter {

    /// Parse JSON string from JS and create a Document model
    static func toDocument(from jsonString: String) -> Document? {
        guard let data = jsonString.data(using: .utf8) else { return nil }

        do {
            let parsed = try JSONDecoder().decode(ParsedDocument.self, from: data)
            return buildDocument(from: parsed)
        } catch {
            print("[STHTMLToDoc] JSON decode error: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Build Document from parsed JSON

    private static func buildDocument(from parsed: ParsedDocument) -> Document {
        let doc = Document()

        for element in parsed.elements {
            switch element.type {
            case "heading":
                let para = buildParagraph(from: element)
                if let level = element.level, level >= 1 && level <= 6 {
                    para.headingLevel = HeadingLevel(rawValue: level)
                }
                doc.paragraphs.append(para)
                doc.elements.append(.paragraph(para))

            case "table":
                let table = buildTable(from: element)
                doc.tables.append(table)
                doc.elements.append(.table(table))

            case "chart":
                let chart = buildChart(from: element)
                doc.charts.append(chart)
                doc.elements.append(.chart(chart))

            case "shape":
                // Image shapes with data URI imageSrc must be converted to paragraph image
                // runs because DocumentWriter silently skips shapes (case .shape: break).
                if element.shapeType == "image",
                   let src = element.imageSrc, src.hasPrefix("data:") {
                    let para = Paragraph()
                    let run = buildRunFromImageDataURI(src,
                                                      widthCSS: element.width,
                                                      heightCSS: element.height)
                    para.runs.append(run)
                    doc.paragraphs.append(para)
                    doc.elements.append(.paragraph(para))
                } else {
                    let shape = buildShape(from: element)
                    doc.shapes.append(shape)
                    doc.elements.append(.shape(shape))
                }

            default: // "paragraph" and any other
                let para = buildParagraph(from: element)
                if let listType = element.listType {
                    para.listType = listType == "numbered" ? .numbered : .bullet
                    para.listLevel = element.listLevel ?? 0
                }
                doc.paragraphs.append(para)
                doc.elements.append(.paragraph(para))
            }
        }

        return doc
    }

    private static func buildParagraph(from element: ParsedElement) -> Paragraph {
        let para = Paragraph()

        // Alignment
        if let align = element.alignment {
            switch align {
            case "center": para.alignment = .center
            case "right": para.alignment = .right
            case "justify": para.alignment = .both
            default: para.alignment = .left
            }
        }

        // Spacing
        if let mt = element.marginTop { para.spacing.before = Double(mt) }
        if let mb = element.marginBottom { para.spacing.after = Double(mb) }
        if let lh = element.lineHeight { para.spacing.lineSpacing = Double(lh) }

        // Indentation
        if let ml = element.marginLeft { para.indentation.left = Double(ml) }
        if let mr = element.marginRight { para.indentation.right = Double(mr) }
        if let ti = element.textIndent { para.indentation.firstLine = Double(ti) }

        // Background color
        if let hex = element.backgroundColor {
            para.backgroundColor = DocXColor(hex: hex.replacingOccurrences(of: "#", with: ""))
        }

        // Paragraph borders
        if element.borderTop != nil || element.borderBottom != nil ||
           element.borderLeft != nil || element.borderRight != nil {
            para.borders = ParagraphBorders(
                top: parseCSSBorder(element.borderTop),
                bottom: parseCSSBorder(element.borderBottom),
                left: parseCSSBorder(element.borderLeft),
                right: parseCSSBorder(element.borderRight)
            )
        }

        // Runs
        if let runs = element.runs {
            for runData in runs {
                let run = buildRun(from: runData)
                para.runs.append(run)
            }
        }

        // Ensure at least one empty run
        if para.runs.isEmpty {
            para.addRun("")
        }

        return para
    }

    private static func buildRun(from data: ParsedRun) -> Run {
        // Image run — reconstruct DocImage from base64 data URI
        if data.isImage == true, let src = data.src, !src.isEmpty {
            let run = Run(text: "")
            // Parse "data:<mimeType>;base64,<encoded>" or blob URL
            if src.hasPrefix("data:") {
                let withoutScheme = src.dropFirst(5) // drop "data:"
                if let semicolon = withoutScheme.firstIndex(of: ";") {
                    let mimeType = String(withoutScheme[withoutScheme.startIndex..<semicolon])
                    let afterSemicolon = withoutScheme[withoutScheme.index(after: semicolon)...]
                    if afterSemicolon.hasPrefix("base64,") {
                        let b64 = String(afterSemicolon.dropFirst(7))
                        if let imgData = Data(base64Encoded: b64, options: .ignoreUnknownCharacters) {
                            let ext = mimeType.contains("jpeg") || mimeType.contains("jpg") ? "jpeg"
                                    : mimeType.contains("gif") ? "gif"
                                    : mimeType.contains("bmp") ? "bmp" : "png"
                            let image = DocImage(data: imgData, fileExtension: ext,
                                                 width: data.width.map { Double($0) },
                                                 height: data.height.map { Double($0) })
                            image.altText = data.alt
                            run.image = image
                        }
                    }
                }
            }
            return run
        }

        var formatting = TextFormatting()
        formatting.bold = data.bold ?? false
        formatting.italic = data.italic ?? false
        formatting.underline = (data.underline ?? false) ? .single : nil
        formatting.strikethrough = data.strikethrough ?? false
        formatting.superscript = data.superscript ?? false
        formatting.subscriptText = data.subscriptText ?? false
        formatting.allCaps = data.allCaps ?? false
        formatting.smallCaps = data.smallCaps ?? false

        if let size = data.fontSize {
            formatting.fontSize = Double(size)
        }
        if let family = data.fontFamily, family != "Calibri" {
            formatting.font = Font(name: family)
        }
        if let hex = data.color {
            formatting.color = DocXColor(hex: hex.replacingOccurrences(of: "#", with: ""))
        }
        if let hex = data.backgroundColor {
            formatting.highlight = highlightFromHex(hex)
        }

        let run = Run(text: data.text, formatting: formatting)

        // Hyperlink
        if let href = data.href, !href.isEmpty {
            let hyperlink = Hyperlink(url: href, text: data.text, tooltip: data.title)
            run.hyperlink = hyperlink
        }

        return run
    }

    private static func buildTable(from element: ParsedElement) -> Table {
        let table = Table()

        guard let rows = element.rows else { return table }

        for rowData in rows {
            let row = TableRow()
            row.isHeader = rowData.isHeader ?? false

            for cellData in (rowData.cells ?? []) {
                let cell = TableCell()
                cell.columnSpan = cellData.colspan ?? 1
                cell.rowSpan = cellData.rowspan ?? 1

                // Background color
                if let hex = cellData.backgroundColor {
                    cell.backgroundColor = DocXColor(hex: hex.replacingOccurrences(of: "#", with: ""))
                }

                // Width
                if let width = cellData.width {
                    cell.width = Double(width)
                }

                // Vertical alignment
                if let va = cellData.verticalAlign {
                    cell.verticalAlignment = VerticalAlignment(rawValue: va)
                }

                // Cell borders
                if cellData.borderTop != nil || cellData.borderBottom != nil ||
                   cellData.borderLeft != nil || cellData.borderRight != nil {
                    cell.borders = TableBorders(
                        top: parseCSSBorder(cellData.borderTop),
                        bottom: parseCSSBorder(cellData.borderBottom),
                        left: parseCSSBorder(cellData.borderLeft),
                        right: parseCSSBorder(cellData.borderRight)
                    )
                }

                // Paragraphs
                for paraData in (cellData.paragraphs ?? []) {
                    let para = buildParagraph(from: paraData)
                    cell.paragraphs.append(para)
                }

                if cell.paragraphs.isEmpty {
                    cell.addParagraph("")
                }

                row.cells.append(cell)
            }

            table.rows.append(row)
        }

        return table
    }

    private static func buildRunFromImageDataURI(_ src: String, widthCSS: String?, heightCSS: String?) -> Run {
        let run = Run(text: "")
        guard src.hasPrefix("data:") else { return run }
        let withoutScheme = src.dropFirst(5)
        guard let semicolon = withoutScheme.firstIndex(of: ";") else { return run }
        let mimeType = String(withoutScheme[withoutScheme.startIndex..<semicolon])
        let afterSemicolon = withoutScheme[withoutScheme.index(after: semicolon)...]
        guard afterSemicolon.hasPrefix("base64,") else { return run }
        let b64 = String(afterSemicolon.dropFirst(7))
        guard let imgData = Data(base64Encoded: b64, options: .ignoreUnknownCharacters) else { return run }
        let ext = mimeType.contains("jpeg") || mimeType.contains("jpg") ? "jpeg"
                : mimeType.contains("gif") ? "gif"
                : mimeType.contains("bmp") ? "bmp" : "png"
        func parseCSSPx(_ css: String?) -> Double? {
            guard let css else { return nil }
            return Double(css.replacingOccurrences(of: "px", with: "")
                            .replacingOccurrences(of: "pt", with: ""))
        }
        let image = DocImage(data: imgData, fileExtension: ext,
                             width: parseCSSPx(widthCSS),
                             height: parseCSSPx(heightCSS))
        run.image = image
        return run
    }

    private static func buildShape(from element: ParsedElement) -> Shape {
        let shapeType = ShapeType(rawValue: element.shapeType ?? "rectangle") ?? .rectangle
        let shape = Shape(shapeType: shapeType)
        shape.width = element.width
        shape.height = element.height
        shape.border = element.border
        shape.backgroundColor = element.backgroundColor
        shape.borderRadius = element.borderRadius
        shape.imageSrc = element.imageSrc
        shape.strokeColor = element.strokeColor
        return shape
    }

    private static func buildChart(from element: ParsedElement) -> Chart {
        let chartType: ChartType
        switch element.chartType ?? "bar" {
        case "line": chartType = .line
        case "pie": chartType = .pie
        case "doughnut": chartType = .doughnut
        case "area": chartType = .area
        default: chartType = .bar
        }

        let chart = Chart(chartType: chartType, title: element.title)
        if let id = element.chartId {
            chart.chartId = id
        }

        if let pos = element.legendPosition {
            switch pos {
            case "top": chart.legendPosition = .top
            case "bottom": chart.legendPosition = .bottom
            case "left": chart.legendPosition = .left
            case "right": chart.legendPosition = .right
            default: chart.legendPosition = .none
            }
        }

        if let dir = element.barDirection {
            chart.barDirection = BarDirection(rawValue: dir)
        }
        if let grp = element.barGrouping {
            chart.barGrouping = BarGrouping(rawValue: grp)
        }

        if let seriesData = element.series {
            chart.series = seriesData.map { s in
                ChartSeries(name: s.name, categories: s.categories, values: s.values)
            }
        }

        return chart
    }

    // MARK: - Helpers

    private static func highlightFromHex(_ hex: String) -> HighlightColor? {
        let cleaned = hex.lowercased().replacingOccurrences(of: "#", with: "")
        switch cleaned {
        case "ffff00": return .yellow
        case "00ff00": return .green
        case "00ffff": return .cyan
        case "ff00ff": return .magenta
        case "0000ff": return .blue
        case "ff0000": return .red
        case "00008b": return .darkBlue
        case "008b8b": return .darkCyan
        case "006400": return .darkGreen
        case "8b008b": return .darkMagenta
        case "8b0000": return .darkRed
        case "8b8b00": return .darkYellow
        case "a9a9a9": return .darkGray
        case "d3d3d3": return .lightGray
        case "000000": return .black
        default: return nil
        }
    }

    private static func parseCSSBorder(_ css: String?) -> Border? {
        guard let css, !css.isEmpty else { return nil }
        // CSS border format: "1px solid #000000"
        let parts = css.components(separatedBy: " ")
        guard parts.count >= 2 else { return nil }

        let width = Double(parts[0].replacingOccurrences(of: "pt", with: "").replacingOccurrences(of: "px", with: "")) ?? 0.5
        let styleStr = parts.count > 1 ? parts[1] : "solid"
        let colorStr = parts.count > 2 ? parts[2] : "#000000"

        let style: BorderStyle
        switch styleStr {
        case "solid": style = .single
        case "double": style = .double
        case "dotted": style = .dotted
        case "dashed": style = .dashed
        case "none": style = .none
        default: style = .single
        }

        let color = DocXColor(hex: colorStr.replacingOccurrences(of: "#", with: ""))

        return Border(style: style, width: width, color: color)
    }
}

// MARK: - Codable Models for JSON Decoding

private struct ParsedDocument: Decodable {
    let elements: [ParsedElement]
}

private struct ParsedElement: Decodable {
    let type: String
    let runs: [ParsedRun]?
    let alignment: String?
    let marginTop: Float?
    let marginBottom: Float?
    let lineHeight: Float?
    let marginLeft: Float?
    let marginRight: Float?
    let textIndent: Float?
    let level: Int?          // heading level
    let listType: String?    // "bullet" or "numbered"
    let listLevel: Int?
    // Paragraph border fields
    let borderTop: String?
    let borderBottom: String?
    let borderLeft: String?
    let borderRight: String?
    let rows: [ParsedRow]?   // table rows
    // Chart fields
    let chartId: String?
    let chartType: String?
    let title: String?
    let legendPosition: String?
    let barDirection: String?
    let barGrouping: String?
    let series: [ParsedChartSeries]?
    // Shape fields
    let shapeType: String?
    let width: String?
    let height: String?
    let border: String?
    let backgroundColor: String?
    let borderRadius: String?
    let imageSrc: String?
    let strokeColor: String?
}

private struct ParsedChartSeries: Decodable {
    let name: String
    let categories: [String]
    let values: [Double]
}

private struct ParsedRun: Decodable {
    let text: String
    let bold: Bool?
    let italic: Bool?
    let underline: Bool?
    let strikethrough: Bool?
    let superscript: Bool?
    let subscriptText: Bool?
    let allCaps: Bool?
    let smallCaps: Bool?
    let fontSize: Float?
    let fontFamily: String?
    let color: String?
    let backgroundColor: String?
    let href: String?
    let title: String?
    let isImage: Bool?
    let src: String?
    let width: Float?
    let height: Float?
    let alt: String?
}

private struct ParsedRow: Decodable {
    let cells: [ParsedCell]?
    let isHeader: Bool?
}

private struct ParsedCell: Decodable {
    let paragraphs: [ParsedElement]?
    let colspan: Int?
    let rowspan: Int?
    let backgroundColor: String?
    let borderTop: String?
    let borderBottom: String?
    let borderLeft: String?
    let borderRight: String?
    let width: Float?
    let verticalAlign: String?
}
