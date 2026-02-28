import SwiftUI
import STKit

/// Observable model for editing chart data in the sheet
@MainActor
final class STChartEditorModel: ObservableObject {
    let chartId: String

    @Published var chartType: ChartType
    @Published var title: String
    @Published var series: [EditableSeries]

    init(chartId: String, chartType: ChartType, title: String, series: [EditableSeries]) {
        self.chartId = chartId
        self.chartType = chartType
        self.title = title
        self.series = series
    }

    /// Create from a Chart model
    convenience init(from chart: Chart) {
        let editableSeries = chart.series.map { s in
            EditableSeries(
                name: s.name,
                values: s.categories.indices.map { i in
                    EditableValue(
                        category: i < s.categories.count ? s.categories[i] : "",
                        value: i < s.values.count ? s.values[i] : 0
                    )
                }
            )
        }
        self.init(
            chartId: chart.chartId,
            chartType: chart.chartType,
            title: chart.title ?? "",
            series: editableSeries
        )
    }

    /// Convert back to Chart JSON for JS bridge
    func toChartJSON() -> String? {
        let seriesData = series.map { s in
            ChartJSONSeries(
                name: s.name,
                categories: s.values.map { $0.category },
                values: s.values.map { $0.value }
            )
        }

        let legendPos: String
        switch chartType {
        case .pie, .doughnut: legendPos = "right"
        default: legendPos = "bottom"
        }

        let data = ChartJSONData(
            chartId: chartId,
            chartType: chartType.chartJSType,
            title: title.isEmpty ? nil : title,
            legendPosition: legendPos,
            barDirection: nil,
            barGrouping: nil,
            series: seriesData
        )

        guard let jsonData = try? JSONEncoder().encode(data) else { return nil }
        return String(data: jsonData, encoding: .utf8)
    }

    func addRow() {
        for i in series.indices {
            series[i].values.append(EditableValue(category: "", value: 0))
        }
    }

    func deleteRow(at index: Int) {
        for i in series.indices {
            if index < series[i].values.count {
                series[i].values.remove(at: index)
            }
        }
    }

    func addSeries() {
        let rowCount = series.first?.values.count ?? 1
        let values = (0..<rowCount).map { _ in EditableValue(category: "", value: 0) }
        series.append(EditableSeries(name: "Series \(series.count + 1)", values: values))
    }

    func deleteSeries(at index: Int) {
        guard series.count > 1 else { return }
        series.remove(at: index)
    }
}

/// An editable data series
struct EditableSeries: Identifiable {
    let id = UUID()
    var name: String
    var values: [EditableValue]
}

/// An editable category-value pair
struct EditableValue: Identifiable {
    let id = UUID()
    var category: String
    var value: Double
}

/// SwiftUI sheet for editing chart data
struct STChartDataEditorView: View {
    @ObservedObject var model: STChartEditorModel
    let onDone: () -> Void
    let onCancel: () -> Void

    var body: some View {
        #if os(macOS)
        macOSBody
        #else
        iOSBody
        #endif
    }

    #if os(macOS)
    private var macOSBody: some View {
        let sw = NSScreen.main?.frame.width ?? 1440
        let sh = NSScreen.main?.frame.height ?? 900
        return VStack(spacing: 0) {
            // Header
            HStack {
                Button("Cancel") { onCancel() }
                    .buttonStyle(.plain)
                    .foregroundColor(.accentColor)
                Spacer()
                Text("Edit Chart")
                    .font(.headline)
                Spacer()
                Button("Done") { onDone() }
                    .buttonStyle(.plain)
                    .foregroundColor(.accentColor)
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            Divider()

            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Chart type
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Chart Type")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        Picker("Type", selection: $model.chartType) {
                            Text("Bar").tag(ChartType.bar)
                            Text("Line").tag(ChartType.line)
                            Text("Pie").tag(ChartType.pie)
                            Text("Doughnut").tag(ChartType.doughnut)
                        }
                        .pickerStyle(.segmented)
                    }

                    // Title
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Title")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        TextField("Chart title", text: $model.title)
                            .textFieldStyle(.roundedBorder)
                    }

                    Divider()

                    // Series
                    ForEach(model.series.indices, id: \.self) { seriesIdx in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Series \(seriesIdx + 1)")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.secondary)
                                Spacer()
                                if model.series.count > 1 {
                                    Button(role: .destructive) {
                                        model.deleteSeries(at: seriesIdx)
                                    } label: {
                                        Image(systemName: "trash")
                                            .font(.caption)
                                    }
                                    .buttonStyle(.plain)
                                    .foregroundColor(.red)
                                }
                            }

                            HStack(spacing: 8) {
                                Text("Name")
                                    .foregroundColor(.secondary)
                                    .frame(width: 60, alignment: .leading)
                                TextField("Series name", text: $model.series[seriesIdx].name)
                                    .textFieldStyle(.roundedBorder)
                            }

                            // Values grid
                            Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 6) {
                                GridRow {
                                    Text("Category")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    Text("Value")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .frame(width: 100, alignment: .trailing)
                                }

                                ForEach(model.series[seriesIdx].values.indices, id: \.self) { valIdx in
                                    GridRow {
                                        if seriesIdx == 0 {
                                            TextField("Category", text: categoryBinding(seriesIdx: seriesIdx, valIdx: valIdx))
                                                .textFieldStyle(.roundedBorder)
                                        } else {
                                            Text(model.series[0].values.indices.contains(valIdx) ? model.series[0].values[valIdx].category : "")
                                                .foregroundColor(.secondary)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                        TextField("Value", value: $model.series[seriesIdx].values[valIdx].value, format: .number)
                                            .textFieldStyle(.roundedBorder)
                                            .frame(width: 100)
                                            .multilineTextAlignment(.trailing)
                                    }
                                }
                            }
                        }
                        .padding(12)
                        .background(Color.gray.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    Divider()

                    // Actions
                    HStack(spacing: 12) {
                        Button {
                            model.addRow()
                        } label: {
                            Label("Add Row", systemImage: "plus.circle")
                                .font(.system(size: 13))
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.accentColor)

                        Button {
                            model.addSeries()
                        } label: {
                            Label("Add Series", systemImage: "chart.bar.xaxis")
                                .font(.system(size: 13))
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.accentColor)
                    }
                }
                .padding(16)
            }
            .frame(maxHeight: sh * 0.6)
        }
        .frame(width: sw * 0.4)
    }
    #endif

    private var iOSBody: some View {
        NavigationView {
            Form {
                chartTypeSection
                titleSection
                seriesSections
                actionsSection
            }
            .navigationTitle("Edit Chart")
            .stNavigationBarTitleDisplayMode()
            .toolbar {
                ToolbarItem(placement: .stLeading) {
                    Button("Cancel") { onCancel() }
                }
                ToolbarItem(placement: .stTrailing) {
                    Button("Done") { onDone() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private var chartTypeSection: some View {
        Section("Chart Type") {
            Picker("Type", selection: $model.chartType) {
                Text("Bar").tag(ChartType.bar)
                Text("Line").tag(ChartType.line)
                Text("Pie").tag(ChartType.pie)
                Text("Doughnut").tag(ChartType.doughnut)
            }
            .pickerStyle(.segmented)
        }
    }

    private var titleSection: some View {
        Section("Title") {
            TextField("Chart title", text: $model.title)
        }
    }

    private var seriesSections: some View {
        ForEach(model.series.indices, id: \.self) { seriesIdx in
            Section {
                HStack {
                    Text("Name")
                        .foregroundColor(.secondary)
                        .frame(width: 50, alignment: .leading)
                    TextField("Series name", text: $model.series[seriesIdx].name)
                }

                ForEach(model.series[seriesIdx].values.indices, id: \.self) { valIdx in
                    seriesValueRow(seriesIdx: seriesIdx, valIdx: valIdx)
                }
                .onDelete { indexSet in
                    for idx in indexSet {
                        model.deleteRow(at: idx)
                    }
                }
            } header: {
                seriesHeader(seriesIdx: seriesIdx)
            }
        }
    }

    private func seriesValueRow(seriesIdx: Int, valIdx: Int) -> some View {
        HStack(spacing: 8) {
            if seriesIdx == 0 {
                TextField("Category", text: categoryBinding(seriesIdx: seriesIdx, valIdx: valIdx))
                    .frame(maxWidth: .infinity)
            } else {
                Text(model.series[0].values.indices.contains(valIdx) ? model.series[0].values[valIdx].category : "")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            TextField("Value", value: $model.series[seriesIdx].values[valIdx].value, format: .number)
                .stKeyboardType(.decimalPad)
                .frame(width: 80)
                .multilineTextAlignment(.trailing)
        }
    }

    private func seriesHeader(seriesIdx: Int) -> some View {
        HStack {
            Text("Series \(seriesIdx + 1)")
            Spacer()
            if model.series.count > 1 {
                Button(role: .destructive) {
                    model.deleteSeries(at: seriesIdx)
                } label: {
                    Image(systemName: "trash")
                        .font(.caption)
                }
            }
        }
    }

    private var actionsSection: some View {
        Section {
            Button {
                model.addRow()
            } label: {
                Label("Add Row", systemImage: "plus.circle")
            }
            Button {
                model.addSeries()
            } label: {
                Label("Add Series", systemImage: "chart.bar.xaxis")
            }
        }
    }

    private func categoryBinding(seriesIdx: Int, valIdx: Int) -> Binding<String> {
        Binding(
            get: {
                guard seriesIdx < model.series.count,
                      valIdx < model.series[seriesIdx].values.count else { return "" }
                return model.series[seriesIdx].values[valIdx].category
            },
            set: { newValue in
                guard seriesIdx < model.series.count,
                      valIdx < model.series[seriesIdx].values.count else { return }
                model.series[seriesIdx].values[valIdx].category = newValue
                // Sync category across all series
                for i in model.series.indices where i != seriesIdx {
                    if valIdx < model.series[i].values.count {
                        model.series[i].values[valIdx].category = newValue
                    }
                }
            }
        )
    }
}
