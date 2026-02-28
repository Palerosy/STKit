import SwiftUI
import STKit

/// View tab content — Zoom, Go To Top/Bottom, Bookmarks
struct STRibbonViewTab: View {
    @ObservedObject var webEditorViewModel: STWebEditorViewModel
    let onGoToTop: () -> Void
    let onGoToBottom: () -> Void

    @State private var showBookmarksList = false

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 2) {
                // Zoom In
                STRibbonToolButton(
                    iconName: "plus.magnifyingglass",
                    label: STStrings.zoomIn
                ) {
                    webEditorViewModel.zoomIn()
                }

                // Zoom Out
                STRibbonToolButton(
                    iconName: "minus.magnifyingglass",
                    label: STStrings.zoomOut
                ) {
                    webEditorViewModel.zoomOut()
                }

                STRibbonSeparator()

                // Go To Top
                STRibbonToolButton(
                    iconName: "arrow.up.to.line",
                    label: STStrings.ribbonGoToTop
                ) {
                    onGoToTop()
                }

                // Go To Bottom
                STRibbonToolButton(
                    iconName: "arrow.down.to.line",
                    label: STStrings.ribbonGoToBottom
                ) {
                    onGoToBottom()
                }

                STRibbonSeparator()

                // Bookmarks
                STRibbonToolButton(
                    iconName: "bookmark",
                    label: STStrings.ribbonBookmarks
                ) {
                    showBookmarksList = true
                }
                .sheet(isPresented: $showBookmarksList) {
                    STBookmarkListView(webEditorViewModel: webEditorViewModel)
                }
            }
            .padding(.horizontal, 8)
        }
    }
}
