import SwiftUI
import STKit

/// Floating annotation toolbar — vertical pill that snaps to left or right edge.
/// Drag the handle to move it between sides. Scrollable when tools exceed screen height.
struct STFloatingToolbar: View {

    @ObservedObject var annotationManager: STAnnotationManager
    let onDone: () -> Void

    /// true = right side (default), false = left side
    @State private var isOnRight = true
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false

    private let toolbarWidth: CGFloat = 64
    private let edgeMargin: CGFloat = 12

    // Tool sections
    private let drawingTools: [STAnnotationType] = [.ink, .highlighter]
    private let shapeTools: [STAnnotationType] = [.rectangle, .circle, .line, .arrow]
    private let textTools: [STAnnotationType] = [.freeText, .textRemove]
    private let extraTools: [STAnnotationType] = [.signature, .stamp, .photo, .note]

    var body: some View {
        GeometryReader { geo in
            let rightX = geo.size.width - toolbarWidth - edgeMargin
            let leftX = edgeMargin
            let baseX = isOnRight ? rightX : leftX

            pill(maxHeight: geo.size.height - 40)
                .offset(x: baseX + dragOffset)
                .frame(maxHeight: .infinity, alignment: .center)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            isDragging = true
                            dragOffset = value.translation.width
                        }
                        .onEnded { value in
                            isDragging = false
                            let finalX = baseX + value.translation.width + toolbarWidth / 2
                            let mid = geo.size.width / 2

                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                isOnRight = finalX > mid
                                dragOffset = 0
                            }

                            STHaptics.impact(.light)
                        }
                )
        }
        .sheet(isPresented: $annotationManager.isPropertyInspectorVisible) {
            propertySheet
        }
    }

    // MARK: - Pill

    private func pill(maxHeight: CGFloat) -> some View {
        VStack(spacing: 0) {
            // Drag handle
            dragHandle
                .padding(.top, 8)
                .padding(.bottom, 6)

            // Scrollable tool area (capped height — shows ~6 items, scroll for rest)
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 2) {
                    // Hand / pan mode
                    iconButton("hand.raised", label: STStrings.hand,
                               active: annotationManager.activeTool == nil && !annotationManager.isMarqueeSelectEnabled) {
                        annotationManager.setTool(nil)
                        annotationManager.isMarqueeSelectEnabled = false
                    }

                    divider

                    // Undo / Redo
                    iconButton("arrow.uturn.backward", label: STStrings.undo,
                               active: false,
                               disabled: !annotationManager.undoManager.canUndo) {
                        annotationManager.undoManager.undo()
                        annotationManager.nuclearPDFViewRedraw()
                    }
                    iconButton("arrow.uturn.forward", label: STStrings.redo,
                               active: false,
                               disabled: !annotationManager.undoManager.canRedo) {
                        annotationManager.undoManager.redo()
                        annotationManager.nuclearPDFViewRedraw()
                    }

                    divider

                    // Zoom
                    iconButton("plus.magnifyingglass", label: STStrings.zoomIn,
                               active: false) {
                        annotationManager.zoomIn()
                    }
                    iconButton("minus.magnifyingglass", label: STStrings.zoomOut,
                               active: false) {
                        annotationManager.zoomOut()
                    }

                    divider

                    // Drawing
                    ForEach(drawingTools) { tool in
                        toolIcon(tool)
                    }

                    divider

                    // Shapes
                    ForEach(shapeTools) { tool in
                        toolIcon(tool)
                    }

                    divider

                    // Text
                    ForEach(textTools) { tool in
                        toolIcon(tool)
                    }

                    divider

                    // Extras
                    ForEach(extraTools) { tool in
                        toolIcon(tool)
                    }

                    divider

                    // Eraser
                    toolIcon(.eraser)

                    divider

                    // Marquee select
                    iconButton("square.dashed", label: STStrings.select,
                               active: annotationManager.isMarqueeSelectEnabled) {
                        annotationManager.toggleMarqueeSelect()
                    }

                    divider

                    // Property inspector
                    if annotationManager.activeTool != nil {
                        iconButton("slider.horizontal.3", label: STStrings.style,
                                   active: annotationManager.isPropertyInspectorVisible) {
                            annotationManager.isPropertyInspectorVisible.toggle()
                        }
                    }
                }
            }
            .frame(maxHeight: min(maxHeight - 80, 310))

            // Close
            divider
            iconButton("xmark", label: STStrings.close, active: false) {
                onDone()
            }
            .padding(.bottom, 4)
        }
        .frame(width: toolbarWidth)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
        .shadow(color: .black.opacity(0.04), radius: 1, x: 0, y: 1)
    }

    // MARK: - Drag Handle

    private var dragHandle: some View {
        VStack(spacing: 3) {
            RoundedRectangle(cornerRadius: 1)
                .fill(Color.secondary.opacity(0.5))
                .frame(width: 28, height: 3)
            RoundedRectangle(cornerRadius: 1)
                .fill(Color.secondary.opacity(0.35))
                .frame(width: 28, height: 3)
        }
        .frame(width: toolbarWidth, height: 14)
        .contentShape(Rectangle())
    }

    // MARK: - Buttons

    @ViewBuilder
    private func toolIcon(_ tool: STAnnotationType) -> some View {
        iconButton(tool.iconName, label: tool.displayName, active: annotationManager.activeTool == tool) {
            annotationManager.toggleTool(tool)
        }
    }

    @ViewBuilder
    private func iconButton(
        _ systemName: String,
        label: String,
        active: Bool,
        disabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: systemName)
                    .font(.system(size: 15, weight: .medium))
                Text(label)
                    .font(.system(size: 7, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundColor(active ? .white : .primary)
            .opacity(disabled ? 0.3 : 1)
            .frame(width: 52, height: 44)
            .background(active ? Color.accentColor : .clear)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .disabled(disabled)
    }

    private var divider: some View {
        Rectangle()
            .fill(.quaternary)
            .frame(width: 32, height: 0.5)
            .padding(.vertical, 2)
    }

    // MARK: - Property Inspector Sheet

    private var inspectorTitle: String {
        if let tool = annotationManager.activeTool {
            return tool.displayName
        }
        if let type = annotationManager.selectedAnnotation?.type {
            switch type {
            case "Ink": return STStrings.toolPen
            case "Square": return STStrings.toolRectangle
            case "Circle": return STStrings.toolCircle
            case "Line": return STStrings.toolLine
            case "FreeText": return STStrings.toolText
            case "Highlight": return STStrings.toolHighlight
            case "Underline": return STStrings.toolUnderline
            case "StrikeOut": return STStrings.toolStrikethrough
            case "Stamp": return STStrings.toolStamp
            case "Text": return STStrings.toolNote
            default: return type
            }
        }
        return ""
    }

    private var propertySheet: some View {
        NavigationView {
            ScrollView {
                STPropertyInspector(annotationManager: annotationManager)
                    .padding(.top, 8)
                    .onChange(of: annotationManager.activeStyle) { _ in
                        if annotationManager.selectedAnnotation != nil {
                            annotationManager.applyStyleToSelectedAnnotation()
                        }
                    }
            }
            .navigationTitle(inspectorTitle)
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
}
