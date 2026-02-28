import SwiftUI
import STKit
import PDFKit
import PhotosUI

/// DOCX blue theme color (Microsoft Word style)
private let docxBlue = Color(red: 0.17, green: 0.35, blue: 0.60)

/// The main DOCX editor view with ribbon menu and text editing.
///
/// Usage:
/// ```swift
/// .fullScreenCover(isPresented: $showEditor) {
///     STDOCXEditorView(url: docxURL, title: "My Document") {
///         showEditor = false
///     }
///     .ignoresSafeArea()
/// }
/// ```
public struct STDOCXEditorView: View {

    private let url: URL
    private let title: String?
    private let configuration: STDOCXConfiguration
    private let onDismiss: (() -> Void)?

    @StateObject private var viewModel: STDOCXEditorViewModel
    @StateObject private var bookmarkManager: STBookmarkManager
    @StateObject private var ribbonViewModel: STRibbonViewModel

    public init(
        url: URL,
        title: String? = nil,
        configuration: STDOCXConfiguration = .default,
        onDismiss: (() -> Void)? = nil
    ) {
        self.url = url
        self.title = title
        self.configuration = configuration
        self.onDismiss = onDismiss

        let doc = STDOCXDocument(url: url, title: title) ?? STDOCXDocument(
            document: PDFDocument(),
            url: url,
            title: title ?? STStrings.untitled
        )

        _viewModel = StateObject(wrappedValue: STDOCXEditorViewModel(
            document: doc,
            configuration: configuration
        ))
        _bookmarkManager = StateObject(wrappedValue: STBookmarkManager(documentURL: url))
        _ribbonViewModel = StateObject(wrappedValue: STRibbonViewModel())
    }

    @State private var isKeyboardVisible = false
    @State private var showPhotoPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showShareSheet = false

    /// Print the current document content
    private func printDocument() {
        if let onPrint = configuration.onPrint ?? STKitConfiguration.shared.onPrint, !onPrint() { return }
        viewModel.webEditorViewModel.printContent()
    }

    /// Dismiss keyboard globally
    private func dismissKeyboard() {
        #if os(iOS)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #elseif os(macOS)
        NSApplication.shared.keyWindow?.makeFirstResponder(nil)
        #endif
    }

    public var body: some View {
        #if os(macOS)
        editorContent
            .tint(docxBlue)
            .task {
                await viewModel.loadDocIfNeeded()
                if viewModel.webEditorViewModel.isReady {
                    viewModel.webEditorViewModel.loadContent()
                }
            }
        #else
        NavigationView {
            editorContent
        }
        .stStackNavigationViewStyle()
        .tint(docxBlue)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            isKeyboardVisible = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            isKeyboardVisible = false
        }
        .task {
            await viewModel.loadDocIfNeeded()
            if viewModel.webEditorViewModel.isReady {
                viewModel.webEditorViewModel.loadContent()
            }
        }
        #endif
    }

    @ViewBuilder
    private var editorContent: some View {
        VStack(spacing: 0) {
            #if os(macOS)
            // macOS inline toolbar
            HStack {
                Button {
                    dismissKeyboard()
                    Task {
                        await viewModel.webEditorViewModel.saveContent()
                        if let docURL = viewModel.document.url {
                            viewModel.document.save(to: docURL)
                        }
                        onDismiss?()
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)

                Spacer()

                Text(viewModel.document.title)
                    .font(.headline)
                    .lineLimit(1)

                Spacer()

                // Print
                Button {
                    dismissKeyboard()
                    printDocument()
                } label: {
                    Image(systemName: "printer")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)

                // Hand / Select mode toggle
                Button {
                    let newMode = !viewModel.webEditorViewModel.isSelectMode
                    viewModel.webEditorViewModel.setSelectMode(newMode)
                    if newMode { dismissKeyboard() }
                } label: {
                    Image(systemName: viewModel.webEditorViewModel.isSelectMode
                          ? "hand.raised.fill" : "hand.raised")
                        .font(.system(size: 14))
                        .foregroundColor(viewModel.webEditorViewModel.isSelectMode
                                         ? docxBlue : .secondary)
                }
                .buttonStyle(.plain)

                STMoreMenu(
                    viewModel: viewModel,
                    bookmarkManager: bookmarkManager,
                    configuration: configuration
                )
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()
            #endif

            // Ribbon menu (always visible)
            STRibbonView(
                ribbonViewModel: ribbonViewModel,
                annotationManager: viewModel.annotationManager,
                webEditorViewModel: viewModel.webEditorViewModel,
                onShowOutline: { viewModel.activeSheet = .outline },
                onShowSearch: { viewModel.activeSheet = .search },
                onShowWordCount: { viewModel.activeSheet = .wordCount },
                onGoToTop: { viewModel.webEditorViewModel.scrollToTop() },
                onGoToBottom: { viewModel.webEditorViewModel.scrollToBottom() },
                onActivateDrawTool: { _ in },
                onInsertImage: {
                    showPhotoPicker = true
                }
            )

            // Content area — switch by viewMode
            switch viewModel.viewMode {
            case .textEditor:
                STWebEditorView(viewModel: viewModel.webEditorViewModel)

                // Page indicator
                if viewModel.webEditorViewModel.totalPages > 1 && !isKeyboardVisible {
                    HStack {
                        Spacer()
                        Text("\(viewModel.webEditorViewModel.currentPage + 1) / \(viewModel.webEditorViewModel.totalPages)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial)
                }

            case .annotations:
                // Placeholder for future annotation mode
                Spacer()
                Text("Annotations mode")
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        #if os(iOS)
        .stNavigationBarTitleDisplayMode()
        .toolbar {
            ToolbarItem(placement: .stLeading) {
                Button {
                    dismissKeyboard()
                    Task {
                        await viewModel.webEditorViewModel.saveContent()
                        if let docURL = viewModel.document.url {
                            viewModel.document.save(to: docURL)
                        }
                        onDismiss?()
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }

            ToolbarItem(placement: .principal) {
                Text(viewModel.document.title)
                    .font(.headline)
                    .lineLimit(1)
            }

            ToolbarItem(placement: .stTrailing) {
                HStack(spacing: 12) {
                    // Hand / Select mode toggle
                    Button {
                        let newMode = !viewModel.webEditorViewModel.isSelectMode
                        viewModel.webEditorViewModel.setSelectMode(newMode)
                        if newMode { dismissKeyboard() }
                    } label: {
                        Image(systemName: viewModel.webEditorViewModel.isSelectMode
                              ? "hand.raised.fill" : "hand.raised")
                            .font(.system(size: 16))
                            .foregroundColor(viewModel.webEditorViewModel.isSelectMode
                                             ? docxBlue : .secondary)
                    }

                    STMoreMenu(
                        viewModel: viewModel,
                        bookmarkManager: bookmarkManager,
                        configuration: configuration
                    )
                }
            }
        }
        #endif
        .sheet(item: $viewModel.activeSheet) { sheet in
            switch sheet {
            case .thumbnails:
                STThumbnailGridView(viewModel: viewModel.viewerViewModel)
            case .search:
                STSearchView(webEditorViewModel: viewModel.webEditorViewModel)
            case .outline:
                STOutlineView(
                    document: viewModel.document.pdfDocument,
                    onPageSelected: { index in
                        viewModel.webEditorViewModel.goToPage(index)
                    }
                )
            case .settings:
                STSettingsView(webEditorViewModel: viewModel.webEditorViewModel)
            case .wordCount:
                STDOCXWordCountView(webEditorViewModel: viewModel.webEditorViewModel)
            }
        }
        .alert(
            STStrings.ribbonComment,
            isPresented: Binding(
                get: { viewModel.webEditorViewModel.tappedComment != nil },
                set: { if !$0 { viewModel.webEditorViewModel.tappedComment = nil } }
            ),
            presenting: viewModel.webEditorViewModel.tappedComment
        ) { comment in
            Button(STStrings.delete, role: .destructive) {
                viewModel.webEditorViewModel.deleteComment(id: comment.id)
                viewModel.webEditorViewModel.tappedComment = nil
            }
            Button(STStrings.done, role: .cancel) {
                viewModel.webEditorViewModel.tappedComment = nil
            }
        } message: { comment in
            Text(comment.text)
        }
        .sheet(isPresented: Binding(
            get: { viewModel.webEditorViewModel.isChartEditorVisible },
            set: { viewModel.webEditorViewModel.isChartEditorVisible = $0 }
        )) {
            if let chartModel = viewModel.webEditorViewModel.editingChartModel {
                STChartDataEditorView(
                    model: chartModel,
                    onDone: { viewModel.webEditorViewModel.applyChartEdit() },
                    onCancel: { viewModel.webEditorViewModel.cancelChartEdit() }
                )
                .stPresentationDetents([.large])
                .stPresentationDragIndicator(.visible)
            }
        }
        #if os(iOS)
        .sheet(isPresented: $showShareSheet) {
            if let docURL = viewModel.document.url {
                ActivityShareSheet(activityItems: [docURL])
            }
        }
        #endif
        .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhotoItem, matching: .images)
        .onChange(of: selectedPhotoItem) { item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   PlatformImage(data: data) != nil {
                    viewModel.webEditorViewModel.insertImage(data: data)
                } else if let image = try? await item.loadTransferable(type: STTransferableImage.self) {
                    if let jpegData = image.platformImage.jpegData(compressionQuality: 0.8) {
                        viewModel.webEditorViewModel.insertImage(data: jpegData)
                    }
                }
                selectedPhotoItem = nil
            }
        }
    }
}

// MARK: - Share Sheet Helper

#if os(iOS)
private struct ActivityShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif

// MARK: - Transferable Image Helper

struct STTransferableImage: Transferable {
    let platformImage: PlatformImage

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(importedContentType: .image) { data in
            guard let image = PlatformImage(data: data) else {
                throw TransferError.importFailed
            }
            return STTransferableImage(platformImage: image)
        }
    }

    enum TransferError: Error {
        case importFailed
    }
}
