import SwiftUI
import STKit

/// Layout tab content — Margins, Orientation, Size, Columns, Text Direction, Section/Page Breaks
struct STRibbonLayoutTab: View {
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 2) {
                // Margins (stub)
                STRibbonToolButton(
                    iconName: "rectangle.dashed",
                    label: STStrings.ribbonMargins,
                    isDisabled: true
                ) { }

                // Orientation (stub)
                STRibbonToolButton(
                    iconName: "rectangle.portrait.rotate",
                    label: STStrings.ribbonOrientation,
                    isDisabled: true
                ) { }

                // Page Size (stub)
                STRibbonToolButton(
                    iconName: "doc",
                    label: STStrings.ribbonPageSize,
                    isDisabled: true
                ) { }

                STRibbonSeparator()

                // Columns (stub)
                STRibbonToolButton(
                    iconName: "text.justify.leading",
                    label: STStrings.ribbonColumns,
                    isDisabled: true
                ) { }

                // Text Direction (stub)
                STRibbonToolButton(
                    iconName: "arrow.left.and.right.text.vertical",
                    label: STStrings.ribbonTextDirection,
                    isDisabled: true
                ) { }

                STRibbonSeparator()

                // Section Break (stub)
                STRibbonToolButton(
                    iconName: "rectangle.split.2x1",
                    label: STStrings.ribbonSectionBreak,
                    isDisabled: true
                ) { }

                // Page Break (stub)
                STRibbonToolButton(
                    iconName: "doc.badge.plus",
                    label: STStrings.ribbonPageBreaks,
                    isDisabled: true
                ) { }
            }
            .padding(.horizontal, 8)
        }
    }
}
