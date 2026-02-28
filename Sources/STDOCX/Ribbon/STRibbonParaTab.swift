import SwiftUI
import STKit

/// Para tab content — Alignment, Indent, Line Spacing, Lists
struct STRibbonParaTab: View {
    @ObservedObject var webEditorViewModel: STWebEditorViewModel

    @State private var showLineSpacingPicker = false

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 2) {
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
                    .stPresentationDetents([.medium])
                    .stPresentationDragIndicator(.visible)
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
            }
            .padding(.horizontal, 8)
        }
    }
}
