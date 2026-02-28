import Foundation
import STKit

/// Groups of annotation tools shown in the toolbar
public enum STAnnotationGroup: String, CaseIterable, Identifiable {
    case drawing
    case shapes
    case text
    case markup
    case extras

    public var id: String { rawValue }

    /// Display name for the group
    public var displayName: String {
        switch self {
        case .drawing: return STStrings.groupDraw
        case .shapes: return STStrings.groupShapes
        case .text: return STStrings.groupText
        case .markup: return STStrings.groupMarkup
        case .extras: return STStrings.groupExtras
        }
    }

    /// Default icon for the group (shows first tool's icon)
    public var iconName: String {
        switch self {
        case .drawing: return "pencil.tip"
        case .shapes: return "rectangle"
        case .text: return "textformat"
        case .markup: return "highlighter"
        case .extras: return "signature"
        }
    }

    /// The annotation types in this group
    public var tools: [STAnnotationType] {
        switch self {
        case .drawing: return [.ink, .highlighter]
        case .shapes: return [.rectangle, .circle, .line, .arrow]
        case .text: return [.freeText, .textEdit]
        case .markup: return [.textHighlight, .textUnderline, .textStrikeOut]
        case .extras: return [.signature, .stamp, .note]
        }
    }

    /// The default (first) tool in this group
    public var defaultTool: STAnnotationType {
        tools.first!
    }
}
