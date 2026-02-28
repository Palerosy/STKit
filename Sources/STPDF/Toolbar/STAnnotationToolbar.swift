import STKit
import SwiftUI

/// The main annotation toolbar shown when annotation mode is active
struct STAnnotationToolbar: View {

    @ObservedObject var annotationManager: STAnnotationManager

    var body: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(spacing: 0) {
                // Undo / Redo
                HStack(spacing: 12) {
                    Button {
                        annotationManager.undoManager.undo()
                        annotationManager.nuclearPDFViewRedraw()
                    } label: {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .disabled(!annotationManager.undoManager.canUndo)

                    Button {
                        annotationManager.undoManager.redo()
                        annotationManager.nuclearPDFViewRedraw()
                    } label: {
                        Image(systemName: "arrow.uturn.forward")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .disabled(!annotationManager.undoManager.canRedo)
                }
                .foregroundColor(.primary)
                .padding(.leading, 16)

                Spacer()

                // Tool groups
                HStack(spacing: 4) {
                    ForEach(STAnnotationGroup.allCases) { group in
                        STToolGroupButton(
                            group: group,
                            annotationManager: annotationManager
                        )
                    }
                }

                Spacer()

                // Property inspector + Done
                HStack(spacing: 12) {
                    if annotationManager.activeTool != nil {
                        Button {
                            annotationManager.isPropertyInspectorVisible.toggle()
                        } label: {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(annotationManager.isPropertyInspectorVisible ? .accentColor : .primary)
                        }
                    }

                    Button {
                        annotationManager.deactivate()
                    } label: {
                        Text(STStrings.done)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.accentColor)
                    }
                }
                .padding(.trailing, 16)
            }
            .frame(height: 48)
            .background(.bar)
        }
    }
}
