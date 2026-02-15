import SwiftUI
import STKit

/// Read-only Excel viewer
///
/// ```swift
/// STExcelViewerView(url: xlsxURL) {
///     showViewer = false
/// }
/// ```
public struct STExcelViewerView: View {

    private let url: URL
    private let title: String?
    private let configuration: STExcelConfiguration
    private let onDismiss: (() -> Void)?

    public init(
        url: URL,
        title: String? = nil,
        configuration: STExcelConfiguration = .viewerDefault,
        onDismiss: (() -> Void)? = nil
    ) {
        self.url = url
        self.title = title
        self.configuration = configuration
        self.onDismiss = onDismiss
    }

    public var body: some View {
        STExcelEditorView(
            url: url,
            title: title,
            configuration: configuration,
            onDismiss: onDismiss
        )
    }
}
