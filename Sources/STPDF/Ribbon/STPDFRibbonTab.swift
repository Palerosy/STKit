import STKit
import SwiftUI

/// All tabs in the PDF ribbon
enum STPDFRibbonTab: String, CaseIterable, Identifiable {
    case draw       // Pen, Highlighter, Shapes, Eraser
    case markup     // FreeText, RemoveText, TextHighlight, Underline, Strikeout
    case insert     // Signature, Stamp, Photo, Note
    case view       // Search, Outline, Thumbnails, Zoom
    case pages      // Page Editor

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .draw:   return STStrings.ribbonDraw
        case .markup: return STStrings.groupMarkup   // "Markup" / "İşaretleme"
        case .insert: return STStrings.ribbonInsert  // "Insert" / "Ekle"
        case .view:   return STStrings.ribbonView
        case .pages:  return STStrings.pages
        }
    }

    var iconName: String {
        switch self {
        case .draw:   return "pencil.tip"
        case .markup: return "highlighter"
        case .insert: return "plus.square"
        case .view:   return "eye"
        case .pages:  return "doc.on.doc"
        }
    }

    /// Whether this tab requires annotation mode to be active in the PDF view
    var isAnnotationTab: Bool {
        switch self {
        case .draw, .markup, .insert: return true
        case .view, .pages:           return false
        }
    }
}
