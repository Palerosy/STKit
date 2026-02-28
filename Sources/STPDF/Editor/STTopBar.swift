import SwiftUI

/// Top navigation bar for the editor (placeholder — toolbar items are in STPDFEditorView)
struct STTopBar: View {

    @ObservedObject var viewModel: STPDFEditorViewModel

    var body: some View {
        // Top bar is implemented via .toolbar in STPDFEditorView
        // This file exists for future extraction if needed
        EmptyView()
    }
}
