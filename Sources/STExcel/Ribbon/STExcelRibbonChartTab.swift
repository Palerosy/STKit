import SwiftUI
import STKit

/// Chart contextual ribbon tab — appears when a chart is selected on the grid
struct STExcelRibbonChartTab: View {
    @ObservedObject var viewModel: STExcelEditorViewModel

    @State private var showTypePicker = false
    @State private var showFormatPicker = false
    @State private var showElementsPicker = false
    @State private var showLayoutsPicker = false
    @State private var showColorsPicker = false
    @State private var showStylesPicker = false

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 2) {
                // Type
                STExcelRibbonToolButton(iconName: "chart.bar.doc.horizontal", label: STExcelStrings.chartType) {
                    showTypePicker = true
                }
                .sheet(isPresented: $showTypePicker) {
                    STExcelChartTypePicker(
                        onSelect: { subtype in
                            if var chart = viewModel.selectedChart {
                                chart.subtype = subtype
                                viewModel.updateChart(chart)
                            }
                            showTypePicker = false
                        },
                        onDismiss: { showTypePicker = false }
                    )
                    .stPresentationDetents([.large])
                }

                // Format
                STExcelRibbonToolButton(iconName: "paintbrush", label: STExcelStrings.chartFormat) {
                    showFormatPicker = true
                }
                .sheet(isPresented: $showFormatPicker) {
                    chartFormatSheet
                        .stPresentationDetents([.medium])
                }

                STExcelRibbonSeparator()

                // Elements
                STExcelRibbonToolButton(iconName: "plus.square", label: STExcelStrings.chartElements) {
                    showElementsPicker = true
                }
                .sheet(isPresented: $showElementsPicker) {
                    chartElementsSheet
                        .stPresentationDetents([.height(350)])
                }

                // Chart Layouts
                STExcelRibbonToolButton(iconName: "rectangle.grid.2x2", label: STExcelStrings.chartLayouts) {
                    showLayoutsPicker = true
                }
                .sheet(isPresented: $showLayoutsPicker) {
                    STExcelChartLayoutsPicker(
                        onSelect: { layout in
                            if var chart = viewModel.selectedChart {
                                if layout.showTitle && chart.title.isEmpty {
                                    chart.title = "Chart Title"
                                } else if !layout.showTitle {
                                    chart.title = ""
                                }
                                chart.showLegend = layout.showLegend
                                chart.showGridlines = layout.showGridlines
                                chart.showAxisLabels = layout.showAxisLabels
                                viewModel.updateChart(chart)
                            }
                            showLayoutsPicker = false
                        },
                        onDismiss: { showLayoutsPicker = false }
                    )
                    .stPresentationDetents([.height(400)])
                }

                // Colors
                STExcelRibbonToolButton(iconName: "paintpalette", label: STExcelStrings.chartColors) {
                    showColorsPicker = true
                }
                .sheet(isPresented: $showColorsPicker) {
                    STExcelChartColorsPicker(
                        onSelect: { theme in
                            if var chart = viewModel.selectedChart {
                                chart.colorTheme = theme
                                viewModel.updateChart(chart)
                            }
                            showColorsPicker = false
                        },
                        onDismiss: { showColorsPicker = false }
                    )
                    .stPresentationDetents([.medium])
                }

                // Chart Styles
                STExcelRibbonToolButton(iconName: "square.grid.2x2", label: STExcelStrings.chartStylesTitle) {
                    showStylesPicker = true
                }
                .sheet(isPresented: $showStylesPicker) {
                    STExcelChartStylesPicker(
                        currentSubtype: viewModel.selectedChart?.subtype ?? .columnClustered
                    ) { style in
                        if var chart = viewModel.selectedChart {
                            chart.colorTheme = style.colorTheme
                            chart.showGridlines = style.showGridlines
                            chart.showLegend = style.showLegend
                            viewModel.updateChart(chart)
                        }
                        showStylesPicker = false
                    } onDismiss: {
                        showStylesPicker = false
                    }
                    .stPresentationDetents([.large])
                }

                STExcelRibbonSeparator()

                // Switch Rows/Columns
                STExcelRibbonToolButton(iconName: "arrow.left.arrow.right", label: STExcelStrings.switchRowsCols) {
                    if var chart = viewModel.selectedChart {
                        chart.seriesInRows.toggle()
                        viewModel.updateChart(chart)
                    }
                }

                STExcelRibbonSeparator()

                // Delete Chart
                STExcelRibbonToolButton(iconName: "trash", label: STExcelStrings.delete) {
                    viewModel.deleteSelectedChart()
                }
            }
            .padding(.horizontal, 8)
        }
    }

    // MARK: - Format Sheet

    private var chartFormatSheet: some View {
        NavigationView {
            List {
                Section(STExcelStrings.labels) {
                    Toggle(STExcelStrings.chartTitle, isOn: Binding(
                        get: { !(viewModel.selectedChart?.title.isEmpty ?? true) },
                        set: { on in
                            if var chart = viewModel.selectedChart {
                                chart.title = on ? "Chart Title" : ""
                                viewModel.updateChart(chart)
                            }
                        }
                    ))

                    if let chart = viewModel.selectedChart, !chart.title.isEmpty {
                        HStack {
                            Text(STExcelStrings.title)
                            TextField(STExcelStrings.enterTitle, text: Binding(
                                get: { viewModel.selectedChart?.title ?? "" },
                                set: { val in
                                    if var chart = viewModel.selectedChart {
                                        chart.title = val
                                        viewModel.updateChart(chart)
                                    }
                                }
                            ))
                            .foregroundColor(.stExcelAccent)
                            .multilineTextAlignment(.trailing)
                        }
                    }

                    Toggle(STExcelStrings.horizontalLabels, isOn: Binding(
                        get: { viewModel.selectedChart?.showAxisLabels ?? true },
                        set: { val in
                            if var chart = viewModel.selectedChart {
                                chart.showAxisLabels = val
                                viewModel.updateChart(chart)
                            }
                        }
                    ))
                }

                Section(STExcelStrings.dataRange) {
                    if let chart = viewModel.selectedChart {
                        HStack {
                            Text(STExcelStrings.range)
                            Spacer()
                            let rangeStr = "\(STExcelSheet.columnLetter(chart.dataStartCol))\(chart.dataStartRow + 1):\(STExcelSheet.columnLetter(chart.dataEndCol))\(chart.dataEndRow + 1)"
                            Text(rangeStr)
                                .foregroundColor(.stExcelAccent)
                        }
                    }

                    HStack {
                        Text(STExcelStrings.seriesIn)
                        Spacer()
                        Text(viewModel.selectedChart?.seriesInRows == true ? STExcelStrings.rows : STExcelStrings.columns)
                            .foregroundColor(.stExcelAccent)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if var chart = viewModel.selectedChart {
                            chart.seriesInRows.toggle()
                            viewModel.updateChart(chart)
                        }
                    }
                }
            }
            .navigationTitle(STExcelStrings.chartFormat)
            .stNavigationBarTitleDisplayMode()
            .toolbar {
                ToolbarItem(placement: .stTrailing) {
                    Button { showFormatPicker = false } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Elements Sheet

    private var chartElementsSheet: some View {
        NavigationView {
            List {
                HStack {
                    Text(STExcelStrings.axes)
                    Spacer()
                    Text(viewModel.selectedChart?.showAxisLabels == true ? STExcelStrings.on : STExcelStrings.off)
                        .foregroundColor(.stExcelAccent)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if var chart = viewModel.selectedChart {
                        chart.showAxisLabels.toggle()
                        viewModel.updateChart(chart)
                    }
                }

                HStack {
                    Text(STExcelStrings.dataLabels)
                    Spacer()
                    Text(viewModel.selectedChart?.showDataLabels == true ? STExcelStrings.on : STExcelStrings.off)
                        .foregroundColor(.stExcelAccent)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if var chart = viewModel.selectedChart {
                        chart.showDataLabels.toggle()
                        viewModel.updateChart(chart)
                    }
                }

                HStack {
                    Text(STExcelStrings.gridlines)
                    Spacer()
                    Text(viewModel.selectedChart?.showGridlines == true ? STExcelStrings.on : STExcelStrings.off)
                        .foregroundColor(.stExcelAccent)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if var chart = viewModel.selectedChart {
                        chart.showGridlines.toggle()
                        viewModel.updateChart(chart)
                    }
                }

                HStack {
                    Text(STExcelStrings.legend)
                    Spacer()
                    Text(viewModel.selectedChart?.showLegend == true ? STExcelStrings.on : STExcelStrings.off)
                        .foregroundColor(.stExcelAccent)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if var chart = viewModel.selectedChart {
                        chart.showLegend.toggle()
                        viewModel.updateChart(chart)
                    }
                }
            }
            .navigationTitle(STExcelStrings.chartElements)
            .stNavigationBarTitleDisplayMode()
            .toolbar {
                ToolbarItem(placement: .stTrailing) {
                    Button { showElementsPicker = false } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}
