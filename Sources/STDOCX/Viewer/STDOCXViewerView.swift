import SwiftUI
import STKit

/// Read-only DOCX viewer — displays document content without editing capabilities.
///
/// Usage:
/// ```swift
/// STDOCXViewerView(url: docxURL) {
///     showViewer = false
/// }
/// ```
public struct STDOCXViewerView: View {

    private let url: URL
    private let title: String?
    private let configuration: STDOCXConfiguration
    private let onDismiss: (() -> Void)?

    @State private var attributedText = NSAttributedString()
    @State private var documentTitle: String = ""
    @State private var showWordCount = false
    @State private var showShareSheet = false
    @State private var showExportOptions = false
    @State private var exportURL: URL?

    public init(
        url: URL,
        title: String? = nil,
        configuration: STDOCXConfiguration = .viewerDefault,
        onDismiss: (() -> Void)? = nil
    ) {
        self.url = url
        self.title = title
        self.configuration = configuration
        self.onDismiss = onDismiss
    }

    public var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    STDOCXContentView(attributedText: attributedText, configuration: configuration)
                        .padding(
                            EdgeInsets(
                                top: configuration.textInsets.top,
                                leading: configuration.textInsets.leading,
                                bottom: configuration.textInsets.bottom,
                                trailing: configuration.textInsets.trailing
                            )
                        )
                }
                .background(configuration.appearance.backgroundColor)

                // License watermark
                if !STDOCX.isLicensed {
                    STLicenseWatermark(moduleName: "STDOCX")
                }
            }
            .navigationTitle(documentTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        onDismiss?()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        if configuration.showWordCount {
                            Button {
                                showWordCount = true
                            } label: {
                                Label(STStrings.wordCount, systemImage: "textformat.123")
                            }
                        }

                        if configuration.showExport {
                            Divider()
                            Button {
                                showExportOptions = true
                            } label: {
                                Label(STStrings.export, systemImage: "square.and.arrow.up")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 18, weight: .medium))
                    }
                }
            }
            .sheet(isPresented: $showWordCount) {
                STDOCXWordCountView(attributedText: attributedText)
                    .presentationDetents([.height(300)])
            }
            .sheet(isPresented: $showExportOptions) {
                STDOCXExportView(
                    attributedText: attributedText,
                    documentTitle: documentTitle,
                    onExport: { exportedURL in
                        exportURL = exportedURL
                        showExportOptions = false
                        showShareSheet = true
                    }
                )
                .presentationDetents([.height(320)])
            }
            .sheet(isPresented: $showShareSheet) {
                if let shareURL = exportURL {
                    STShareSheet(activityItems: [shareURL])
                }
            }
        }
        .onAppear {
            loadDocument()
        }
    }

    private func loadDocument() {
        documentTitle = title ?? url.deletingPathExtension().lastPathComponent

        if let content = STDOCXConverter.readFile(at: url) {
            attributedText = content
        }
    }
}

// MARK: - Viewer Default Configuration

public extension STDOCXConfiguration {
    /// Default configuration for viewer (read-only, no formatting toolbar)
    static var viewerDefault: STDOCXConfiguration {
        var config = STDOCXConfiguration()
        config.isEditable = false
        config.showFormattingToolbar = false
        config.showSaveButton = false
        return config
    }
}

// MARK: - Content View (renders attributed text read-only)

struct STDOCXContentView: UIViewRepresentable {
    let attributedText: NSAttributedString
    let configuration: STDOCXConfiguration

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.attributedText = attributedText
        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        textView.attributedText = attributedText
    }
}
