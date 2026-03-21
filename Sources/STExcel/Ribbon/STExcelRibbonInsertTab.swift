import SwiftUI
import PhotosUI
import STKit

/// Insert tab — Comment, Link, Chart, Picture; Stub: Shape, Table
struct STExcelRibbonInsertTab: View {
    @ObservedObject var viewModel: STExcelEditorViewModel
    @State private var showCommentSheet = false
    @State private var showLinkAlert = false
    @State private var showChartTypePicker = false
    @State private var selectedChartSubtype: STExcelChartSubtype?
    @State private var linkURL = ""
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var showShapePicker = false
    @State private var showTableSheet = false

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 2) {
                // Comment
                STExcelRibbonToolButton(iconName: "text.bubble", label: STStrings.ribbonComment) {
                    showCommentSheet = true
                }
                .sheet(isPresented: $showCommentSheet) {
                    STExcelCommentView(
                        comment: viewModel.currentComment ?? "",
                        onSave: { text in
                            viewModel.addComment(text)
                            showCommentSheet = false
                        },
                        onDelete: {
                            viewModel.deleteComment()
                            showCommentSheet = false
                        },
                        onCancel: { showCommentSheet = false }
                    )
                    .stPresentationDetents([.height(250)])
                }

                // Link
                STExcelRibbonToolButton(iconName: "link", label: STStrings.ribbonLink) {
                    showLinkAlert = true
                }
                .alert(STStrings.ribbonLink, isPresented: $showLinkAlert) {
                    TextField("URL", text: $linkURL)
                    Button(STStrings.cancel, role: .cancel) {}
                    Button("OK") {
                        if !linkURL.isEmpty {
                            viewModel.setCellValue(linkURL)
                            linkURL = ""
                        }
                    }
                }

                STExcelRibbonSeparator()

                // Chart — opens type picker first, then chart view
                STExcelRibbonToolButton(iconName: "chart.bar", label: STExcelStrings.chart) {
                    showChartTypePicker = true
                }
                .sheet(isPresented: $showChartTypePicker) {
                    STExcelChartTypePicker(
                        onSelect: { subtype in
                            showChartTypePicker = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                selectedChartSubtype = subtype
                            }
                        },
                        onDismiss: { showChartTypePicker = false }
                    )
                    .stPresentationDetents([.large])
                }
                .sheet(item: $selectedChartSubtype) { subtype in
                    STExcelChartView(
                        viewModel: viewModel,
                        initialSubtype: subtype
                    ) {
                        selectedChartSubtype = nil
                    }
                    .stPresentationDetents([.large])
                }

                // Picture — PhotosPicker
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    VStack(spacing: 2) {
                        Image(systemName: "photo")
                            .font(.system(size: 17, weight: .medium))
                            .frame(width: 24, height: 24)
                        Text(STExcelStrings.picture)
                            .font(.system(size: 9, weight: .medium))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.7)
                    }
                    .foregroundColor(.primary)
                    .frame(width: 52, height: 50)
                }
                .buttonStyle(.plain)
                .onChange(of: selectedPhotoItem) { item in
                    guard let item = item else { return }
                    Task {
                        if let data = try? await item.loadTransferable(type: Data.self) {
                            insertImage(data: data)
                        }
                        selectedPhotoItem = nil
                    }
                }

                // Shape
                STExcelRibbonToolButton(iconName: "square.on.circle", label: STStrings.ribbonShape) {
                    showShapePicker = true
                }
                .sheet(isPresented: $showShapePicker) {
                    STExcelShapePicker { shapeType in
                        insertShape(shapeType)
                        showShapePicker = false
                    } onDismiss: {
                        showShapePicker = false
                    }
                    .stPresentationDetents([.medium])
                }

                // Table
                STExcelRibbonToolButton(iconName: "tablecells", label: STStrings.ribbonTable) {
                    showTableSheet = true
                }
                .sheet(isPresented: $showTableSheet) {
                    STExcelInsertTableView(viewModel: viewModel) { table in
                        viewModel.addTable(table)
                        showTableSheet = false
                    } onCancel: {
                        showTableSheet = false
                    }
                    .stPresentationDetents([.medium])
                }

                STExcelRibbonSeparator()

                // Append Row at end
                STExcelRibbonToolButton(iconName: "plus.rectangle", label: STExcelStrings.appendRow) {
                    viewModel.appendRow()
                }

                // Append Column at end
                STExcelRibbonToolButton(iconName: "plus.rectangle.portrait", label: STExcelStrings.appendColumn) {
                    viewModel.appendColumn()
                }

                // Delete last row
                STExcelRibbonToolButton(iconName: "minus.rectangle", label: STExcelStrings.deleteRow) {
                    viewModel.deleteLastRow()
                }

                // Delete last column
                STExcelRibbonToolButton(iconName: "minus.rectangle.portrait", label: STExcelStrings.deleteColumn) {
                    viewModel.deleteLastColumn()
                }
            }
            .padding(.horizontal, 8)
        }
    }

    @MainActor
    private func insertImage(data: Data) {
        #if canImport(UIKit)
        guard let uiImage = UIImage(data: data) else { return }
        let aspect = uiImage.size.width / uiImage.size.height
        #else
        let aspect: CGFloat = 1.0
        #endif

        // Fit within 240pt width, maintain aspect ratio
        let imgW: CGFloat = 240
        let imgH = imgW / max(aspect, 0.1)

        // Position near selected cell or default
        let cellRow = viewModel.selectedRow ?? 0
        let cellCol = viewModel.selectedCol ?? 0
        let colWidth: CGFloat = 80
        let rowHeight: CGFloat = 28
        let posX = CGFloat(cellCol) * colWidth + colWidth
        let posY = CGFloat(cellRow) * rowHeight + rowHeight

        let image = STExcelEmbeddedImage(
            imageData: data,
            x: posX, y: posY,
            width: imgW, height: imgH,
            aspectRatio: aspect
        )
        viewModel.addImage(image)
    }

    private func insertShape(_ shapeType: STExcelShapeType) {
        let cellRow = viewModel.selectedRow ?? 0
        let cellCol = viewModel.selectedCol ?? 0
        let colWidth: CGFloat = 80
        let rowHeight: CGFloat = 28
        let posX = CGFloat(cellCol) * colWidth + colWidth
        let posY = CGFloat(cellRow) * rowHeight + rowHeight

        let isLine = shapeType == .line || shapeType == .dashedLine
        let shape = STExcelEmbeddedShape(
            shapeType: shapeType,
            x: posX, y: posY,
            width: isLine ? 160 : 120,
            height: isLine ? 4 : 80
        )
        viewModel.addShape(shape)
    }
}
