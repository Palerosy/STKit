import SwiftUI

/// An embedded chart that lives on the spreadsheet grid
struct STExcelEmbeddedChart: Identifiable {
    let id = UUID()
    var subtype: STExcelChartSubtype
    var title: String
    var colorTheme: STExcelChartColorTheme
    var showLegend: Bool
    var showGridlines: Bool
    var showAxisLabels: Bool
    var showDataLabels: Bool
    var seriesInRows: Bool

    /// Position and size on the grid (in points)
    var x: CGFloat
    var y: CGFloat
    var width: CGFloat
    var height: CGFloat

    /// Data source range
    var dataStartRow: Int
    var dataStartCol: Int
    var dataEndRow: Int
    var dataEndCol: Int

    init(
        subtype: STExcelChartSubtype = .columnClustered,
        title: String = "",
        colorTheme: STExcelChartColorTheme = .colorful1,
        showLegend: Bool = true,
        showGridlines: Bool = true,
        showAxisLabels: Bool = true,
        showDataLabels: Bool = false,
        seriesInRows: Bool = false,
        x: CGFloat = 60,
        y: CGFloat = 60,
        width: CGFloat = 320,
        height: CGFloat = 240,
        dataStartRow: Int = 0,
        dataStartCol: Int = 0,
        dataEndRow: Int = 0,
        dataEndCol: Int = 0
    ) {
        self.subtype = subtype
        self.title = title
        self.colorTheme = colorTheme
        self.showLegend = showLegend
        self.showGridlines = showGridlines
        self.showAxisLabels = showAxisLabels
        self.showDataLabels = showDataLabels
        self.seriesInRows = seriesInRows
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.dataStartRow = dataStartRow
        self.dataStartCol = dataStartCol
        self.dataEndRow = dataEndRow
        self.dataEndCol = dataEndCol
    }

    /// Size tooltip text (cm units)
    var sizeTooltip: String {
        let wCm = width / 96.0 * 2.54
        let hCm = height / 96.0 * 2.54
        return String(format: "Width: %.2f cm\nHeight: %.2f cm", wCm, hCm)
    }
}
