import SwiftUI

/// Router view — switches on selectedTab and renders the correct tab content
struct STExcelRibbonTabContent: View {
    let selectedTab: STExcelRibbonTab
    @ObservedObject var editorViewModel: STExcelEditorViewModel

    var body: some View {
        Group {
            switch selectedTab {
            case .home:     STExcelRibbonHomeTab(viewModel: editorViewModel)
            case .insert:   STExcelRibbonInsertTab(viewModel: editorViewModel)
            case .format:   STExcelRibbonFormatTab(viewModel: editorViewModel)
            case .formulas: STExcelRibbonFormulasTab(viewModel: editorViewModel)
            case .data:     STExcelRibbonDataTab(viewModel: editorViewModel)
            case .review:   STExcelRibbonReviewTab(viewModel: editorViewModel)
            case .view:     STExcelRibbonViewTab(viewModel: editorViewModel)
            case .chart:    STExcelRibbonChartTab(viewModel: editorViewModel)
            case .shape:    STExcelRibbonShapeTab(viewModel: editorViewModel)
            case .table:    STExcelRibbonTableTab(viewModel: editorViewModel)
            }
        }
        .frame(height: 58)
    }
}
