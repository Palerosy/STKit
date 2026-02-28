import SwiftUI

/// Appearance and theming configuration
public struct STAppearanceConfiguration {

    /// Default appearance
    public static let `default` = STAppearanceConfiguration()

    /// Tint color for buttons and controls
    public var tintColor: Color = .accentColor

    /// Toolbar background color
    public var toolbarBackgroundColor: Color = Color.stSystemBackground

    /// Annotation toolbar position
    public var annotationToolbarPosition: STToolbarPosition = .top

    public init() {}
}

/// Position of the annotation toolbar
public enum STToolbarPosition {
    case top
    case bottom
}
