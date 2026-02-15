import SwiftUI

/// Configuration for STExcel views
public struct STExcelConfiguration {

    public static let `default` = STExcelConfiguration()

    // MARK: - Grid Settings

    /// Default column width
    public var columnWidth: CGFloat = 100

    /// Default row height
    public var rowHeight: CGFloat = 40

    /// Row header width (for row numbers)
    public var rowHeaderWidth: CGFloat = 50

    /// Column header height (for A, B, C...)
    public var columnHeaderHeight: CGFloat = 36

    /// Whether cells are editable
    public var isEditable: Bool = true

    // MARK: - Toolbar Visibility

    /// Show save button
    public var showSaveButton: Bool = true

    /// Show more menu
    public var showMoreMenu: Bool = true

    /// Show export option
    public var showExport: Bool = true

    /// Show sheet tabs
    public var showSheetTabs: Bool = true

    // MARK: - Appearance

    /// Grid line color
    public var gridLineColor: Color = Color(.separator)

    /// Header background color
    public var headerBackgroundColor: Color = Color(.secondarySystemBackground)

    /// Selected cell highlight color
    public var selectionColor: Color = .accentColor

    /// Cell background color
    public var cellBackgroundColor: Color = Color(.systemBackground)

    public init() {}

    /// Read-only configuration
    public static var viewerDefault: STExcelConfiguration {
        var config = STExcelConfiguration()
        config.isEditable = false
        config.showSaveButton = false
        return config
    }
}
