import SwiftUI

/// Top-level ribbon container — tab bar + active tab content strip
/// Replaces the floating toolbar with a Microsoft Word-style ribbon menu
struct STRibbonView: View {
    @ObservedObject var ribbonViewModel: STRibbonViewModel
    @ObservedObject var annotationManager: STAnnotationManager
    @ObservedObject var webEditorViewModel: STWebEditorViewModel
    let onShowOutline: () -> Void
    let onShowSearch: () -> Void
    let onShowWordCount: () -> Void
    let onGoToTop: () -> Void
    let onGoToBottom: () -> Void
    let onActivateDrawTool: (STAnnotationType) -> Void
    var onInsertImage: (() -> Void)? = nil

    /// Dynamic tabs: base tabs + contextual .table when cursor is in a table
    private var dynamicTabs: [STRibbonTab] {
        var tabs = ribbonViewModel.availableTabs
        if webEditorViewModel.isInTable && !tabs.contains(.table) {
            if let insertIdx = tabs.firstIndex(of: .insert) {
                tabs.insert(.table, at: insertIdx + 1)
            } else {
                tabs.append(.table)
            }
        }
        return tabs
    }

    var body: some View {
        VStack(spacing: 0) {
            // Tab bar (always visible)
            STRibbonTabBar(
                selectedTab: $ribbonViewModel.selectedTab,
                availableTabs: dynamicTabs
            )

            Divider()

            // Tab content (collapsible)
            if !ribbonViewModel.isCollapsed {
                STRibbonTabContent(
                    selectedTab: ribbonViewModel.selectedTab,
                    annotationManager: annotationManager,
                    webEditorViewModel: webEditorViewModel,
                    onShowOutline: onShowOutline,
                    onShowSearch: onShowSearch,
                    onShowWordCount: onShowWordCount,
                    onGoToTop: onGoToTop,
                    onGoToBottom: onGoToBottom,
                    onActivateDrawTool: onActivateDrawTool,
                    onInsertImage: onInsertImage
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            Divider()
        }
        .background(.ultraThinMaterial)
        .onChange(of: webEditorViewModel.isInTable) { isInTable in
            if !isInTable && ribbonViewModel.selectedTab == .table {
                ribbonViewModel.selectedTab = .home
            }
        }
    }
}
