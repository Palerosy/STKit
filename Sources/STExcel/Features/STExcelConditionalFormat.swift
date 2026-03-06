import SwiftUI

// MARK: - Rule Type

enum STExcelCFRuleType: String, CaseIterable, Identifiable {
    case highlightCells
    case topBottom
    case customFormula
    case dataBar
    case colorScale

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .highlightCells: return STExcelStrings.highlightCellsRules
        case .topBottom: return STExcelStrings.topBottomAvgRules
        case .customFormula: return STExcelStrings.customFormula
        case .dataBar: return STExcelStrings.dataBars
        case .colorScale: return STExcelStrings.colorScales
        }
    }
}

// MARK: - Highlight Condition

enum STExcelCFCondition: String, CaseIterable, Identifiable {
    case greaterThan, lessThan, between, equalTo, notEqualTo
    case textContains, textNotContains
    case duplicates, uniqueValues

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .greaterThan: return STExcelStrings.cfGreaterThan
        case .lessThan: return STExcelStrings.cfLessThan
        case .between: return STExcelStrings.cfBetween
        case .equalTo: return STExcelStrings.cfEqualTo
        case .notEqualTo: return STExcelStrings.cfNotEqualTo
        case .textContains: return STExcelStrings.cfTextContains
        case .textNotContains: return STExcelStrings.cfTextNotContains
        case .duplicates: return STExcelStrings.cfDuplicates
        case .uniqueValues: return STExcelStrings.cfUniqueValues
        }
    }

    var needsValue1: Bool {
        switch self {
        case .duplicates, .uniqueValues: return false
        default: return true
        }
    }

    var needsValue2: Bool { self == .between }
}

// MARK: - Top/Bottom Rank

enum STExcelCFRank: String, CaseIterable, Identifiable {
    case top, bottom, aboveAverage, belowAverage

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .top: return STExcelStrings.cfTop
        case .bottom: return STExcelStrings.cfBottom
        case .aboveAverage: return STExcelStrings.cfAboveAverage
        case .belowAverage: return STExcelStrings.cfBelowAverage
        }
    }

    var needsCount: Bool { self == .top || self == .bottom }
}

// MARK: - Format Preset

struct STExcelCFPreset: Identifiable {
    let id = UUID()
    let name: String
    let bgColor: Color?
    let textColor: Color
    let borderColor: Color?

    static let presets: [STExcelCFPreset] = [
        STExcelCFPreset(name: "Light Red Fill", bgColor: Color(red: 1, green: 0.8, blue: 0.8), textColor: .primary, borderColor: nil),
        STExcelCFPreset(name: "Light Green Fill", bgColor: Color(red: 0.8, green: 0.95, blue: 0.8), textColor: .primary, borderColor: nil),
        STExcelCFPreset(name: "Light Yellow Fill", bgColor: Color(red: 1, green: 0.97, blue: 0.75), textColor: .primary, borderColor: nil),
        STExcelCFPreset(name: "No Fill", bgColor: nil, textColor: .primary, borderColor: nil),
        STExcelCFPreset(name: "Red Text", bgColor: nil, textColor: .red, borderColor: nil),
        STExcelCFPreset(name: "Red Border", bgColor: nil, textColor: .primary, borderColor: .red),
    ]
}

// MARK: - Data Bar Color

enum STExcelCFBarColor: String, CaseIterable, Identifiable {
    case blue, green, red, orange, purple, cyan

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .blue: return .blue
        case .green: return .green
        case .red: return .red
        case .orange: return .orange
        case .purple: return .purple
        case .cyan: return .cyan
        }
    }
}

// MARK: - Color Scale

enum STExcelCFColorScale: String, CaseIterable, Identifiable {
    case greenYellowRed, redYellowGreen, greenWhiteRed, redWhiteGreen, blueWhiteRed

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .greenYellowRed: return "Green - Yellow - Red"
        case .redYellowGreen: return "Red - Yellow - Green"
        case .greenWhiteRed: return "Green - White - Red"
        case .redWhiteGreen: return "Red - White - Green"
        case .blueWhiteRed: return "Blue - White - Red"
        }
    }

    var lowColor: Color {
        switch self {
        case .greenYellowRed, .greenWhiteRed: return .green
        case .redYellowGreen, .redWhiteGreen: return .red
        case .blueWhiteRed: return .blue
        }
    }

    var midColor: Color {
        switch self {
        case .greenYellowRed, .redYellowGreen: return .yellow
        case .greenWhiteRed, .redWhiteGreen, .blueWhiteRed: return .white
        }
    }

    var highColor: Color {
        switch self {
        case .greenYellowRed, .greenWhiteRed: return .red
        case .redYellowGreen, .redWhiteGreen: return .green
        case .blueWhiteRed: return .red
        }
    }
}

// MARK: - Conditional Formatting Rule

struct STExcelConditionalRule: Identifiable {
    let id = UUID()

    /// Range this rule applies to
    var startRow: Int
    var startCol: Int
    var endRow: Int
    var endCol: Int

    var ruleType: STExcelCFRuleType

    // Highlight cells
    var condition: STExcelCFCondition = .greaterThan
    var value1: String = ""
    var value2: String = ""

    // Top/Bottom
    var rank: STExcelCFRank = .top
    var rankCount: Int = 10
    var rankIsPercent: Bool = false

    // Data bar
    var barColor: STExcelCFBarColor = .blue

    // Color scale
    var colorScale: STExcelCFColorScale = .greenYellowRed

    // Custom formula
    var formula: String = ""

    // Formatting (for highlight/topBottom/customFormula)
    var preset: STExcelCFPreset = STExcelCFPreset.presets[0]

    func contains(row: Int, col: Int) -> Bool {
        row >= startRow && row <= endRow && col >= startCol && col <= endCol
    }

    var rangeString: String {
        "\(STExcelSheet.columnLetter(startCol))\(startRow + 1):\(STExcelSheet.columnLetter(endCol))\(endRow + 1)"
    }
}
