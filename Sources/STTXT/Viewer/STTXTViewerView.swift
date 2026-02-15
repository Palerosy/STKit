import SwiftUI
import STKit

/// Read-only text viewer
///
/// ```swift
/// STTXTViewerView(url: txtURL) {
///     showViewer = false
/// }
/// ```
public struct STTXTViewerView: View {

    private let url: URL
    private let title: String?
    private let onDismiss: (() -> Void)?

    public init(
        url: URL,
        title: String? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        self.url = url
        self.title = title
        self.onDismiss = onDismiss
    }

    public var body: some View {
        STTXTEditorView(
            url: url,
            title: title,
            configuration: .viewerDefault,
            onDismiss: onDismiss
        )
    }
}
