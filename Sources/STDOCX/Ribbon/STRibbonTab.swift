import SwiftUI
import STKit

/// All ribbon tabs available in the STDOCX editor
enum STRibbonTab: String, CaseIterable, Identifiable, Sendable {
    case home
    case para
    case insert
    case table
    case draw
    case design
    case layout
    case review
    case view

    var id: String { rawValue }

    /// Localized display name
    var displayName: String {
        switch self {
        case .home: return STStrings.ribbonHome
        case .para: return STStrings.ribbonPara
        case .insert: return STStrings.ribbonInsert
        case .table: return STStrings.ribbonTable
        case .draw: return STStrings.ribbonDraw
        case .design: return STStrings.ribbonDesign
        case .layout: return STStrings.ribbonLayout
        case .review: return STStrings.ribbonReview
        case .view: return STStrings.ribbonView
        }
    }

    /// SF Symbol icon for compact display
    var iconName: String {
        switch self {
        case .home: return "house"
        case .para: return "text.alignjustified"
        case .insert: return "plus.square"
        case .table: return "tablecells"
        case .draw: return "pencil.tip"
        case .design: return "paintbrush"
        case .layout: return "rectangle.split.3x1"
        case .review: return "text.magnifyingglass"
        case .view: return "eye"
        }
    }
}
