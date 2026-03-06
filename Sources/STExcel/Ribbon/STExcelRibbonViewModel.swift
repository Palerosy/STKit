import SwiftUI
import Combine

/// View model for the ribbon tab bar state
@MainActor
final class STExcelRibbonViewModel: ObservableObject {
    @Published var selectedTab: STExcelRibbonTab = .home
    @Published var isCollapsed: Bool = false
    var availableTabs: [STExcelRibbonTab] = STExcelRibbonTab.standardTabs

    /// When true, the chart contextual tab is shown
    @Published var showChartTab: Bool = false
    /// When true, the shape contextual tab is shown
    @Published var showShapeTab: Bool = false
    @Published var showTableTab: Bool = false

    init(defaultTab: STExcelRibbonTab = .home, availableTabs: [STExcelRibbonTab]? = nil) {
        self.selectedTab = defaultTab
        if let tabs = availableTabs { self.availableTabs = tabs }
    }

    var visibleTabs: [STExcelRibbonTab] {
        var tabs = availableTabs.filter { $0 != .chart && $0 != .shape && $0 != .table }
        if showChartTab { tabs.append(.chart) }
        if showShapeTab { tabs.append(.shape) }
        if showTableTab { tabs.append(.table) }
        return tabs
    }

    func activateChartTab() {
        showChartTab = true
        showShapeTab = false
        selectedTab = .chart
    }

    func deactivateChartTab() {
        showChartTab = false
        if selectedTab == .chart { selectedTab = .home }
    }

    func activateShapeTab() {
        showShapeTab = true
        showChartTab = false
        selectedTab = .shape
    }

    func deactivateShapeTab() {
        showShapeTab = false
        if selectedTab == .shape { selectedTab = .home }
    }

    func activateTableTab() {
        showTableTab = true
        showChartTab = false
        showShapeTab = false
        selectedTab = .table
    }

    func deactivateTableTab() {
        showTableTab = false
        if selectedTab == .table { selectedTab = .home }
    }

    func toggleCollapse() {
        withAnimation(.easeInOut(duration: 0.2)) { isCollapsed.toggle() }
    }
}
