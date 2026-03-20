import Foundation

/// Error types for document reading operations
public enum DocumentReaderError: Error, LocalizedError {
    case fileNotFound(String)
    case invalidDocument(String)
    case parsingFailed(String)

    public var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):
            return "Document not found: \(path)"
        case .invalidDocument(let detail):
            return "Invalid Word document: \(detail)"
        case .parsingFailed(let detail):
            return "Failed to parse document: \(detail)"
        }
    }
}

/// Reads Word documents from .docx files
public class DocumentReader {
    private let zipReader: ZIPReader

    public init() {
        self.zipReader = ZIPReader()
    }

    /// Reads document elements (paragraphs, tables, and charts) from a .docx file
    public func read(from url: URL) throws -> [DocumentElement] {
        let doc = try readDocument(from: url)
        return doc.elements
    }

    /// Reads a full Document from a .docx file, preserving original styles/theme data for round-trip fidelity
    public func readDocument(from url: URL) throws -> Document {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw DocumentReaderError.fileNotFound(url.path)
        }

        // Read relationships to resolve chart references
        var relationships: [String: DocumentRelationship] = [:]
        if let relsData = try? zipReader.readEntry(at: url, entryPath: "word/_rels/document.xml.rels") {
            let relParser = RelationshipParser()
            relationships = relParser.parse(relsData)
        }

        // Parse theme.xml for theme color resolution
        var themeColors: ThemeColorScheme?
        let themePath = relationships.values.first { $0.type.contains("theme") }?.target ?? "theme/theme1.xml"
        let themeFullPath = "word/\(themePath)"
        let themeData = try? zipReader.readEntry(at: url, entryPath: themeFullPath)
        if let themeData {
            themeColors = ThemeParser().parse(themeData)
        }

        // Read document.xml from the archive
        let documentData: Data
        do {
            documentData = try zipReader.readEntry(at: url, entryPath: "word/document.xml")
        } catch {
            throw DocumentReaderError.invalidDocument("Could not read document.xml: \(error.localizedDescription)")
        }

        // Parse the XML content (fresh parser each time to avoid reuse issues)
        let xmlParser = DocumentXMLParser()
        let elements: [DocumentElement]
        do {
            elements = try xmlParser.parseDocumentXML(documentData, relationships: relationships, themeColors: themeColors)
        } catch {
            throw DocumentReaderError.parsingFailed(error.localizedDescription)
        }

        // Resolve chart placeholders: read and parse chart XML for each chart element
        var resolved: [DocumentElement] = []
        for element in elements {
            if case .chart(let chart) = element, let relId = chart.relationshipId {
                if let rel = relationships[relId],
                   rel.type.contains("chart") {
                    let ct = rel.target
                    let chartPath = ct.hasPrefix("/") ? String(ct.dropFirst()) : "word/\(ct)"
                    if let chartData = try? zipReader.readEntry(at: url, entryPath: chartPath) {
                        let chartParser = ChartXMLParser()
                        if let parsedChart = chartParser.parse(chartData) {
                            parsedChart.chartId = chart.chartId
                            parsedChart.relationshipId = relId
                            parsedChart.entryPath = chartPath
                            parsedChart.width = chart.width
                            parsedChart.height = chart.height
                            parsedChart.originalChartXML = chartData
                            resolved.append(.chart(parsedChart))
                            continue
                        }
                    }
                }
            }
            resolved.append(element)
        }

        // Resolve styles from styles.xml
        // Try word/styles.xml first, then word/styles2.xml (some templates use this)
        let stylesData: Data? = (try? zipReader.readEntry(at: url, entryPath: "word/styles.xml"))
            ?? (try? zipReader.readEntry(at: url, entryPath: "word/styles2.xml"))

        if let stylesData {
            // Resolve table styles
            let hasStyledTables = resolved.contains { element in
                if case .table(let table) = element { return table.styleName != nil }
                return false
            }
            if hasStyledTables {
                let tableStyleParser = TableStyleParser()
                tableStyleParser.themeColors = themeColors
                let tableStyles = tableStyleParser.parse(stylesData)
                if !tableStyles.isEmpty {
                    TableStyleResolver.resolve(elements: &resolved, styles: tableStyles)
                }
            }

            // Resolve paragraph styles
            let paragraphStyleParser = ParagraphStyleParser()
            paragraphStyleParser.themeColors = themeColors
            let paragraphStyles = paragraphStyleParser.parse(stylesData)
            if !paragraphStyles.isEmpty {
                ParagraphStyleResolver.resolve(elements: &resolved, styles: paragraphStyles)
            }
        }

        // Resolve inline image data from word/media/
        resolveImages(in: &resolved, relationships: relationships, docURL: url)

        // Build Document with preserved original data
        let document = Document()
        document.elements = resolved
        for element in resolved {
            switch element {
            case .paragraph(let p): document.paragraphs.append(p)
            case .table(let t): document.tables.append(t)
            case .chart(let c): document.charts.append(c)
            case .shape(let s): document.shapes.append(s)
            }
        }
        // Preserve original styles and theme for round-trip fidelity
        document.originalStylesData = stylesData
        document.originalThemeData = themeData
        document.themeEntryPath = themeFullPath

        return document
    }

    /// Fills in image data for runs that have image placeholders (relationshipId set, data empty)
    private func resolveImages(in elements: inout [DocumentElement],
                               relationships: [String: DocumentRelationship],
                               docURL: URL) {
        for element in elements {
            switch element {
            case .paragraph(let para):
                fillImages(in: para, relationships: relationships, docURL: docURL)
            case .table(let table):
                for row in table.rows {
                    for cell in row.cells {
                        for para in cell.paragraphs {
                            fillImages(in: para, relationships: relationships, docURL: docURL)
                        }
                    }
                }
            default:
                break
            }
        }
    }

    private func fillImages(in para: Paragraph,
                            relationships: [String: DocumentRelationship],
                            docURL: URL) {
        for run in para.runs {
            guard let image = run.image,
                  let relId = image.relationshipId,
                  image.data.isEmpty else { continue }
            guard let rel = relationships[relId], rel.type.contains("image") else { continue }
            // Target may be absolute ("/word/media/image1.jpeg") or relative ("media/image1.jpeg")
            let target = rel.target
            let mediaPath = target.hasPrefix("/") ? String(target.dropFirst()) : "word/\(target)"
            guard let data = try? zipReader.readEntry(at: docURL, entryPath: mediaPath),
                  !data.isEmpty else { continue }
            image.data = data
            if let ext = rel.target.components(separatedBy: ".").last {
                image.fileExtension = ext.lowercased()
            }
        }
    }

    /// Lists the contents of a .docx file (for debugging)
    public func listContents(at url: URL) throws -> [String] {
        return try zipReader.listEntries(at: url)
    }
}
