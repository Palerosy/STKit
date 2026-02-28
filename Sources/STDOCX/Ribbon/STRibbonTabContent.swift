import SwiftUI

/// Router view that shows the active tab's content
struct STRibbonTabContent: View {
    let selectedTab: STRibbonTab
    @ObservedObject var annotationManager: STAnnotationManager
    @ObservedObject var webEditorViewModel: STWebEditorViewModel
    let onShowOutline: () -> Void
    let onShowSearch: () -> Void
    let onShowWordCount: () -> Void
    let onGoToTop: () -> Void
    let onGoToBottom: () -> Void
    let onActivateDrawTool: (STAnnotationType) -> Void
    var onInsertImage: (() -> Void)? = nil

    var body: some View {
        Group {
            switch selectedTab {
            case .home:
                STRibbonHomeTab(
                    annotationManager: annotationManager,
                    webEditorViewModel: webEditorViewModel
                )
            case .para:
                STRibbonParaTab(webEditorViewModel: webEditorViewModel)
            case .insert:
                STRibbonInsertTab(
                    annotationManager: annotationManager,
                    onActivateDrawTool: onActivateDrawTool,
                    onInsertImage: onInsertImage,
                    webEditorViewModel: webEditorViewModel
                )
            case .table:
                STRibbonTableTab(
                    webEditorViewModel: webEditorViewModel
                )
            case .draw:
                STRibbonDrawTab(annotationManager: annotationManager)
            case .design:
                STRibbonDesignTab()
            case .layout:
                STRibbonLayoutTab()
            case .review:
                STRibbonReviewTab(
                    webEditorViewModel: webEditorViewModel,
                    onShowSearch: onShowSearch,
                    onShowWordCount: onShowWordCount
                )
            case .view:
                STRibbonViewTab(
                    webEditorViewModel: webEditorViewModel,
                    onGoToTop: onGoToTop,
                    onGoToBottom: onGoToBottom
                )
            }
        }
        .frame(height: 58)
    }
}
