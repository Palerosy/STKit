import STKit
import SwiftUI

/// View tab — navigation and display options
struct STPDFRibbonViewTab: View {

    @ObservedObject var viewModel: STPDFEditorViewModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 2) {

                // Search
                STPDFRibbonToolButton(
                    iconName: "magnifyingglass",
                    label: STStrings.search
                ) {
                    viewModel.activeSheet = .search
                }

                // Outline
                STPDFRibbonToolButton(
                    iconName: "list.bullet.indent",
                    label: STStrings.outline
                ) {
                    viewModel.activeSheet = .outline
                }

                // Thumbnails grid
                STPDFRibbonToolButton(
                    iconName: "rectangle.grid.2x2",
                    label: STStrings.ribbonThumbnails
                ) {
                    viewModel.activeSheet = .thumbnails
                }

                STPDFRibbonSeparator()

                // Zoom In
                STPDFRibbonToolButton(
                    iconName: "plus.magnifyingglass",
                    label: STStrings.zoomIn
                ) {
                    viewModel.annotationManager.zoomIn()
                }

                // Zoom Out
                STPDFRibbonToolButton(
                    iconName: "minus.magnifyingglass",
                    label: STStrings.zoomOut
                ) {
                    viewModel.annotationManager.zoomOut()
                }

                // Settings removed — not useful on iOS
            }
            .padding(.horizontal, 8)
        }
    }
}
