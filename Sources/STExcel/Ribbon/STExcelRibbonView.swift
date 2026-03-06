import SwiftUI

/// Top-level ribbon container — tab bar + active tab content strip
struct STExcelRibbonView: View {
    @ObservedObject var ribbonViewModel: STExcelRibbonViewModel
    @ObservedObject var editorViewModel: STExcelEditorViewModel

    var body: some View {
        VStack(spacing: 0) {
            STExcelRibbonTabBar(
                selectedTab: $ribbonViewModel.selectedTab,
                availableTabs: ribbonViewModel.visibleTabs
            )
            Divider()
            if !ribbonViewModel.isCollapsed {
                STExcelRibbonTabContent(
                    selectedTab: ribbonViewModel.selectedTab,
                    editorViewModel: editorViewModel
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            Divider()
        }
        .background(.ultraThinMaterial)
    }
}
