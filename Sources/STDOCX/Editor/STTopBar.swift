import SwiftUI

/// Top navigation bar for the editor (placeholder — toolbar items are in STDOCXEditorView)
struct STTopBar: View {

    @ObservedObject var viewModel: STDOCXEditorViewModel

    var body: some View {
        // Top bar is implemented via .toolbar in STDOCXEditorView
        // This file exists for future extraction if needed
        EmptyView()
    }
}
