import Foundation

/// Resolves paragraph styles from styles.xml and applies defaults to paragraphs/runs
enum ParagraphStyleResolver {

    /// Resolve paragraph styles: apply style-defined formatting as defaults
    /// to paragraphs and their runs that don't have explicit inline formatting.
    static func resolve(elements: inout [DocumentElement], styles: [String: ParagraphStyleDefinition]) {
        for element in elements {
            switch element {
            case .paragraph(let para):
                resolveParagraph(para, styles: styles)
            case .table(let table):
                for row in table.rows {
                    for cell in row.cells {
                        for para in cell.paragraphs {
                            resolveParagraph(para, styles: styles)
                        }
                    }
                }
            default:
                break
            }
        }
    }

    /// Resolve a single paragraph's style
    private static func resolveParagraph(_ para: Paragraph, styles: [String: ParagraphStyleDefinition]) {
        guard let styleId = para.pStyleId else { return }

        // Build resolved style by walking the inheritance chain
        let resolved = resolveStyleChain(styleId: styleId, styles: styles)

        // Apply paragraph-level defaults (only if paragraph doesn't have explicit values)
        if para.alignment == nil, let alignment = resolved.alignment {
            para.alignment = alignment
        }
        if para.spacing.before == nil, let before = resolved.spacingBefore {
            para.spacing.before = before
        }
        if para.spacing.after == nil, let after = resolved.spacingAfter {
            para.spacing.after = after
        }
        if para.spacing.lineSpacing == nil, let lineSpacing = resolved.lineSpacing {
            para.spacing.lineSpacing = lineSpacing
        }
        if para.indentation.left == nil, let left = resolved.indentLeft {
            para.indentation.left = left
        }
        if para.indentation.right == nil, let right = resolved.indentRight {
            para.indentation.right = right
        }
        if para.indentation.firstLine == nil, let firstLine = resolved.indentFirstLine {
            para.indentation.firstLine = firstLine
        }
        if para.backgroundColor == nil, let bg = resolved.backgroundColor {
            para.backgroundColor = bg
        }
        if para.borders == nil, let borders = resolved.borders {
            para.borders = borders
        }

        // Apply run-level defaults: for each run without explicit formatting,
        // fill in style defaults
        for run in para.runs {
            applyRunDefaults(run, from: resolved)
        }
    }

    /// Apply style defaults to a run's formatting (only fills in missing values)
    private static func applyRunDefaults(_ run: Run, from style: ParagraphStyleDefinition) {
        // Bold: only apply if run doesn't explicitly set it and style says bold
        if !run.formatting.bold, let bold = style.bold, bold {
            run.formatting.bold = true
        }

        // Italic
        if !run.formatting.italic, let italic = style.italic, italic {
            run.formatting.italic = true
        }

        // Underline
        if run.formatting.underline == nil, let underline = style.underline {
            run.formatting.underline = underline
        }

        // Strikethrough
        if !run.formatting.strikethrough, let strike = style.strikethrough, strike {
            run.formatting.strikethrough = true
        }

        // Color
        if run.formatting.color == nil, let color = style.color {
            run.formatting.color = color
        }

        // Font
        if run.formatting.font == nil, let font = style.font {
            run.formatting.font = font
        }

        // Font size
        if run.formatting.fontSize == nil, let fontSize = style.fontSize {
            run.formatting.fontSize = fontSize
        }

        // All caps
        if !run.formatting.allCaps, let allCaps = style.allCaps, allCaps {
            run.formatting.allCaps = true
        }

        // Small caps
        if !run.formatting.smallCaps, let smallCaps = style.smallCaps, smallCaps {
            run.formatting.smallCaps = true
        }
    }

    /// Walk the basedOn chain to build a fully resolved style definition
    private static func resolveStyleChain(styleId: String, styles: [String: ParagraphStyleDefinition]) -> ParagraphStyleDefinition {
        var chain: [ParagraphStyleDefinition] = []
        var visited = Set<String>()
        var currentId: String? = styleId

        // Walk up the chain
        while let id = currentId, !visited.contains(id) {
            visited.insert(id)
            if let style = styles[id] {
                chain.append(style)
                currentId = style.basedOn
            } else {
                break
            }
        }

        // Merge from base to derived (base first, then overrides)
        guard let first = chain.first else {
            return ParagraphStyleDefinition(styleId: styleId)
        }

        if chain.count == 1 { return first }

        // Start from the most base style and overlay
        var resolved = chain.last!
        for style in chain.dropLast().reversed() {
            // Run properties — derived overrides base
            if let v = style.bold { resolved.bold = v }
            if let v = style.italic { resolved.italic = v }
            if let v = style.underline { resolved.underline = v }
            if let v = style.strikethrough { resolved.strikethrough = v }
            if let v = style.color { resolved.color = v }
            if let v = style.font { resolved.font = v }
            if let v = style.fontSize { resolved.fontSize = v }
            if let v = style.allCaps { resolved.allCaps = v }
            if let v = style.smallCaps { resolved.smallCaps = v }

            // Paragraph properties
            if let v = style.alignment { resolved.alignment = v }
            if let v = style.spacingBefore { resolved.spacingBefore = v }
            if let v = style.spacingAfter { resolved.spacingAfter = v }
            if let v = style.lineSpacing { resolved.lineSpacing = v }
            if let v = style.indentLeft { resolved.indentLeft = v }
            if let v = style.indentRight { resolved.indentRight = v }
            if let v = style.indentFirstLine { resolved.indentFirstLine = v }
            if let v = style.backgroundColor { resolved.backgroundColor = v }
            if let v = style.borders { resolved.borders = v }
        }

        resolved.styleId = first.styleId
        return resolved
    }
}
