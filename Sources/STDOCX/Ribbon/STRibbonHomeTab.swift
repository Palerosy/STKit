import SwiftUI
import STKit

/// Home tab content — Clipboard, Font, Bold/Italic/Underline, Text color, Alignment, Lists, Undo/Redo
/// Formatting buttons are wired to STWebEditorViewModel for WKWebView-based editing
struct STRibbonHomeTab: View {
    @ObservedObject var annotationManager: STAnnotationManager
    @ObservedObject var webEditorViewModel: STWebEditorViewModel

    @State private var showTextColorPicker = false
    @State private var showHighlightColorPicker = false
    @State private var showFontPicker = false
    @State private var showLineSpacingPicker = false
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
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
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

                // Alignment
                STRibbonToolButton(
                    iconName: "text.alignleft",
                    label: STStrings.ribbonAlignLeft,
                    isActive: webEditorViewModel.textAlignment == .left
                ) {
                    webEditorViewModel.setAlignment(.left)
                }

                STRibbonToolButton(
                    iconName: "text.aligncenter",
                    label: STStrings.ribbonAlignCenter,
                    isActive: webEditorViewModel.textAlignment == .center
                ) {
                    webEditorViewModel.setAlignment(.center)
                }

                STRibbonToolButton(
                    iconName: "text.alignright",
                    label: STStrings.ribbonAlignRight,
                    isActive: webEditorViewModel.textAlignment == .right
                ) {
                    webEditorViewModel.setAlignment(.right)
                }

                STRibbonToolButton(
                    iconName: "text.justify",
                    label: STStrings.ribbonJustify,
                    isActive: webEditorViewModel.textAlignment == .justified
                ) {
                    webEditorViewModel.setAlignment(.justified)
                }

                STRibbonSeparator()

                // Indent
                STRibbonToolButton(
                    iconName: "increase.indent",
                    label: STStrings.ribbonIncreaseIndent
                ) {
                    webEditorViewModel.increaseIndent()
                }

                STRibbonToolButton(
                    iconName: "decrease.indent",
                    label: STStrings.ribbonDecreaseIndent
                ) {
                    webEditorViewModel.decreaseIndent()
                }

                // Line Spacing
                STRibbonToolButton(
                    iconName: "line.3.horizontal",
                    label: STStrings.ribbonLineSpacing
                ) {
                    showLineSpacingPicker.toggle()
                }
                .sheet(isPresented: $showLineSpacingPicker) {
                    STLineSpacingPickerView { value in
                        webEditorViewModel.setLineSpacing(value)
                    }
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
                }

                STRibbonSeparator()

                // Bullet List
                STRibbonToolButton(
                    iconName: "list.bullet",
                    label: STStrings.ribbonBulletList,
                    isActive: webEditorViewModel.isBulletList
                ) {
                    webEditorViewModel.toggleBulletList()
                }

                // Numbered List
                STRibbonToolButton(
                    iconName: "list.number",
                    label: STStrings.ribbonNumberedList,
                    isActive: webEditorViewModel.isNumberedList
                ) {
                    webEditorViewModel.toggleNumberedList()
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
