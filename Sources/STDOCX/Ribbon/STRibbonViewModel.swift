import SwiftUI
import Combine

/// ViewModel for the ribbon menu — tracks selected tab and mediates actions
@MainActor
final class STRibbonViewModel: ObservableObject {

    /// Currently selected ribbon tab
    @Published var selectedTab: STRibbonTab = .home

    /// Whether the ribbon content strip is collapsed (only tab bar visible)
    @Published var isCollapsed: Bool = false

    /// Reference to the annotation manager (for draw tab actions)
    weak var annotationManager: STAnnotationManager?

    /// Available tabs (configurable — Draw, Design, Layout hidden until implemented)
    var availableTabs: [STRibbonTab] = [.home, .para, .insert, .review, .view]

    init(defaultTab: STRibbonTab = .home, availableTabs: [STRibbonTab]? = nil) {
        self.selectedTab = defaultTab
        if let tabs = availableTabs {
            self.availableTabs = tabs
        }
    }

    /// Whether the current tab should show annotation mode (PDFView + overlays)
    var isDrawMode: Bool {
        selectedTab == .draw
    }

    /// Toggle ribbon content collapse
    func toggleCollapse() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isCollapsed.toggle()
        }
    }
}
