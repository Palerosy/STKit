import SwiftUI
import Charts
import STKit

// MARK: - Chart Category & Subtypes

/// Top-level chart category matching the competitor's tab filter
enum STExcelChartCategory: String, CaseIterable, Identifiable {
    case all, column, bar, line, lineWithMarkers, area, pie, scatter

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .all: return STExcelStrings.chartAll
        case .column: return STExcelStrings.chartColumn
        case .bar: return STExcelStrings.chartBar
        case .line: return STExcelStrings.chartLine
        case .lineWithMarkers: return STExcelStrings.chartLineWithMarkers
        case .area: return STExcelStrings.chartArea
        case .pie: return STExcelStrings.chartPie
        case .scatter: return STExcelStrings.chartScatter
        }
    }
}

/// Individual chart subtype with preview icon
enum STExcelChartSubtype: String, CaseIterable, Identifiable {
    // Column
    case columnClustered, columnStacked, columnPercentStacked
    // Bar
    case barClustered, barStacked, barPercentStacked
    // Line
    case line, lineSmooth, lineNone
    // Line with markers
    case lineMarkers, lineMarkersSmooth, lineMarkersNone
    // Area
    case area, areaStacked, areaPercentStacked
    // Pie
    case pie, pie3D, doughnut, pieExploded
    // Scatter
    case scatterDots, scatterLines, scatterSmooth

    var id: String { rawValue }

    var category: STExcelChartCategory {
        switch self {
        case .columnClustered, .columnStacked, .columnPercentStacked: return .column
        case .barClustered, .barStacked, .barPercentStacked: return .bar
        case .line, .lineSmooth, .lineNone: return .line
        case .lineMarkers, .lineMarkersSmooth, .lineMarkersNone: return .lineWithMarkers
        case .area, .areaStacked, .areaPercentStacked: return .area
        case .pie, .pie3D, .doughnut, .pieExploded: return .pie
        case .scatterDots, .scatterLines, .scatterSmooth: return .scatter
        }
    }

    var displayName: String {
        switch self {
        case .columnClustered: return STExcelStrings.chartClustered
        case .columnStacked: return STExcelStrings.chartStacked
        case .columnPercentStacked: return STExcelStrings.chartPercentStacked
        case .barClustered: return STExcelStrings.chartClustered
        case .barStacked: return STExcelStrings.chartStacked
        case .barPercentStacked: return STExcelStrings.chartPercentStacked
        case .line: return STExcelStrings.chartLine
        case .lineSmooth: return STExcelStrings.chartSmooth
        case .lineNone: return STExcelStrings.chartSimple
        case .lineMarkers: return STExcelStrings.chartMarkers
        case .lineMarkersSmooth: return STExcelStrings.chartSmooth
        case .lineMarkersNone: return STExcelStrings.chartSimple
        case .area: return STExcelStrings.chartArea
        case .areaStacked: return STExcelStrings.chartStacked
        case .areaPercentStacked: return STExcelStrings.chartPercentStacked
        case .pie: return STExcelStrings.chartPie
        case .pie3D: return STExcelStrings.chart3DPie
        case .doughnut: return STExcelStrings.chartDoughnut
        case .pieExploded: return STExcelStrings.chartExploded
        case .scatterDots: return STExcelStrings.chartDots
        case .scatterLines: return STExcelStrings.chartLines
        case .scatterSmooth: return STExcelStrings.chartSmooth
        }
    }

    var iconName: String {
        switch self {
        case .columnClustered: return "chart.bar.xaxis"
        case .columnStacked: return "chart.bar.xaxis"
        case .columnPercentStacked: return "chart.bar.xaxis"
        case .barClustered: return "chart.bar.fill"
        case .barStacked: return "chart.bar.fill"
        case .barPercentStacked: return "chart.bar.fill"
        case .line, .lineSmooth, .lineNone: return "chart.xyaxis.line"
        case .lineMarkers, .lineMarkersSmooth, .lineMarkersNone: return "chart.line.uptrend.xyaxis"
        case .area, .areaStacked, .areaPercentStacked: return "chart.line.uptrend.xyaxis"
        case .pie, .pie3D, .doughnut, .pieExploded: return "chart.pie.fill"
        case .scatterDots, .scatterLines, .scatterSmooth: return "chart.dots.scatter"
        }
    }

    var isStacked: Bool {
        switch self {
        case .columnStacked, .barStacked, .areaStacked: return true
        default: return false
        }
    }

    var isPercentStacked: Bool {
        switch self {
        case .columnPercentStacked, .barPercentStacked, .areaPercentStacked: return true
        default: return false
        }
    }

    /// Group subtypes by category
    static func subtypes(for category: STExcelChartCategory) -> [STExcelChartSubtype] {
        if category == .all { return STExcelChartSubtype.allCases }
        return STExcelChartSubtype.allCases.filter { $0.category == category }
    }
}

// MARK: - Color Themes

/// Predefined chart color palettes — 20 themes matching competitor's Colors picker
enum STExcelChartColorTheme: String, CaseIterable, Identifiable {
    // Colorful (rows with distinct colors)
    case colorful1, colorful2, colorful3, colorful4
    // Monochromatic
    case monoBlue, monoGray, monoOrange, monoGreen, monoNavy, monoRed
    case monoBrown, monoYellow, monoTeal, monoPurple
    // Gradient / pastel
    case pastelBlue, pastelOrange, pastelGray, pastelGold, pastelGreen, pastelDark

    var id: String { rawValue }

    var colors: [Color] {
        switch self {
        case .colorful1:
            return [c(0.27,0.51,0.71), c(0.89,0.54,0.24), c(0.6,0.6,0.6), c(0.94,0.77,0.24), c(0.45,0.67,0.82), c(0.45,0.73,0.28)]
        case .colorful2:
            return [c(0.27,0.51,0.71), c(0.6,0.6,0.6), c(0.45,0.67,0.82), c(0.18,0.28,0.49), c(0.5,0.5,0.5), c(0.13,0.42,0.62)]
        case .colorful3:
            return [c(0.89,0.54,0.24), c(0.94,0.77,0.24), c(0.45,0.73,0.28), c(0.65,0.38,0.16), c(0.72,0.58,0.12), c(0.28,0.53,0.18)]
        case .colorful4:
            return [c(0.45,0.73,0.28), c(0.35,0.55,0.75), c(0.94,0.77,0.24), c(0.28,0.53,0.18), c(0.22,0.38,0.65), c(0.72,0.58,0.12)]
        case .monoBlue:
            return [c(0.15,0.35,0.60), c(0.22,0.45,0.70), c(0.35,0.55,0.78), c(0.50,0.68,0.85), c(0.65,0.78,0.90), c(0.80,0.88,0.95)]
        case .monoGray:
            return [c(0.4,0.4,0.4), c(0.5,0.5,0.5), c(0.6,0.6,0.6), c(0.7,0.7,0.7), c(0.8,0.8,0.8), c(0.9,0.9,0.9)]
        case .monoOrange:
            return [c(0.76,0.38,0.10), c(0.84,0.48,0.18), c(0.89,0.58,0.30), c(0.93,0.68,0.44), c(0.96,0.78,0.60), c(0.98,0.88,0.78)]
        case .monoGreen:
            return [c(0.10,0.42,0.16), c(0.18,0.52,0.24), c(0.30,0.64,0.36), c(0.46,0.74,0.50), c(0.62,0.84,0.66), c(0.80,0.92,0.82)]
        case .monoNavy:
            return [c(0.12,0.20,0.42), c(0.18,0.28,0.52), c(0.25,0.38,0.62), c(0.38,0.50,0.72), c(0.55,0.64,0.80), c(0.72,0.78,0.88)]
        case .monoRed:
            return [c(0.72,0.22,0.15), c(0.80,0.32,0.24), c(0.86,0.44,0.36), c(0.90,0.58,0.50), c(0.94,0.72,0.66), c(0.97,0.86,0.82)]
        case .monoBrown:
            return [c(0.50,0.34,0.12), c(0.60,0.44,0.20), c(0.68,0.54,0.30), c(0.76,0.64,0.42), c(0.84,0.75,0.56), c(0.92,0.86,0.72)]
        case .monoYellow:
            return [c(0.72,0.58,0.12), c(0.80,0.66,0.20), c(0.86,0.74,0.32), c(0.90,0.82,0.46), c(0.94,0.88,0.62), c(0.97,0.94,0.80)]
        case .monoTeal:
            return [c(0.10,0.44,0.42), c(0.18,0.54,0.52), c(0.30,0.64,0.62), c(0.46,0.74,0.72), c(0.62,0.84,0.82), c(0.80,0.92,0.92)]
        case .monoPurple:
            return [c(0.42,0.22,0.58), c(0.52,0.32,0.68), c(0.62,0.44,0.76), c(0.72,0.58,0.84), c(0.82,0.72,0.90), c(0.90,0.84,0.95)]
        case .pastelBlue:
            return [c(0.60,0.72,0.82), c(0.65,0.76,0.86), c(0.70,0.80,0.88), c(0.75,0.84,0.90), c(0.80,0.88,0.94), c(0.88,0.92,0.96)]
        case .pastelOrange:
            return [c(0.90,0.68,0.50), c(0.92,0.72,0.56), c(0.93,0.76,0.62), c(0.95,0.80,0.68), c(0.96,0.84,0.76), c(0.98,0.90,0.84)]
        case .pastelGray:
            return [c(0.5,0.5,0.5), c(0.55,0.55,0.55), c(0.62,0.62,0.62), c(0.70,0.70,0.70), c(0.80,0.80,0.80), c(0.88,0.88,0.88)]
        case .pastelGold:
            return [c(0.80,0.66,0.30), c(0.84,0.70,0.38), c(0.87,0.74,0.46), c(0.90,0.80,0.56), c(0.93,0.86,0.66), c(0.96,0.92,0.80)]
        case .pastelGreen:
            return [c(0.40,0.62,0.35), c(0.48,0.68,0.42), c(0.56,0.74,0.50), c(0.64,0.80,0.60), c(0.74,0.86,0.70), c(0.84,0.92,0.82)]
        case .pastelDark:
            return [c(0.35,0.35,0.38), c(0.42,0.42,0.45), c(0.5,0.5,0.5), c(0.0,0.0,0.0), c(0.75,0.75,0.75), c(0.6,0.6,0.6)]
        }
    }

    private func c(_ r: Double, _ g: Double, _ b: Double) -> Color {
        Color(red: r, green: g, blue: b)
    }
}

// MARK: - Chart Layout Presets

/// Predefined chart layout presets matching competitor
enum STExcelChartLayout: String, CaseIterable, Identifiable {
    case layout1, layout2, layout3, layout4, layout5, layout6

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .layout1: return "\(STExcelStrings.layoutLabel) 1"
        case .layout2: return "\(STExcelStrings.layoutLabel) 2"
        case .layout3: return "\(STExcelStrings.layoutLabel) 3"
        case .layout4: return "\(STExcelStrings.layoutLabel) 4"
        case .layout5: return "\(STExcelStrings.layoutLabel) 5"
        case .layout6: return "\(STExcelStrings.layoutLabel) 6"
        }
    }

    var iconName: String {
        switch self {
        case .layout1: return "rectangle.topthird.inset.filled"
        case .layout2: return "rectangle.bottomthird.inset.filled"
        case .layout3: return "rectangle.leadingthird.inset.filled"
        case .layout4: return "rectangle.trailingthird.inset.filled"
        case .layout5: return "rectangle.inset.filled"
        case .layout6: return "rectangle"
        }
    }

    var showTitle: Bool {
        switch self {
        case .layout1, .layout3, .layout5: return true
        default: return false
        }
    }

    var showLegend: Bool {
        switch self {
        case .layout1, .layout2, .layout4, .layout5: return true
        default: return false
        }
    }

    var showGridlines: Bool {
        switch self {
        case .layout1, .layout3, .layout5, .layout6: return true
        default: return false
        }
    }

    var showAxisLabels: Bool {
        switch self {
        case .layout1, .layout2, .layout3, .layout5: return true
        default: return false
        }
    }
}

// MARK: - Data Point

struct STExcelChartDataPoint: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
    let series: String
}

// MARK: - Multi-series data

struct STExcelChartSeries: Identifiable {
    let id = UUID()
    let name: String
    let points: [STExcelChartDataPoint]
    let color: Color
}

// MARK: - Chart Type Picker Sheet

/// Full chart type picker matching competitor: category tabs + subtype thumbnails
struct STExcelChartTypePicker: View {
    let onSelect: (STExcelChartSubtype) -> Void
    let onDismiss: () -> Void

    @State private var selectedCategory: STExcelChartCategory = .all

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Category tabs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(STExcelChartCategory.allCases) { cat in
                            Button {
                                selectedCategory = cat
                            } label: {
                                Text(cat.displayName)
                                    .font(.system(size: 14, weight: selectedCategory == cat ? .semibold : .regular))
                                    .foregroundColor(selectedCategory == cat ? .white : .stExcelAccent)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(selectedCategory == cat ? Color.stExcelAccent : Color.clear)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }

                Divider()

                // Subtypes grid grouped by category
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        if selectedCategory == .all {
                            ForEach(STExcelChartCategory.allCases.filter { $0 != .all }) { cat in
                                chartCategorySection(cat)
                            }
                        } else {
                            chartCategorySection(selectedCategory)
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle(STExcelStrings.chart)
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

    private func chartCategorySection(_ category: STExcelChartCategory) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(category.displayName.uppercased())
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ForEach(STExcelChartSubtype.subtypes(for: category)) { subtype in
                    Button { onSelect(subtype) } label: {
                        chartThumbnail(subtype)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func chartThumbnail(_ subtype: STExcelChartSubtype) -> some View {
        VStack(spacing: 4) {
            Image(systemName: subtype.iconName)
                .font(.system(size: 20))
                .foregroundColor(.stExcelAccent)
                .frame(width: 60, height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.stSeparator, lineWidth: 1)
                )
            Text(subtype.displayName)
                .font(.system(size: 9))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
    }
}

// MARK: - Elements Picker

/// Chart elements toggle sheet (Title, Legend, Gridlines, Axis, Data Labels)
struct STExcelChartElementsPicker: View {
    @Binding var showTitle: Bool
    @Binding var showLegend: Bool
    @Binding var showGridlines: Bool
    @Binding var showAxisLabels: Bool
    @Binding var showDataLabels: Bool
    let onDismiss: () -> Void

    var body: some View {
        NavigationView {
            List {
                Toggle(STExcelStrings.chartTitle, isOn: $showTitle)
                Toggle(STExcelStrings.legend, isOn: $showLegend)
                Toggle(STExcelStrings.gridlines, isOn: $showGridlines)
                Toggle(STExcelStrings.axisLabels, isOn: $showAxisLabels)
                Toggle(STExcelStrings.dataLabels, isOn: $showDataLabels)
            }
            .navigationTitle(STExcelStrings.chartElements)
            .stNavigationBarTitleDisplayMode()
            .toolbar {
                ToolbarItem(placement: .stTrailing) {
                    Button(STStrings.done) { onDismiss() }
                }
            }
        }
    }
}

// MARK: - Layouts Picker

/// Chart layout preset grid
struct STExcelChartLayoutsPicker: View {
    let onSelect: (STExcelChartLayout) -> Void
    let onDismiss: () -> Void

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16),
                ], spacing: 16) {
                    ForEach(STExcelChartLayout.allCases) { layout in
                        Button { onSelect(layout) } label: {
                            VStack(spacing: 6) {
                                Image(systemName: layout.iconName)
                                    .font(.system(size: 28))
                                    .foregroundColor(.stExcelAccent)
                                    .frame(width: 80, height: 60)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.stSeparator, lineWidth: 1)
                                    )
                                Text(layout.displayName)
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
            .navigationTitle(STExcelStrings.chartLayouts)
            .stNavigationBarTitleDisplayMode()
            .toolbar {
                ToolbarItem(placement: .stTrailing) {
                    Button(STStrings.done) { onDismiss() }
                }
            }
        }
    }
}

// MARK: - Colors Picker

/// Chart color theme picker — rows of 6 color swatches matching competitor
struct STExcelChartColorsPicker: View {
    var selectedTheme: STExcelChartColorTheme = .colorful1
    let onSelect: (STExcelChartColorTheme) -> Void
    let onDismiss: () -> Void

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(STExcelChartColorTheme.allCases) { theme in
                        Button { onSelect(theme) } label: {
                            HStack(spacing: 4) {
                                // Checkmark indicator
                                if theme.id == selectedTheme.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(.stExcelAccent)
                                        .frame(width: 28)
                                } else {
                                    Color.clear.frame(width: 28)
                                }
                                // 6 color swatches
                                HStack(spacing: 3) {
                                    ForEach(0..<min(theme.colors.count, 6), id: \.self) { i in
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(theme.colors[i])
                                            .frame(height: 36)
                                    }
                                }
                            }
                            .padding(.horizontal, 12)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 16)
            }
            .navigationTitle(STExcelStrings.chartColors)
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
}

// MARK: - Main Chart View (after type selected)

struct STExcelChartView: View {
    @ObservedObject var viewModel: STExcelEditorViewModel
    var initialSubtype: STExcelChartSubtype = .columnClustered
    let onDismiss: () -> Void

    @State private var chartSubtype: STExcelChartSubtype = .columnClustered
    @State private var showTypePicker = false
    @State private var showElementsPicker = false
    @State private var showLayoutsPicker = false
    @State private var showColorsPicker = false
    @State private var chartTitle: String = ""
    @State private var showLegend = true
    @State private var showGridlines = true
    @State private var showAxisLabels = true
    @State private var showDataLabels = false
    @State private var dataSeries: [STExcelChartSeries] = []
    @State private var colorTheme: STExcelChartColorTheme = .colorful1
    @State private var dataRangeText: String = ""

    private var activeColors: [Color] { colorTheme.colors }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                chartToolbar

                Divider()

                ScrollView {
                    VStack(spacing: 16) {
                        // Data Range — prominent at top
                        dataRangeInput

                        // Chart preview
                        if !allPoints.isEmpty {
                            // Title above chart
                            if !chartTitle.isEmpty {
                                Text(chartTitle)
                                    .font(.system(size: 16, weight: .semibold))
                            }

                            chartContent
                                .frame(height: 280)
                                .padding(.horizontal, 8)

                            // Data info below chart
                            dataInfoSection
                        } else {
                            emptyState
                        }

                        // Chart title field
                        TextField(STExcelStrings.chartTitle, text: $chartTitle)
                            .textFieldStyle(.roundedBorder)
                            .padding(.horizontal, 16)

                        // Subtype info
                        HStack {
                            Image(systemName: chartSubtype.iconName)
                                .foregroundColor(.stExcelAccent)
                            Text("\(chartSubtype.category.displayName) — \(chartSubtype.displayName)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.vertical, 12)
                }
            }
            .navigationTitle(STExcelStrings.chart)
            .stNavigationBarTitleDisplayMode()
            .toolbar {
                ToolbarItem(placement: .stLeading) {
                    Button(STStrings.cancel) { onDismiss() }
                }
                ToolbarItem(placement: .stTrailing) {
                    Button(STStrings.done) {
                        embedChartOnGrid()
                        onDismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showTypePicker) {
                STExcelChartTypePicker(
                    onSelect: { subtype in
                        chartSubtype = subtype
                        showTypePicker = false
                    },
                    onDismiss: { showTypePicker = false }
                )
                .stPresentationDetents([.large])
            }
            .sheet(isPresented: $showElementsPicker) {
                STExcelChartElementsPicker(
                    showTitle: Binding(
                        get: { !chartTitle.isEmpty },
                        set: { if !$0 { chartTitle = "" } else if chartTitle.isEmpty { chartTitle = "Chart Title" } }
                    ),
                    showLegend: $showLegend,
                    showGridlines: $showGridlines,
                    showAxisLabels: $showAxisLabels,
                    showDataLabels: $showDataLabels,
                    onDismiss: { showElementsPicker = false }
                )
                .stPresentationDetents([.height(350)])
            }
            .sheet(isPresented: $showLayoutsPicker) {
                STExcelChartLayoutsPicker(
                    onSelect: { layout in
                        applyLayout(layout)
                        showLayoutsPicker = false
                    },
                    onDismiss: { showLayoutsPicker = false }
                )
                .stPresentationDetents([.height(300)])
            }
            .sheet(isPresented: $showColorsPicker) {
                STExcelChartColorsPicker(
                    selectedTheme: colorTheme,
                    onSelect: { theme in
                        colorTheme = theme
                        recolorSeries()
                        showColorsPicker = false
                    },
                    onDismiss: { showColorsPicker = false }
                )
                .stPresentationDetents([.large])
            }
        }
        .onAppear {
            chartSubtype = initialSubtype
            loadDataSmartly()
        }
        .onChange(of: dataRangeText) { _ in
            loadDataFromRangeText()
        }
    }

    private var allPoints: [STExcelChartDataPoint] {
        dataSeries.flatMap { $0.points }
    }

    // MARK: - Chart Toolbar

    private var chartToolbar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 2) {
                STExcelRibbonToolButton(iconName: "chart.bar.doc.horizontal", label: STExcelStrings.chartType) {
                    showTypePicker = true
                }

                STExcelRibbonSeparator()

                STExcelRibbonToolButton(iconName: "plus.square", label: STExcelStrings.chartElements) {
                    showElementsPicker = true
                }
                STExcelRibbonToolButton(iconName: "rectangle.grid.2x2", label: STExcelStrings.layouts) {
                    showLayoutsPicker = true
                }

                STExcelRibbonSeparator()

                STExcelRibbonToolButton(iconName: "paintpalette", label: STExcelStrings.chartColors) {
                    showColorsPicker = true
                }

                STExcelRibbonSeparator()

                // Quick toggles
                STExcelRibbonToolButton(
                    iconName: "text.below.photo",
                    label: STExcelStrings.legend,
                    isActive: showLegend
                ) {
                    showLegend.toggle()
                }
                STExcelRibbonToolButton(
                    iconName: "square.grid.3x3",
                    label: STExcelStrings.grid,
                    isActive: showGridlines
                ) {
                    showGridlines.toggle()
                }
                STExcelRibbonToolButton(
                    iconName: "number",
                    label: STExcelStrings.dataLabels,
                    isActive: showDataLabels
                ) {
                    showDataLabels.toggle()
                }
            }
            .padding(.horizontal, 8)
        }
        .frame(height: 58)
        .background(.ultraThinMaterial)
    }

    // MARK: - Apply Layout

    private func applyLayout(_ layout: STExcelChartLayout) {
        if layout.showTitle && chartTitle.isEmpty {
            chartTitle = "Chart Title"
        } else if !layout.showTitle {
            chartTitle = ""
        }
        showLegend = layout.showLegend
        showGridlines = layout.showGridlines
        showAxisLabels = layout.showAxisLabels
    }

    // MARK: - Recolor Series

    private func recolorSeries() {
        let colors = activeColors
        dataSeries = dataSeries.enumerated().map { index, s in
            STExcelChartSeries(
                name: s.name,
                points: s.points,
                color: colors[index % colors.count]
            )
        }
    }

    // MARK: - Chart Content

    @ViewBuilder
    private var chartContent: some View {
        let category = chartSubtype.category

        switch category {
        case .column:
            columnChart
        case .bar:
            barChart
        case .line, .lineWithMarkers:
            lineChart
        case .area:
            areaChart
        case .pie:
            pieChart
        case .scatter:
            scatterChart
        case .all:
            columnChart
        }
    }

    // MARK: - Column Chart

    private var columnChart: some View {
        Chart(allPoints) { point in
            if chartSubtype.isStacked || chartSubtype.isPercentStacked {
                BarMark(
                    x: .value("Label", point.label),
                    y: .value("Value", point.value),
                    stacking: chartSubtype.isPercentStacked ? .normalized : .standard
                )
                .foregroundStyle(by: .value("Series", point.series))
            } else {
                BarMark(
                    x: .value("Label", point.label),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(by: .value("Series", point.series))
            }
        }
        .chartForegroundStyleScale(range: activeColors)
        .chartLegend(showLegend ? .visible : .hidden)
        .chartXAxis {
            if showAxisLabels {
                AxisMarks { _ in AxisValueLabel().font(.caption2) }
            } else {
                AxisMarks(values: [Double]()) { _ in }
            }
        }
        .chartYAxis {
            if showGridlines {
                AxisMarks()
            } else {
                AxisMarks(values: [Double]()) { _ in }
            }
        }
    }

    // MARK: - Bar Chart

    private var barChart: some View {
        Chart(allPoints) { point in
            if chartSubtype.isStacked || chartSubtype.isPercentStacked {
                BarMark(
                    x: .value("Value", point.value),
                    y: .value("Label", point.label),
                    stacking: chartSubtype.isPercentStacked ? .normalized : .standard
                )
                .foregroundStyle(by: .value("Series", point.series))
            } else {
                BarMark(
                    x: .value("Value", point.value),
                    y: .value("Label", point.label)
                )
                .foregroundStyle(by: .value("Series", point.series))
            }
        }
        .chartForegroundStyleScale(range: activeColors)
        .chartLegend(showLegend ? .visible : .hidden)
        .chartYAxis {
            if showAxisLabels {
                AxisMarks { _ in AxisValueLabel().font(.caption2) }
            } else {
                AxisMarks(values: [Double]()) { _ in }
            }
        }
        .chartXAxis {
            if showGridlines {
                AxisMarks()
            } else {
                AxisMarks(values: [Double]()) { _ in }
            }
        }
    }

    // MARK: - Line Chart

    private var lineChart: some View {
        Chart(allPoints) { point in
            LineMark(
                x: .value("Label", point.label),
                y: .value("Value", point.value)
            )
            .foregroundStyle(by: .value("Series", point.series))
            .symbol(chartSubtype.category == .lineWithMarkers ? .circle : .square)
            .symbolSize(chartSubtype.category == .lineWithMarkers ? 40 : 0)
            .interpolationMethod(
                chartSubtype == .lineSmooth || chartSubtype == .lineMarkersSmooth
                    ? .catmullRom : .linear
            )
        }
        .chartForegroundStyleScale(range: activeColors)
        .chartLegend(showLegend ? .visible : .hidden)
        .chartXAxis {
            if showAxisLabels {
                AxisMarks { _ in AxisValueLabel().font(.caption2) }
            } else {
                AxisMarks(values: [Double]()) { _ in }
            }
        }
        .chartYAxis {
            if showGridlines { AxisMarks() } else { AxisMarks(values: [Double]()) { _ in } }
        }
    }

    // MARK: - Area Chart

    private var areaChart: some View {
        Chart(allPoints) { point in
            if chartSubtype.isStacked || chartSubtype.isPercentStacked {
                AreaMark(
                    x: .value("Label", point.label),
                    y: .value("Value", point.value),
                    stacking: chartSubtype.isPercentStacked ? .normalized : .standard
                )
                .foregroundStyle(by: .value("Series", point.series))
                .opacity(0.6)
            } else {
                AreaMark(
                    x: .value("Label", point.label),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(by: .value("Series", point.series))
                .opacity(0.6)
            }
        }
        .chartForegroundStyleScale(range: activeColors)
        .chartLegend(showLegend ? .visible : .hidden)
        .chartXAxis {
            if showAxisLabels {
                AxisMarks { _ in AxisValueLabel().font(.caption2) }
            } else {
                AxisMarks(values: [Double]()) { _ in }
            }
        }
        .chartYAxis {
            if showGridlines { AxisMarks() } else { AxisMarks(values: [Double]()) { _ in } }
        }
    }

    // MARK: - Pie Chart

    @ViewBuilder
    private var pieChart: some View {
        if #available(macOS 14.0, iOS 17.0, *) {
            Chart(allPoints) { point in
                SectorMark(
                    angle: .value("Value", point.value),
                    innerRadius: chartSubtype == .doughnut ? .ratio(0.45) : .ratio(0),
                    angularInset: chartSubtype == .pieExploded ? 3 : 1.5
                )
                .foregroundStyle(by: .value("Label", point.label))
                .cornerRadius(3)
            }
            .chartForegroundStyleScale(range: activeColors)
            .chartLegend(showLegend ? .visible : .hidden)
        } else {
            Chart(allPoints) { point in
                BarMark(x: .value("Label", point.label), y: .value("Value", point.value))
                    .foregroundStyle(by: .value("Series", point.series))
            }
            .chartForegroundStyleScale(range: activeColors)
        }
    }

    // MARK: - Scatter Chart

    private var scatterChart: some View {
        Chart(allPoints) { point in
            if chartSubtype == .scatterLines {
                LineMark(
                    x: .value("Index", point.label),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(by: .value("Series", point.series))
                PointMark(
                    x: .value("Index", point.label),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(by: .value("Series", point.series))
                .symbolSize(30)
            } else if chartSubtype == .scatterSmooth {
                LineMark(
                    x: .value("Index", point.label),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(by: .value("Series", point.series))
                .interpolationMethod(.catmullRom)
                PointMark(
                    x: .value("Index", point.label),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(by: .value("Series", point.series))
                .symbolSize(30)
            } else {
                PointMark(
                    x: .value("Index", point.label),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(by: .value("Series", point.series))
                .symbolSize(40)
            }
        }
        .chartForegroundStyleScale(range: activeColors)
        .chartLegend(showLegend ? .visible : .hidden)
        .chartXAxis {
            if showAxisLabels {
                AxisMarks { _ in AxisValueLabel().font(.caption2) }
            } else {
                AxisMarks(values: [Double]()) { _ in }
            }
        }
        .chartYAxis {
            if showGridlines { AxisMarks() } else { AxisMarks(values: [Double]()) { _ in } }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.stSecondarySystemBackground)
            .frame(height: 180)
            .overlay(
                VStack(spacing: 8) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    Text(STExcelStrings.noNumericData)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    Text(STExcelStrings.editDataRangeHint)
                        .font(.caption)
                        .foregroundColor(.secondary.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
            )
            .padding(.horizontal, 16)
    }

    // MARK: - Data Range Input

    private var dataRangeInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "tablecells")
                    .foregroundColor(.stExcelAccent)
                    .font(.system(size: 16))

                Text(STExcelStrings.chartDataRange)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)

                Spacer()

                // Status indicator
                if !allPoints.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.stExcelAccent)
                        Text("\(allPoints.count) \(STExcelStrings.points)")
                            .font(.system(size: 12))
                            .foregroundColor(.stExcelAccent)
                    }
                } else if !dataRangeText.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.orange)
                        Text(STExcelStrings.noData)
                            .font(.system(size: 12))
                            .foregroundColor(.orange)
                    }
                }
            }

            TextField("e.g. A1:D10", text: $dataRangeText)
                .font(.system(size: 16, weight: .medium, design: .monospaced))
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.stSecondarySystemBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(allPoints.isEmpty && !dataRangeText.isEmpty ? Color.orange.opacity(0.5) : Color.stSeparator, lineWidth: 1)
                )
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Data Info

    private var dataInfoSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            if !dataSeries.isEmpty {
                Text("\(dataSeries.count) \(STExcelStrings.series), \(allPoints.count) \(STExcelStrings.dataPoints)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                ForEach(dataSeries) { series in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(series.color)
                            .frame(width: 8, height: 8)
                        Text(series.name)
                            .font(.caption)
                            .foregroundColor(.primary)
                        Text("(\(series.points.count) \(STExcelStrings.points))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Parse Range Text

    /// Parse a range string like "A1:D5" or "A1 : D5" into (startRow, startCol, endRow, endCol)
    private static func parseRange(_ text: String) -> (sr: Int, sc: Int, er: Int, ec: Int)? {
        // Remove all spaces, uppercase
        let cleaned = text.replacingOccurrences(of: " ", with: "").uppercased()
        guard !cleaned.isEmpty else { return nil }

        let parts = cleaned.split(separator: ":")
        guard parts.count == 2 else {
            // Single cell like "A1"
            if let ref = CellReference(string: cleaned) {
                return (ref.row, ref.col, ref.row, ref.col)
            }
            return nil
        }
        guard let start = CellReference(string: String(parts[0])),
              let end = CellReference(string: String(parts[1])) else {
            return nil
        }
        return (
            min(start.row, end.row), min(start.col, end.col),
            max(start.row, end.row), max(start.col, end.col)
        )
    }

    /// Build range text from row/col indices (e.g. "A1:D5")
    private static func rangeText(sr: Int, sc: Int, er: Int, ec: Int) -> String {
        let startRef = "\(STExcelSheet.columnLetter(sc))\(sr + 1)"
        let endRef = "\(STExcelSheet.columnLetter(ec))\(er + 1)"
        if sr == er && sc == ec { return startRef }
        return "\(startRef):\(endRef)"
    }

    private func loadDataFromRangeText() {
        guard let parsed = Self.parseRange(dataRangeText) else {
            dataSeries = []
            return
        }
        loadDataForRange(sr: parsed.sr, sc: parsed.sc, er: parsed.er, ec: parsed.ec)
    }

    // MARK: - Smart Data Loading

    /// Called on appear — tries: 1) current selection, 2) auto-detect data region
    private func loadDataSmartly() {
        guard let sheet = viewModel.sheet else { return }

        // 1) If user has a multi-cell selection, use it
        if viewModel.hasRangeSelection {
            let sr = min(viewModel.selectionStartRow, viewModel.selectionActualEndRow)
            let sc = min(viewModel.selectionStartCol, viewModel.selectionActualEndCol)
            let er = max(viewModel.selectionStartRow, viewModel.selectionActualEndRow)
            let ec = max(viewModel.selectionStartCol, viewModel.selectionActualEndCol)
            dataRangeText = Self.rangeText(sr: sr, sc: sc, er: er, ec: ec)
            return // onChange will trigger loadDataFromRangeText
        }

        // 2) Auto-detect: find the used data region in the sheet
        let detected = autoDetectDataRange(in: sheet)
        if let range = detected {
            dataRangeText = Self.rangeText(sr: range.sr, sc: range.sc, er: range.er, ec: range.ec)
            return // onChange will trigger
        }

        // 3) Fallback: use whatever single cell is selected
        let sr = viewModel.selectionStartRow
        let sc = viewModel.selectionStartCol
        dataRangeText = Self.rangeText(sr: sr, sc: sc, er: sr, ec: sc)
    }

    /// Scan sheet to find the data region — limited to 15 data rows for readable charts
    private func autoDetectDataRange(in sheet: STExcelSheet) -> (sr: Int, sc: Int, er: Int, ec: Int)? {
        var minR = Int.max, minC = Int.max
        var maxR = -1, maxC = -1
        var hasNumeric = false

        let rowLimit = min(sheet.rowCount, 100)
        let colLimit = min(sheet.columnCount, 50)

        for r in 0..<rowLimit {
            for c in 0..<colLimit {
                let cell = sheet.cell(row: r, column: c)
                if !cell.value.isEmpty {
                    minR = min(minR, r)
                    minC = min(minC, c)
                    maxR = max(maxR, r)
                    maxC = max(maxC, c)
                    if Double(cell.value) != nil { hasNumeric = true }
                }
            }
        }

        guard hasNumeric, maxR >= 0 else { return nil }

        // Cap to ~15 data rows so chart bars stay readable
        let maxDataRows = 15
        let adjustedEndRow = min(maxR, minR + maxDataRows)
        return (minR, minC, adjustedEndRow, maxC)
    }

    /// Core data loading from a specific range
    private func loadDataForRange(sr: Int, sc: Int, er: Int, ec: Int) {
        guard let sheet = viewModel.sheet else { return }
        guard sr >= 0, sc >= 0, er < sheet.rowCount, ec < sheet.columnCount else {
            dataSeries = []
            return
        }

        let colors = activeColors
        var series: [STExcelChartSeries] = []

        // Single column: one series
        if sc == ec {
            var points: [STExcelChartDataPoint] = []
            for r in sr...er {
                let cell = sheet.cell(row: r, column: sc)
                if let num = Double(cell.value) {
                    points.append(STExcelChartDataPoint(
                        label: "\(STExcelStrings.row) \(r + 1)", value: num, series: STExcelStrings.dataLabel
                    ))
                }
            }
            if !points.isEmpty {
                series.append(STExcelChartSeries(name: STExcelStrings.dataLabel, points: points, color: colors[0]))
            }
        }
        // Two columns: labels + values
        else if ec == sc + 1 {
            var points: [STExcelChartDataPoint] = []
            for r in sr...er {
                let labelCell = sheet.cell(row: r, column: sc)
                let valueCell = sheet.cell(row: r, column: ec)
                if let num = Double(valueCell.value) {
                    let label = labelCell.value.isEmpty ? "\(STExcelStrings.row) \(r + 1)" : labelCell.value
                    points.append(STExcelChartDataPoint(
                        label: label, value: num, series: STExcelStrings.dataLabel
                    ))
                }
            }
            if !points.isEmpty {
                series.append(STExcelChartSeries(name: STExcelStrings.dataLabel, points: points, color: colors[0]))
            }
        }
        // Multiple columns: first col = labels, other cols = series
        else {
            let firstRowIsHeader = Double(sheet.cell(row: sr, column: sc + 1).value) == nil
            let dataStartRow = firstRowIsHeader ? sr + 1 : sr

            for c in (sc + 1)...ec {
                let seriesIndex = c - sc - 1
                let seriesName = firstRowIsHeader
                    ? (sheet.cell(row: sr, column: c).value.isEmpty
                        ? STExcelSheet.columnLetter(c) : sheet.cell(row: sr, column: c).value)
                    : STExcelSheet.columnLetter(c)
                let color = colors[seriesIndex % colors.count]

                var points: [STExcelChartDataPoint] = []
                for r in dataStartRow...er {
                    let labelCell = sheet.cell(row: r, column: sc)
                    let valueCell = sheet.cell(row: r, column: c)
                    if let num = Double(valueCell.value) {
                        let label = labelCell.value.isEmpty ? "\(STExcelStrings.row) \(r + 1)" : labelCell.value
                        points.append(STExcelChartDataPoint(
                            label: label, value: num, series: seriesName
                        ))
                    }
                }
                if !points.isEmpty {
                    series.append(STExcelChartSeries(name: seriesName, points: points, color: color))
                }
            }

            // Fallback: all numeric cells as single series
            if series.isEmpty {
                var points: [STExcelChartDataPoint] = []
                for c in sc...ec {
                    let cell = sheet.cell(row: sr, column: c)
                    if let num = Double(cell.value) {
                        points.append(STExcelChartDataPoint(
                            label: STExcelSheet.columnLetter(c), value: num, series: STExcelStrings.dataLabel
                        ))
                    }
                }
                if !points.isEmpty {
                    series.append(STExcelChartSeries(name: STExcelStrings.dataLabel, points: points, color: colors[0]))
                }
            }
        }

        dataSeries = series
    }

    // MARK: - Embed Chart on Grid

    private func embedChartOnGrid() {
        // Use the range from the text field (which may have been manually edited)
        let range = Self.parseRange(dataRangeText) ?? (
            min(viewModel.selectionStartRow, viewModel.selectionActualEndRow),
            min(viewModel.selectionStartCol, viewModel.selectionActualEndCol),
            max(viewModel.selectionStartRow, viewModel.selectionActualEndRow),
            max(viewModel.selectionStartCol, viewModel.selectionActualEndCol)
        )

        // Position chart to the right of the data range with padding
        let colWidth: CGFloat = 80 // default column width
        let rowHeight: CGFloat = 28 // default row height
        let chartX = CGFloat(range.ec + 1) * colWidth + 20  // right of data + 20px gap
        let chartY = max(CGFloat(range.sr) * rowHeight, 30)  // aligned with data start, min 30px from top

        let chart = STExcelEmbeddedChart(
            subtype: chartSubtype,
            title: chartTitle,
            colorTheme: colorTheme,
            showLegend: showLegend,
            showGridlines: showGridlines,
            showAxisLabels: showAxisLabels,
            showDataLabels: showDataLabels,
            x: chartX,
            y: chartY,
            width: 320,
            height: 240,
            dataStartRow: range.sr,
            dataStartCol: range.sc,
            dataEndRow: range.er,
            dataEndCol: range.ec
        )
        viewModel.addChart(chart)
    }
}
