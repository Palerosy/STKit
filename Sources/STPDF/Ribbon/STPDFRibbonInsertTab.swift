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
                    annotationManager.resetPageViews()
                }

                // Redo
                STPDFRibbonToolButton(
                    iconName: "arrow.uturn.forward",
                    label: STStrings.redo,
                    isDisabled: !annotationManager.undoManager.canRedo
                ) {
                    annotationManager.undoManager.redo()
                    annotationManager.resetPageViews()
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
        #if os(iOS)
        .sheet(isPresented: $annotationManager.isPropertyInspectorVisible) {
            propertySheet
        }
        #endif
    }

    // MARK: - Property Inspector Sheet

    #if os(iOS)
    private var propertySheet: some View {
        STNavigationView {
            ScrollView {
                STPropertyInspector(annotationManager: annotationManager)
                    .padding(.top, 8)
            }
            .navigationTitle(propertyTitle)
            .stNavigationBarTitleDisplayMode()
            .toolbar {
                ToolbarItem(placement: .stTrailing) {
                    Button(STStrings.done) {
                        annotationManager.isPropertyInspectorVisible = false
                    }
                }
            }
        }
        .stPresentationDetents([.medium])
        .stPresentationDragIndicator(.visible)
    }

    private var propertyTitle: String {
        if let annotation = annotationManager.selectedAnnotation {
            if annotation is STSignatureAnnotation {
                return STStrings.toolSignature
            }
            if let type = annotation.type {
                switch type {
                case "Stamp": return STStrings.toolStamp
                case "Ink": return STStrings.toolPen
                default: return type
                }
            }
        }
        return STStrings.style
    }
    #endif

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
