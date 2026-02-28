import SwiftUI

/// Main configuration for STPDFEditorView
public struct STPDFConfiguration {

    /// Default configuration with all features enabled
    public static let `default` = STPDFConfiguration()

    // MARK: - Viewer Settings

    /// Scroll direction for the PDF viewer
    public var scrollDirection: STScrollDirection = .vertical

    /// Page display mode
    public var pageTransition: STPageTransition = .scrollContinuous

    // MARK: - Toolbar Settings

    /// Whether the annotation toolbar is draggable
    public var isToolbarDraggable: Bool = false

    /// Whether to auto-show the annotation toolbar on appear
    public var autoShowToolbar: Bool = true

    // MARK: - Bottom Bar Visibility

    /// Show thumbnails button in bottom bar
    public var showThumbnails: Bool = true

    /// Show bookmarks button in bottom bar
    public var showBookmarks: Bool = true

    /// Show search button in bottom bar
    public var showSearch: Bool = true

    /// Show settings button in bottom bar
    public var showSettings: Bool = true

    // MARK: - More Menu Visibility

    /// Show outline option in more menu
    public var showOutline: Bool = true

    /// Show edit pages option in more menu
    public var showEditPages: Bool = true

    /// Show share option in more menu
    public var showShare: Bool = true

    /// Show print option in more menu
    public var showPrint: Bool = true

    /// Show "save as text" option in more menu
    public var showSaveAsText: Bool = true

    // MARK: - Behavior

    /// Allow annotation editing
    public var allowAnnotationEditing: Bool = true

    /// Allow document editing (page add/remove/reorder)
    public var allowDocumentEditing: Bool = true

    /// Enable autosave
    public var autosaveEnabled: Bool = true

    /// Autosave interval in seconds
    public var autosaveInterval: TimeInterval = 10

    // MARK: - Callbacks

    /// Called when the user taps print. Return `true` to allow printing, `false` to block.
    /// When nil, printing is always allowed.
    public var onPrint: (() -> Bool)?

    // MARK: - Appearance

    /// Appearance configuration (colors, theming)
    public var appearance: STAppearanceConfiguration = .default

    public init() {}
}

/// Scroll direction for PDF viewer
public enum STScrollDirection {
    case vertical
    case horizontal
}

/// Page transition style
public enum STPageTransition {
    case scrollContinuous
    case scrollPerSpread
}
