import STKit
import SwiftUI

/// Markup tab — text annotation tools (FreeText, highlights, underline, strikeout)
struct STPDFRibbonMarkupTab: View {

    @ObservedObject var annotationManager: STAnnotationManager

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 2) {

                // Pan / Hand mode
                STPDFRibbonToolButton(
                    iconName: "hand.raised",
                    label: STStrings.hand,
                    isActive: annotationManager.activeTool == nil && !annotationManager.isMarqueeSelectEnabled
                ) {
                    annotationManager.setTool(nil)
                    annotationManager.isMarqueeSelectEnabled = false
                }

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

                // Text annotations
                toolButton(.freeText)
                toolButton(.textRemove)

                STPDFRibbonSeparator()

                // Text markup (requires text selection)
                toolButton(.textHighlight)
                toolButton(.textUnderline)
                toolButton(.textStrikeOut)

                STPDFRibbonSeparator()

                // Marquee select
                STPDFRibbonToolButton(
                    iconName: "square.dashed",
                    label: STStrings.select,
                    isActive: annotationManager.isMarqueeSelectEnabled
                ) {
                    annotationManager.toggleMarqueeSelect()
                }

                // Style inspector (only when a tool is active)
                if annotationManager.activeTool != nil {
                    STPDFRibbonToolButton(
                        iconName: "slider.horizontal.3",
                        label: STStrings.style,
                        isActive: annotationManager.isPropertyInspectorVisible
                    ) {
                        annotationManager.isPropertyInspectorVisible.toggle()
                    }
                    #if os(macOS)
                    .popover(isPresented: $annotationManager.isPropertyInspectorVisible) {
                        macOSPropertyPopover
                    }
                    #endif
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

    // MARK: - macOS Property Popover

    #if os(macOS)
    private var macOSPropertyPopover: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(propertyTitle)
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)

            ScrollView {
                STPropertyInspector(annotationManager: annotationManager)
                    .padding(.top, 4)
                    .onChange(of: annotationManager.activeStyle) { _ in
                        if annotationManager.selectedAnnotation != nil {
                            annotationManager.applyStyleToSelectedAnnotation()
                        }
                    }
            }
        }
        .frame(width: 280, height: 320)
    }
    #endif

    // MARK: - Property Inspector Sheet

    private var propertySheet: some View {
        STNavigationView {
            ScrollView {
                STPropertyInspector(annotationManager: annotationManager)
                    .padding(.top, 8)
                    .onChange(of: annotationManager.activeStyle) { _ in
                        if annotationManager.selectedAnnotation != nil {
                            annotationManager.applyStyleToSelectedAnnotation()
                        }
                    }
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
        if let tool = annotationManager.activeTool {
            return tool.displayName
        }
        if let type = annotationManager.selectedAnnotation?.type {
            switch type {
            case "FreeText": return STStrings.toolText
            case "Highlight": return STStrings.toolHighlight
            case "Underline": return STStrings.toolUnderline
            case "StrikeOut": return STStrings.toolStrikethrough
            default: return type
            }
        }
        return STStrings.style
    }
}
