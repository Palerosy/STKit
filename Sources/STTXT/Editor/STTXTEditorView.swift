import SwiftUI
import STKit
#if os(macOS)
import AppKit
#endif

/// Plain text editor view — drop-in SwiftUI component.
///
/// Usage:
/// ```swift
/// .fullScreenCover(isPresented: $showEditor) {
///     STTXTEditorView(url: txtURL) { savedURL in
///         print("Saved: \(savedURL)")
///     } onDismiss: {
///         showEditor = false
///     }
/// }
/// ```
public struct STTXTEditorView: View {

    private let url: URL?
    private let title: String?
    private let configuration: STTXTConfiguration
    private let onSave: ((URL) -> Void)?
    private let onDismiss: (() -> Void)?

    @State private var text: String = ""
    @State private var documentTitle = ""
    @State private var hasUnsavedChanges = false
    @State private var isSaving = false
    @State private var showDiscardAlert = false
    @State private var showWordCount = false
    @State private var showShareSheet = false
    @State private var exportURL: URL?

    /// Open an existing text file
    public init(
        url: URL,
        title: String? = nil,
        configuration: STTXTConfiguration = .default,
        onSave: ((URL) -> Void)? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        self.url = url
        self.title = title
        self.configuration = configuration
        self.onSave = onSave
        self.onDismiss = onDismiss
    }

    /// Create a new blank text document
    public init(
        title: String = "Untitled",
        configuration: STTXTConfiguration = .default,
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
        #if os(macOS)
        editorBody
            .onAppear { loadDocument() }
        #else
        NavigationView {
            editorBody
        }
        .stStackNavigationViewStyle()
        .onAppear { loadDocument() }
        #endif
    }

    @ViewBuilder
    private var editorBody: some View {
        VStack(spacing: 0) {
            #if os(macOS)
            // macOS inline toolbar
            HStack {
                Button {
                    if hasUnsavedChanges {
                        showDiscardAlert = true
                    } else {
                        onDismiss?()
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)

                Spacer()

                Text(documentTitle.isEmpty ? STStrings.newDocument : documentTitle)
                    .font(.headline)
                    .lineLimit(1)

                Spacer()

                if configuration.showMoreMenu {
                    Menu {
                        Button {
                            showWordCount = true
                        } label: {
                            Label(STStrings.wordCount, systemImage: "textformat.123")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    printDocument()
                } label: {
                    Image(systemName: "printer")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(NSColor.windowBackgroundColor))
            .overlay(alignment: .bottom) {
                Divider()
            }
            #endif

            ZStack {
                STTXTTextView(
                    text: $text,
                    configuration: configuration
                )
                .onChange(of: text) { _ in
                    hasUnsavedChanges = true
                }

                #if os(iOS)
                // License watermark (iOS only — macOS uses shared STLicenseManager)
                if !STTXTKit.isLicensed {
                    STLicenseWatermark(moduleName: "STTXT")
                }
                #endif
            }
            #if !os(macOS)
            .navigationTitle(documentTitle.isEmpty ? STStrings.newDocument : documentTitle)
            .stNavigationBarTitleDisplayMode()
            .toolbar {
                ToolbarItem(placement: .stLeading) {
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

                ToolbarItemGroup(placement: .stTrailing) {
                    if configuration.showMoreMenu {
                        Menu {
                            Button {
                                showWordCount = true
                            } label: {
                                Label(STStrings.wordCount, systemImage: "textformat.123")
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
            #endif
        }
        .alert(STStrings.unsavedChanges, isPresented: $showDiscardAlert) {
            Button(STStrings.discard, role: .destructive) { onDismiss?() }
            Button(STStrings.saveAndClose) {
                saveDocument()
                onDismiss?()
            }
            Button(STStrings.cancel, role: .cancel) {}
        } message: {
            Text(STStrings.unsavedChangesMessage)
        }
        .sheet(isPresented: $showWordCount) {
            STTXTWordCountView(text: text)
                .stPresentationDetents([.height(300)])
        }
    }

    private func loadDocument() {
        if let url {
            documentTitle = title ?? url.deletingPathExtension().lastPathComponent
            text = (try? String(contentsOf: url, encoding: .utf8)) ?? ""
        } else {
            documentTitle = title ?? STStrings.newDocument
            text = ""
        }
        hasUnsavedChanges = false
    }

    #if os(macOS)
    private func printDocument() {
        if let onPrint = configuration.onPrint ?? STKitConfiguration.shared.onPrint, !onPrint() { return }

        let printInfo = NSPrintInfo.shared
        let paperWidth = printInfo.paperSize.width - printInfo.leftMargin - printInfo.rightMargin
        let paperHeight = printInfo.paperSize.height - printInfo.topMargin - printInfo.bottomMargin

        let textView = NSTextView(frame: NSRect(x: 0, y: 0, width: paperWidth, height: paperHeight))
        textView.string = text
        textView.font = NSFont(name: configuration.fontName, size: configuration.fontSize)
            ?? .monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.sizeToFit()

        let printOperation = NSPrintOperation(view: textView)
        printOperation.run()
    }
    #endif

    private func saveDocument() {
        isSaving = true
        DispatchQueue.global(qos: .userInitiated).async {
            let saveName = documentTitle.isEmpty ? "Document" : documentTitle
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("\(saveName).txt")
            let success = (try? text.write(to: tempURL, atomically: true, encoding: .utf8)) != nil

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
