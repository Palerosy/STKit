import SwiftUI
import PDFKit

/// Floating horizontal page thumbnail strip — overlaid at the bottom of the editor.
/// Matches compact pill design with "X of Y" counter and scrollable page previews.
struct STPageThumbnailStrip: View {

    @ObservedObject var viewModel: STDOCXViewerViewModel
    let onDismiss: () -> Void

    private let thumbHeight: CGFloat = 60

    var body: some View {
        VStack(spacing: 6) {
            // Page counter pill
            Text("\(viewModel.currentPageIndex + 1) of \(viewModel.totalPages)")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

            // Horizontal thumbnail scroll in rounded container
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 6) {
                        ForEach(0..<viewModel.totalPages, id: \.self) { index in
                            thumbnailCell(for: index)
                                .id(index)
                                .onTapGesture {
                                    viewModel.goToPage(index)
                                }
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation {
                            proxy.scrollTo(viewModel.currentPageIndex, anchor: .center)
                        }
                    }
                }
                .onChange(of: viewModel.currentPageIndex) { newIndex in
                    withAnimation(.easeInOut(duration: 0.25)) {
                        proxy.scrollTo(newIndex, anchor: .center)
                    }
                }
            }
            .frame(height: thumbHeight + 16)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
            .padding(.horizontal, 24)
        }
    }

    @ViewBuilder
    private func thumbnailCell(for index: Int) -> some View {
        let isSelected = viewModel.currentPageIndex == index

        if let page = viewModel.document.page(at: index) {
            let stPage = STDOCXPage(id: index, page: page)
            Image(platformImage: stPage.thumbnail(maxSize: thumbHeight * 2))
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: thumbHeight)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(
                            isSelected ? Color.accentColor : Color.clear,
                            lineWidth: isSelected ? 2.5 : 0
                        )
                )
        }
    }
}
