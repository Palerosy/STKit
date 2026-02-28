import PDFKit
import STKit

/// All annotation tool types supported by STDOCX
public enum STAnnotationType: String, CaseIterable, Identifiable, Sendable {
    // Phase 2 — Drawing
    case ink
    case highlighter

    // Phase 2 — Text
    case freeText
    case textEdit
    case textRemove

    // Phase 2 — Markup
    case textHighlight
    case textUnderline
    case textStrikeOut

    // Phase 3 — Shapes
    case rectangle
    case circle
    case line
    case arrow

    // Phase 3 — Other
    case signature
    case stamp
    case photo
    case note
    case eraser

    public var id: String { rawValue }

    /// The PDFAnnotation subtype for this tool
    var pdfSubtype: PDFAnnotationSubtype? {
        switch self {
        case .ink, .highlighter, .signature: return .ink
        case .freeText: return .freeText
        case .textHighlight: return .highlight
        case .textUnderline: return .underline
        case .textStrikeOut: return .strikeOut
        case .rectangle: return .square
        case .circle: return .circle
        case .line, .arrow: return .line
        case .stamp: return .stamp
        case .photo: return .stamp
        case .note: return .text
        case .textEdit: return nil
        case .textRemove: return nil
        case .eraser: return nil
        }
    }

    /// Human readable display name
    public var displayName: String {
        switch self {
        case .ink: return STStrings.toolPen
        case .highlighter: return STStrings.toolHighlighter
        case .freeText: return STStrings.toolText
        case .textHighlight: return STStrings.toolHighlight
        case .textUnderline: return STStrings.toolUnderline
        case .textStrikeOut: return STStrings.toolStrikethrough
        case .rectangle: return STStrings.toolRectangle
        case .circle: return STStrings.toolCircle
        case .line: return STStrings.toolLine
        case .arrow: return STStrings.toolArrow
        case .signature: return STStrings.toolSignature
        case .stamp: return STStrings.toolStamp
        case .photo: return STStrings.toolPhoto
        case .note: return STStrings.toolNote
        case .textEdit: return STStrings.toolTextEdit
        case .textRemove: return STStrings.removeText
        case .eraser: return STStrings.toolEraser
        }
    }

    /// SF Symbol icon name
    public var iconName: String {
        switch self {
        case .ink: return "pencil.tip"
        case .highlighter: return "paintbrush.pointed"
        case .freeText: return "textformat"
        case .textHighlight: return "text.badge.star"
        case .textUnderline: return "underline"
        case .textStrikeOut: return "strikethrough"
        case .rectangle: return "rectangle"
        case .circle: return "circle"
        case .line: return "line.diagonal"
        case .arrow: return "arrow.up.right"
        case .signature: return "signature"
        case .stamp: return "seal"
        case .photo: return "photo"
        case .note: return "note.text"
        case .textEdit: return "pencil.line"
        case .textRemove: return "text.badge.minus"
        case .eraser: return "eraser"
        }
    }

    /// Whether this tool requires text selection (markup tools)
    var requiresTextSelection: Bool {
        switch self {
        case .textHighlight, .textUnderline, .textStrikeOut: return true
        default: return false
        }
    }

    /// Whether this tool uses freeform drawing (ink overlay)
    var isDrawingTool: Bool {
        switch self {
        case .ink, .highlighter: return true
        default: return false
        }
    }

    /// Whether this tool draws shapes (shape overlay)
    var isShapeTool: Bool {
        switch self {
        case .rectangle, .circle, .line, .arrow: return true
        default: return false
        }
    }

    /// Whether this tool uses eraser hit-testing
    var isEraserTool: Bool {
        self == .eraser
    }

    /// Contextual hint text shown at the top when this tool is active.
    /// Returns nil for tools that have their own overlay (textEdit, textRemove, markup).
    var hintText: String? {
        switch self {
        case .ink, .highlighter: return STStrings.hintDraw
        case .rectangle, .circle, .line, .arrow: return STStrings.hintShape
        case .freeText: return STStrings.hintTapToAddText
        case .signature, .stamp, .photo, .note: return STStrings.tapToPlace
        case .eraser: return STStrings.hintErase
        case .textEdit, .textRemove, .textHighlight, .textUnderline, .textStrikeOut: return nil
        }
    }

    /// Whether this tool needs a line width control
    var hasLineWidth: Bool {
        switch self {
        case .ink, .highlighter, .rectangle, .circle, .line, .arrow, .signature: return true
        default: return false
        }
    }

    /// Tools available in Phase 2
    public static var phase2Tools: [STAnnotationType] {
        [.ink, .highlighter, .freeText, .textHighlight, .textUnderline, .textStrikeOut]
    }

    /// Tools available in Phase 3
    public static var phase3Tools: [STAnnotationType] {
        [.rectangle, .circle, .line, .arrow, .signature, .stamp, .note, .eraser]
    }

    /// All available tools
    public static var allTools: [STAnnotationType] {
        phase2Tools + phase3Tools
    }
}
