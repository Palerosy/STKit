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
    @State private var showDismissAlert = false

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
        .overlay {
            if viewModel.isSaving {
                savingOverlay
            }
        }
        #else
        STNavigationView {
            Group {
                if viewModel.viewMode == .documentEditor {
                    STPageEditorView(
                        viewModel: viewModel.pageEditorViewModel,
                        onDone: {
                            if viewModel.pageEditorViewModel.canUndo {
                                viewModel.hasUnsavedChanges = true
                            }
                            viewModel.viewMode = .viewer
                            viewModel.viewerViewModel.refreshPageCount()
                        }
                    )
                } else {
                    viewerContent
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
            .animation(.easeInOut(duration: 0.25), value: viewModel.viewMode)
            .overlay {
                if viewModel.isSaving {
                    savingOverlay
                }
            }
        }
        .stStackNavigationViewStyle()
        .toolbar(.hidden, for: .tabBar)
        #endif
    }

    @ViewBuilder
    private var viewerContent: some View {
        VStack(spacing: 0) {
            #if os(macOS)
            // macOS inline toolbar
            HStack {
                Button {
                    if viewModel.hasUnsavedChanges {
                        showDismissAlert = true
                    } else {
                        viewModel.saveAsync { onDismiss?() }
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isSaving)

                Spacer()

                Text(viewModel.document.title)
                    .font(.headline)
                    .lineLimit(1)

                Spacer()

                Button {
                    guard STKitConfiguration.shared.isPurchased else {
                        STKitConfiguration.shared.onPremiumFeatureTapped?()
                        if STKitConfiguration.shared.onPremiumFeatureTapped == nil {
                            viewModel.showPaywall = true
                        }
                        return
                    }
                    // Use the in-memory document for printing so custom annotation draw methods are preserved
                    viewModel.saveAsync {
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
                    }
                } label: {
                    Image(systemName: "printer")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isSaving)

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
                    if viewModel.hasUnsavedChanges {
                        showDismissAlert = true
                    } else {
                        viewModel.saveAsync { onDismiss?() }
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                .disabled(viewModel.isSaving)
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
                EmptyView()
            case .notes:
                STNotesListView(
                    document: viewModel.document.pdfDocument,
                    onNoteSelected: { index in
                        viewModel.viewerViewModel.goToPage(index)
                    },
                    onNoteDeleted: {
                        viewModel.annotationManager.forcePDFViewRedraw()
                    }
                )
            }
        }
        .alert(STStrings.unsavedChanges, isPresented: $showDismissAlert) {
            Button(STStrings.discard, role: .destructive) {
                viewModel.revertAsync { onDismiss?() }
            }
            Button(STStrings.saveAndClose) {
                if STKitConfiguration.shared.isPurchased {
                    viewModel.saveAsync { onDismiss?() }
                } else {
                    if let _ = STKitConfiguration.shared.onPremiumFeatureTapped {
                        STKitConfiguration.shared.onPremiumFeatureTapped?()
                    } else {
                        viewModel.showPaywall = true
                    }
                }
            }
            Button(STStrings.cancel, role: .cancel) {}
        } message: {
            Text(STStrings.unsavedChangesMessage)
        }
        #if os(iOS)
        .fullScreenCover(isPresented: $viewModel.showPaywall) {
            if let paywallView = STKitConfiguration.shared.premiumPaywallView {
                paywallView(configuration.paywallPlacement ?? STKitConfiguration.shared.paywallPlacement)
            }
        }
        #else
        .sheet(isPresented: $viewModel.showPaywall) {
            if let paywallView = STKitConfiguration.shared.premiumPaywallView {
                paywallView(configuration.paywallPlacement ?? STKitConfiguration.shared.paywallPlacement)
            }
        }
        #endif
        .onReceive(NotificationCenter.default.publisher(for: .purchaseStatusChanged)) { _ in
            if STKitConfiguration.shared.isPurchased && viewModel.hasUnsavedChanges {
                viewModel.saveAsync {
                    viewModel.showPaywall = false
                    viewModel.hasUnsavedChanges = false
                }
            }
        }
    }

    private var savingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            VStack(spacing: 12) {
                ProgressView()
                    .controlSize(.large)
                Text(STStrings.saving)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white)
            }
            .padding(24)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
        .allowsHitTesting(true)
    }
}
