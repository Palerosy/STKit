import SwiftUI
import STKit

/// View tab — Gridlines, Headings, Formula Bar, Freeze Panes, Go To Cell, Select All, Zoom
struct STExcelRibbonViewTab: View {
    @ObservedObject var viewModel: STExcelEditorViewModel
    @State private var showGoToCell = false
    @State private var showZoomPicker = false

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 2) {
                // Gridlines
                STExcelRibbonToolButton(
                    iconName: "grid",
                    label: STExcelStrings.gridlines,
                    isActive: viewModel.showGridlines
                ) {
                    viewModel.showGridlines.toggle()
                }

                // Headings
                STExcelRibbonToolButton(
                    iconName: "textformat.123",
                    label: STExcelStrings.headings,
                    isActive: viewModel.showHeadings
                ) {
                    viewModel.showHeadings.toggle()
                }

                // Formula Bar
                STExcelRibbonToolButton(
                    iconName: "function",
                    label: STExcelStrings.formulaBar,
                    isActive: viewModel.showFormulaBar
                ) {
                    viewModel.showFormulaBar.toggle()
                }

                STExcelRibbonSeparator()

                // Freeze Panes
                STExcelRibbonToolButton(
                    iconName: "rectangle.split.2x2",
                    label: STExcelStrings.freezePanes,
                    isActive: viewModel.frozenRows > 0 || viewModel.frozenCols > 0
                ) {
                    viewModel.toggleFreezePanes()
                }

                STExcelRibbonSeparator()

                // Go To Cell
                STExcelRibbonToolButton(iconName: "arrow.right.square", label: STExcelStrings.goToCell) {
                    showGoToCell = true
                }
                .sheet(isPresented: $showGoToCell) {
                    STExcelGoToCellView { ref in
                        viewModel.goToCell(ref)
                        showGoToCell = false
                    } onCancel: {
                        showGoToCell = false
                    }
                    .stPresentationDetents([.height(200)])
                }

                // Select All
                STExcelRibbonToolButton(iconName: "selection.pin.in.out", label: STStrings.ribbonSelectAll) {
                    viewModel.selectAll()
                }

                STExcelRibbonSeparator()

                // Zoom — shows current %, tap for picker
                STExcelRibbonToolButton(
                    iconName: "magnifyingglass",
                    label: "\(Int(viewModel.zoomScale * 100))%"
                ) {
                    showZoomPicker = true
                }
                .sheet(isPresented: $showZoomPicker) {
                    zoomPickerSheet
                        .stPresentationDetents([.height(320)])
                }

                // Zoom In / Out quick buttons
                STExcelRibbonToolButton(iconName: "plus.magnifyingglass", label: STExcelStrings.zoomIn) {
                    viewModel.zoomScale = min(viewModel.zoomScale + 0.25, 4.0)
                }
                STExcelRibbonToolButton(iconName: "minus.magnifyingglass", label: STExcelStrings.zoomOut) {
                    viewModel.zoomScale = max(viewModel.zoomScale - 0.25, 0.25)
                }
            }
            .padding(.horizontal, 8)
        }
    }

    private var zoomPickerSheet: some View {
        NavigationView {
            VStack(spacing: 16) {
                // Zoom slider
                VStack(spacing: 8) {
                    Text("\(Int(viewModel.zoomScale * 100))%")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.stExcelAccent)

                    Slider(value: $viewModel.zoomScale, in: 0.25...4.0, step: 0.25)
                        .tint(.stExcelAccent)
                        .padding(.horizontal, 24)

                    HStack {
                        Text("25%").font(.caption).foregroundColor(.secondary)
                        Spacer()
                        Text("400%").font(.caption).foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 24)
                }

                // Quick zoom buttons
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                ], spacing: 8) {
                    ForEach([50, 75, 100, 125, 150, 200, 300, 400], id: \.self) { pct in
                        Button {
                            viewModel.zoomScale = CGFloat(pct) / 100.0
                            showZoomPicker = false
                        } label: {
                            Text("\(pct)%")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Int(viewModel.zoomScale * 100) == pct ? .white : .primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Int(viewModel.zoomScale * 100) == pct ? Color.stExcelAccent : Color.stSecondarySystemBackground)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)

                Spacer()
            }
            .padding(.top, 16)
            .navigationTitle(STExcelStrings.zoom)
            .stNavigationBarTitleDisplayMode()
            .toolbar {
                ToolbarItem(placement: .stTrailing) {
                    Button(STStrings.done) { showZoomPicker = false }
                }
            }
        }
    }
}
