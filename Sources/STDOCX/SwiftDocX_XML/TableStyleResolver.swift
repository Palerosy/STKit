import Foundation

/// Applies parsed table style definitions to table cells.
/// Only fills in colors/borders where cells don't already have explicit inline values.
enum TableStyleResolver {

    /// Resolve table styles for all table elements in the document
    static func resolve(elements: inout [DocumentElement], styles: [String: TableStyleDefinition]) {
        guard !styles.isEmpty else { return }
        for i in elements.indices {
            if case .table(let table) = elements[i] {
                applyStyle(to: table, styles: styles)
            }
        }
    }

    /// Apply the referenced style to a single table
    static func applyStyle(to table: Table, styles: [String: TableStyleDefinition]) {
        guard let styleName = table.styleName,
              let styleDef = resolveStyleChain(styleName, styles: styles) else { return }

        let look = table.tblLook ?? TableLook()
        let rowCount = table.rows.count
        let colCount = table.rows.first?.cells.count ?? 0

        // Apply table-level borders from style if table has no explicit borders
        if let wholeTable = styleDef.conditions[.wholeTable],
           let styleBorders = wholeTable.borders {
            if table.borders.top == nil { table.borders.top = styleBorders.top }
            if table.borders.bottom == nil { table.borders.bottom = styleBorders.bottom }
            if table.borders.left == nil { table.borders.left = styleBorders.left }
            if table.borders.right == nil { table.borders.right = styleBorders.right }
            if table.borders.insideH == nil { table.borders.insideH = styleBorders.insideH }
            if table.borders.insideV == nil { table.borders.insideV = styleBorders.insideV }
        }
        // Also check tableBorders directly
        if let styleBorders = styleDef.tableBorders {
            if table.borders.top == nil { table.borders.top = styleBorders.top }
            if table.borders.bottom == nil { table.borders.bottom = styleBorders.bottom }
            if table.borders.left == nil { table.borders.left = styleBorders.left }
            if table.borders.right == nil { table.borders.right = styleBorders.right }
            if table.borders.insideH == nil { table.borders.insideH = styleBorders.insideH }
            if table.borders.insideV == nil { table.borders.insideV = styleBorders.insideV }
        }

        for (rowIdx, row) in table.rows.enumerated() {
            for (colIdx, cell) in row.cells.enumerated() {
                // Determine which condition applies to this cell
                let condition = determineCondition(
                    rowIdx: rowIdx, colIdx: colIdx,
                    rowCount: rowCount, colCount: colCount,
                    isHeaderRow: row.isHeader,
                    look: look, styleDef: styleDef
                )

                guard let cond = condition else { continue }

                // Apply background color only if cell doesn't have an explicit one
                if cell.backgroundColor == nil, let shading = cond.cellShading {
                    cell.backgroundColor = shading
                }

                // Apply text formatting to runs in the cell
                if cond.textColor != nil || cond.bold != nil {
                    for para in cell.paragraphs {
                        for run in para.runs {
                            if run.formatting.color == nil, let textColor = cond.textColor {
                                run.formatting.color = textColor
                            }
                            if let bold = cond.bold, !run.formatting.bold {
                                run.formatting.bold = bold
                            }
                        }
                    }
                }

                // Note: condition-level borders are NOT applied to individual cells
                // to avoid visual conflicts with table-level borders.
                // Table-level borders (applied above) handle the main grid lines.
            }
        }
    }

    // MARK: - Private

    /// Resolve style inheritance chain and merge conditions
    private static func resolveStyleChain(_ styleId: String, styles: [String: TableStyleDefinition]) -> TableStyleDefinition? {
        guard var style = styles[styleId] else { return nil }

        // Resolve basedOn chain (max depth 5 to prevent cycles)
        var depth = 0
        var currentId = style.basedOn
        while let parentId = currentId, depth < 5 {
            if let parent = styles[parentId] {
                // Merge parent conditions into current (current overrides parent)
                for (condType, parentCond) in parent.conditions {
                    if style.conditions[condType] == nil {
                        style.conditions[condType] = parentCond
                    }
                }
                // Merge parent table borders if missing
                if style.tableBorders == nil {
                    style.tableBorders = parent.tableBorders
                }
                currentId = parent.basedOn
            } else {
                break
            }
            depth += 1
        }

        return style
    }

    /// Determine the most specific applicable condition for a cell
    private static func determineCondition(
        rowIdx: Int, colIdx: Int,
        rowCount: Int, colCount: Int,
        isHeaderRow: Bool,
        look: TableLook,
        styleDef: TableStyleDefinition
    ) -> TableStyleCondition? {

        // Start with wholeTable defaults
        var result = styleDef.conditions[.wholeTable]

        // Apply banding (lower priority than row/column conditions)
        if !look.noHBand {
            // Determine effective row index for banding (skip header rows)
            let bandRowIdx = look.firstRow ? rowIdx - 1 : rowIdx
            if bandRowIdx >= 0 {
                let bandType: TableStyleConditionType = (bandRowIdx % 2 == 0) ? .band1Horz : .band2Horz
                if let bandCond = styleDef.conditions[bandType] {
                    result = mergeCondition(base: result, overlay: bandCond)
                }
            }
        }
        if !look.noVBand {
            let bandType: TableStyleConditionType = (colIdx % 2 == 0) ? .band1Vert : .band2Vert
            if let bandCond = styleDef.conditions[bandType] {
                result = mergeCondition(base: result, overlay: bandCond)
            }
        }

        // Apply first/last column (higher priority than banding)
        if look.firstColumn && colIdx == 0 {
            if let cond = styleDef.conditions[.firstCol] {
                result = mergeCondition(base: result, overlay: cond)
            }
        }
        if look.lastColumn && colIdx == colCount - 1 {
            if let cond = styleDef.conditions[.lastCol] {
                result = mergeCondition(base: result, overlay: cond)
            }
        }

        // Apply first/last row (highest priority)
        if look.firstRow && (rowIdx == 0 || isHeaderRow) {
            if let cond = styleDef.conditions[.firstRow] {
                result = mergeCondition(base: result, overlay: cond)
            }
        }
        if look.lastRow && rowIdx == rowCount - 1 {
            if let cond = styleDef.conditions[.lastRow] {
                result = mergeCondition(base: result, overlay: cond)
            }
        }

        // Corner cells (highest specificity)
        if look.firstRow && rowIdx == 0 && look.firstColumn && colIdx == 0 {
            if let cond = styleDef.conditions[.nwCell] {
                result = mergeCondition(base: result, overlay: cond)
            }
        }
        if look.firstRow && rowIdx == 0 && look.lastColumn && colIdx == colCount - 1 {
            if let cond = styleDef.conditions[.neCell] {
                result = mergeCondition(base: result, overlay: cond)
            }
        }
        if look.lastRow && rowIdx == rowCount - 1 && look.firstColumn && colIdx == 0 {
            if let cond = styleDef.conditions[.swCell] {
                result = mergeCondition(base: result, overlay: cond)
            }
        }
        if look.lastRow && rowIdx == rowCount - 1 && look.lastColumn && colIdx == colCount - 1 {
            if let cond = styleDef.conditions[.seCell] {
                result = mergeCondition(base: result, overlay: cond)
            }
        }

        return result
    }

    /// Merge overlay condition onto base (overlay wins where defined)
    private static func mergeCondition(base: TableStyleCondition?, overlay: TableStyleCondition) -> TableStyleCondition {
        var merged = base ?? TableStyleCondition()
        if let shading = overlay.cellShading { merged.cellShading = shading }
        if let color = overlay.textColor { merged.textColor = color }
        if let bold = overlay.bold { merged.bold = bold }
        if let borders = overlay.borders { merged.borders = borders }
        return merged
    }
}
