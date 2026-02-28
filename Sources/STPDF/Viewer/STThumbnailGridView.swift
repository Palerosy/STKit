import STKit
import SwiftUI
import PDFKit

/// Grid view of page thumbnails for quick navigation
struct STThumbnailGridView: View {

    @ObservedObject var viewModel: STPDFViewerViewModel
    @Environment(\.dismiss) private var dismiss

    private let columns = [GridItem(.adaptive(minimum: 120), spacing: 20)]

    var body: some View {
        #if os(macOS)
        macOSBody
        #else
        iOSBody
        #endif
    }

    private var thumbnailGrid: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(0..<viewModel.totalPages, id: \.self) { index in
                        thumbnailCell(for: index)
                            .id(index)
                            .onTapGesture {
                                viewModel.goToPage(index)
                                dismiss()
                            }
                    }
                }
                .padding(20)
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation {
                        proxy.scrollTo(viewModel.currentPageIndex, anchor: .center)
                    }
                }
            }
        }
        .background(Color.stSystemBackground)
    }

    #if os(macOS)
    private var macOSBody: some View {
        let sw = NSScreen.main?.frame.width ?? 1440
        let sh = NSScreen.main?.frame.height ?? 900
        return VStack(spacing: 0) {
            HStack {
                Text(STStrings.pages)
                    .font(.headline)
                Spacer()
                Button(STStrings.done) { dismiss() }
                    .buttonStyle(.plain)
                    .foregroundColor(.accentColor)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            Divider()

            thumbnailGrid
                .frame(maxHeight: sh * 0.55)
        }
        .frame(width: sw * 0.45)
    }
    #endif

    private var iOSBody: some View {
        STNavigationView {
            thumbnailGrid
                .navigationTitle(STStrings.pages)
                .stNavigationBarTitleDisplayMode()
                .toolbar {
                    ToolbarItem(placement: .stTrailing) {
                        Button(STStrings.done) { dismiss() }
                            .fontWeight(.semibold)
                    }
                }
        }
    }

    @ViewBuilder
    private func thumbnailCell(for index: Int) -> some View {
        let isSelected = viewModel.currentPageIndex == index

        VStack(spacing: 8) {
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
                                isSelected ? Color.accentColor : Color.clear,
                                lineWidth: 3
                            )
                    )
                    .shadow(color: .black.opacity(0.12), radius: 4, x: 0, y: 2)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isSelected ? Color.accentColor.opacity(0.08) : Color.clear)
                            .padding(-4)
                    )
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
}
