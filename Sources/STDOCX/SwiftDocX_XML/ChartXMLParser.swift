import Foundation

/// Parses chart XML (word/charts/chartN.xml) into a Chart model using SAX-style parsing
class ChartXMLParser: NSObject, XMLParserDelegate {

    private var chart = Chart()

    // State tracking
    private var inChartSpace = false
    private var inChart = false
    private var inPlotArea = false
    private var inTitle = false
    private var inTitleText = false
    private var inSeries = false
    private var inSeriesName = false
    private var inCategories = false
    private var inValues = false
    private var inLegend = false
    private var inStringCache = false
    private var inNumCache = false
    private var inPoint = false

    // Current chart type element depth tracking
    private var chartTypeElement: String?

    // Current series being built
    private var currentSeriesName = ""
    private var currentCategories: [String] = []
    private var currentValues: [Double] = []
    private var currentPointIndex: Int = 0
    private var currentPointValue = ""

    // Text accumulator
    private var textBuffer = ""
    private var collectText = false

    /// Parse chart XML data and return a Chart model
    func parse(_ xmlData: Data) -> Chart? {
        chart = Chart()
        let parser = XMLParser(data: xmlData)
        parser.delegate = self
        parser.shouldProcessNamespaces = true
        parser.parse()

        return chart.series.isEmpty ? nil : chart
    }

    // MARK: - XMLParserDelegate

    func parser(_ parser: XMLParser, didStartElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?,
                attributes attributeDict: [String: String] = [:]) {

        let local = stripNamespace(elementName)

        switch local {
        case "chartSpace":
            inChartSpace = true

        case "chart" where inChartSpace:
            inChart = true

        case "plotArea" where inChart:
            inPlotArea = true

        // Chart type elements
        case "barChart", "bar3DChart" where inPlotArea:
            chartTypeElement = local
            chart.chartType = local == "bar3DChart" ? .bar3D : .bar

        case "lineChart" where inPlotArea:
            chartTypeElement = local
            chart.chartType = .line

        case "pieChart" where inPlotArea:
            chartTypeElement = local
            chart.chartType = .pie

        case "areaChart" where inPlotArea:
            chartTypeElement = local
            chart.chartType = .area

        case "doughnutChart" where inPlotArea:
            chartTypeElement = local
            chart.chartType = .doughnut

        // Bar direction and grouping
        case "barDir" where chartTypeElement != nil:
            if let val = attributeDict["val"] {
                chart.barDirection = BarDirection(rawValue: val)
            }

        case "grouping" where chartTypeElement != nil:
            if let val = attributeDict["val"] {
                chart.barGrouping = BarGrouping(rawValue: val)
            }

        // Title
        case "title" where inChart && !inPlotArea:
            inTitle = true

        // Series
        case "ser" where chartTypeElement != nil:
            inSeries = true
            currentSeriesName = ""
            currentCategories = []
            currentValues = []

        // Series name (tx element)
        case "tx" where inSeries:
            inSeriesName = true

        // Categories (cat element)
        case "cat" where inSeries:
            inCategories = true

        // Values (val element)
        case "val" where inSeries:
            inValues = true

        // String cache (shared by series name, categories)
        case "strCache":
            inStringCache = true

        // Numeric cache (values)
        case "numCache":
            inNumCache = true

        // Point index
        case "pt" where inStringCache || inNumCache:
            inPoint = true
            if let idx = attributeDict["idx"] {
                currentPointIndex = Int(idx) ?? 0
            }

        // Value text
        case "v" where inPoint:
            collectText = true
            textBuffer = ""

        // Title text (a:t inside title)
        case "t" where inTitle:
            collectText = true
            textBuffer = ""

        // Legend
        case "legend" where inChart:
            inLegend = true

        case "legendPos" where inLegend:
            if let val = attributeDict["val"] {
                chart.legendPosition = ChartLegendPosition(rawValue: val) ?? .bottom
            }

        default:
            break
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if collectText {
            textBuffer += string
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?) {

        let local = stripNamespace(elementName)

        switch local {
        case "chartSpace":
            inChartSpace = false

        case "chart" where inChart:
            inChart = false

        case "plotArea":
            inPlotArea = false

        // End chart type element
        case "barChart", "bar3DChart", "lineChart", "pieChart", "areaChart", "doughnutChart":
            if local == chartTypeElement {
                chartTypeElement = nil
            }

        case "title" where inTitle && !inPlotArea:
            inTitle = false

        case "t" where inTitle && collectText:
            chart.title = textBuffer.trimmingCharacters(in: .whitespacesAndNewlines)
            collectText = false
            textBuffer = ""

        // Series end
        case "ser" where inSeries:
            let series = ChartSeries(
                name: currentSeriesName,
                categories: currentCategories,
                values: currentValues
            )
            chart.series.append(series)
            inSeries = false

        case "tx" where inSeriesName:
            inSeriesName = false

        case "cat" where inCategories:
            inCategories = false

        case "val" where inValues:
            inValues = false

        case "strCache":
            inStringCache = false

        case "numCache":
            inNumCache = false

        case "pt" where inPoint:
            inPoint = false

        case "v" where collectText:
            let value = textBuffer.trimmingCharacters(in: .whitespacesAndNewlines)

            if inSeriesName && inStringCache {
                currentSeriesName = value
            } else if inCategories && inStringCache {
                // Extend array if needed
                while currentCategories.count <= currentPointIndex {
                    currentCategories.append("")
                }
                currentCategories[currentPointIndex] = value
            } else if inValues && inNumCache {
                // Extend array if needed
                while currentValues.count <= currentPointIndex {
                    currentValues.append(0)
                }
                currentValues[currentPointIndex] = Double(value) ?? 0
            }

            collectText = false
            textBuffer = ""

        case "legend":
            inLegend = false

        default:
            break
        }
    }

    // MARK: - Helpers

    private func stripNamespace(_ name: String) -> String {
        if let colonIndex = name.lastIndex(of: ":") {
            return String(name[name.index(after: colonIndex)...])
        }
        return name
    }
}
