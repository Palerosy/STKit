import Foundation

/// Builds chart XML (ChartML) for DOCX export
enum ChartXMLBuilder {

    /// Build complete chart XML for word/charts/chartN.xml
    static func buildChartXML(_ chart: Chart) -> String {
        var xml = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <c:chartSpace xmlns:c="http://schemas.openxmlformats.org/drawingml/2006/chart" xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
        <c:chart>
        """

        // Title
        if let title = chart.title, !title.isEmpty {
            xml += buildTitleXML(title)
        }

        xml += "<c:autoTitleDeleted val=\"\(chart.title == nil ? "1" : "0")\"/>"

        // Plot area
        xml += "<c:plotArea>"
        xml += "<c:layout/>"

        // Chart type element with series
        xml += buildChartTypeXML(chart)

        // Axes (not needed for pie/doughnut)
        if chart.chartType != .pie && chart.chartType != .doughnut {
            xml += buildAxesXML()
        }

        xml += "</c:plotArea>"

        // Legend
        if chart.legendPosition != .none {
            xml += "<c:legend>"
            xml += "<c:legendPos val=\"\(chart.legendPosition.rawValue)\"/>"
            xml += "<c:overlay val=\"0\"/>"
            xml += "</c:legend>"
        }

        xml += "<c:plotVisOnly val=\"1\"/>"
        xml += "</c:chart>"
        xml += "</c:chartSpace>"

        return xml
    }

    // MARK: - Private

    private static func buildTitleXML(_ title: String) -> String {
        let escaped = escapeXML(title)
        return """
        <c:title>
        <c:tx>
        <c:rich>
        <a:bodyPr/>
        <a:lstStyle/>
        <a:p>
        <a:r>
        <a:rPr lang="en-US" dirty="0"/>
        <a:t>\(escaped)</a:t>
        </a:r>
        </a:p>
        </c:rich>
        </c:tx>
        <c:overlay val="0"/>
        </c:title>
        """
    }

    private static func buildChartTypeXML(_ chart: Chart) -> String {
        var xml = ""

        switch chart.chartType {
        case .bar, .bar3D:
            let element = chart.chartType == .bar3D ? "c:bar3DChart" : "c:barChart"
            xml += "<\(element)>"
            xml += "<c:barDir val=\"\(chart.barDirection?.rawValue ?? "col")\"/>"
            xml += "<c:grouping val=\"\(chart.barGrouping?.rawValue ?? "clustered")\"/>"
            xml += "<c:varyColors val=\"0\"/>"
            for (index, series) in chart.series.enumerated() {
                xml += buildSeriesXML(series, index: index)
            }
            xml += "<c:axId val=\"1\"/>"
            xml += "<c:axId val=\"2\"/>"
            xml += "</\(element)>"

        case .line:
            xml += "<c:lineChart>"
            xml += "<c:grouping val=\"standard\"/>"
            xml += "<c:varyColors val=\"0\"/>"
            for (index, series) in chart.series.enumerated() {
                xml += buildSeriesXML(series, index: index)
            }
            xml += "<c:axId val=\"1\"/>"
            xml += "<c:axId val=\"2\"/>"
            xml += "</c:lineChart>"

        case .pie:
            xml += "<c:pieChart>"
            xml += "<c:varyColors val=\"1\"/>"
            for (index, series) in chart.series.enumerated() {
                xml += buildSeriesXML(series, index: index)
            }
            xml += "</c:pieChart>"

        case .area:
            xml += "<c:areaChart>"
            xml += "<c:grouping val=\"standard\"/>"
            xml += "<c:varyColors val=\"0\"/>"
            for (index, series) in chart.series.enumerated() {
                xml += buildSeriesXML(series, index: index)
            }
            xml += "<c:axId val=\"1\"/>"
            xml += "<c:axId val=\"2\"/>"
            xml += "</c:areaChart>"

        case .doughnut:
            xml += "<c:doughnutChart>"
            xml += "<c:varyColors val=\"1\"/>"
            for (index, series) in chart.series.enumerated() {
                xml += buildSeriesXML(series, index: index)
            }
            xml += "<c:holeSize val=\"50\"/>"
            xml += "</c:doughnutChart>"
        }

        return xml
    }

    private static func buildSeriesXML(_ series: ChartSeries, index: Int) -> String {
        var xml = "<c:ser>"
        xml += "<c:idx val=\"\(index)\"/>"
        xml += "<c:order val=\"\(index)\"/>"

        // Series name
        if !series.name.isEmpty {
            xml += "<c:tx><c:strRef><c:strCache>"
            xml += "<c:ptCount val=\"1\"/>"
            xml += "<c:pt idx=\"0\"><c:v>\(escapeXML(series.name))</c:v></c:pt>"
            xml += "</c:strCache></c:strRef></c:tx>"
        }

        // Categories
        if !series.categories.isEmpty {
            xml += "<c:cat><c:strRef><c:strCache>"
            xml += "<c:ptCount val=\"\(series.categories.count)\"/>"
            for (i, cat) in series.categories.enumerated() {
                xml += "<c:pt idx=\"\(i)\"><c:v>\(escapeXML(cat))</c:v></c:pt>"
            }
            xml += "</c:strCache></c:strRef></c:cat>"
        }

        // Values
        if !series.values.isEmpty {
            xml += "<c:val><c:numRef><c:numCache>"
            xml += "<c:formatCode>General</c:formatCode>"
            xml += "<c:ptCount val=\"\(series.values.count)\"/>"
            for (i, val) in series.values.enumerated() {
                let formatted = val.truncatingRemainder(dividingBy: 1) == 0 ?
                    String(format: "%.0f", val) : String(val)
                xml += "<c:pt idx=\"\(i)\"><c:v>\(formatted)</c:v></c:pt>"
            }
            xml += "</c:numCache></c:numRef></c:val>"
        }

        xml += "</c:ser>"
        return xml
    }

    private static func buildAxesXML() -> String {
        var xml = ""

        // Category axis
        xml += """
        <c:catAx>
        <c:axId val="1"/>
        <c:scaling><c:orientation val="minMax"/></c:scaling>
        <c:delete val="0"/>
        <c:axPos val="b"/>
        <c:crossAx val="2"/>
        </c:catAx>
        """

        // Value axis
        xml += """
        <c:valAx>
        <c:axId val="2"/>
        <c:scaling><c:orientation val="minMax"/></c:scaling>
        <c:delete val="0"/>
        <c:axPos val="l"/>
        <c:crossAx val="1"/>
        </c:valAx>
        """

        return xml
    }

    private static func escapeXML(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }
}
