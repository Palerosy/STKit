import Foundation

/// Configuration for which toolbar items to display
public struct STToolbarConfiguration {

    /// Default toolbar with all items
    public static let `default` = STToolbarConfiguration()

    /// Show close button
    public var showCloseButton: Bool = true

    /// Show annotation toggle button
    public var showAnnotationToggle: Bool = true

    /// Show more menu button
    public var showMoreMenu: Bool = true

    public init() {}
}
