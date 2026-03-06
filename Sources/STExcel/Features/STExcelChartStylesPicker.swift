import SwiftUI
import Charts
import STKit

/// A chart style preset (visual appearance)
struct STExcelChartStylePreset: Identifiable {
    let id = UUID()
    let name: String
    let colorTheme: STExcelChartColorTheme
    let showGridlines: Bool
    let showLegend: Bool
    let darkBackground: Bool
}

/// Chart Styles picker — grid of style thumbnails matching competitor
struct STExcelChartStylesPicker: View {
    let currentSubtype: STExcelChartSubtype
    let onSelect: (STExcelChartStylePreset) -> Void
    let onDismiss: () -> Void

    @State private var selectedIndex: Int = 0

    private let presets: [STExcelChartStylePreset] = [
        STExcelChartStylePreset(name: "Style 1", colorTheme: .colorful1, showGridlines: true, showLegend: true, darkBackground: false),
        STExcelChartStylePreset(name: "Style 2", colorTheme: .colorful1, showGridlines: true, showLegend: false, darkBackground: false),
        STExcelChartStylePreset(name: "Style 3", colorTheme: .colorful1, showGridlines: false, showLegend: false, darkBackground: false),
        STExcelChartStylePreset(name: "Style 4", colorTheme: .colorful2, showGridlines: true, showLegend: true, darkBackground: true),
        STExcelChartStylePreset(name: "Style 5", colorTheme: .colorful2, showGridlines: true, showLegend: true, darkBackground: false),
        STExcelChartStylePreset(name: "Style 6", colorTheme: .colorful2, showGridlines: true, showLegend: false, darkBackground: false),
        STExcelChartStylePreset(name: "Style 7", colorTheme: .monoGreen, showGridlines: true, showLegend: true, darkBackground: false),
        STExcelChartStylePreset(name: "Style 8", colorTheme: .monoGreen, showGridlines: true, showLegend: true, darkBackground: true),
        STExcelChartStylePreset(name: "Style 9", colorTheme: .monoBlue, showGridlines: true, showLegend: true, darkBackground: false),
        STExcelChartStylePreset(name: "Style 10", colorTheme: .monoBlue, showGridlines: false, showLegend: false, darkBackground: true),
        STExcelChartStylePreset(name: "Style 11", colorTheme: .monoOrange, showGridlines: true, showLegend: true, darkBackground: false),
        STExcelChartStylePreset(name: "Style 12", colorTheme: .monoOrange, showGridlines: true, showLegend: false, darkBackground: false),
    ]

    // Sample data for thumbnails
    private let sampleData: [(String, Double)] = [
        ("1", 0.6), ("2", 0.8), ("3", 0.4), ("4", 0.9), ("5", 0.3)
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16),
                ], spacing: 16) {
                    ForEach(Array(presets.enumerated()), id: \.element.id) { index, preset in
                        Button {
                            selectedIndex = index
                            onSelect(preset)
                        } label: {
                            styleThumbnail(preset, isSelected: index == selectedIndex)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
            .navigationTitle(STExcelStrings.chartStylesNav)
            .stNavigationBarTitleDisplayMode()
            .toolbar {
                ToolbarItem(placement: .stTrailing) {
                    Button { onDismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    private func styleThumbnail(_ preset: STExcelChartStylePreset, isSelected: Bool) -> some View {
        VStack(spacing: 0) {
            // Mini chart preview
            Chart(sampleData, id: \.0) { item in
                BarMark(
                    x: .value("X", item.0),
                    y: .value("Y", item.1)
                )
                .foregroundStyle(preset.colorTheme.colors.first ?? .blue)
            }
            .chartXAxis {
                if preset.showGridlines {
                    AxisMarks { _ in AxisValueLabel().font(.system(size: 6)) }
                } else {
                    AxisMarks(values: [Double]()) { _ in }
                }
            }
            .chartYAxis {
                if preset.showGridlines {
                    AxisMarks { _ in AxisGridLine(); AxisValueLabel().font(.system(size: 6)) }
                } else {
                    AxisMarks(values: [Double]()) { _ in }
                }
            }
            .chartLegend(.hidden)
            .frame(height: 140)
            .padding(8)
            .background(preset.darkBackground ? Color.black.opacity(0.85) : Color.stSystemBackground)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.stExcelAccent : Color.stSeparator,
                        lineWidth: isSelected ? 3 : 1)
        )
    }
}
