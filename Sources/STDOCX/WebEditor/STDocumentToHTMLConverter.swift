import Foundation
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif
import STKit

/// Converts a SwiftDocX Document model to HTML string for WKWebView editing
enum STDocumentToHTMLConverter {

    /// Convert a Document to a full HTML string (body content only, no wrapper)
    static func toHTML(_ document: Document) -> String {
        var html = ""

        // Use elements if available (newly created docs), fallback to paragraphs
        if !document.elements.isEmpty {
            for element in document.elements {
                switch element {
                case .paragraph(let paragraph):
                    html += paragraphToHTML(paragraph)
                case .table(let table):
                    html += tableToHTML(table)
                case .chart(let chart):
                    html += chartToHTML(chart)
                case .shape(let shape):
                    html += shapeToHTML(shape)
                }
            }
        } else {
            for paragraph in document.paragraphs {
                html += paragraphToHTML(paragraph)
            }
        }

        // If empty, provide a single empty paragraph for editing
        if html.isEmpty {
            html = "<p><br></p>"
        }

        return html
    }

    /// Convert plain text to HTML (for legacy DOC files with extracted text)
    static func plainTextToHTML(_ text: String) -> String {
        let escaped = escapeHTML(text)
        let paragraphs = escaped.components(separatedBy: "\n")
        return paragraphs.map { "<p>\($0.isEmpty ? "<br>" : $0)</p>" }.joined()
    }

    // MARK: - Paragraph

    private static func paragraphToHTML(_ paragraph: Paragraph) -> String {
        // Heading
        if let level = paragraph.headingLevel {
            let tag = "h\(level.rawValue)"
            let style = paragraphStyle(paragraph)
            let content = runsToHTML(paragraph.runs)
            return "<\(tag)\(style)>\(content.isEmpty ? "<br>" : content)</\(tag)>"
        }

        // List item
        if let listType = paragraph.listType {
            let tag = listType == .bullet ? "ul" : "ol"
            let style = paragraphStyle(paragraph)
            let content = runsToHTML(paragraph.runs)
            // Each list item wrapped in its own list (simplified for contentEditable)
            return "<\(tag)\(style)><li>\(content.isEmpty ? "<br>" : content)</li></\(tag)>"
        }

        // Normal paragraph
        let style = paragraphStyle(paragraph)
        let content = runsToHTML(paragraph.runs)
        return "<p\(style)>\(content.isEmpty ? "<br>" : content)</p>"
    }

    private static func paragraphStyle(_ paragraph: Paragraph) -> String {
        var css: [String] = []

        if let alignment = paragraph.alignment {
            switch alignment {
            case .left: break // default
            case .center: css.append("text-align:center")
            case .right: css.append("text-align:right")
            case .both, .distribute: css.append("text-align:justify")
            }
        }

        if let before = paragraph.spacing.before, before > 0 {
            css.append("margin-top:\(before)pt")
        }
        if let after = paragraph.spacing.after, after > 0 {
            css.append("margin-bottom:\(after)pt")
        }
        if let lineSpacing = paragraph.spacing.lineSpacing, lineSpacing > 0 {
            css.append("line-height:\(lineSpacing)")
        }

        if let left = paragraph.indentation.left, left > 0 {
            css.append("margin-left:\(left)pt")
        }
        if let right = paragraph.indentation.right, right > 0 {
            css.append("margin-right:\(right)pt")
        }
        if let firstLine = paragraph.indentation.firstLine {
            if firstLine > 0 {
                css.append("text-indent:\(firstLine)pt")
            } else if firstLine < 0 {
                css.append("text-indent:\(firstLine)pt")
            }
        }

        if paragraph.pageBreakBefore {
            css.append("page-break-before:always")
        }

        // Background color
        if let bg = paragraph.backgroundColor {
            css.append("background-color:#\(bg.hexString)")
            css.append("padding:4px 8px")
        }

        // Paragraph borders
        if let borders = paragraph.borders {
            if let b = borders.top { css.append("border-top:\(borderToCSS(b))") }
            if let b = borders.bottom { css.append("border-bottom:\(borderToCSS(b))") }
            if let b = borders.left { css.append("border-left:\(borderToCSS(b))") }
            if let b = borders.right { css.append("border-right:\(borderToCSS(b))") }
        }

        return css.isEmpty ? "" : " style=\"\(css.joined(separator: ";"))\""
    }

    // MARK: - Runs

    private static func runsToHTML(_ runs: [Run]) -> String {
        runs.map { runToHTML($0) }.joined()
    }

    private static func runToHTML(_ run: Run) -> String {
        // Image
        if let image = run.image {
            return imageToHTML(image)
        }

        let text = escapeHTML(run.text)
        if text.isEmpty { return "" }

        var css: [String] = []
        var openTags = ""
        var closeTags = ""

        let fmt = run.formatting

        // Font
        if let font = fmt.font {
            css.append("font-family:'\(font.name)'")
        }
        if let size = fmt.fontSize {
            css.append("font-size:\(size)pt")
        }
        if let color = fmt.color {
            css.append("color:#\(color.hexString)")
        }
        if let highlight = fmt.highlight {
            css.append("background-color:\(highlightToCSS(highlight))")
        }

        // Bold
        if fmt.bold {
            openTags += "<b>"
            closeTags = "</b>" + closeTags
        }
        // Italic
        if fmt.italic {
            openTags += "<i>"
            closeTags = "</i>" + closeTags
        }
        // Underline
        if fmt.underline != nil {
            openTags += "<u>"
            closeTags = "</u>" + closeTags
        }
        // Strikethrough
        if fmt.strikethrough {
            openTags += "<s>"
            closeTags = "</s>" + closeTags
        }
        // Superscript
        if fmt.superscript {
            openTags += "<sup>"
            closeTags = "</sup>" + closeTags
        }
        // Subscript
        if fmt.subscriptText {
            openTags += "<sub>"
            closeTags = "</sub>" + closeTags
        }
        // All caps
        if fmt.allCaps {
            css.append("text-transform:uppercase")
        }
        // Small caps
        if fmt.smallCaps {
            css.append("font-variant:small-caps")
        }

        // Hyperlink
        if let hyperlink = run.hyperlink {
            let href = escapeHTMLAttribute(hyperlink.url)
            let tooltip = hyperlink.tooltip.map { " title=\"\(escapeHTMLAttribute($0))\"" } ?? ""
            return "<a href=\"\(href)\"\(tooltip)>\(openTags)<span\(styleAttr(css))>\(text)</span>\(closeTags)</a>"
        }

        if css.isEmpty && openTags.isEmpty {
            return text
        }

        if css.isEmpty {
            return "\(openTags)\(text)\(closeTags)"
        }

        return "\(openTags)<span\(styleAttr(css))>\(text)</span>\(closeTags)"
    }

    // MARK: - Table

    private static func tableToHTML(_ table: Table) -> String {
        var css: [String] = ["border-collapse:collapse", "width:100%", "margin:8px 0"]

        if let width = table.width {
            css.append("width:\(width)pt")
        }
        if let alignment = table.alignment {
            switch alignment {
            case .center: css.append("margin-left:auto;margin-right:auto")
            case .right: css.append("margin-left:auto;margin-right:0")
            default: break
            }
        }

        var html = "<table\(styleAttr(css))>"

        for row in table.rows {
            html += "<tr\(rowStyle(row))>"
            var gridColIdx = 0  // Track actual grid column index (accounts for column spans)
            for cell in row.cells {
                let tag = row.isHeader ? "th" : "td"
                let cellCSS = cellStyle(cell, tableBorders: table.borders, gridColIdx: gridColIdx, colWidths: table.columnWidths)

                var attrs = styleAttr(cellCSS)
                if cell.columnSpan > 1 {
                    attrs += " colspan=\"\(cell.columnSpan)\""
                }
                if cell.rowSpan > 1 {
                    attrs += " rowspan=\"\(cell.rowSpan)\""
                }

                html += "<\(tag)\(attrs)>"
                if cell.paragraphs.isEmpty {
                    html += "<br>"
                } else {
                    for para in cell.paragraphs {
                        html += paragraphToHTML(para)
                    }
                }
                html += "</\(tag)>"
                gridColIdx += cell.columnSpan
            }
            html += "</tr>"
        }

        html += "</table>"
        return html
    }

    private static func rowStyle(_ row: TableRow) -> String {
        var css: [String] = []
        if let height = row.height {
            css.append("height:\(height)pt")
        }
        return css.isEmpty ? "" : " style=\"\(css.joined(separator: ";"))\""
    }

    private static func cellStyle(_ cell: TableCell, tableBorders: TableBorders, gridColIdx: Int, colWidths: [Double?]) -> [String] {
        var css: [String] = ["padding:3px 5px"]

        // Cell width: use explicit cell width, or sum grid column widths for spanned cells
        if let width = cell.width {
            css.append("width:\(width)pt")
        } else if gridColIdx < colWidths.count {
            var totalWidth: Double = 0
            let endCol = min(gridColIdx + cell.columnSpan, colWidths.count)
            for i in gridColIdx..<endCol {
                totalWidth += colWidths[i] ?? 0
            }
            if totalWidth > 0 {
                css.append("width:\(totalWidth)pt")
            }
        }

        // Background color
        if let bg = cell.backgroundColor {
            css.append("background-color:#\(bg.hexString)")
        }

        // Vertical alignment
        if let va = cell.verticalAlignment {
            css.append("vertical-align:\(va.rawValue)")
        }

        // Borders: cell-level borders take priority, then table-level
        // Resolve each side: cell explicit > table explicit > insideH/V fallback
        let cellB = cell.borders
        let tblB = tableBorders

        let topBorder = cellB?.top ?? tblB.top ?? tblB.insideH
        let bottomBorder = cellB?.bottom ?? tblB.bottom ?? tblB.insideH
        let leftBorder = cellB?.left ?? tblB.left ?? tblB.insideV
        let rightBorder = cellB?.right ?? tblB.right ?? tblB.insideV

        if let b = topBorder { css.append("border-top:\(borderToCSS(b))") }
        if let b = bottomBorder { css.append("border-bottom:\(borderToCSS(b))") }
        if let b = leftBorder { css.append("border-left:\(borderToCSS(b))") }
        if let b = rightBorder { css.append("border-right:\(borderToCSS(b))") }

        return css
    }

    // MARK: - Image

    private static func imageToHTML(_ image: DocImage) -> String {
        let width = image.width ?? 200
        let height = image.height ?? 200
        let alt = escapeHTMLAttribute(image.altText ?? "Image")

        // Embed as base64 data URI
        let base64 = image.data.base64EncodedString()
        let mimeType = image.contentType
        return "<img src=\"data:\(mimeType);base64,\(base64)\" width=\"\(Int(width))\" height=\"\(Int(height))\" alt=\"\(alt)\" style=\"max-width:100%\">"
    }

    // MARK: - Border Helpers

    private static func borderToCSS(_ border: Border) -> String {
        if border.style == .none { return "none" }

        // Clamp border width: DOCX uses eighths-of-a-point which can be very large.
        // For screen display, cap at 3pt to keep it clean.
        let clampedWidth = min(max(border.width, 0.5), 3.0)
        let width = "\(clampedWidth)pt"
        let style: String
        switch border.style {
        case .none: return "none"
        case .single: style = "solid"
        case .thick: style = "solid"
        case .double: style = "double"
        case .dotted: style = "dotted"
        case .dashed, .dashSmallGap: style = "dashed"
        case .dotDash, .dotDotDash: style = "dashed"
        case .triple: style = "double"
        case .wave: style = "solid"
        }
        let color = border.color.map { "#\($0.hexString)" } ?? "#000000"
        return "\(width) \(style) \(color)"
    }

    private static func highlightToCSS(_ highlight: HighlightColor) -> String {
        switch highlight {
        case .yellow: return "#FFFF00"
        case .green: return "#00FF00"
        case .cyan: return "#00FFFF"
        case .magenta: return "#FF00FF"
        case .blue: return "#0000FF"
        case .red: return "#FF0000"
        case .darkBlue: return "#00008B"
        case .darkCyan: return "#008B8B"
        case .darkGreen: return "#006400"
        case .darkMagenta: return "#8B008B"
        case .darkRed: return "#8B0000"
        case .darkYellow: return "#8B8B00"
        case .darkGray: return "#A9A9A9"
        case .lightGray: return "#D3D3D3"
        case .black: return "#000000"
        }
    }

    // MARK: - Chart

    private static func chartToHTML(_ chart: Chart) -> String {
        guard let json = chart.toJSON() else {
            return "<p>[Chart]</p>"
        }
        let escapedJSON = escapeHTMLAttribute(json)
        return "<div class=\"st-chart-container\" contenteditable=\"false\" data-chart-id=\"\(escapeHTMLAttribute(chart.chartId))\" data-chart-json=\"\(escapedJSON)\"><canvas></canvas></div>"
    }

    // MARK: - Shape

    private static func shapeToHTML(_ shape: Shape) -> String {
        let w = shape.width ?? "200px"
        let h = shape.height ?? "120px"
        let border = shape.border ?? "2px solid #2B579A"
        let bg = shape.backgroundColor ?? "rgba(43,87,154,0.05)"

        switch shape.shapeType {
        case .rectangle:
            return "<div class=\"st-shape\" contenteditable=\"false\" style=\"width:\(w);height:\(h);border:\(border);background:\(bg);\"><div class=\"st-shape-handle\"></div></div>"

        case .circle:
            return "<div class=\"st-shape\" contenteditable=\"false\" style=\"width:\(w);height:\(h);border:\(border);background:\(bg);border-radius:50%;\"><div class=\"st-shape-handle\"></div></div>"

        case .line:
            return "<div class=\"st-shape st-shape-line\" contenteditable=\"false\" style=\"width:\(w);border-top:\(border);\"><div class=\"st-shape-handle\"></div></div>"

        case .arrow:
            let color = shape.strokeColor ?? "#2B579A"
            return """
            <div class="st-shape st-shape-arrow" contenteditable="false" style="width:\(w);height:\(h);"><svg width="100%" height="100%" viewBox="0 0 200 40" preserveAspectRatio="none"><defs><marker id="ah" markerWidth="10" markerHeight="7" refX="10" refY="3.5" orient="auto"><polygon points="0 0,10 3.5,0 7" fill="\(color)"/></marker></defs><line x1="0" y1="20" x2="180" y2="20" stroke="\(color)" stroke-width="2" marker-end="url(#ah)"/></svg><div class="st-shape-handle"></div></div>
            """

        case .image:
            if let src = shape.imageSrc {
                return "<div class=\"st-shape st-shape-image\" contenteditable=\"false\" style=\"width:\(w);max-width:400px;position:relative;\"><img src=\"\(src)\" style=\"display:block;width:100%;height:auto;\"/><div class=\"st-shape-handle\"></div></div>"
            }
            return ""
        }
    }

    // MARK: - Utility

    private static func styleAttr(_ css: [String]) -> String {
        css.isEmpty ? "" : " style=\"\(css.joined(separator: ";"))\""
    }

    private static func escapeHTML(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }

    private static func escapeHTMLAttribute(_ string: String) -> String {
        escapeHTML(string).replacingOccurrences(of: "'", with: "&#39;")
    }
}
