import SwiftUI
import STKit

/// Draw tab content — Pen, Highlighter, Eraser, Shapes (separate), Add Text, Select, Undo/Redo
struct STRibbonDrawTab: View {
    @ObservedObject var annotationManager: STAnnotationManager

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 2) {
                // Hand / Pan
                STRibbonToolButton(
                    iconName: "hand.raised",
                    label: STStrings.hand,
                    isActive: annotationManager.activeTool == nil && !annotationManager.isMarqueeSelectEnabled
                ) {
                    annotationManager.setTool(nil)
                    annotationManager.isMarqueeSelectEnabled = false
                }

                STRibbonSeparator()

                // Pen
                STRibbonToolButton(
                    iconName: STAnnotationType.ink.iconName,
                    label: STAnnotationType.ink.displayName,
                    isActive: annotationManager.activeTool == .ink
                ) {
                    annotationManager.toggleTool(.ink)
                }

                // Highlighter
                STRibbonToolButton(
                    iconName: STAnnotationType.highlighter.iconName,
                    label: STAnnotationType.highlighter.displayName,
                    isActive: annotationManager.activeTool == .highlighter
                ) {
                    annotationManager.toggleTool(.highlighter)
                }

                // Eraser
                STRibbonToolButton(
                    iconName: STAnnotationType.eraser.iconName,
                    label: STAnnotationType.eraser.displayName,
                    isActive: annotationManager.activeTool == .eraser
                ) {
                    annotationManager.toggleTool(.eraser)
                }

                STRibbonSeparator()

                // Rectangle
                STRibbonToolButton(
                    iconName: STAnnotationType.rectangle.iconName,
                    label: STAnnotationType.rectangle.displayName,
                    isActive: annotationManager.activeTool == .rectangle
                ) {
                    annotationManager.toggleTool(.rectangle)
                }

                // Circle
                STRibbonToolButton(
                    iconName: STAnnotationType.circle.iconName,
                    label: STAnnotationType.circle.displayName,
                    isActive: annotationManager.activeTool == .circle
                ) {
                    annotationManager.toggleTool(.circle)
                }

                // Line
                STRibbonToolButton(
                    iconName: STAnnotationType.line.iconName,
                    label: STAnnotationType.line.displayName,
                    isActive: annotationManager.activeTool == .line
                ) {
                    annotationManager.toggleTool(.line)
                }

                // Arrow
                STRibbonToolButton(
                    iconName: STAnnotationType.arrow.iconName,
                    label: STAnnotationType.arrow.displayName,
                    isActive: annotationManager.activeTool == .arrow
                ) {
                    annotationManager.toggleTool(.arrow)
                }

                STRibbonSeparator()

                // Add Text
                STRibbonToolButton(
                    iconName: STAnnotationType.freeText.iconName,
                    label: STStrings.addText,
                    isActive: annotationManager.activeTool == .freeText
                ) {
                    annotationManager.toggleTool(.freeText)
                }

                STRibbonSeparator()

                // Style inspector
                if annotationManager.activeTool != nil {
                    STRibbonToolButton(
                        iconName: "slider.horizontal.3",
                        label: STStrings.style,
                        isActive: annotationManager.isPropertyInspectorVisible
                    ) {
                        annotationManager.isPropertyInspectorVisible.toggle()
                    }

                    STRibbonSeparator()
                }

                // Select (marquee)
                STRibbonToolButton(
                    iconName: "square.dashed",
                    label: STStrings.select,
                    isActive: annotationManager.isMarqueeSelectEnabled
                ) {
                    annotationManager.toggleMarqueeSelect()
                }

                STRibbonSeparator()

                // Undo
                STRibbonToolButton(
                    iconName: "arrow.uturn.backward",
                    label: STStrings.undo,
                    isDisabled: !annotationManager.undoManager.canUndo
                ) {
                    annotationManager.undoManager.undo()
                    annotationManager.nuclearPDFViewRedraw()
                }

                // Redo
                STRibbonToolButton(
                    iconName: "arrow.uturn.forward",
                    label: STStrings.redo,
                    isDisabled: !annotationManager.undoManager.canRedo
                ) {
                    annotationManager.undoManager.redo()
                    annotationManager.nuclearPDFViewRedraw()
                }

                STRibbonSeparator()

                // Zoom
                STRibbonToolButton(
                    iconName: "plus.magnifyingglass",
                    label: STStrings.zoomIn
                ) {
                    annotationManager.zoomIn()
                }

                STRibbonToolButton(
                    iconName: "minus.magnifyingglass",
                    label: STStrings.zoomOut
                ) {
                    annotationManager.zoomOut()
                }
            }
            .padding(.horizontal, 8)
        }
    }
}
