import SwiftUI
import STKit

/// Configuration for STTXT views
public struct STTXTConfiguration {

    public static let `default` = STTXTConfiguration()

    /// Whether text is editable
    public var isEditable: Bool = true

    /// Font name (monospaced recommended)
    public var fontName: String = "Menlo"

    /// Font size
    public var fontSize: CGFloat = 14

    /// Text color
    public var textColor: Color = .primary

    /// Background color
    public var backgroundColor: Color = .stSystemBackground

    /// Text insets
    public var textInsets: EdgeInsets = EdgeInsets(top: 16, leading: 12, bottom: 16, trailing: 12)

    /// Show save button
    public var showSaveButton: Bool = true

    /// Show more menu
    public var showMoreMenu: Bool = true

    /// Show line numbers (future feature)
    public var showLineNumbers: Bool = false

    /// Called when the user taps print. Return `true` to allow printing, `false` to block.
    /// When nil, printing is always allowed.
    public var onPrint: (() -> Bool)?

    public init() {}

    /// Read-only configuration
    public static var viewerDefault: STTXTConfiguration {
        var config = STTXTConfiguration()
        config.isEditable = false
        config.showSaveButton = false
        return config
    }
}
