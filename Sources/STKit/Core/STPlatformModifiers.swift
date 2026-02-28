import SwiftUI

/// Drop-in replacement for NavigationView that always uses stack style on macOS
/// to prevent sidebar/detail split inside sheets.
public struct STNavigationView<Content: View>: View {
    let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        #if os(iOS)
        NavigationView { content }
            .navigationViewStyle(.stack)
        #else
        NavigationView { content }
        #endif
    }
}

extension View {
    @ViewBuilder
    public func stNavigationBarTitleDisplayMode() -> some View {
        #if os(iOS)
        self.navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }

    @ViewBuilder
    public func stPresentationDetents(_ detents: Set<PresentationDetent>) -> some View {
        #if os(iOS)
        self.presentationDetents(detents)
        #else
        self
        #endif
    }

    @ViewBuilder
    public func stPresentationDragIndicator(_ visibility: Visibility) -> some View {
        #if os(iOS)
        self.presentationDragIndicator(visibility)
        #else
        self
        #endif
    }

    @ViewBuilder
    public func stToolbarPlacementTopBarLeading() -> some View {
        self
    }

    @ViewBuilder
    public func stToolbarPlacementTopBarTrailing() -> some View {
        self
    }

    /// Cross-platform presentationCompactAdaptation
    @ViewBuilder
    public func stPresentationCompactAdaptation() -> some View {
        #if os(iOS)
        if #available(iOS 16.4, *) {
            self.presentationCompactAdaptation(.popover)
        } else {
            self
        }
        #else
        self
        #endif
    }

    /// Cross-platform listStyle that uses insetGrouped on iOS, plain on macOS
    @ViewBuilder
    public func stInsetGroupedListStyle() -> some View {
        #if os(iOS)
        self.listStyle(.insetGrouped)
        #else
        self.listStyle(.plain)
        #endif
    }

    /// Cross-platform keyboardType — no-op on macOS
    @ViewBuilder
    public func stKeyboardType(_ type: STKeyboardType) -> some View {
        #if os(iOS)
        switch type {
        case .URL: self.keyboardType(.URL)
        case .numberPad: self.keyboardType(.numberPad)
        case .decimalPad: self.keyboardType(.decimalPad)
        case .default_: self.keyboardType(.default)
        }
        #else
        self
        #endif
    }

    /// Cross-platform navigationViewStyle(.stack)
    @ViewBuilder
    public func stStackNavigationViewStyle() -> some View {
        #if os(iOS)
        self.navigationViewStyle(.stack)
        #else
        self
        #endif
    }
}

/// Cross-platform keyboard type enum
public enum STKeyboardType {
    case URL
    case numberPad
    case decimalPad
    case default_
}

// MARK: - Cross-platform toolbar placement helpers

public extension ToolbarItemPlacement {
    /// Maps to .topBarLeading on iOS, .automatic on macOS
    static var stLeading: ToolbarItemPlacement {
        #if os(iOS)
        .topBarLeading
        #else
        .automatic
        #endif
    }

    /// Maps to .topBarTrailing on iOS, .automatic on macOS
    static var stTrailing: ToolbarItemPlacement {
        #if os(iOS)
        .topBarTrailing
        #else
        .automatic
        #endif
    }
}
