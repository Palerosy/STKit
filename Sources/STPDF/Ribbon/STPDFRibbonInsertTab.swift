import STKit
import SwiftUI

/// Insert tab — signature, stamp, photo, note annotations
struct STPDFRibbonInsertTab: View {

    @ObservedObject var annotationManager: STAnnotationManager
    @ObservedObject var viewModel: STPDFEditorViewModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 2) {

                // Undo
                STPDFRibbonToolButton(
                    iconName: "arrow.uturn.backward",
                    label: STStrings.undo,
                    isDisabled: !annotationManager.undoManager.canUndo
                ) {
                    annotationManager.undoManager.undo()
                    annotationManager.nuclearPDFViewRedraw()
                }

                // Redo
                STPDFRibbonToolButton(
                    iconName: "arrow.uturn.forward",
                    label: STStrings.redo,
                    isDisabled: !annotationManager.undoManager.canRedo
                ) {
                    annotationManager.undoManager.redo()
                    annotationManager.nuclearPDFViewRedraw()
                }

                STPDFRibbonSeparator()

                // Insert items
                toolButton(.signature)
                toolButton(.stamp)
                toolButton(.photo)
                toolButton(.note)

                STPDFRibbonSeparator()

                // Notes list
                STPDFRibbonToolButton(
                    iconName: "list.bullet.rectangle",
                    label: STStrings.toolNotes
                ) {
                    viewModel.activeSheet = .notes
                }
            }
            .padding(.horizontal, 8)
        }
    }

    // MARK: - Tool Button

    @ViewBuilder
    private func toolButton(_ tool: STAnnotationType) -> some View {
        STPDFRibbonToolButton(
            iconName: tool.iconName,
            label: tool.displayName,
            isActive: annotationManager.activeTool == tool
        ) {
            annotationManager.toggleTool(tool)
        }
    }
}
