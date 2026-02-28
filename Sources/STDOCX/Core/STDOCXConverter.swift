import Foundation
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif
import STKit

/// Converts between NSAttributedString and SwiftDocX Document
public enum STDOCXConverter {

    // MARK: - NSAttributedString → Document

    /// Convert NSAttributedString to a SwiftDocX Document for saving
    static func toDocument(_ attributedString: NSAttributedString) -> Document {
        let doc = Document()
        let fullText = attributedString.string
        let paragraphTexts = fullText.components(separatedBy: "\n")

        var location = 0
        for paraText in paragraphTexts {
            let paragraph = doc.addParagraph()
            let paraRange = NSRange(location: location, length: paraText.count)

            // Extract paragraph-level alignment
            if paraText.count > 0 {
                let firstCharAttrs = attributedString.attributes(at: paraRange.location, effectiveRange: nil)
                if let pStyle = firstCharAttrs[.paragraphStyle] as? NSParagraphStyle {
                    paragraph.alignment = pStyle.alignment.toDocXAlignment()
                }
            }

            // Enumerate runs within this paragraph
            attributedString.enumerateAttributes(in: paraRange, options: []) { attrs, range, _ in
                let runText = (attributedString.string as NSString).substring(with: range)
                let formatting = textFormatting(from: attrs)
                paragraph.addRun(runText, formatting: formatting)
            }

            // Ensure at least one empty run
            if paragraph.runs.isEmpty {
                paragraph.addRun("")
            }

            location += paraText.count + 1
        }

        return doc
    }

    // MARK: - Document → NSAttributedString

    /// Convert SwiftDocX Document to NSAttributedString for display/editing
    static func toAttributedString(_ document: Document) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let defaultFont = PlatformFont(name: "Calibri", size: 11) ?? PlatformFont.systemFont(ofSize: 11)

        // Use elements if available (newly created docs), fallback to paragraphs (read from file)
        if !document.elements.isEmpty {
            for (index, element) in document.elements.enumerated() {
                switch element {
                case .paragraph(let paragraph):
                    let paraString = attributedString(from: paragraph, defaultFont: defaultFont)
                    result.append(paraString)
                    if index < document.elements.count - 1 {
                        result.append(NSAttributedString(string: "\n"))
                    }
                case .table:
                    let tableText = NSAttributedString(
                        string: "[Table]\n",
                        attributes: [.font: defaultFont, .foregroundColor: PlatformColor.secondaryLabel]
                    )
                    result.append(tableText)
                case .chart(let chart):
                    let chartTitle = chart.title ?? "Chart"
                    let chartText = NSAttributedString(
                        string: "[Chart: \(chartTitle)]\n",
                        attributes: [.font: defaultFont, .foregroundColor: PlatformColor.secondaryLabel]
                    )
                    result.append(chartText)
                case .shape(let shape):
                    let shapeText = NSAttributedString(
                        string: "[Shape: \(shape.shapeType.rawValue)]\n",
                        attributes: [.font: defaultFont, .foregroundColor: PlatformColor.secondaryLabel]
                    )
                    result.append(shapeText)
                }
            }
        } else {
            for (index, paragraph) in document.paragraphs.enumerated() {
                let paraString = attributedString(from: paragraph, defaultFont: defaultFont)
                result.append(paraString)
                if index < document.paragraphs.count - 1 {
                    result.append(NSAttributedString(string: "\n"))
                }
            }
        }

        return result
    }

    // MARK: - Read helpers

    /// Read a DOCX file and return NSAttributedString
    public static func readFile(at url: URL) -> NSAttributedString? {
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "docx", "doc":
            guard let doc = try? Document(contentsOf: url) else { return nil }
            return toAttributedString(doc)
        case "txt":
            guard let text = try? String(contentsOf: url, encoding: .utf8) else { return nil }
            let font = PlatformFont(name: "Calibri", size: 11) ?? PlatformFont.systemFont(ofSize: 11)
            return NSAttributedString(string: text, attributes: [.font: font])
        case "rtf":
            guard let data = try? Data(contentsOf: url) else { return nil }
            return try? NSAttributedString(
                data: data,
                options: [.documentType: NSAttributedString.DocumentType.rtf],
                documentAttributes: nil
            )
        default:
            return nil
        }
    }

    // MARK: - Private Helpers

    private static func textFormatting(from attrs: [NSAttributedString.Key: Any]) -> TextFormatting {
        var bold = false
        var italic = false
        var underline: UnderlineStyle? = nil
        var strikethrough = false
        var font: Font? = nil
        var color: DocXColor? = nil
        var fontSize: Double? = nil

        if let uiFont = attrs[.font] as? PlatformFont {
            let traits = uiFont.fontDescriptor.symbolicTraits
            #if os(iOS)
            bold = traits.contains(.traitBold)
            italic = traits.contains(.traitItalic)
            font = Font(name: uiFont.familyName)
            #elseif os(macOS)
            bold = traits.contains(.bold)
            italic = traits.contains(.italic)
            font = Font(name: uiFont.familyName ?? "Calibri")
            #endif
            fontSize = Double(uiFont.pointSize)
        }

        if let underlineValue = attrs[.underlineStyle] as? Int, underlineValue != 0 {
            underline = .single
        }

        if let strikeThroughValue = attrs[.strikethroughStyle] as? Int, strikeThroughValue != 0 {
            strikethrough = true
        }

        if let uiColor = attrs[.foregroundColor] as? PlatformColor {
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            #if os(macOS)
            let convertedColor = uiColor.usingColorSpace(.sRGB) ?? uiColor
            convertedColor.getRed(&r, green: &g, blue: &b, alpha: &a)
            #else
            uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
            #endif
            if !(r == 0 && g == 0 && b == 0 && a == 1) {
                color = DocXColor(red: UInt8(r * 255), green: UInt8(g * 255), blue: UInt8(b * 255))
            }
        }

        return TextFormatting(
            bold: bold,
            italic: italic,
            underline: underline,
            strikethrough: strikethrough,
            font: font,
            color: color,
            fontSize: fontSize
        )
    }

    private static func attributedString(from paragraph: Paragraph, defaultFont: PlatformFont) -> NSAttributedString {
        let result = NSMutableAttributedString()

        let headingFont: PlatformFont? = {
            guard let level = paragraph.headingLevel else { return nil }
            let size: CGFloat
            switch level {
            case .heading1: size = 24
            case .heading2: size = 18
            case .heading3: size = 14
            case .heading4: size = 12
            case .heading5: size = 11
            case .heading6: size = 11
            }
            return PlatformFont.boldSystemFont(ofSize: size)
        }()

        for run in paragraph.runs {
            var attrs: [NSAttributedString.Key: Any] = [:]

            let baseSize = run.formatting.fontSize ?? Double(headingFont?.pointSize ?? defaultFont.pointSize)
            #if os(iOS)
            let fontName = run.formatting.font?.name ?? (headingFont?.familyName ?? defaultFont.familyName)
            #elseif os(macOS)
            let fontName = run.formatting.font?.name ?? (headingFont?.familyName ?? defaultFont.familyName ?? "Calibri")
            #endif
            var uiFont = PlatformFont(name: fontName, size: CGFloat(baseSize)) ?? PlatformFont.systemFont(ofSize: CGFloat(baseSize))

            #if os(iOS)
            var traits: PlatformFontDescriptor.SymbolicTraits = []
            if run.formatting.bold || headingFont != nil { traits.insert(.traitBold) }
            if run.formatting.italic { traits.insert(.traitItalic) }
            if let descriptor = uiFont.fontDescriptor.withSymbolicTraits(traits) {
                uiFont = PlatformFont(descriptor: descriptor, size: 0)
            }
            #elseif os(macOS)
            var traits: PlatformFontDescriptor.SymbolicTraits = []
            if run.formatting.bold || headingFont != nil { traits.insert(.bold) }
            if run.formatting.italic { traits.insert(.italic) }
            let descriptor = uiFont.fontDescriptor.withSymbolicTraits(traits)
            uiFont = PlatformFont(descriptor: descriptor, size: 0) ?? uiFont
            #endif
            attrs[.font] = uiFont

            if run.formatting.underline != nil {
                attrs[.underlineStyle] = NSUnderlineStyle.single.rawValue
            }

            if run.formatting.strikethrough {
                attrs[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
            }

            if let docColor = run.formatting.color {
                attrs[.foregroundColor] = PlatformColor(
                    red: CGFloat(docColor.red) / 255.0,
                    green: CGFloat(docColor.green) / 255.0,
                    blue: CGFloat(docColor.blue) / 255.0,
                    alpha: 1.0
                )
            }

            if let highlight = run.formatting.highlight {
                attrs[.backgroundColor] = PlatformColor.st_from(highlight: highlight)
            }

            result.append(NSAttributedString(string: run.text, attributes: attrs))
        }

        // Apply paragraph-level alignment
        if let alignment = paragraph.alignment {
            let style = NSMutableParagraphStyle()
            style.alignment = alignment.toNSTextAlignment()
            result.addAttribute(.paragraphStyle, value: style, range: NSRange(location: 0, length: result.length))
        }

        return result
    }
}

// MARK: - Alignment Extensions

private extension NSTextAlignment {
    func toDocXAlignment() -> ParagraphAlignment? {
        switch self {
        case .left: return .left
        case .center: return .center
        case .right: return .right
        case .justified: return .both
        default: return nil
        }
    }
}

private extension ParagraphAlignment {
    func toNSTextAlignment() -> NSTextAlignment {
        switch self {
        case .left: return .left
        case .center: return .center
        case .right: return .right
        case .both, .distribute: return .justified
        }
    }
}

// MARK: - Highlight Color

extension PlatformColor {
    static func st_from(highlight: HighlightColor) -> PlatformColor {
        switch highlight {
        case .yellow: return .systemYellow
        case .green: return .systemGreen
        case .cyan: return .systemCyan
        case .magenta: return .systemPink
        case .blue: return .systemBlue
        case .red: return .systemRed
        case .darkBlue: return PlatformColor(red: 0, green: 0, blue: 0.55, alpha: 1)
        case .darkCyan: return PlatformColor(red: 0, green: 0.55, blue: 0.55, alpha: 1)
        case .darkGreen: return PlatformColor(red: 0, green: 0.39, blue: 0, alpha: 1)
        case .darkMagenta: return PlatformColor(red: 0.55, green: 0, blue: 0.55, alpha: 1)
        case .darkRed: return PlatformColor(red: 0.55, green: 0, blue: 0, alpha: 1)
        case .darkYellow: return PlatformColor(red: 0.55, green: 0.55, blue: 0, alpha: 1)
        case .darkGray: return .darkGray
        case .lightGray: return .lightGray
        case .black: return .black
        }
    }
}
