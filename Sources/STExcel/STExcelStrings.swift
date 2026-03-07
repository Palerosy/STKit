import Foundation
import STKit

/// Localized strings for STExcel module
public enum STExcelStrings {
    // Existing
    public static var sheet: String { loc("stexcel.sheet") }
    public static var cell: String { loc("stexcel.cell") }
    public static var row: String { loc("stexcel.row") }
    public static var column: String { loc("stexcel.column") }
    public static var value: String { loc("stexcel.value") }

    // Ribbon tabs
    public static var ribbonFormat: String { loc("stexcel.ribbon.format") }
    public static var ribbonFormulas: String { loc("stexcel.ribbon.formulas") }
    public static var ribbonData: String { loc("stexcel.ribbon.data") }

    // Home tab
    public static var cut: String { loc("stexcel.cut") }
    public static var copy: String { loc("stexcel.copy") }
    public static var fillColor: String { loc("stexcel.fillColor") }
    public static var wrapText: String { loc("stexcel.wrapText") }
    public static var merge: String { loc("stexcel.merge") }
    public static var borders: String { loc("stexcel.borders") }

    // Border picker
    public static var noBorder: String { loc("stexcel.noBorder") }
    public static var allBorders: String { loc("stexcel.allBorders") }
    public static var outsideBorder: String { loc("stexcel.outsideBorder") }
    public static var bottomBorder: String { loc("stexcel.bottomBorder") }
    public static var thickBorder: String { loc("stexcel.thickBorder") }

    // Format tab
    public static var numberFormat: String { loc("stexcel.numberFormat") }
    public static var currency: String { loc("stexcel.currency") }
    public static var percent: String { loc("stexcel.percent") }
    public static var decimalIncrease: String { loc("stexcel.decimalIncrease") }
    public static var decimalDecrease: String { loc("stexcel.decimalDecrease") }
    public static var clear: String { loc("stexcel.clear") }
    public static var conditionalFormat: String { loc("stexcel.conditionalFormat") }
    public static var cellStyle: String { loc("stexcel.cellStyle") }

    // Insert tab
    public static var chart: String { loc("stexcel.chart") }
    public static var picture: String { loc("stexcel.picture") }

    // Formulas tab
    public static var autoSum: String { loc("stexcel.autoSum") }
    public static var recalculate: String { loc("stexcel.recalculate") }
    public static var financial: String { loc("stexcel.financial") }
    public static var logical: String { loc("stexcel.logical") }
    public static var textFunctions: String { loc("stexcel.textFunctions") }
    public static var dateTime: String { loc("stexcel.dateTime") }
    public static var reference: String { loc("stexcel.reference") }
    public static var math: String { loc("stexcel.math") }
    public static var insertFunction: String { loc("stexcel.insertFunction") }
    public static var defineName: String { loc("stexcel.defineName") }
    public static var nameManager: String { loc("stexcel.nameManager") }

    // Data tab
    public static var sort: String { loc("stexcel.sort") }
    public static var sortAZ: String { loc("stexcel.sortAZ") }
    public static var sortZA: String { loc("stexcel.sortZA") }
    public static var sortByColor: String { loc("stexcel.sortByColor") }
    public static var filter: String { loc("stexcel.filter") }
    public static var reapplyFilter: String { loc("stexcel.reapplyFilter") }
    public static var dataValidation: String { loc("stexcel.dataValidation") }
    public static var circleInvalid: String { loc("stexcel.circleInvalid") }
    public static var group: String { loc("stexcel.group") }
    public static var ungroup: String { loc("stexcel.ungroup") }
    public static var subtotal: String { loc("stexcel.subtotal") }
    public static var removeAll: String { loc("stexcel.removeAll") }
    public static var showDetail: String { loc("stexcel.showDetail") }
    public static var hideDetail: String { loc("stexcel.hideDetail") }
    public static var textToColumns: String { loc("stexcel.textToColumns") }
    public static var apply: String { loc("stexcel.apply") }
    public static var sortBy: String { loc("stexcel.sortBy") }
    public static var thenBy: String { loc("stexcel.thenBy") }
    public static var myDataHasHeaders: String { loc("stexcel.myDataHasHeaders") }
    public static var caseSensitive: String { loc("stexcel.caseSensitive") }
    public static var none: String { loc("stexcel.none") }

    // Review tab
    public static var addComment: String { loc("stexcel.addComment") }
    public static var editComment: String { loc("stexcel.editComment") }
    public static var deleteComment: String { loc("stexcel.deleteComment") }
    public static var protectSheet: String { loc("stexcel.protectSheet") }
    public static var unprotectSheet: String { loc("stexcel.unprotectSheet") }
    public static var sheetIsProtected: String { loc("stexcel.sheetIsProtected") }
    public static var sheetNotProtected: String { loc("stexcel.sheetNotProtected") }

    // View tab
    public static var gridlines: String { loc("stexcel.gridlines") }
    public static var headings: String { loc("stexcel.headings") }
    public static var formulaBar: String { loc("stexcel.formulaBar") }
    public static var freezePanes: String { loc("stexcel.freezePanes") }
    public static var goToCell: String { loc("stexcel.goToCell") }
    public static var go: String { loc("stexcel.go") }
    public static var zoom: String { loc("stexcel.zoom") }

    // Home tab — Insert/Delete menus
    public static var insertOptions: String { loc("stexcel.insertOptions") }
    public static var deleteOptions: String { loc("stexcel.deleteOptions") }
    public static var shiftCellsRight: String { loc("stexcel.shiftCellsRight") }
    public static var shiftCellsDown: String { loc("stexcel.shiftCellsDown") }
    public static var shiftCellsLeft: String { loc("stexcel.shiftCellsLeft") }
    public static var shiftCellsUp: String { loc("stexcel.shiftCellsUp") }
    public static var entireRow: String { loc("stexcel.entireRow") }
    public static var entireColumn: String { loc("stexcel.entireColumn") }
    public static var rows: String { loc("stexcel.rows") }
    public static var columns: String { loc("stexcel.columns") }
    public static var worksheet: String { loc("stexcel.worksheet") }
    public static var insert: String { loc("stexcel.insert") }
    public static var delete: String { loc("stexcel.delete") }

    // Format tab buttons
    public static var cellFont: String { loc("stexcel.cellFont") }
    public static var cellBorder: String { loc("stexcel.cellBorder") }
    public static var lockCell: String { loc("stexcel.lockCell") }
    public static var cellSize: String { loc("stexcel.cellSize") }
    public static var rowHeight: String { loc("stexcel.rowHeight") }
    public static var columnWidth: String { loc("stexcel.columnWidth") }
    public static var autoFitRow: String { loc("stexcel.autoFitRow") }
    public static var autoFitColumn: String { loc("stexcel.autoFitColumn") }

    // Format Cells dialog
    public static var formatCells: String { loc("stexcel.formatCells") }
    public static var number: String { loc("stexcel.number") }
    public static var cellTab: String { loc("stexcel.cellTab") }
    public static var borderTab: String { loc("stexcel.borderTab") }
    public static var protection: String { loc("stexcel.protection") }
    public static var font: String { loc("stexcel.font") }
    public static var size: String { loc("stexcel.size") }
    public static var textColor: String { loc("stexcel.textColor") }
    public static var cellColor: String { loc("stexcel.cellColor") }
    public static var indent: String { loc("stexcel.indent") }
    public static var lineType: String { loc("stexcel.lineType") }
    public static var clearBorder: String { loc("stexcel.clearBorder") }
    public static var standardColors: String { loc("stexcel.standardColors") }
    public static var locked: String { loc("stexcel.locked") }
    public static var hidden: String { loc("stexcel.hidden") }
    public static var singleUnderline: String { loc("stexcel.singleUnderline") }
    public static var doubleUnderline: String { loc("stexcel.doubleUnderline") }

    // AutoSum
    public static var sum: String { loc("stexcel.sum") }
    public static var average: String { loc("stexcel.average") }
    public static var count: String { loc("stexcel.count") }
    public static var max: String { loc("stexcel.max") }
    public static var min: String { loc("stexcel.min") }
    public static var median: String { loc("stexcel.median") }

    // More menu
    public static var saveAs: String { loc("stexcel.saveAs") }
    public static var fileInfo: String { loc("stexcel.fileInfo") }
    public static var failedToOpen: String { loc("stexcel.failedToOpen") }
    public static var fileName: String { loc("stexcel.fileName") }
    public static var fileLocation: String { loc("stexcel.fileLocation") }
    public static var fileType: String { loc("stexcel.fileType") }
    public static var fileSize: String { loc("stexcel.fileSize") }
    public static var createdDate: String { loc("stexcel.createdDate") }
    public static var modifiedDate: String { loc("stexcel.modifiedDate") }
    public static var onEnter: String { loc("stexcel.onEnter") }
    public static var moveDown: String { loc("stexcel.moveDown") }
    public static var moveRight: String { loc("stexcel.moveRight") }
    public static var stay: String { loc("stexcel.stay") }
    public static var autoCalculate: String { loc("stexcel.autoCalculate") }
    public static var unknown: String { loc("stexcel.unknown") }
    public static var dontSave: String { loc("stexcel.dontSave") }
    public static func saveChangesTitle(_ name: String) -> String {
        String(format: loc("stexcel.saveChangesTitle"), name)
    }
    public static var licenseRequired: String { loc("stexcel.licenseRequired") }
    public static var licenseRequiredMessage: String { loc("stexcel.licenseRequiredMessage") }

    // Sheet management
    public static var addSheet: String { loc("stexcel.addSheet") }
    public static var renameSheet: String { loc("stexcel.renameSheet") }
    public static var duplicateSheet: String { loc("stexcel.duplicateSheet") }
    public static var deleteSheet: String { loc("stexcel.deleteSheet") }
    public static var moveSheetLeft: String { loc("stexcel.moveSheetLeft") }
    public static var moveSheetRight: String { loc("stexcel.moveSheetRight") }
    public static var sheetName: String { loc("stexcel.sheetName") }

    // Chart categories
    public static var chartAll: String { loc("stexcel.chartAll") }
    public static var chartColumn: String { loc("stexcel.chartColumn") }
    public static var chartBar: String { loc("stexcel.chartBar") }
    public static var chartLine: String { loc("stexcel.chartLine") }
    public static var chartLineWithMarkers: String { loc("stexcel.chartLineWithMarkers") }
    public static var chartArea: String { loc("stexcel.chartArea") }
    public static var chartPie: String { loc("stexcel.chartPie") }
    public static var chartScatter: String { loc("stexcel.chartScatter") }

    // Chart subtypes
    public static var chartClustered: String { loc("stexcel.chartClustered") }
    public static var chartStacked: String { loc("stexcel.chartStacked") }
    public static var chartPercentStacked: String { loc("stexcel.chartPercentStacked") }
    public static var chartSmooth: String { loc("stexcel.chartSmooth") }
    public static var chartSimple: String { loc("stexcel.chartSimple") }
    public static var chartMarkers: String { loc("stexcel.chartMarkers") }
    public static var chartDots: String { loc("stexcel.chartDots") }
    public static var chartLines: String { loc("stexcel.chartLines") }
    public static var chart3DPie: String { loc("stexcel.chart3DPie") }
    public static var chartDoughnut: String { loc("stexcel.chartDoughnut") }
    public static var chartExploded: String { loc("stexcel.chartExploded") }

    // Shape types
    public static var shapeRectangle: String { loc("stexcel.shapeRectangle") }
    public static var shapeRoundedRect: String { loc("stexcel.shapeRoundedRect") }
    public static var shapeCircle: String { loc("stexcel.shapeCircle") }
    public static var shapeOval: String { loc("stexcel.shapeOval") }
    public static var shapeTriangle: String { loc("stexcel.shapeTriangle") }
    public static var shapeRightTriangle: String { loc("stexcel.shapeRightTriangle") }
    public static var shapeDiamond: String { loc("stexcel.shapeDiamond") }
    public static var shapeArrowRight: String { loc("stexcel.shapeArrowRight") }
    public static var shapeArrowLeft: String { loc("stexcel.shapeArrowLeft") }
    public static var shapeArrowUp: String { loc("stexcel.shapeArrowUp") }
    public static var shapeArrowDown: String { loc("stexcel.shapeArrowDown") }
    public static var shapeStar: String { loc("stexcel.shapeStar") }
    public static var shapeHexagon: String { loc("stexcel.shapeHexagon") }
    public static var shapePentagon: String { loc("stexcel.shapePentagon") }
    public static var shapeLine: String { loc("stexcel.shapeLine") }
    public static var shapeDashedLine: String { loc("stexcel.shapeDashedLine") }

    // Shape picker sections
    public static var basicShapes: String { loc("stexcel.basicShapes") }
    public static var arrowsTriangles: String { loc("stexcel.arrowsTriangles") }
    public static var starsMore: String { loc("stexcel.starsMore") }
    public static var lineShapes: String { loc("stexcel.lineShapes") }

    // Table insert
    public static var insertTable: String { loc("stexcel.insertTable") }
    public static var dataRange: String { loc("stexcel.dataRange") }
    public static var tableStyle: String { loc("stexcel.tableStyle") }
    public static var myTableHasHeaders: String { loc("stexcel.myTableHasHeaders") }

    // Table styles
    public static var styleBlue: String { loc("stexcel.styleBlue") }
    public static var styleGreen: String { loc("stexcel.styleGreen") }
    public static var styleOrange: String { loc("stexcel.styleOrange") }
    public static var stylePurple: String { loc("stexcel.stylePurple") }
    public static var styleRed: String { loc("stexcel.styleRed") }
    public static var styleGray: String { loc("stexcel.styleGray") }
    public static var styleDark: String { loc("stexcel.styleDark") }

    // Table tab
    public static var headerRow: String { loc("stexcel.headerRow") }
    public static var bandedRows: String { loc("stexcel.bandedRows") }
    public static var bandedCols: String { loc("stexcel.bandedCols") }

    // Chart format
    public static var labels: String { loc("stexcel.labels") }
    public static var chartTitle: String { loc("stexcel.chartTitle") }
    public static var title: String { loc("stexcel.title") }
    public static var enterTitle: String { loc("stexcel.enterTitle") }
    public static var horizontalLabels: String { loc("stexcel.horizontalLabels") }
    public static var range: String { loc("stexcel.range") }
    public static var seriesIn: String { loc("stexcel.seriesIn") }
    public static var chartType: String { loc("stexcel.chartType") }
    public static var chartFormat: String { loc("stexcel.chartFormat") }
    public static var chartElements: String { loc("stexcel.chartElements") }
    public static var chartLayouts: String { loc("stexcel.chartLayouts") }
    public static var chartColors: String { loc("stexcel.chartColors") }
    public static var chartStylesTitle: String { loc("stexcel.chartStylesTitle") }
    public static var switchRowsCols: String { loc("stexcel.switchRowsCols") }
    public static var legend: String { loc("stexcel.legend") }
    public static var axisLabels: String { loc("stexcel.axisLabels") }
    public static var dataLabels: String { loc("stexcel.dataLabels") }
    public static var axes: String { loc("stexcel.axes") }
    public static var on: String { loc("stexcel.on") }
    public static var off: String { loc("stexcel.off") }
    public static var noNumericData: String { loc("stexcel.noNumericData") }
    public static var editDataRangeHint: String { loc("stexcel.editDataRangeHint") }
    public static var points: String { loc("stexcel.points") }
    public static var noData: String { loc("stexcel.noData") }
    public static var series: String { loc("stexcel.series") }
    public static var dataPoints: String { loc("stexcel.dataPoints") }
    public static var grid: String { loc("stexcel.grid") }
    public static var layouts: String { loc("stexcel.layouts") }

    // Format cells
    public static var noColor: String { loc("stexcel.noColor") }
    public static var lockingInfo: String { loc("stexcel.lockingInfo") }
    public static var lineThin: String { loc("stexcel.lineThin") }
    public static var lineMedium: String { loc("stexcel.lineMedium") }
    public static var lineThick: String { loc("stexcel.lineThick") }
    public static var lineDashed: String { loc("stexcel.lineDashed") }
    public static var lineDotted: String { loc("stexcel.lineDotted") }
    public static var lineDouble: String { loc("stexcel.lineDouble") }

    // Number format
    public static var use1000Separator: String { loc("stexcel.use1000Separator") }
    public static var accounting: String { loc("stexcel.accounting") }
    public static var date: String { loc("stexcel.date") }
    public static var time: String { loc("stexcel.time") }
    public static var percentage: String { loc("stexcel.percentage") }
    public static var fraction: String { loc("stexcel.fraction") }
    public static var scientific: String { loc("stexcel.scientific") }
    public static var special: String { loc("stexcel.special") }
    public static var custom: String { loc("stexcel.custom") }
    public static var negativeNumbers: String { loc("stexcel.negativeNumbers") }

    // Shape tab
    public static var fill: String { loc("stexcel.fill") }
    public static var fillColorTitle: String { loc("stexcel.fillColorTitle") }
    public static var outline: String { loc("stexcel.outline") }
    public static var outlineColor: String { loc("stexcel.outlineColor") }
    public static var changeShape: String { loc("stexcel.changeShape") }

    // View tab extras
    public static var zoomIn: String { loc("stexcel.zoomIn") }
    public static var zoomOut: String { loc("stexcel.zoomOut") }

    // Conditional formatting
    public static var newRule: String { loc("stexcel.newRule") }
    public static var highlightCellsRules: String { loc("stexcel.highlightCellsRules") }
    public static var topBottomAvgRules: String { loc("stexcel.topBottomAvgRules") }
    public static var customFormula: String { loc("stexcel.customFormula") }
    public static var dataBars: String { loc("stexcel.dataBars") }
    public static var colorScales: String { loc("stexcel.colorScales") }
    public static var clearRules: String { loc("stexcel.clearRules") }
    public static var fromSelection: String { loc("stexcel.fromSelection") }
    public static var activeRules: String { loc("stexcel.activeRules") }
    public static var conditionalFormatting: String { loc("stexcel.conditionalFormatting") }
    public static var presets: String { loc("stexcel.presets") }
    public static var condition: String { loc("stexcel.condition") }
    public static var enterValue1: String { loc("stexcel.enterValue1") }
    public static var enterValue2: String { loc("stexcel.enterValue2") }
    public static var rank: String { loc("stexcel.rank") }
    public static var barColor: String { loc("stexcel.barColor") }
    public static var colorScaleSection: String { loc("stexcel.colorScaleSection") }
    public static var formulaSection: String { loc("stexcel.formulaSection") }
    public static var chartStylesNav: String { loc("stexcel.chartStylesNav") }

    // Additional keys
    public static var decimalPlaces: String { loc("stexcel.decimalPlaces") }
    public static var fromEntireSheet: String { loc("stexcel.fromEntireSheet") }
    public static var formatCellsFormula: String { loc("stexcel.formatCellsFormula") }
    public static var goodBadNeutral: String { loc("stexcel.goodBadNeutral") }
    public static var dataModel: String { loc("stexcel.dataModel") }
    public static var titlesHeadings: String { loc("stexcel.titlesHeadings") }
    public static var allow: String { loc("stexcel.allow") }
    public static var useFunction: String { loc("stexcel.useFunction") }
    public static var insertSubtotal: String { loc("stexcel.insertSubtotal") }
    public static var delimiter: String { loc("stexcel.delimiter") }
    public static var convertAction: String { loc("stexcel.convert") }
    public static var enterDelimiter: String { loc("stexcel.enterDelimiter") }
    public static var anyValue: String { loc("stexcel.anyValue") }
    public static var wholeNumber: String { loc("stexcel.wholeNumber") }
    public static var decimalType: String { loc("stexcel.decimalType") }
    public static var listType: String { loc("stexcel.listType") }
    public static var textLength: String { loc("stexcel.textLength") }
    public static var commaDelimiter: String { loc("stexcel.commaDelimiter") }
    public static var tabDelimiter: String { loc("stexcel.tabDelimiter") }
    public static var semicolonDelimiter: String { loc("stexcel.semicolonDelimiter") }
    public static var spaceDelimiter: String { loc("stexcel.spaceDelimiter") }
    public static var sourceList: String { loc("stexcel.sourceList") }
    public static var searchFunctions: String { loc("stexcel.searchFunctions") }
    public static var noDefinedNames: String { loc("stexcel.noDefinedNames") }
    public static var text: String { loc("stexcel.textFunctions") }

    // Number format
    public static var general: String { loc("stexcel.general") }

    // Conditional format conditions
    public static var cfGreaterThan: String { loc("stexcel.cfGreaterThan") }
    public static var cfLessThan: String { loc("stexcel.cfLessThan") }
    public static var cfBetween: String { loc("stexcel.cfBetween") }
    public static var cfEqualTo: String { loc("stexcel.cfEqualTo") }
    public static var cfNotEqualTo: String { loc("stexcel.cfNotEqualTo") }
    public static var cfTextContains: String { loc("stexcel.cfTextContains") }
    public static var cfTextNotContains: String { loc("stexcel.cfTextNotContains") }
    public static var cfDuplicates: String { loc("stexcel.cfDuplicates") }
    public static var cfUniqueValues: String { loc("stexcel.cfUniqueValues") }

    // Conditional format ranks
    public static var cfTop: String { loc("stexcel.cfTop") }
    public static var cfBottom: String { loc("stexcel.cfBottom") }
    public static var cfAboveAverage: String { loc("stexcel.cfAboveAverage") }
    public static var cfBelowAverage: String { loc("stexcel.cfBelowAverage") }

    // Conditional format view labels
    public static var cfItems: String { loc("stexcel.cfItems") }
    public static var value1Label: String { loc("stexcel.value1Label") }
    public static var value2Label: String { loc("stexcel.value2Label") }

    // Chart layout
    public static var layoutLabel: String { loc("stexcel.layoutLabel") }

    // Chart data
    public static var chartDataRange: String { loc("stexcel.chartDataRange") }
    public static var dataLabel: String { loc("stexcel.dataLabel") }

    // Cell style presets
    public static var presetNormal: String { loc("stexcel.presetNormal") }
    public static var presetGood: String { loc("stexcel.presetGood") }
    public static var presetBad: String { loc("stexcel.presetBad") }
    public static var presetNeutral: String { loc("stexcel.presetNeutral") }
    public static var presetInput: String { loc("stexcel.presetInput") }
    public static var presetOutput: String { loc("stexcel.presetOutput") }
    public static var presetCalculation: String { loc("stexcel.presetCalculation") }
    public static var presetCheckCell: String { loc("stexcel.presetCheckCell") }
    public static var presetNote: String { loc("stexcel.presetNote") }
    public static var presetWarning: String { loc("stexcel.presetWarning") }
    public static var presetLinkedCell: String { loc("stexcel.presetLinkedCell") }
    public static var presetExplanatory: String { loc("stexcel.presetExplanatory") }
    public static var presetTitle: String { loc("stexcel.presetTitle") }
    public static var presetHeading1: String { loc("stexcel.presetHeading1") }
    public static var presetHeading2: String { loc("stexcel.presetHeading2") }
    public static var presetHeading3: String { loc("stexcel.presetHeading3") }
    public static var presetHeading4: String { loc("stexcel.presetHeading4") }
    public static var presetTotal: String { loc("stexcel.presetTotal") }
    public static var presetComma: String { loc("stexcel.presetComma") }
    public static var presetCurrency: String { loc("stexcel.presetCurrency") }
    public static var presetPercent: String { loc("stexcel.presetPercent") }

    // Function descriptions
    public static var funcPMT: String { loc("stexcel.func.PMT") }
    public static var funcFV: String { loc("stexcel.func.FV") }
    public static var funcPV: String { loc("stexcel.func.PV") }
    public static var funcRATE: String { loc("stexcel.func.RATE") }
    public static var funcNPV: String { loc("stexcel.func.NPV") }
    public static var funcIRR: String { loc("stexcel.func.IRR") }
    public static var funcIF: String { loc("stexcel.func.IF") }
    public static var funcAND: String { loc("stexcel.func.AND") }
    public static var funcOR: String { loc("stexcel.func.OR") }
    public static var funcNOT: String { loc("stexcel.func.NOT") }
    public static var funcIFERROR: String { loc("stexcel.func.IFERROR") }
    public static var funcTRUE: String { loc("stexcel.func.TRUE") }
    public static var funcFALSE: String { loc("stexcel.func.FALSE") }
    public static var funcCONCATENATE: String { loc("stexcel.func.CONCATENATE") }
    public static var funcLEN: String { loc("stexcel.func.LEN") }
    public static var funcLEFT: String { loc("stexcel.func.LEFT") }
    public static var funcRIGHT: String { loc("stexcel.func.RIGHT") }
    public static var funcMID: String { loc("stexcel.func.MID") }
    public static var funcUPPER: String { loc("stexcel.func.UPPER") }
    public static var funcLOWER: String { loc("stexcel.func.LOWER") }
    public static var funcTRIM: String { loc("stexcel.func.TRIM") }
    public static var funcFIND: String { loc("stexcel.func.FIND") }
    public static var funcREPLACE: String { loc("stexcel.func.REPLACE") }
    public static var funcSUBSTITUTE: String { loc("stexcel.func.SUBSTITUTE") }
    public static var funcNOW: String { loc("stexcel.func.NOW") }
    public static var funcTODAY: String { loc("stexcel.func.TODAY") }
    public static var funcDATE: String { loc("stexcel.func.DATE") }
    public static var funcYEAR: String { loc("stexcel.func.YEAR") }
    public static var funcMONTH: String { loc("stexcel.func.MONTH") }
    public static var funcDAY: String { loc("stexcel.func.DAY") }
    public static var funcHOUR: String { loc("stexcel.func.HOUR") }
    public static var funcMINUTE: String { loc("stexcel.func.MINUTE") }
    public static var funcSECOND: String { loc("stexcel.func.SECOND") }
    public static var funcVLOOKUP: String { loc("stexcel.func.VLOOKUP") }
    public static var funcHLOOKUP: String { loc("stexcel.func.HLOOKUP") }
    public static var funcINDEX: String { loc("stexcel.func.INDEX") }
    public static var funcMATCH: String { loc("stexcel.func.MATCH") }
    public static var funcCHOOSE: String { loc("stexcel.func.CHOOSE") }
    public static var funcINDIRECT: String { loc("stexcel.func.INDIRECT") }
    public static var funcSUM: String { loc("stexcel.func.SUM") }
    public static var funcAVERAGE: String { loc("stexcel.func.AVERAGE") }
    public static var funcCOUNT: String { loc("stexcel.func.COUNT") }
    public static var funcCOUNTA: String { loc("stexcel.func.COUNTA") }
    public static var funcMIN: String { loc("stexcel.func.MIN") }
    public static var funcMAX: String { loc("stexcel.func.MAX") }
    public static var funcABS: String { loc("stexcel.func.ABS") }
    public static var funcROUND: String { loc("stexcel.func.ROUND") }
    public static var funcINT: String { loc("stexcel.func.INT") }
    public static var funcMOD: String { loc("stexcel.func.MOD") }
    public static var funcPOWER: String { loc("stexcel.func.POWER") }
    public static var funcSQRT: String { loc("stexcel.func.SQRT") }
    public static var funcSUMIF: String { loc("stexcel.func.SUMIF") }
    public static var funcCOUNTIF: String { loc("stexcel.func.COUNTIF") }
    public static var funcPRODUCT: String { loc("stexcel.func.PRODUCT") }

    private static func loc(_ key: String) -> String {
        let bundle = STKitConfiguration.shared.languageBundle(for: STExcelBundleHelper.resourceBundle) ?? STExcelBundleHelper.resourceBundle
        return NSLocalizedString(key, bundle: bundle, comment: "")
    }
}

internal enum STExcelBundleHelper {
    static let resourceBundle: Bundle = {
        let bundleName = "STKit_STExcel"

        if let url = Bundle.main.url(forResource: bundleName, withExtension: "bundle"),
           let bundle = Bundle(url: url) {
            return bundle
        }

        if let frameworksURL = Bundle.main.privateFrameworksURL {
            let url = frameworksURL.appendingPathComponent("STExcel.framework/\(bundleName).bundle")
            if let bundle = Bundle(url: url) {
                return bundle
            }
        }

        if let resourceURL = Bundle.main.resourceURL {
            let url = resourceURL.appendingPathComponent("\(bundleName).bundle")
            if let bundle = Bundle(url: url) {
                return bundle
            }
        }

        return Bundle.main
    }()
}
