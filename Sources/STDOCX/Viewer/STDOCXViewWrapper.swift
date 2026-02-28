import SwiftUI
import PDFKit
import STKit

#if os(iOS)
import UIKit

/// UIViewRepresentable wrapper for Apple's PDFView with drawing, shape, eraser, and selection overlays
struct STDOCXViewWrapper: UIViewRepresentable {

    let document: PDFDocument
    @Binding var currentPageIndex: Int
    let configuration: STDOCXConfiguration
    let annotationManager: STAnnotationManager
    let isAnnotationModeActive: Bool
    let activeTool: STAnnotationType?
    let activeStyle: STAnnotationStyle
    let hasSelection: Bool
    let hasMultiSelection: Bool
    let isMarqueeSelectEnabled: Bool

    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        let pdfView = PDFView()
        pdfView.document = document
        pdfView.autoScales = true
        pdfView.displayMode = .singlePage
        pdfView.displayDirection = .horizontal
        pdfView.usePageViewController(true)
        pdfView.pageShadowsEnabled = true
        pdfView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(pdfView)
        NSLayoutConstraint.activate([
            pdfView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            pdfView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            pdfView.topAnchor.constraint(equalTo: container.topAnchor),
            pdfView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        context.coordinator.pdfView = pdfView
        context.coordinator.annotationManager = annotationManager
        annotationManager.pdfView = pdfView

        setupOverlays(in: container, pdfView: pdfView, context: context)
        setupNotifications(pdfView: pdfView, context: context)
        return container
    }

    func updateUIView(_ container: UIView, context: Context) {
        guard let pdfView = context.coordinator.pdfView,
              let drawingView = context.coordinator.drawingView,
              let shapeView = context.coordinator.shapeView,
              let eraserView = context.coordinator.eraserView,
              let selectionView = context.coordinator.selectionView else { return }

        // Update document if replaced
        if pdfView.document !== document {
            pdfView.document = document
            pdfView.autoScales = true
            DispatchQueue.main.async {
                pdfView.autoScales = true
                if let page = document.page(at: self.currentPageIndex) { pdfView.go(to: page) }
            }
            return
        }

        if let targetPage = document.page(at: currentPageIndex), pdfView.currentPage != targetPage {
            DispatchQueue.main.async { pdfView.go(to: targetPage) }
        }

        context.coordinator.annotationManager = annotationManager
        annotationManager.pdfView = pdfView
        updateOverlays(drawingView: drawingView, shapeView: shapeView, eraserView: eraserView, selectionView: selectionView, pdfView: pdfView)
    }

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    private func setupOverlays(in container: UIView, pdfView: PDFView, context: Context) {
        let drawingView = STInkDrawingView()
        drawingView.translatesAutoresizingMaskIntoConstraints = false
        drawingView.isHidden = true
        drawingView.isUserInteractionEnabled = false
        drawingView.pdfView = pdfView
        container.addSubview(drawingView)
        NSLayoutConstraint.activate([
            drawingView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            drawingView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            drawingView.topAnchor.constraint(equalTo: container.topAnchor),
            drawingView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        context.coordinator.drawingView = drawingView
        drawingView.onStrokeCommitted = { [weak coordinator = context.coordinator] annotation, page in
            Task { @MainActor in coordinator?.annotationManager?.undoManager.record(.add(annotation: annotation, page: page)) }
        }

        let shapeView = STShapeDrawingView()
        shapeView.translatesAutoresizingMaskIntoConstraints = false
        shapeView.isHidden = true
        shapeView.isUserInteractionEnabled = false
        shapeView.pdfView = pdfView
        container.addSubview(shapeView)
        NSLayoutConstraint.activate([
            shapeView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            shapeView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            shapeView.topAnchor.constraint(equalTo: container.topAnchor),
            shapeView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        context.coordinator.shapeView = shapeView
        shapeView.onShapeCommitted = { [weak coordinator = context.coordinator] annotation, page in
            Task { @MainActor in coordinator?.annotationManager?.undoManager.record(.add(annotation: annotation, page: page)) }
        }

        let eraserView = STEraserOverlayView()
        eraserView.translatesAutoresizingMaskIntoConstraints = false
        eraserView.isHidden = true
        eraserView.isUserInteractionEnabled = false
        eraserView.pdfView = pdfView
        container.addSubview(eraserView)
        NSLayoutConstraint.activate([
            eraserView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            eraserView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            eraserView.topAnchor.constraint(equalTo: container.topAnchor),
            eraserView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        context.coordinator.eraserView = eraserView
        eraserView.onAnnotationErased = { [weak coordinator = context.coordinator] annotation, page in
            Task { @MainActor in coordinator?.annotationManager?.undoManager.record(.remove(annotation: annotation, page: page)) }
        }

        let selectionView = STAnnotationSelectionView()
        selectionView.translatesAutoresizingMaskIntoConstraints = false
        selectionView.isHidden = true
        selectionView.isUserInteractionEnabled = false
        selectionView.pdfView = pdfView
        container.addSubview(selectionView)
        NSLayoutConstraint.activate([
            selectionView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            selectionView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            selectionView.topAnchor.constraint(equalTo: container.topAnchor),
            selectionView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        context.coordinator.selectionView = selectionView
        selectionView.onAnnotationSelected = { [weak coordinator = context.coordinator] annotation, page in
            Task { @MainActor in coordinator?.annotationManager?.selectAnnotation(annotation, on: page) }
        }
        selectionView.onSelectionCleared = { [weak coordinator = context.coordinator] in
            Task { @MainActor in coordinator?.annotationManager?.clearAnnotationSelection() }
        }
        selectionView.onAnnotationModified = { [weak coordinator = context.coordinator] annotation, page, oldBounds in
            Task { @MainActor in coordinator?.annotationManager?.undoManager.record(.move(annotation: annotation, page: page, oldBounds: oldBounds)) }
        }
        selectionView.onMultipleAnnotationsSelected = { [weak coordinator = context.coordinator] annotations, page in
            Task { @MainActor in coordinator?.annotationManager?.selectMultipleAnnotations(annotations, on: page) }
        }
        selectionView.onMultiAnnotationsModified = { [weak coordinator = context.coordinator] annotations, page, oldBounds in
            Task { @MainActor in
                var batchActions: [STUndoManager.Action] = []
                for (i, annotation) in annotations.enumerated() where i < oldBounds.count {
                    batchActions.append(.move(annotation: annotation, page: page, oldBounds: oldBounds[i]))
                }
                coordinator?.annotationManager?.undoManager.record(.batch(batchActions))
            }
        }

        // Long-press-to-select on overlays
        for overlay in [drawingView, shapeView, eraserView] as [UIView] {
            let longPress = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleAnnotationLongPress(_:)))
            longPress.minimumPressDuration = 0.4
            overlay.addGestureRecognizer(longPress)
        }
    }

    private func updateOverlays(drawingView: STInkDrawingView, shapeView: STShapeDrawingView, eraserView: STEraserOverlayView, selectionView: STAnnotationSelectionView, pdfView: PDFView) {
        let tool = activeTool
        let isDrawing = tool?.isDrawingTool == true
        let isShape = tool?.isShapeTool == true
        let isErasing = tool?.isEraserTool == true
        let isSelectionMode = (tool == nil) && isAnnotationModeActive

        if !isAnnotationModeActive {
            drawingView.clearOverlayLayers(); drawingView.isHidden = true; drawingView.isUserInteractionEnabled = false; drawingView.layer.mask = nil
            shapeView.clearCurrentShape(); shapeView.isHidden = true; shapeView.isUserInteractionEnabled = false; shapeView.layer.mask = nil
            eraserView.isHidden = true; eraserView.isUserInteractionEnabled = false
            selectionView.isHidden = true; selectionView.isUserInteractionEnabled = false
            if selectionView.selectedAnnotation != nil { selectionView.clearSelection() }
            return
        }

        let isMarkup = tool?.requiresTextSelection == true
        drawingView.isHidden = isMarkup; drawingView.isUserInteractionEnabled = isDrawing
        if isMarkup { drawingView.clearOverlayLayers() }
        if !isDrawing { drawingView.clearCurrentStroke() }
        shapeView.isHidden = !isShape; shapeView.isUserInteractionEnabled = isShape
        if isShape, let shapeTool = tool { shapeView.shapeType = shapeTool }
        if !isShape { shapeView.clearCurrentShape() }
        eraserView.isHidden = !isErasing; eraserView.isUserInteractionEnabled = isErasing
        selectionView.isHidden = !isSelectionMode; selectionView.isUserInteractionEnabled = isSelectionMode
        selectionView.isMarqueeEnabled = annotationManager.isMarqueeSelectEnabled

        if !isSelectionMode && selectionView.selectedAnnotation != nil { selectionView.clearSelection() }

        if isSelectionMode {
            if let annotation = annotationManager.selectedAnnotation, let page = annotationManager.selectedAnnotationPage {
                if selectionView.selectedAnnotation !== annotation { selectionView.select(annotation: annotation, on: page) }
                selectionView.refreshVisuals()
            } else if !annotationManager.multiSelectedAnnotations.isEmpty, let page = annotationManager.multiSelectionPage {
                let viewAnnotations = selectionView.multiSelectedAnnotations
                let managerAnnotations = annotationManager.multiSelectedAnnotations
                let needsSync = viewAnnotations.count != managerAnnotations.count || !zip(viewAnnotations, managerAnnotations).allSatisfy({ $0 === $1 })
                if needsSync { selectionView.selectMultiple(annotations: managerAnnotations, on: page) }
                selectionView.refreshVisuals()
            } else if selectionView.selectedAnnotation != nil || !selectionView.multiSelectedAnnotations.isEmpty {
                selectionView.clearSelection()
            }
        }

        // Clip drawing overlays to visible PDF page bounds
        let overlayViews: [UIView] = [drawingView, shapeView]
        for overlay in overlayViews {
            if !overlay.isHidden {
                let combinedPath = PlatformBezierPath()
                for page in pdfView.visiblePages {
                    let pageBounds = page.bounds(for: .mediaBox)
                    let rectInPDFView = pdfView.convert(pageBounds, from: page)
                    let rectInOverlay = overlay.convert(rectInPDFView, from: pdfView)
                    combinedPath.append(PlatformBezierPath(rect: rectInOverlay))
                }
                let mask = CAShapeLayer()
                mask.path = combinedPath.cgPath
                overlay.layer.mask = mask
            } else {
                overlay.layer.mask = nil
            }
        }

        let style = activeStyle
        drawingView.strokeColor = style.color; drawingView.strokeWidth = style.lineWidth; drawingView.strokeOpacity = style.opacity
        shapeView.strokeColor = style.color; shapeView.strokeWidth = style.lineWidth; shapeView.strokeOpacity = style.opacity
    }

    private func setupNotifications(pdfView: PDFView, context: Context) {
        NotificationCenter.default.addObserver(context.coordinator, selector: #selector(Coordinator.pageChanged(_:)), name: .PDFViewPageChanged, object: pdfView)
        NotificationCenter.default.addObserver(context.coordinator, selector: #selector(Coordinator.viewChanged(_:)), name: .PDFViewScaleChanged, object: pdfView)
    }

    class Coordinator: NSObject {
        let parent: STDOCXViewWrapper
        weak var pdfView: PDFView?
        weak var drawingView: STInkDrawingView?
        weak var shapeView: STShapeDrawingView?
        weak var eraserView: STEraserOverlayView?
        weak var selectionView: STAnnotationSelectionView?
        var annotationManager: STAnnotationManager?

        init(parent: STDOCXViewWrapper) {
            self.parent = parent
            self.annotationManager = parent.annotationManager
        }

        @objc func pageChanged(_ notification: Notification) {
            guard let pdfView = notification.object as? PDFView, let currentPage = pdfView.currentPage,
                  let pageIndex = pdfView.document?.index(for: currentPage) else { return }
            DispatchQueue.main.async {
                if self.parent.currentPageIndex != pageIndex { self.parent.currentPageIndex = pageIndex }
                self.drawingView?.clearOverlayLayers()
            }
        }

        @objc func viewChanged(_ notification: Notification) {
            DispatchQueue.main.async {
                self.drawingView?.clearOverlayLayers()
                self.selectionView?.refreshVisuals()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                    self?.selectionView?.refreshVisuals()
                }
            }
        }

        @objc func handleAnnotationLongPress(_ gesture: UILongPressGestureRecognizer) {
            guard gesture.state == .began, let overlay = gesture.view, let pdfView = pdfView else { return }
            let point = gesture.location(in: overlay)
            let pointInPDFView = overlay.convert(point, to: pdfView)
            guard let page = pdfView.page(for: pointInPDFView, nearest: false) else { return }
            let pointInPage = pdfView.convert(pointInPDFView, to: page)
            let hitRadius: CGFloat = 12
            let hitRect = CGRect(x: pointInPage.x - hitRadius, y: pointInPage.y - hitRadius, width: hitRadius * 2, height: hitRadius * 2)
            let protectedSubtypes: Set<String> = ["Link", "Widget"]
            for annotation in page.annotations.reversed() {
                if let subtype = annotation.type, protectedSubtypes.contains(subtype) { continue }
                if annotation.bounds.intersects(hitRect) {
                    Task { @MainActor [weak self] in
                        self?.annotationManager?.setTool(nil)
                        self?.annotationManager?.selectAnnotation(annotation, on: page)
                    }
                    STHaptics.impact(.medium)
                    return
                }
            }
        }
    }
}

#elseif os(macOS)
import AppKit

/// NSViewRepresentable wrapper for Apple's PDFView with drawing, shape, eraser, and selection overlays
struct STDOCXViewWrapper: NSViewRepresentable {

    let document: PDFDocument
    @Binding var currentPageIndex: Int
    let configuration: STDOCXConfiguration
    let annotationManager: STAnnotationManager
    let isAnnotationModeActive: Bool
    let activeTool: STAnnotationType?
    let activeStyle: STAnnotationStyle
    let hasSelection: Bool
    let hasMultiSelection: Bool
    let isMarqueeSelectEnabled: Bool

    func makeNSView(context: Context) -> NSView {
        let container = NSView()
        let pdfView = PDFView()
        pdfView.document = document
        pdfView.autoScales = true
        pdfView.displayMode = .singlePage
        pdfView.displayDirection = .horizontal
        pdfView.pageShadowsEnabled = true
        pdfView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(pdfView)
        NSLayoutConstraint.activate([
            pdfView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            pdfView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            pdfView.topAnchor.constraint(equalTo: container.topAnchor),
            pdfView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        context.coordinator.pdfView = pdfView
        context.coordinator.annotationManager = annotationManager
        annotationManager.pdfView = pdfView

        let drawingView = STInkDrawingView()
        drawingView.translatesAutoresizingMaskIntoConstraints = false
        drawingView.isHidden = true
        drawingView.pdfView = pdfView
        container.addSubview(drawingView)
        NSLayoutConstraint.activate([
            drawingView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            drawingView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            drawingView.topAnchor.constraint(equalTo: container.topAnchor),
            drawingView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        context.coordinator.drawingView = drawingView
        drawingView.onStrokeCommitted = { [weak coordinator = context.coordinator] annotation, page in
            Task { @MainActor in coordinator?.annotationManager?.undoManager.record(.add(annotation: annotation, page: page)) }
        }

        let shapeView = STShapeDrawingView()
        shapeView.translatesAutoresizingMaskIntoConstraints = false
        shapeView.isHidden = true
        shapeView.pdfView = pdfView
        container.addSubview(shapeView)
        NSLayoutConstraint.activate([
            shapeView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            shapeView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            shapeView.topAnchor.constraint(equalTo: container.topAnchor),
            shapeView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        context.coordinator.shapeView = shapeView
        shapeView.onShapeCommitted = { [weak coordinator = context.coordinator] annotation, page in
            Task { @MainActor in coordinator?.annotationManager?.undoManager.record(.add(annotation: annotation, page: page)) }
        }

        let eraserView = STEraserOverlayView()
        eraserView.translatesAutoresizingMaskIntoConstraints = false
        eraserView.isHidden = true
        eraserView.pdfView = pdfView
        container.addSubview(eraserView)
        NSLayoutConstraint.activate([
            eraserView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            eraserView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            eraserView.topAnchor.constraint(equalTo: container.topAnchor),
            eraserView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        context.coordinator.eraserView = eraserView
        eraserView.onAnnotationErased = { [weak coordinator = context.coordinator] annotation, page in
            Task { @MainActor in coordinator?.annotationManager?.undoManager.record(.remove(annotation: annotation, page: page)) }
        }

        let selectionView = STAnnotationSelectionView()
        selectionView.translatesAutoresizingMaskIntoConstraints = false
        selectionView.isHidden = true
        selectionView.pdfView = pdfView
        selectionView.annotationManager = annotationManager
        container.addSubview(selectionView)
        NSLayoutConstraint.activate([
            selectionView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            selectionView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            selectionView.topAnchor.constraint(equalTo: container.topAnchor),
            selectionView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        context.coordinator.selectionView = selectionView
        selectionView.onAnnotationSelected = { [weak coordinator = context.coordinator] annotation, page in
            Task { @MainActor in coordinator?.annotationManager?.selectAnnotation(annotation, on: page) }
        }
        selectionView.onSelectionCleared = { [weak coordinator = context.coordinator] in
            Task { @MainActor in coordinator?.annotationManager?.clearAnnotationSelection() }
        }

        NotificationCenter.default.addObserver(context.coordinator, selector: #selector(Coordinator.pageChanged(_:)), name: .PDFViewPageChanged, object: pdfView)
        NotificationCenter.default.addObserver(context.coordinator, selector: #selector(Coordinator.viewChanged(_:)), name: .PDFViewScaleChanged, object: pdfView)

        return container
    }

    func updateNSView(_ container: NSView, context: Context) {
        guard let pdfView = context.coordinator.pdfView,
              let drawingView = context.coordinator.drawingView,
              let shapeView = context.coordinator.shapeView,
              let eraserView = context.coordinator.eraserView,
              let selectionView = context.coordinator.selectionView else { return }

        if pdfView.document !== document {
            pdfView.document = document
            pdfView.autoScales = true
            return
        }

        if let targetPage = document.page(at: currentPageIndex), pdfView.currentPage != targetPage {
            pdfView.go(to: targetPage)
        }
        context.coordinator.annotationManager = annotationManager
        annotationManager.pdfView = pdfView

        let tool = activeTool
        let isDrawing = tool?.isDrawingTool == true
        let isShape = tool?.isShapeTool == true
        let isErasing = tool?.isEraserTool == true
        let isSelectionMode = (tool == nil) && isAnnotationModeActive

        if !isAnnotationModeActive {
            drawingView.clearOverlayLayers(); drawingView.isHidden = true
            shapeView.clearCurrentShape(); shapeView.isHidden = true
            eraserView.isHidden = true
            selectionView.isHidden = true; selectionView.clearSelection()
            return
        }

        let isMarkup = tool?.requiresTextSelection == true
        drawingView.isHidden = isMarkup
        if isMarkup { drawingView.clearOverlayLayers() }
        if !isDrawing { drawingView.clearCurrentStroke() }
        shapeView.isHidden = !isShape
        if isShape, let shapeTool = tool { shapeView.shapeType = shapeTool }
        if !isShape { shapeView.clearCurrentShape() }
        eraserView.isHidden = !isErasing
        selectionView.isHidden = !isSelectionMode

        if isSelectionMode { selectionView.updateSelection() }

        let style = activeStyle
        drawingView.strokeColor = style.color; drawingView.strokeWidth = style.lineWidth; drawingView.strokeOpacity = style.opacity
        shapeView.strokeColor = style.color; shapeView.strokeWidth = style.lineWidth; shapeView.strokeOpacity = style.opacity
    }

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    class Coordinator: NSObject {
        let parent: STDOCXViewWrapper
        weak var pdfView: PDFView?
        weak var drawingView: STInkDrawingView?
        weak var shapeView: STShapeDrawingView?
        weak var eraserView: STEraserOverlayView?
        weak var selectionView: STAnnotationSelectionView?
        var annotationManager: STAnnotationManager?

        init(parent: STDOCXViewWrapper) { self.parent = parent; self.annotationManager = parent.annotationManager }

        @objc func pageChanged(_ notification: Notification) {
            guard let pdfView = notification.object as? PDFView, let currentPage = pdfView.currentPage,
                  let pageIndex = pdfView.document?.index(for: currentPage) else { return }
            DispatchQueue.main.async {
                if self.parent.currentPageIndex != pageIndex { self.parent.currentPageIndex = pageIndex }
                self.drawingView?.clearOverlayLayers()
            }
        }

        @objc func viewChanged(_ notification: Notification) {
            DispatchQueue.main.async {
                self.drawingView?.clearOverlayLayers()
                self.selectionView?.updateSelection()
            }
        }
    }
}
#endif
