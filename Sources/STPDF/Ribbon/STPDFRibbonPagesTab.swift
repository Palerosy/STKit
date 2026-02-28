import STKit
import SwiftUI

/// Pages tab — page management shortcuts
struct STPDFRibbonPagesTab: View {

    @ObservedObject var viewModel: STPDFEditorViewModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 2) {

                // Open full page editor
                STPDFRibbonToolButton(
                    iconName: "doc.badge.gearshape",
                    label: STStrings.editPages
                ) {
                    viewModel.viewMode = .documentEditor
                }

                STPDFRibbonSeparator()

                // Thumbnail grid (shortcut)
                STPDFRibbonToolButton(
                    iconName: "rectangle.grid.2x2",
                    label: STStrings.ribbonThumbnails
                ) {
                    viewModel.activeSheet = .thumbnails
                }
            }
            .padding(.horizontal, 8)
        }
    }
}
