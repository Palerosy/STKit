import SwiftUI
import STKit

/// Shape contextual ribbon tab — appears when a shape is selected
struct STExcelRibbonShapeTab: View {
    @ObservedObject var viewModel: STExcelEditorViewModel

    @State private var showFillColorPicker = false
    @State private var showStrokeColorPicker = false
    @State private var showShapeTypePicker = false

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 2) {
                // Fill Color
                STExcelRibbonToolButton(iconName: "paintbrush.fill", label: STExcelStrings.fill) {
                    showFillColorPicker = true
                }
                .popover(isPresented: $showFillColorPicker) {
                    STExcelColorPicker(
                        title: STExcelStrings.fillColorTitle,
                        colors: STExcelColorPresets.shapeColors,
                        showNone: true
                    ) { hex in
                        if var s = viewModel.selectedShape {
                            s.fillColor = hex == "none" ? .clear : (Color(hex: hex) ?? .blue).opacity(0.3)
                            viewModel.updateShape(s)
                        }
                        showFillColorPicker = false
                    }
                }

                // Stroke Color
                STExcelRibbonToolButton(iconName: "pencil.tip", label: STExcelStrings.outline) {
                    showStrokeColorPicker = true
                }
                .popover(isPresented: $showStrokeColorPicker) {
                    STExcelColorPicker(
                        title: STExcelStrings.outlineColor,
                        colors: STExcelColorPresets.shapeColors,
                        showNone: true
                    ) { hex in
                        if var s = viewModel.selectedShape {
                            s.strokeColor = hex == "none" ? .clear : (Color(hex: hex) ?? .blue)
                            viewModel.updateShape(s)
                        }
                        showStrokeColorPicker = false
                    }
                }

                STExcelRibbonSeparator()

                // Stroke width
                STExcelRibbonToolButton(iconName: "lineweight", label: STExcelStrings.lineThin) {
                    if var s = viewModel.selectedShape {
                        s.strokeWidth = 1
                        viewModel.updateShape(s)
                    }
                }
                STExcelRibbonToolButton(iconName: "lineweight", label: STExcelStrings.lineMedium) {
                    if var s = viewModel.selectedShape {
                        s.strokeWidth = 3
                        viewModel.updateShape(s)
                    }
                }
                STExcelRibbonToolButton(iconName: "lineweight", label: STExcelStrings.lineThick) {
                    if var s = viewModel.selectedShape {
                        s.strokeWidth = 6
                        viewModel.updateShape(s)
                    }
                }

                STExcelRibbonSeparator()

                // Change shape type
                STExcelRibbonToolButton(iconName: "square.on.circle", label: STExcelStrings.changeShape) {
                    showShapeTypePicker = true
                }
                .sheet(isPresented: $showShapeTypePicker) {
                    STExcelShapePicker { shapeType in
                        if var s = viewModel.selectedShape {
                            s.shapeType = shapeType
                            viewModel.updateShape(s)
                        }
                        showShapeTypePicker = false
                    } onDismiss: {
                        showShapeTypePicker = false
                    }
                    .stPresentationDetents([.medium])
                }

                STExcelRibbonSeparator()

                // Delete
                STExcelRibbonToolButton(iconName: "trash", label: STExcelStrings.delete) {
                    viewModel.deleteSelectedShape()
                }
            }
            .padding(.horizontal, 8)
        }
    }
}
