import STKit
import SwiftUI
import PDFKit

/// Full-screen page editor with thumbnail grid and toolbar
struct STPageEditorView: View {

    @ObservedObject var viewModel: STPageEditorViewModel
    let onDone: () -> Void

    private let columns = [GridItem(.adaptive(minimum: 130), spacing: 20)]

    var body: some View {
        VStack(spacing: 0) {
            // Thumbnail grid
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(0..<viewModel.document.pageCount, id: \.self) { index in
                        pageThumbnailCell(for: index)
                            .id("\(index)-\(viewModel.thumbnailRefreshID)")
                            .onTapGesture {
                                viewModel.toggleSelection(index)
                            }
                    }
                }
                .padding(20)
                .padding(.bottom, 80)
            }
            .background(Color.stSystemBackground)

            // Bottom toolbar
            pageEditorToolbar
        }
        .stNavigationBarTitleDisplayMode()
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(STStrings.editPages)
                    .font(.headline)
            }
            ToolbarItem(placement: .stTrailing) {
                Button(STStrings.done) {
                    viewModel.document.save()
                    onDone()
                }
                .fontWeight(.semibold)
            }
        }
        .sheet(isPresented: $viewModel.showAddPageSheet) {
            STAddPageView(viewModel: viewModel)
        }
    }

    // MARK: - Thumbnail Cell

    @ViewBuilder
    private func pageThumbnailCell(for index: Int) -> some View {
        let isSelected = viewModel.selectedPages.contains(index)

        VStack(spacing: 8) {
            ZStack(alignment: .topLeading) {
                if let page = viewModel.document.page(at: index) {
                    let stPage = STPDFPage(id: index, page: page)
                    Image(platformImage: stPage.thumbnail(maxSize: 200))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 200)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(
                                    isSelected ? Color.accentColor : Color.gray.opacity(0.3),
                                    lineWidth: isSelected ? 3 : 1
                                )
                        )
                        .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
                }

                // Selection circle
                selectionCircle(isSelected: isSelected)
                    .padding(6)
            }

            Text("\(index + 1)")
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.accentColor : Color.clear)
                )
        }
    }

    @ViewBuilder
    private func selectionCircle(isSelected: Bool) -> some View {
        ZStack {
            Circle()
                .fill(isSelected ? Color.accentColor : Color.white.opacity(0.9))
                .frame(width: 24, height: 24)
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.accentColor : Color.gray.opacity(0.4), lineWidth: 1.5)
                )

            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }

    // MARK: - Toolbar

    private var pageEditorToolbar: some View {
        VStack(spacing: 0) {
            Divider()
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    toolbarButton(
                        icon: "plus.rectangle",
                        label: STStrings.pageNewPage,
                        enabled: true
                    ) {
                        viewModel.showAddPageSheet = true
                    }

                    toolbarButton(
                        icon: "trash",
                        label: STStrings.pageRemove,
                        enabled: viewModel.hasSelection && viewModel.selectedPages.count < viewModel.document.pageCount
                    ) {
                        viewModel.removeSelectedPages()
                    }

                    toolbarButton(
                        icon: "plus.square.on.square",
                        label: STStrings.pageDuplicate,
                        enabled: viewModel.hasSelection
                    ) {
                        viewModel.duplicateSelectedPages()
                    }

                    toolbarDivider

                    toolbarButton(
                        icon: "rotate.right",
                        label: STStrings.pageRotate,
                        enabled: viewModel.hasSelection
                    ) {
                        viewModel.rotateSelectedPages()
                    }

                    toolbarButton(
                        icon: "checkmark.circle",
                        label: viewModel.allSelected ? STStrings.pageDeselectAll : STStrings.pageSelectAll,
                        enabled: true
                    ) {
                        viewModel.selectAll()
                    }

                    toolbarDivider

                    toolbarButton(
                        icon: "scissors",
                        label: STStrings.pageCut,
                        enabled: viewModel.hasSelection && viewModel.selectedPages.count < viewModel.document.pageCount
                    ) {
                        viewModel.cutSelectedPages()
                    }

                    toolbarButton(
                        icon: "doc.on.doc",
                        label: STStrings.pageCopy,
                        enabled: viewModel.hasSelection
                    ) {
                        viewModel.copySelectedPages()
                    }

                    toolbarButton(
                        icon: "clipboard",
                        label: STStrings.pagePaste,
                        enabled: viewModel.hasClipboard
                    ) {
                        viewModel.paste()
                    }

                    toolbarDivider

                    toolbarButton(
                        icon: "arrow.uturn.backward",
                        label: STStrings.undo,
                        enabled: viewModel.canUndo
                    ) {
                        viewModel.undo()
                    }

                    toolbarButton(
                        icon: "arrow.uturn.forward",
                        label: STStrings.redo,
                        enabled: viewModel.canRedo
                    ) {
                        viewModel.redo()
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .background(Color.stSystemBackground)
        }
    }

    @ViewBuilder
    private func toolbarButton(icon: String, label: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                Text(label)
                    .font(.system(size: 10))
                    .lineLimit(1)
            }
            .frame(minWidth: 60)
            .padding(.vertical, 6)
            .padding(.horizontal, 4)
            .foregroundColor(enabled ? .accentColor : .gray)
        }
        .disabled(!enabled)
    }

    private var toolbarDivider: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .frame(width: 1, height: 36)
            .padding(.horizontal, 4)
    }
}
