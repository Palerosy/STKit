import Foundation

// MARK: - Cell Style

/// Rich formatting for a spreadsheet cell
public struct STExcelCellStyle: Equatable, Sendable {
    public var fontName: String = "Calibri"
    public var fontSize: Double = 11
    public var isBold: Bool = false
    public var isItalic: Bool = false
    public var isUnderline: Bool = false
    public var isStrikethrough: Bool = false
    public var textColor: String? = nil        // hex "#FF0000", nil = auto/black
    public var fillColor: String? = nil        // hex "#FFFF00", nil = no fill
    public var horizontalAlignment: STHorizontalAlignment = .general
    public var verticalAlignment: STVerticalAlignment = .bottom
    public var wrapText: Bool = false
    public var indent: Int = 0
    public var borders: STCellBorders = .init()
    public var numberFormatId: Int = 0
    public var numberFormatCode: String? = nil
    public var isLocked: Bool = true          // Excel default: cells are locked
    public var isHidden: Bool = false         // hide formula when sheet protected

    public init() {}

    /// True if this style differs from default
    public var isCustom: Bool {
        self != STExcelCellStyle()
    }
}

// MARK: - Alignment Enums

public enum STHorizontalAlignment: String, Equatable, Sendable, CaseIterable {
    case general, left, center, right, justify
}

public enum STVerticalAlignment: String, Equatable, Sendable, CaseIterable {
    case top, center, bottom
}

// MARK: - Borders

public enum STBorderStyle: String, Equatable, Sendable {
    case none, thin, medium, thick, dashed, dotted, double_
}

public enum STBorderEdge: String, Equatable, Sendable, CaseIterable {
    case left, right, top, bottom
}

public struct STCellBorders: Equatable, Sendable {
    public var left: STBorderStyle = .none
    public var right: STBorderStyle = .none
    public var top: STBorderStyle = .none
    public var bottom: STBorderStyle = .none
    public var color: String? = nil  // hex, nil = black

    public init() {}

    public static var allThin: STCellBorders {
        STCellBorders(left: .thin, right: .thin, top: .thin, bottom: .thin)
    }

    public init(left: STBorderStyle = .none, right: STBorderStyle = .none,
                top: STBorderStyle = .none, bottom: STBorderStyle = .none,
                color: String? = nil) {
        self.left = left
        self.right = right
        self.top = top
        self.bottom = bottom
        self.color = color
    }

    public var hasAny: Bool {
        left != .none || right != .none || top != .none || bottom != .none
    }
}

// MARK: - Merged Region

public struct STMergedRegion: Equatable, Sendable {
    public let startRow: Int
    public let startCol: Int
    public let endRow: Int
    public let endCol: Int

    public init(startRow: Int, startCol: Int, endRow: Int, endCol: Int) {
        self.startRow = startRow
        self.startCol = startCol
        self.endRow = endRow
        self.endCol = endCol
    }

    public func contains(row: Int, col: Int) -> Bool {
        row >= startRow && row <= endRow && col >= startCol && col <= endCol
    }

    public var isOrigin: Bool { true } // convenience — check via (row,col) == (startRow, startCol)
}

// MARK: - Number Format Helpers

public enum STNumberFormat: Int, CaseIterable {
    case general = 0
    case number = 1
    case currency = 2
    case percent = 3
    case date = 4
    case time = 5
    case accounting = 44
    case fraction = 12
    case scientific = 11
    case text = 49
    case special = -1
    case custom = -2

    public var displayName: String {
        switch self {
        case .general: return STExcelStrings.general
        case .number: return STExcelStrings.number
        case .currency: return STExcelStrings.currency
        case .accounting: return STExcelStrings.accounting
        case .percent: return STExcelStrings.percentage
        case .date: return STExcelStrings.date
        case .time: return STExcelStrings.time
        case .fraction: return STExcelStrings.fraction
        case .scientific: return STExcelStrings.scientific
        case .text: return STExcelStrings.textFunctions
        case .special: return STExcelStrings.special
        case .custom: return STExcelStrings.custom
        }
    }

    public var formatCode: String {
        switch self {
        case .general: return "General"
        case .number: return "#,##0.00"
        case .currency: return "$#,##0.00"
        case .accounting: return "_($* #,##0.00_)"
        case .percent: return "0.00%"
        case .date: return "mm/dd/yyyy"
        case .time: return "hh:mm:ss"
        case .fraction: return "# ?/?"
        case .scientific: return "0.00E+00"
        case .text: return "@"
        case .special: return "00000"
        case .custom: return "General"
        }
    }

    /// Whether this format has sub-options (drill-down detail page)
    public var hasSubOptions: Bool {
        switch self {
        case .general, .text: return false
        default: return true
        }
    }
}
