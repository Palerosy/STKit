import SwiftUI
import UIKit
import STKit

/// The main DOCX editor view — drop-in SwiftUI component.
///
/// Usage:
/// ```swift
/// .fullScreenCover(isPresented: $showEditor) {
///     STDOCXEditorView(url: docxURL, title: "My Document") {
///         showEditor = false
///     }
/// }
/// ```
public struct STDOCXEditorView: View {

    private let url: URL?
    private let title: String?
    private let configuration: STDOCXConfiguration
    private let onDismiss: (() -> Void)?
    private let onSave: ((URL) -> Void)?

    @StateObject private var editorState = STDOCXEditorState()
    @State private var attributedText = NSAttributedString()
    @State private var documentTitle: String = ""
    @State private var hasUnsavedChanges = false
    @State private var isSaving = false
    @State private var showDiscardAlert = false
    @State private var showShareSheet = false
    @State private var showExportOptions = false
    @State private var showFontPicker = false
    @State private var showColorPicker = false
    @State private var showWordCount = false
    @State private var exportURL: URL?

    /// Create an editor for an existing DOCX file
    /// - Parameters:
    ///   - url: URL of the DOCX file to open
    ///   - title: Optional display title (defaults to filename)
    ///   - configuration: Editor configuration
    ///   - onSave: Called when the user saves (receives the saved URL)
    ///   - onDismiss: Called when the editor is dismissed
    public init(
        url: URL,
        title: String? = nil,
        configuration: STDOCXConfiguration = .default,
        onSave: ((URL) -> Void)? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        self.url = url
        self.title = title
        self.configuration = configuration
        self.onSave = onSave
        self.onDismiss = onDismiss
    }

    /// Create an editor for a new blank document
    /// - Parameters:
    ///   - title: Display title for the new document
    ///   - configuration: Editor configuration
    ///   - onSave: Called when the user saves
    ///   - onDismiss: Called when the editor is dismissed
    public init(
        title: String = "Untitled",
        configuration: STDOCXConfiguration = .default,
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
            VStack(spacing: 0) {
                // Formatting Toolbar
                if configuration.showFormattingToolbar {
                    STDOCXFormattingToolbar(
                        editorState: editorState,
                        configuration: configuration,
                        onFontTap: { showFontPicker = true },
                        onColorTap: { showColorPicker = true }
                    )
                    Divider()
                }

                // Editor
                ZStack {
                    STDOCXTextView(
                        editorState: editorState,
                        attributedText: $attributedText,
                        configuration: configuration
                    )
                    .onChange(of: attributedText) { _ in
                        hasUnsavedChanges = true
                    }

                    // License watermark
                    if !STDOCX.isLicensed {
                        STLicenseWatermark(moduleName: "STDOCX")
                    }
                }
            }
            .navigationTitle(documentTitle.isEmpty ? STStrings.newDocument : documentTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        if hasUnsavedChanges {
                            showDiscardAlert = true
                        } else {
                            onDismiss?()
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                }

                ToolbarItemGroup(placement: .topBarTrailing) {
                    if configuration.showMoreMenu {
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

                    if configuration.showSaveButton {
                        Button {
                            saveDocument()
                        } label: {
                            if isSaving {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Text(STStrings.save)
                                    .font(.system(size: 16, weight: .semibold))
                            }
                        }
                        .disabled(isSaving)
                    }
                }
            }
            .alert(STStrings.unsavedChanges, isPresented: $showDiscardAlert) {
                Button(STStrings.discard, role: .destructive) {
                    onDismiss?()
                }
                Button(STStrings.saveAndClose) {
                    saveDocument()
                    onDismiss?()
                }
                Button(STStrings.cancel, role: .cancel) {}
            } message: {
                Text(STStrings.unsavedChangesMessage)
            }
            .sheet(isPresented: $showFontPicker) {
                STDOCXFontPicker(editorState: editorState)
                    .presentationDetents([.medium])
            }
            .sheet(isPresented: $showColorPicker) {
                STDOCXColorPicker(editorState: editorState)
                    .presentationDetents([.medium])
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

    // MARK: - Load

    private func loadDocument() {
        guard let url else {
            let font = UIFont(name: configuration.defaultFontName, size: configuration.defaultFontSize)
                ?? UIFont.systemFont(ofSize: configuration.defaultFontSize)
            attributedText = NSAttributedString(
                string: "",
                attributes: [.font: font, .foregroundColor: UIColor.label]
            )
            documentTitle = title ?? STStrings.newDocument
            hasUnsavedChanges = false
            return
        }

        documentTitle = title ?? url.deletingPathExtension().lastPathComponent

        if let content = STDOCXConverter.readFile(at: url) {
            attributedText = content
        } else if let text = try? String(contentsOf: url, encoding: .utf8) {
            let font = UIFont(name: configuration.defaultFontName, size: configuration.defaultFontSize)
                ?? UIFont.systemFont(ofSize: configuration.defaultFontSize)
            attributedText = NSAttributedString(string: text, attributes: [.font: font])
        }

        hasUnsavedChanges = false
    }

    // MARK: - Save

    private func saveDocument() {
        isSaving = true

        DispatchQueue.global(qos: .userInitiated).async {
            let saveName = documentTitle.isEmpty ? "Document" : documentTitle
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("\(saveName).docx")

            let doc = STDOCXConverter.toDocument(attributedText)
            let success = (try? doc.write(to: tempURL)) != nil

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
