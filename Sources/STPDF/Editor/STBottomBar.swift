import STKit
import SwiftUI

/// Bottom toolbar with page navigation and feature buttons
struct STBottomBar: View {

    @ObservedObject var viewModel: STPDFEditorViewModel

    var body: some View {
        VStack(spacing: 0) {
            Divider()

            HStack {
                Spacer()

                // Pages → open page editor
                if viewModel.configuration.showThumbnails {
                    bottomButton(icon: "rectangle.grid.2x2", label: STStrings.pages) {
                        viewModel.viewMode = .documentEditor
                    }
                }

                Spacer()

                // Add Text
                bottomButton(icon: "textformat", label: STStrings.addText) {
                    viewModel.activateAnnotationTool(.freeText)
                }

                Spacer()

                // Remove Text
                bottomButton(icon: "text.badge.minus", label: STStrings.removeText) {
                    viewModel.activateAnnotationTool(.textRemove)
                }

                Spacer()

                // Search
                if viewModel.configuration.showSearch {
                    bottomButton(icon: "magnifyingglass", label: STStrings.search) {
                        viewModel.activeSheet = .search
                    }
                }

                Spacer()
            }
            .padding(.vertical, 10)
            .background(.bar)
        }
    }

    private func bottomButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                Text(label)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(.accentColor)
        }
    }
}
