import SwiftUI
import STKit

/// Insert tab content — Table, Image, Link, Page Break, Horizontal Rule, Bookmark
struct STRibbonInsertTab: View {
    @ObservedObject var annotationManager: STAnnotationManager
    let onActivateDrawTool: (STAnnotationType) -> Void
    var onInsertImage: (() -> Void)? = nil
    @ObservedObject var webEditorViewModel: STWebEditorViewModel

    @State private var showTablePicker = false
    @State private var showTableStylePicker = false
    @State private var showLinkAlert = false
    @State private var linkURL = ""
    @State private var showBookmarkAlert = false
    @State private var bookmarkName = ""

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 2) {
                // Table
                STRibbonToolButton(
                    iconName: "tablecells",
                    label: STStrings.ribbonTable
                ) {
                    showTablePicker.toggle()
                }
                .popover(isPresented: $showTablePicker) {
                    STTableSizePickerView { rows, cols in
                        webEditorViewModel.insertTable(rows: rows, cols: cols)
                        showTablePicker = false
                    }
                }

                // Styled Table Templates
                STRibbonToolButton(
                    iconName: "tablecells.badge.ellipsis",
                    label: STStrings.ribbonTableStyle
                ) {
                    showTableStylePicker = true
                }
                .sheet(isPresented: $showTableStylePicker) {
                    STTableStylePickerView(mode: .insert) { style, rows, cols in
                        webEditorViewModel.insertTableTemplate(
                            templateId: style.id,
                            rows: rows,
                            cols: cols
                        )
                    }
                    .stPresentationDetents([.medium, .large])
                    .stPresentationDragIndicator(.visible)
                }

                STRibbonSeparator()

                // Photo / Image
                STRibbonToolButton(
                    iconName: "photo",
                    label: STStrings.ribbonImage
                ) {
                    onInsertImage?()
                }

                STRibbonSeparator()

                // Link
                STRibbonToolButton(
                    iconName: "link",
                    label: STStrings.ribbonLink
                ) {
                    linkURL = ""
                    showLinkAlert = true
                }
                .alert(STStrings.ribbonLink, isPresented: $showLinkAlert) {
                    TextField("https://", text: $linkURL)
                        #if os(iOS)
                    .textInputAutocapitalization(.never)
                    #endif
                        #if os(iOS)
                        .keyboardType(.URL)
                        #endif
                    Button(STStrings.cancel, role: .cancel) { }
                    Button(STStrings.add) {
                        let url = linkURL.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !url.isEmpty else { return }
                        let finalURL = url.hasPrefix("http") ? url : "https://\(url)"
                        webEditorViewModel.insertLink(url: finalURL)
                    }
                }

                STRibbonSeparator()

                // Horizontal Rule
                STRibbonToolButton(
                    iconName: "minus",
                    label: STStrings.ribbonLine
                ) {
                    webEditorViewModel.insertHorizontalRule()
                }

                // Page Break
                STRibbonToolButton(
                    iconName: "doc.badge.plus",
                    label: STStrings.ribbonPageBreak
                ) {
                    webEditorViewModel.insertPageBreak()
                }

                STRibbonSeparator()

                // Bookmark
                STRibbonToolButton(
                    iconName: "bookmark",
                    label: STStrings.ribbonBookmark
                ) {
                    bookmarkName = ""
                    showBookmarkAlert = true
                }
                .alert(STStrings.ribbonBookmark, isPresented: $showBookmarkAlert) {
                    TextField(STStrings.ribbonBookmark, text: $bookmarkName)
                    Button(STStrings.cancel, role: .cancel) { }
                    Button(STStrings.add) {
                        let name = bookmarkName.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !name.isEmpty else { return }
                        webEditorViewModel.insertBookmark(name: name)
                    }
                }
            }
            .padding(.horizontal, 8)
        }
    }
}
