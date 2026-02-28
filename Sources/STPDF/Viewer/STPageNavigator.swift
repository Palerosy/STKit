import SwiftUI

/// Page navigation indicator shown at the bottom of the viewer
struct STPageNavigator: View {

    @ObservedObject var viewModel: STPDFViewerViewModel

    var body: some View {
        HStack(spacing: 16) {
            Button {
                viewModel.previousPage()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
            }
            .disabled(viewModel.currentPageIndex == 0)

            Text(viewModel.pageLabel)
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundColor(.secondary)

            Button {
                viewModel.nextPage()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
            }
            .disabled(viewModel.currentPageIndex >= viewModel.totalPages - 1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
    }
}
