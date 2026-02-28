import STKit
import SwiftUI
import PDFKit

/// The main PDF editor view — drop-in replacement for PSPDFKitEditorView.
///
/// Usage:
/// ```swift
/// .fullScreenCover(isPresented: $showEditor) {
///     STPDFEditorView(url: pdfURL, title: "My Document") {
///         showEditor = false
///     }
///     .ignoresSafeArea()
/// }
/// ```
public struct STPDFEditorView: View {

    private let url: URL
    private let title: String?
    private let openInPageEditor: Bool
    private let configuration: STPDFConfiguration
    private let onDismiss: (() -> Void)?

    @StateObject private var viewModel: STPDFEditorViewModel
    @StateObject private var bookmarkManager: STBookmarkManager

    public init(
        url: URL,
        title: String? = nil,
        openInPageEditor: Bool = false,
        configuration: STPDFConfiguration = .default,
        onDismiss: (() -> Void)? = nil
    ) {
        self.url = url
        self.title = title
        self.openInPageEditor = openInPageEditor
        self.configuration = configuration
        self.onDismiss = onDismiss

        let doc = STPDFDocument(url: url, title: title) ?? STPDFDocument(
            document: PDFDocument(),
            url: url,
            title: title ?? STStrings.untitled
        )

        _viewModel = StateObject(wrappedValue: STPDFEditorViewModel(
            document: doc,
            configuration: configuration,
            openInPageEditor: openInPageEditor
        ))
        _bookmarkManager = StateObject(wrappedValue: STBookmarkManager(documentURL: url))
    }

    public var body: some View {
        #if os(macOS)
        Group {
            if viewModel.viewMode == .documentEditor {
                STPageEditorView(
                    viewModel: viewModel.pageEditorViewModel,
                    onDone: {
                        viewModel.viewMode = .viewer
                        viewModel.viewerViewModel.refreshPageCount()
                    }
                )
            } else {
                viewerContent
            }
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.viewMode)
        #else
        STNavigationView {
            Group {
                if viewModel.viewMode == .documentEditor {
                    STPageEditorView(
                        viewModel: viewModel.pageEditorViewModel,
                        onDone: {
                            viewModel.viewMode = .viewer
                            viewModel.viewerViewModel.refreshPageCount()
                        }
                    )
                } else {
                    viewerContent
                }
            }
            .animation(.easeInOut(duration: 0.25), value: viewModel.viewMode)
        }
        .stStackNavigationViewStyle()
        #endif
    }

    @ViewBuilder
    private var viewerContent: some View {
        VStack(spacing: 0) {
            #if os(macOS)
            // macOS inline toolbar
            HStack {
                Button {
                    viewModel.serializer.save()
                    onDismiss?()
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

                Button {
                    // Use the in-memory document for printing so custom annotation draw methods are preserved
                    viewModel.serializer.save()
                    let printDoc = viewModel.document.pdfDocument
                    let printInfo = NSPrintInfo.shared.copy() as! NSPrintInfo
                    printInfo.isHorizontallyCentered = true
                    printInfo.isVerticallyCentered = true
                    printInfo.scalingFactor = 1.0
                    if let printOp = printDoc.printOperation(for: printInfo, scalingMode: .pageScaleToFit, autoRotate: true) {
                        printOp.showsPrintPanel = true
                        printOp.showsProgressPanel = true
                        printOp.run()
                    }
                } label: {
                    Image(systemName: "printer")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
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

            // Ribbon — tab bar + collapsible tool strip at the top
            STPDFRibbonView(viewModel: viewModel)

            // PDF Viewer fills the remaining space
            STPDFViewerView(
                viewModel: viewModel.viewerViewModel,
                configuration: configuration,
                annotationManager: viewModel.annotationManager,
                isAnnotationModeActive: viewModel.ribbonSelectedTab.isAnnotationTab
            )

            // Page thumbnail strip — below the viewer, not overlapping
            STPageThumbnailStrip(
                viewModel: viewModel.viewerViewModel,
                onDismiss: { }
            )
            .padding(.vertical, 8)
        }
        #if os(iOS)
        .stNavigationBarTitleDisplayMode()
        .toolbar {
            ToolbarItem(placement: .stLeading) {
                Button {
                    viewModel.serializer.save()
                    onDismiss?()
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
                STMoreMenu(
                    viewModel: viewModel,
                    bookmarkManager: bookmarkManager,
                    configuration: configuration
                )
            }
        }
        #endif
        .sheet(item: $viewModel.activeSheet) { sheet in
            switch sheet {
            case .thumbnails:
                STThumbnailGridView(viewModel: viewModel.viewerViewModel)
            case .search:
                STSearchView(
                    document: viewModel.document.pdfDocument,
                    onResultSelected: { selection in
                        if let page = selection.pages.first {
                            let index = viewModel.document.pdfDocument.index(for: page)
                            viewModel.viewerViewModel.goToPage(index)
                        }
                        // Highlight found text in yellow, then clear after 1.5s
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            viewModel.highlightSearchResult(selection)
                        }
                    }
                )
            case .outline:
                STOutlineView(
                    document: viewModel.document.pdfDocument,
                    onPageSelected: { index in
                        viewModel.viewerViewModel.goToPage(index)
                    }
                )
            case .settings:
                STSettingsView()
            }
        }
    }
}
