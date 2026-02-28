import SwiftUI
import STKit

/// Design tab content — Themes, Page Color, Watermark
struct STRibbonDesignTab: View {
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 2) {
                // Themes (stub)
                STRibbonToolButton(
                    iconName: "paintpalette",
                    label: STStrings.ribbonThemes,
                    isDisabled: true
                ) { }

                STRibbonSeparator()

                // Page Color (stub)
                STRibbonToolButton(
                    iconName: "paintbrush",
                    label: STStrings.pageColor,
                    isDisabled: true
                ) { }

                // Watermark (stub)
                STRibbonToolButton(
                    iconName: "drop.triangle",
                    label: STStrings.ribbonWatermark,
                    isDisabled: true
                ) { }
            }
            .padding(.horizontal, 8)
        }
    }
}
