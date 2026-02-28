import Foundation

/// Chart types supported in DOCX documents
public enum ChartType: String, Sendable, Codable {
    case bar = "barChart"
    case bar3D = "bar3DChart"
    case line = "lineChart"
    case pie = "pieChart"
    case area = "areaChart"
    case doughnut = "doughnutChart"

    /// Chart.js type string for rendering
    public var chartJSType: String {
        switch self {
        case .bar, .bar3D: return "bar"
        case .line: return "line"
        case .pie: return "pie"
        case .area: return "line" // area = line with fill
        case .doughnut: return "doughnut"
        }
    }
}

/// Bar chart direction
public enum BarDirection: String, Sendable, Codable {
    case column = "col"  // Vertical bars (default)
    case bar = "bar"     // Horizontal bars
}

/// Bar chart grouping
public enum BarGrouping: String, Sendable, Codable {
    case clustered = "clustered"
    case stacked = "stacked"
    case percentStacked = "percentStacked"
}

/// Legend position for charts
public enum ChartLegendPosition: String, Sendable, Codable {
    case top = "t"
    case bottom = "b"
    case left = "l"
    case right = "r"
    case none = "none"

    /// Chart.js position string
    public var chartJSPosition: String {
        switch self {
        case .top: return "top"
        case .bottom: return "bottom"
        case .left: return "left"
        case .right: return "right"
        case .none: return "none"
        }
    }
}

/// A data series in a chart
public class ChartSeries: Codable {
    /// Series name (legend label)
    public var name: String

    /// Category labels (x-axis)
    public var categories: [String]

    /// Numeric values
    public var values: [Double]

    public init(name: String = "", categories: [String] = [], values: [Double] = []) {
        self.name = name
        self.categories = categories
        self.values = values
    }
}

/// A chart embedded in a DOCX document
public class Chart {
    /// Unique chart identifier
    public var chartId: String

    /// Chart type
    public var chartType: ChartType

    /// Chart title
    public var title: String?

    /// Data series
    public var series: [ChartSeries]

    /// Legend position
    public var legendPosition: ChartLegendPosition

    /// Bar chart direction (only for bar charts)
    public var barDirection: BarDirection?

    /// Bar chart grouping (only for bar charts)
    public var barGrouping: BarGrouping?

    /// Chart width in points
    public var width: Double?

    /// Chart height in points
    public var height: Double?

    // Internal properties for round-trip preservation
    /// Original chart XML data (for preserving unsupported features)
    var originalChartXML: Data?

    /// Relationship ID in document.xml
    var relationshipId: String?

    /// Path in the ZIP archive (e.g., "word/charts/chart1.xml")
    var entryPath: String?

    public init(
        chartType: ChartType = .bar,
        title: String? = nil,
        series: [ChartSeries] = []
    ) {
        self.chartId = UUID().uuidString
        self.chartType = chartType
        self.title = title
        self.series = series
        self.legendPosition = .bottom
    }

    /// Encode chart data to JSON for Chart.js rendering
    public func toJSON() -> String? {
        let data = ChartJSONData(
            chartId: chartId,
            chartType: chartType.chartJSType,
            title: title,
            legendPosition: legendPosition.chartJSPosition,
            barDirection: barDirection?.rawValue,
            barGrouping: barGrouping?.rawValue,
            series: series.map { s in
                ChartJSONSeries(name: s.name, categories: s.categories, values: s.values)
            }
        )
        guard let jsonData = try? JSONEncoder().encode(data) else { return nil }
        return String(data: jsonData, encoding: .utf8)
    }

    /// Decode chart data from JSON (from Chart.js)
    public static func fromJSON(_ json: String) -> Chart? {
        guard let data = json.data(using: .utf8),
              let decoded = try? JSONDecoder().decode(ChartJSONData.self, from: data) else { return nil }

        let chartType: ChartType
        switch decoded.chartType {
        case "bar": chartType = .bar
        case "line": chartType = .line
        case "pie": chartType = .pie
        case "doughnut": chartType = .doughnut
        default: chartType = .bar
        }

        let chart = Chart(chartType: chartType, title: decoded.title)
        chart.chartId = decoded.chartId

        if let pos = decoded.legendPosition {
            switch pos {
            case "top": chart.legendPosition = .top
            case "bottom": chart.legendPosition = .bottom
            case "left": chart.legendPosition = .left
            case "right": chart.legendPosition = .right
            default: chart.legendPosition = .none
            }
        }

        if let dir = decoded.barDirection {
            chart.barDirection = BarDirection(rawValue: dir)
        }
        if let grp = decoded.barGrouping {
            chart.barGrouping = BarGrouping(rawValue: grp)
        }

        chart.series = decoded.series.map { s in
            ChartSeries(name: s.name, categories: s.categories, values: s.values)
        }

        return chart
    }
}

extension Chart: CustomStringConvertible {
    public var description: String {
        "Chart(\(chartType.rawValue), series: \(series.count))"
    }
}

// MARK: - JSON Codable Structures (for Chart.js bridge)

struct ChartJSONData: Codable {
    let chartId: String
    let chartType: String
    let title: String?
    let legendPosition: String?
    let barDirection: String?
    let barGrouping: String?
    let series: [ChartJSONSeries]
}

struct ChartJSONSeries: Codable {
    let name: String
    let categories: [String]
    let values: [Double]
}
