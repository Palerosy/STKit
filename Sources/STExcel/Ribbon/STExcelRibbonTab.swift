import SwiftUI
import STKit

/// Tab identifiers for the Excel ribbon toolbar
public enum STExcelRibbonTab: String, CaseIterable, Identifiable, Sendable {
    case home, insert, format, formulas, data, review, view, chart, shape, table

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .home: return STStrings.ribbonHome
        case .insert: return STStrings.ribbonInsert
        case .format: return STExcelStrings.ribbonFormat
        case .formulas: return STExcelStrings.ribbonFormulas
        case .data: return STExcelStrings.ribbonData
        case .review: return STStrings.ribbonReview
        case .view: return STStrings.ribbonView
        case .chart: return STExcelStrings.chart
        case .shape: return "Shape"
        case .table: return "Table"
        }
    }

    var iconName: String {
        switch self {
        case .home: return "house"
        case .insert: return "plus.square"
        case .format: return "number"
        case .formulas: return "function"
        case .data: return "chart.bar"
        case .review: return "text.magnifyingglass"
        case .view: return "eye"
        case .chart: return "chart.bar.xaxis"
        case .shape: return "square.on.circle"
        case .table: return "tablecells"
        }
    }

    /// Standard tabs (without contextual chart tab)
    public static var standardTabs: [STExcelRibbonTab] {
        [.home, .insert, .format, .formulas, .data, .review, .view]
    }
}
