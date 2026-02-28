import SwiftUI
import STKit

/// The main Excel editor view — drop-in SwiftUI component.
///
/// Usage:
/// ```swift
/// .fullScreenCover(isPresented: $showEditor) {
///     STExcelEditorView(url: xlsxURL) { savedURL in
///         print("Saved: \(savedURL)")
///     } onDismiss: {
///         showEditor = false
///     }
/// }
/// ```
public struct STExcelEditorView: View {

    private let url: URL?
    private let title: String?
    private let configuration: STExcelConfiguration
    private let onSave: ((URL) -> Void)?
    private let onDismiss: (() -> Void)?

    @State private var document: STExcelDocument?
    @State private var documentTitle = ""
    @State private var hasUnsavedChanges = false
    @State private var isSaving = false
    @State private var showExportOptions = false
    @State private var showShareSheet = false
    @State private var exportURL: URL?

    /// Create an editor for an existing xlsx file
    public init(
        url: URL,
        title: String? = nil,
        configuration: STExcelConfiguration = .default,
        onSave: ((URL) -> Void)? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        self.url = url
        self.title = title
        self.configuration = configuration
        self.onSave = onSave
        self.onDismiss = onDismiss
    }

    /// Create an editor for a new blank spreadsheet
    public init(
        title: String = "Untitled",
        configuration: STExcelConfiguration = .default,
        onSave: ((URL) -> Void)? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        self.url = nil
        self.title = title
        self.configuration = configuration
        self.onSave = onSave
        self.onDismiss = onDismiss
    }

    public var body: some View {
        NavigationView {
            ZStack {
                if let doc = document {
                    VStack(spacing: 0) {
                        // Grid
                        STExcelGridView(
                            sheet: doc.activeSheet,
                            configuration: configuration,
                            isEditable: configuration.isEditable
                        )

                        // Sheet tabs
                        if configuration.showSheetTabs && doc.sheets.count > 1 {
                            sheetTabs(doc)
                        }
                    }

                    // License watermark
                    if !STExcelKit.isLicensed {
                        STLicenseWatermark(moduleName: "STExcel")
                    }
                } else {
                    ProgressView()
                }
            }
            .navigationTitle(documentTitle)
            .stNavigationBarTitleDisplayMode()
            .toolbar {
                ToolbarItem(placement: .stLeading) {
                    Button {
                        onDismiss?()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                }

                ToolbarItemGroup(placement: .stTrailing) {
                    if configuration.showMoreMenu {
                        Menu {
                            if configuration.showExport {
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

                    if configuration.showSaveButton {
                        Button {
                            saveDocument()
                        } label: {
                            if isSaving {
                                ProgressView().scaleEffect(0.8)
                            } else {
                                Text(STStrings.save)
                                    .font(.system(size: 16, weight: .semibold))
                            }
                        }
                        .disabled(isSaving)
                    }
                }
            }
            .sheet(isPresented: $showExportOptions) {
                STExcelExportView(
                    document: document,
                    documentTitle: documentTitle,
                    onExport: { exportedURL in
                        exportURL = exportedURL
                        showExportOptions = false
                        showShareSheet = true
                    }
                )
                .stPresentationDetents([.height(280)])
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

    // MARK: - Sheet Tabs

    private func sheetTabs(_ doc: STExcelDocument) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(Array(doc.sheets.enumerated()), id: \.element.id) { index, sheet in
                    Button {
                        doc.activeSheetIndex = index
                    } label: {
                        Text(sheet.name)
                            .font(.system(size: 13, weight: index == doc.activeSheetIndex ? .semibold : .regular))
                            .foregroundColor(index == doc.activeSheetIndex ? .accentColor : .secondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                index == doc.activeSheetIndex
                                    ? Color.accentColor.opacity(0.1)
                                    : Color.clear
                            )
                    }

                    if index < doc.sheets.count - 1 {
                        Rectangle()
                            .fill(Color.stSeparator)
                            .frame(width: 0.5, height: 20)
                    }
                }
            }
            .padding(.horizontal, 8)
        }
        .frame(height: 40)
        .background(Color.stSecondarySystemBackground)
        .overlay(alignment: .top) {
            Divider()
        }
    }

    // MARK: - Load

    private func loadDocument() {
        if let url {
            documentTitle = title ?? url.deletingPathExtension().lastPathComponent
            document = STExcelDocument(url: url, title: documentTitle)
        } else {
            documentTitle = title ?? "Untitled"
            document = STExcelDocument(title: documentTitle)
        }
    }

    // MARK: - Save

    private func saveDocument() {
        guard let document else { return }
        isSaving = true

        DispatchQueue.global(qos: .userInitiated).async {
            let saveName = documentTitle.isEmpty ? "Spreadsheet" : documentTitle
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("\(saveName).xlsx")

            let success = document.save(to: tempURL)

            DispatchQueue.main.async {
                isSaving = false
                if success {
                    hasUnsavedChanges = false
                    onSave?(tempURL)
                }
            }
        }
    }
}
