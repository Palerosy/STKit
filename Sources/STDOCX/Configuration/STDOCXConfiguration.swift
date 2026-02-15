import SwiftUI

/// Configuration for STDOCXEditorView
public struct STDOCXConfiguration {

    /// Default configuration with all features enabled
    public static let `default` = STDOCXConfiguration()

    // MARK: - Editor Settings

    /// Whether the document is editable (false = read-only viewer mode)
    public var isEditable: Bool = true

    /// Default font name for new documents
    public var defaultFontName: String = "Helvetica Neue"

    /// Default font size for new documents
    public var defaultFontSize: CGFloat = 14

    /// Text container insets
    public var textInsets: EdgeInsets = EdgeInsets(top: 16, leading: 12, bottom: 16, trailing: 12)

    // MARK: - Toolbar Visibility

    /// Show the formatting toolbar
    public var showFormattingToolbar: Bool = true

    /// Show the more menu (ellipsis button)
    public var showMoreMenu: Bool = true

    /// Show save button in toolbar
    public var showSaveButton: Bool = true

    // MARK: - Feature Visibility

    /// Show word count in more menu
    public var showWordCount: Bool = true

    /// Show find & replace in more menu
    public var showFindReplace: Bool = true

    /// Show export options in more menu
    public var showExport: Bool = true

    /// Show share option
    public var showShare: Bool = true

    // MARK: - Behavior

    /// Enable autosave
    public var autosaveEnabled: Bool = false

    /// Autosave interval in seconds
    public var autosaveInterval: TimeInterval = 10

    // MARK: - Appearance

    /// Appearance configuration
    public var appearance: STDOCXAppearance = .default

    public init() {}
}

/// Appearance configuration for STDOCX views
public struct STDOCXAppearance {

    /// Default appearance
    public static let `default` = STDOCXAppearance()

    /// Accent color for active buttons and highlights
    public var accentColor: Color = .accentColor

    /// Background color for the editor
    public var backgroundColor: Color = Color(.systemBackground)

    /// Background color for the toolbar
    public var toolbarBackgroundColor: UIColor = .secondarySystemBackground

    public init() {}
}
