import SwiftUI
import STKit

/// Home tab content — Undo/Redo, Font, Bold/Italic/Underline/Strikethrough, Sub/Super, Colors, Select All
struct STRibbonHomeTab: View {
    @ObservedObject var annotationManager: STAnnotationManager
    @ObservedObject var webEditorViewModel: STWebEditorViewModel

    @State private var showTextColorPicker = false
    @State private var showHighlightColorPicker = false
    @State private var showFontPicker = false
    @State private var pendingFontFamily: String? = nil

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 2) {
                // Undo
                STRibbonToolButton(
                    iconName: "arrow.uturn.backward",
                    label: STStrings.undo
                ) {
                    webEditorViewModel.undo()
                }

                // Redo
                STRibbonToolButton(
                    iconName: "arrow.uturn.forward",
                    label: STStrings.redo
                ) {
                    webEditorViewModel.redo()
                }

                STRibbonSeparator()

                // Font picker
                STRibbonToolButton(
                    iconName: "textformat",
                    label: webEditorViewModel.currentFontName.count > 8
                        ? String(webEditorViewModel.currentFontName.prefix(8)) + "…"
                        : webEditorViewModel.currentFontName
                ) {
                    showFontPicker.toggle()
                }
                .sheet(isPresented: $showFontPicker, onDismiss: {
                    guard let fontName = pendingFontFamily else { return }
                    pendingFontFamily = nil
                    // Delay so WKWebView fully regains first-responder after sheet dismissal
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        webEditorViewModel.setFontFamily(fontName)
                    }
                }) {
                    STRibbonFontPickerView(
                        currentFont: webEditorViewModel.currentFontName
                    ) { fontName in
                        pendingFontFamily = fontName
                    }
                    .stPresentationDetents([.medium, .large])
                    .stPresentationDragIndicator(.visible)
                }

                // Font Size +/-
                STRibbonToolButton(
                    iconName: "plus.circle",
                    label: "\(Int(webEditorViewModel.currentFontSize))"
                ) {
                    webEditorViewModel.increaseFontSize()
                }

                STRibbonToolButton(
                    iconName: "minus.circle",
                    label: STStrings.ribbonFontSize
                ) {
                    webEditorViewModel.decreaseFontSize()
                }

                STRibbonSeparator()

                // Bold
                STRibbonToolButton(
                    iconName: "bold",
                    label: STStrings.ribbonBold,
                    isActive: webEditorViewModel.isBold
                ) {
                    webEditorViewModel.toggleBold()
                }

                // Italic
                STRibbonToolButton(
                    iconName: "italic",
                    label: STStrings.ribbonItalic,
                    isActive: webEditorViewModel.isItalic
                ) {
                    webEditorViewModel.toggleItalic()
                }

                // Underline
                STRibbonToolButton(
                    iconName: "underline",
                    label: STStrings.ribbonUnderline,
                    isActive: webEditorViewModel.isUnderline
                ) {
                    webEditorViewModel.toggleUnderline()
                }

                // Strikethrough
                STRibbonToolButton(
                    iconName: "strikethrough",
                    label: STStrings.ribbonStrikethrough,
                    isActive: webEditorViewModel.isStrikethrough
                ) {
                    webEditorViewModel.toggleStrikethrough()
                }

                // Subscript
                STRibbonToolButton(
                    iconName: "textformat.subscript",
                    label: STStrings.ribbonSubscript,
                    isActive: webEditorViewModel.isSubscript
                ) {
                    webEditorViewModel.toggleSubscript()
                }

                // Superscript
                STRibbonToolButton(
                    iconName: "textformat.superscript",
                    label: STStrings.ribbonSuperscript,
                    isActive: webEditorViewModel.isSuperscript
                ) {
                    webEditorViewModel.toggleSuperscript()
                }

                STRibbonSeparator()

                // Text Color
                STRibbonToolButton(
                    iconName: "paintpalette",
                    label: STStrings.ribbonTextColor
                ) {
                    showTextColorPicker.toggle()
                }
                .popover(isPresented: $showTextColorPicker) {
                    STColorPickerPopover(
                        title: STStrings.ribbonTextColor,
                        colors: STColorPresets.textColors,
                        showNone: false
                    ) { hex in
                        webEditorViewModel.setTextColor(hex)
                        showTextColorPicker = false
                    }
                }

                // Highlight Color
                STRibbonToolButton(
                    iconName: "highlighter",
                    label: STStrings.ribbonHighlightColor
                ) {
                    showHighlightColorPicker.toggle()
                }
                .popover(isPresented: $showHighlightColorPicker) {
                    STColorPickerPopover(
                        title: STStrings.ribbonHighlightColor,
                        colors: STColorPresets.highlightColors,
                        showNone: true
                    ) { hex in
                        webEditorViewModel.setHighlightColor(hex)
                        showHighlightColorPicker = false
                    }
                }

                STRibbonSeparator()

                // Select All
                STRibbonToolButton(
                    iconName: "selection.pin.in.out",
                    label: STStrings.ribbonSelectAll
                ) {
                    webEditorViewModel.selectAll()
                }
            }
            .padding(.horizontal, 8)
        }
    }
}
