#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif
import STKit
import PDFKit

/// Handle positions around a selected annotation
enum STHandlePosition: CaseIterable {
    case topLeft, topCenter, topRight
    case midLeft, midRight
    case bottomLeft, bottomCenter, bottomRight

    /// Offset multiplier for handle placement relative to annotation bounds
    var offset: CGPoint {
        switch self {
        case .topLeft:      return CGPoint(x: 0, y: 0)
        case .topCenter:    return CGPoint(x: 0.5, y: 0)
        case .topRight:     return CGPoint(x: 1, y: 0)
        case .midLeft:      return CGPoint(x: 0, y: 0.5)
        case .midRight:     return CGPoint(x: 1, y: 0.5)
        case .bottomLeft:   return CGPoint(x: 0, y: 1)
        case .bottomCenter: return CGPoint(x: 0.5, y: 1)
        case .bottomRight:  return CGPoint(x: 1, y: 1)
        }
    }
}

#if os(iOS)
/// Transparent overlay that handles annotation selection, movement, and resizing.
/// Active when annotation mode is on but no specific drawing/text tool is selected.
final class STAnnotationSelectionView: UIView {

    // MARK: - Callbacks

    /// Called when an annotation is selected
    var onAnnotationSelected: ((_ annotation: PDFAnnotation, _ page: PDFPage) -> Void)?

    /// Called when selection is cleared
    var onSelectionCleared: (() -> Void)?

    /// Called when an annotation is moved/resized (for undo)
    var onAnnotationModified: ((_ annotation: PDFAnnotation, _ page: PDFPage, _ oldBounds: CGRect) -> Void)?

    /// Called when delete is tapped
    var onDeleteRequested: ((_ annotation: PDFAnnotation, _ page: PDFPage) -> Void)?

    /// Called when context menu item is tapped
    var onMenuAction: ((_ action: STSelectionAction, _ annotation: PDFAnnotation, _ page: PDFPage) -> Void)?

    /// Called when multiple annotations are selected via marquee
    var onMultipleAnnotationsSelected: ((_ annotations: [PDFAnnotation], _ page: PDFPage) -> Void)?

    /// Called when multiple annotations are moved (for undo)
    var onMultiAnnotationsModified: ((_ annotations: [PDFAnnotation], _ page: PDFPage, _ oldBounds: [CGRect]) -> Void)?

    // MARK: - Public State

    weak var pdfView: PDFView?

    /// Currently selected annotation (single)
    private(set) var selectedAnnotation: PDFAnnotation?
    private(set) var selectedPage: PDFPage?

    /// Currently multi-selected annotations (from marquee)
    private(set) var multiSelectedAnnotations: [PDFAnnotation] = []
    private(set) var multiSelectedPage: PDFPage?

    /// Whether marquee selection mode is enabled (set externally)
    var isMarqueeEnabled = false

    // MARK: - Private State

    private let handleRadius: CGFloat = 7
    private let handleHitRadius: CGFloat = 22
    private let selectionColor = PlatformColor.systemBlue

    private var borderLayer: CAShapeLayer?
    private var handleLayers: [STHandlePosition: CAShapeLayer] = [:]

    private var isDragging = false
    private var isResizing = false
    private var isRotating = false
    private var activeHandle: STHandlePosition?
    private var dragStartPoint: CGPoint = .zero
    private var originalBoundsInView: CGRect = .zero
    private var originalBoundsInPage: CGRect = .zero
    private var rotationStartAngle: CGFloat = 0

    /// Rotation handle visual layers (only for STInkAnnotation)
    private var rotationLineLayer: CAShapeLayer?
    private var rotationHandleLayer: CAShapeLayer?
    private let rotationHandleDistance: CGFloat = 30

    /// Marquee selection state
    private var isPotentialMarquee = false
    private var isMarqueeSelecting = false
    private var marqueeStartPoint: CGPoint = .zero
    private var marqueeLayer: CAShapeLayer?
    private let marqueeThreshold: CGFloat = 5

    /// Multi-move state
    private var isMultiMoving = false
    private var multiOriginalBounds: [CGRect] = []

    /// Multi-selection border layers
    private var multiBorderLayers: [CAShapeLayer] = []

    /// Protected annotation subtypes that should not be selected
    private static let protectedSubtypes: Set<String> = ["Link", "Widget"]

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isMultipleTouchEnabled = false
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
        isMultipleTouchEnabled = false
    }

    // MARK: - Public

    /// Clear all selection visuals and state (single + multi)
    func clearSelection() {
        selectedAnnotation = nil
        selectedPage = nil
        removeBorderAndHandles()
        multiSelectedAnnotations.removeAll()
        multiSelectedPage = nil
        removeMultiSelectionVisuals()
        removeMarqueeLayer()
        onSelectionCleared?()
    }

    /// Select a specific annotation programmatically
    func select(annotation: PDFAnnotation, on page: PDFPage) {
        // Clear multi-selection
        multiSelectedAnnotations.removeAll()
        multiSelectedPage = nil
        removeMultiSelectionVisuals()
        removeMarqueeLayer()

        selectedAnnotation = annotation
        selectedPage = page
        updateSelectionVisuals()
        onAnnotationSelected?(annotation, page)
    }

    /// Select multiple annotations programmatically (from marquee)
    func selectMultiple(annotations: [PDFAnnotation], on page: PDFPage) {
        // Clear single selection
        selectedAnnotation = nil
        selectedPage = nil
        removeBorderAndHandles()

        multiSelectedAnnotations = annotations
        multiSelectedPage = page
        updateMultiSelectionVisuals()
        onMultipleAnnotationsSelected?(annotations, page)
    }

    /// Clear only multi-selection (without affecting single or firing cleared callback)
    func clearMultiSelection() {
        multiSelectedAnnotations.removeAll()
        multiSelectedPage = nil
        removeMultiSelectionVisuals()
        removeMarqueeLayer()
    }

    /// Refresh the selection visuals (e.g. after scroll/zoom)
    func refreshVisuals() {
        if selectedAnnotation != nil {
            updateSelectionVisuals()
        }
        if !multiSelectedAnnotations.isEmpty {
            updateMultiSelectionVisuals()
        }
    }

    // MARK: - Hit Test (pass through empty areas for PDFView scroll/pan)

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard isUserInteractionEnabled, !isHidden, alpha > 0.01 else { return nil }

        // Marquee mode: capture all touches for drag selection
        if isMarqueeEnabled { return self }

        // Single selection active: check handles and annotation body
        if selectedAnnotation != nil {
            // Rotation handle (ink only)
            if selectedAnnotation is STInkAnnotation,
               let rotCenter = rotationHandleCenter(),
               hypot(point.x - rotCenter.x, point.y - rotCenter.y) <= handleHitRadius {
                return self
            }
            // Resize handles
            if handleAt(point) != nil { return self }
            // Inside selected annotation
            if let rect = annotationRectInView(), rect.insetBy(dx: -8, dy: -8).contains(point) {
                return self
            }
        }

        // Multi-selection: check if on any selected annotation
        if !multiSelectedAnnotations.isEmpty, multiSelectedAnnotationAt(point) != nil {
            return self
        }

        // Check if point is over any annotation on the page (for new selection)
        if hitTestAnnotation(at: point) != nil { return self }

        // Nothing under finger → pass through to PDFView for scroll/pan/zoom
        return nil
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let point = touch.location(in: self)

        // Reset potential-gesture states
        isPotentialMarquee = false
        isMarqueeSelecting = false
        isMultiMoving = false

        // --- Single Selection active: check rotate/resize/move ---
        if selectedAnnotation != nil {
            // Check rotation handle hit (ink annotations only)
            if selectedAnnotation is STInkAnnotation,
               let rotCenter = rotationHandleCenter(),
               hypot(point.x - rotCenter.x, point.y - rotCenter.y) <= handleHitRadius {
                isRotating = true
                isDragging = false
                isResizing = false
                dragStartPoint = point
                originalBoundsInView = annotationRectInView() ?? .zero
                originalBoundsInPage = selectedAnnotation?.bounds ?? .zero
                rotationStartAngle = (selectedAnnotation as? STInkAnnotation)?.rotationAngle ?? 0
                return
            }

            // Check if touching a handle (resize)
            if let handle = handleAt(point) {
                activeHandle = handle
                isResizing = true
                isDragging = false
                isRotating = false
                dragStartPoint = point
                originalBoundsInView = annotationRectInView() ?? .zero
                originalBoundsInPage = selectedAnnotation?.bounds ?? .zero
                return
            }

            // Check if touching inside the selected annotation (move)
            if let rect = annotationRectInView(), rect.insetBy(dx: -8, dy: -8).contains(point) {
                isDragging = true
                isResizing = false
                isRotating = false
                dragStartPoint = point
                originalBoundsInView = rect
                originalBoundsInPage = selectedAnnotation?.bounds ?? .zero
                return
            }
        }

        // --- Multi-Selection active: check multi-move ---
        if !multiSelectedAnnotations.isEmpty {
            if multiSelectedAnnotationAt(point) != nil {
                isMultiMoving = true
                dragStartPoint = point
                multiOriginalBounds = multiSelectedAnnotations.map { $0.bounds }
                return
            }
        }

        // --- No handle/annotation hit: try to select new annotation ---
        isDragging = false
        isResizing = false
        isRotating = false

        if let (annotation, page) = hitTestAnnotation(at: point) {
            // Clear multi-selection visuals if switching to single
            if !multiSelectedAnnotations.isEmpty {
                multiSelectedAnnotations.removeAll()
                multiSelectedPage = nil
                removeMultiSelectionVisuals()
            }
            select(annotation: annotation, on: page)
            STHaptics.impact(.light)
            return
        }

        // --- Nothing hit: clear selection ---
        clearSelection()

        // Only start marquee if the mode is enabled
        if isMarqueeEnabled {
            isPotentialMarquee = true
            marqueeStartPoint = point
            dragStartPoint = point
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let point = touch.location(in: self)

        if isRotating {
            performRotation(to: point)
        } else if isResizing, let handle = activeHandle {
            performResize(to: point, handle: handle)
        } else if isDragging {
            performMove(to: point)
        } else if isMultiMoving {
            performMultiMove(to: point)
        } else if isMarqueeSelecting {
            updateMarqueeLayer(from: marqueeStartPoint, to: point)
        } else if isPotentialMarquee {
            let distance = hypot(point.x - marqueeStartPoint.x, point.y - marqueeStartPoint.y)
            if distance > marqueeThreshold {
                isPotentialMarquee = false
                isMarqueeSelecting = true
                updateMarqueeLayer(from: marqueeStartPoint, to: point)
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Handle rotation end
        if isRotating,
           let inkAnnotation = selectedAnnotation as? STInkAnnotation,
           let page = selectedPage {
            let oldBounds = originalBoundsInPage
            inkAnnotation.applyRotation()
            forcePDFViewRedraw()
            updateSelectionVisuals()
            onAnnotationModified?(inkAnnotation, page, oldBounds)
            STHaptics.impact(.light)
            resetGestureState()
            return
        }

        // Handle single move/resize end
        if (isDragging || isResizing),
           let annotation = selectedAnnotation,
           let page = selectedPage,
           annotation.bounds != originalBoundsInPage {

            // Bake in the new position/scale for custom-drawn annotations
            if let inkAnnotation = annotation as? STInkAnnotation {
                inkAnnotation.applyBoundsOffset()
            } else if let lineAnnotation = annotation as? STLineAnnotation {
                lineAnnotation.applyBoundsOffset()
            }

            // Scale font size proportionally for FreeText annotations
            if isResizing, annotation.type == "FreeText",
               originalBoundsInPage.height > 0 {
                let scale = annotation.bounds.height / originalBoundsInPage.height
                if let currentFont = annotation.font {
                    let newSize = max(8, min(currentFont.pointSize * scale, 200))
                    annotation.font = currentFont.withSize(newSize)
                }
            }

            onAnnotationModified?(annotation, page, originalBoundsInPage)
            STHaptics.impact(.light)
        }

        // Handle multi-move end
        if isMultiMoving, let page = multiSelectedPage {
            var anyMoved = false
            for (i, annotation) in multiSelectedAnnotations.enumerated() {
                if i < multiOriginalBounds.count && annotation.bounds != multiOriginalBounds[i] {
                    anyMoved = true
                    if let inkAnnotation = annotation as? STInkAnnotation {
                        inkAnnotation.applyBoundsOffset()
                    } else if let lineAnnotation = annotation as? STLineAnnotation {
                        lineAnnotation.applyBoundsOffset()
                    }
                }
            }
            if anyMoved {
                onMultiAnnotationsModified?(multiSelectedAnnotations, page, multiOriginalBounds)
                STHaptics.impact(.light)
            }
            updateMultiSelectionVisuals()
        }

        // Handle marquee selection end
        if isMarqueeSelecting {
            guard let touch = touches.first else {
                removeMarqueeLayer()
                resetGestureState()
                return
            }
            let point = touch.location(in: self)
            let results = annotationsInMarquee(from: marqueeStartPoint, to: point)
            removeMarqueeLayer()

            if let page = results.first?.1, !results.isEmpty {
                let annots = results.map { $0.0 }
                if annots.count == 1 {
                    // Single annotation in marquee → treat as single selection
                    select(annotation: annots[0], on: page)
                } else {
                    selectMultiple(annotations: annots, on: page)
                }
                STHaptics.impact(.medium)
            }
        }

        // Potential marquee that never moved enough (tap on empty) — already cleared in touchesBegan
        resetGestureState()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Revert rotation on cancel
        if isRotating, let inkAnnotation = selectedAnnotation as? STInkAnnotation {
            inkAnnotation.rotationAngle = rotationStartAngle
            forcePDFViewRedraw()
        }
        // Revert single move/resize on cancel
        if isDragging || isResizing, let annotation = selectedAnnotation {
            annotation.bounds = originalBoundsInPage
        }
        // Revert multi-move on cancel
        if isMultiMoving {
            for (i, annotation) in multiSelectedAnnotations.enumerated() {
                if i < multiOriginalBounds.count {
                    annotation.bounds = multiOriginalBounds[i]
                }
            }
            if multiSelectedAnnotations.contains(where: { $0 is STInkAnnotation || $0 is STLineAnnotation || $0 is STImageAnnotation || $0 is STStampAnnotation }) {
                forcePDFViewRedraw()
            }
        }

        // Complete marquee selection even on cancel (system gesture, etc.)
        if isMarqueeSelecting, let touch = touches.first {
            let point = touch.location(in: self)
            let results = annotationsInMarquee(from: marqueeStartPoint, to: point)
            removeMarqueeLayer()
            if let page = results.first?.1, !results.isEmpty {
                let annots = results.map { $0.0 }
                if annots.count == 1 {
                    select(annotation: annots[0], on: page)
                } else {
                    selectMultiple(annotations: annots, on: page)
                }
                STHaptics.impact(.medium)
            }
        } else {
            removeMarqueeLayer()
        }

        if selectedAnnotation != nil {
            updateSelectionVisuals()
        }
        if !multiSelectedAnnotations.isEmpty {
            updateMultiSelectionVisuals()
        }
        resetGestureState()
    }

    private func resetGestureState() {
        isDragging = false
        isResizing = false
        isRotating = false
        activeHandle = nil
        isPotentialMarquee = false
        isMarqueeSelecting = false
        isMultiMoving = false
    }

    // MARK: - Hit Testing

    /// Hit-test for an annotation at the given point in this view's coordinate space.
    /// Prefers smallest matching annotation (most precise hit) to handle overlapping bounds.
    private func hitTestAnnotation(at point: CGPoint) -> (PDFAnnotation, PDFPage)? {
        guard let pdfView = pdfView else { return nil }

        let pointInPDFView = convert(point, to: pdfView)
        guard let page = pdfView.page(for: pointInPDFView, nearest: false) else { return nil }

        let pointInPage = pdfView.convert(pointInPDFView, to: page)

        let eligible = page.annotations.filter { annotation in
            if let subtype = annotation.type, Self.protectedSubtypes.contains(subtype) { return false }
            return true
        }

        // Pass 1: exact contains — prefer smallest area
        var bestExact: PDFAnnotation?
        var bestExactArea: CGFloat = .greatestFiniteMagnitude
        for annotation in eligible {
            if annotation.bounds.contains(pointInPage) {
                let area = annotation.bounds.width * annotation.bounds.height
                if area < bestExactArea {
                    bestExact = annotation
                    bestExactArea = area
                }
            }
        }
        if let best = bestExact { return (best, page) }

        // Pass 2: intersects with tolerance — prefer smallest area
        let hitRect = CGRect(
            x: pointInPage.x - 10,
            y: pointInPage.y - 10,
            width: 20,
            height: 20
        )
        var bestNear: PDFAnnotation?
        var bestNearArea: CGFloat = .greatestFiniteMagnitude
        for annotation in eligible {
            if annotation.bounds.intersects(hitRect) {
                let area = annotation.bounds.width * annotation.bounds.height
                if area < bestNearArea {
                    bestNear = annotation
                    bestNearArea = area
                }
            }
        }
        if let best = bestNear { return (best, page) }

        return nil
    }

    /// Check if the given point falls inside any multi-selected annotation.
    private func multiSelectedAnnotationAt(_ point: CGPoint) -> PDFAnnotation? {
        guard let pdfView = pdfView, let page = multiSelectedPage else { return nil }

        for annotation in multiSelectedAnnotations {
            let rectInPDFView = pdfView.convert(annotation.bounds, from: page)
            let rectInSelf = convert(rectInPDFView, from: pdfView)
            if rectInSelf.insetBy(dx: -8, dy: -8).contains(point) {
                return annotation
            }
        }
        return nil
    }

    // MARK: - Move

    private func performMove(to point: CGPoint) {
        guard let pdfView = pdfView,
              let annotation = selectedAnnotation,
              let page = selectedPage else { return }

        let dx = point.x - dragStartPoint.x
        let dy = point.y - dragStartPoint.y

        // Convert the delta from screen to PDF page coordinates
        let originalCenterInView = CGPoint(
            x: originalBoundsInView.midX,
            y: originalBoundsInView.midY
        )
        let newCenterInView = CGPoint(
            x: originalCenterInView.x + dx,
            y: originalCenterInView.y + dy
        )

        let originalCenterInPDFView = convert(originalCenterInView, to: pdfView)
        let newCenterInPDFView = convert(newCenterInView, to: pdfView)

        let originalInPage = pdfView.convert(originalCenterInPDFView, to: page)
        let newInPage = pdfView.convert(newCenterInPDFView, to: page)

        let pageDX = newInPage.x - originalInPage.x
        let pageDY = newInPage.y - originalInPage.y

        var newBounds = originalBoundsInPage
        newBounds.origin.x += pageDX
        newBounds.origin.y += pageDY

        // Clamp to page bounds — prevent annotation from going off-page
        let pageBounds = page.bounds(for: .mediaBox)
        newBounds.origin.x = max(pageBounds.minX, min(newBounds.origin.x, pageBounds.maxX - newBounds.width))
        newBounds.origin.y = max(pageBounds.minY, min(newBounds.origin.y, pageBounds.maxY - newBounds.height))

        annotation.bounds = newBounds

        // Force PDFView tile redraw for custom-drawn annotations
        if annotation is STInkAnnotation || annotation is STLineAnnotation || annotation is STImageAnnotation || annotation is STStampAnnotation {
            forcePDFViewRedraw()
        }

        updateSelectionVisuals()
    }

    // MARK: - Multi-Move

    private func performMultiMove(to point: CGPoint) {
        guard let pdfView = pdfView, let page = multiSelectedPage else { return }

        // Convert delta from screen to PDF page coordinates
        let startInPDFView = convert(dragStartPoint, to: pdfView)
        let currentInPDFView = convert(point, to: pdfView)
        let startInPage = pdfView.convert(startInPDFView, to: page)
        let currentInPage = pdfView.convert(currentInPDFView, to: page)

        let pageDX = currentInPage.x - startInPage.x
        let pageDY = currentInPage.y - startInPage.y

        let pageBounds = page.bounds(for: .mediaBox)
        var needsRedraw = false

        for (i, annotation) in multiSelectedAnnotations.enumerated() {
            guard i < multiOriginalBounds.count else { continue }
            var newBounds = multiOriginalBounds[i]
            newBounds.origin.x += pageDX
            newBounds.origin.y += pageDY

            // Clamp to page bounds
            newBounds.origin.x = max(pageBounds.minX, min(newBounds.origin.x, pageBounds.maxX - newBounds.width))
            newBounds.origin.y = max(pageBounds.minY, min(newBounds.origin.y, pageBounds.maxY - newBounds.height))

            annotation.bounds = newBounds

            if annotation is STInkAnnotation || annotation is STLineAnnotation || annotation is STImageAnnotation || annotation is STStampAnnotation {
                needsRedraw = true
            }
        }

        if needsRedraw {
            forcePDFViewRedraw()
        }

        updateMultiSelectionVisuals()
    }

    // MARK: - Resize

    private func performResize(to point: CGPoint, handle: STHandlePosition) {
        guard let pdfView = pdfView,
              let annotation = selectedAnnotation,
              let page = selectedPage else { return }

        // Convert delta to page coordinates
        let refInPDFView = convert(dragStartPoint, to: pdfView)
        let newInPDFView = convert(point, to: pdfView)
        let refInPage = pdfView.convert(refInPDFView, to: page)
        let newInPage = pdfView.convert(newInPDFView, to: page)
        let pageDX = newInPage.x - refInPage.x
        let pageDY = newInPage.y - refInPage.y

        var newBounds = originalBoundsInPage
        let minSize: CGFloat = 20

        switch handle {
        case .topLeft:
            newBounds.origin.x += pageDX
            newBounds.size.width -= pageDX
            newBounds.size.height += pageDY  // PDF Y is flipped vs screen Y
            // In PDF coords, increasing Y means up
        case .topCenter:
            newBounds.size.height += pageDY
        case .topRight:
            newBounds.size.width += pageDX
            newBounds.size.height += pageDY
        case .midLeft:
            newBounds.origin.x += pageDX
            newBounds.size.width -= pageDX
        case .midRight:
            newBounds.size.width += pageDX
        case .bottomLeft:
            newBounds.origin.x += pageDX
            newBounds.size.width -= pageDX
            newBounds.origin.y += pageDY
            newBounds.size.height -= pageDY
        case .bottomCenter:
            newBounds.origin.y += pageDY
            newBounds.size.height -= pageDY
        case .bottomRight:
            newBounds.size.width += pageDX
            newBounds.origin.y += pageDY
            newBounds.size.height -= pageDY
        }

        // Enforce minimum size (prevent flipping)
        if newBounds.width < minSize {
            newBounds.size.width = minSize
            if handle == .topLeft || handle == .midLeft || handle == .bottomLeft {
                newBounds.origin.x = originalBoundsInPage.maxX - minSize
            }
        }
        if newBounds.height < minSize {
            newBounds.size.height = minSize
            if handle == .bottomLeft || handle == .bottomCenter || handle == .bottomRight {
                newBounds.origin.y = originalBoundsInPage.maxY - minSize
            }
        }

        // Clamp to page bounds
        let pageBounds = page.bounds(for: .mediaBox)
        newBounds.origin.x = max(pageBounds.minX, min(newBounds.origin.x, pageBounds.maxX - newBounds.width))
        newBounds.origin.y = max(pageBounds.minY, min(newBounds.origin.y, pageBounds.maxY - newBounds.height))
        newBounds.size.width = min(newBounds.width, pageBounds.width - (newBounds.origin.x - pageBounds.minX))
        newBounds.size.height = min(newBounds.height, pageBounds.height - (newBounds.origin.y - pageBounds.minY))

        annotation.bounds = newBounds

        // Force PDFView tile redraw for custom-drawn annotations
        if annotation is STInkAnnotation || annotation is STLineAnnotation || annotation is STImageAnnotation || annotation is STStampAnnotation {
            forcePDFViewRedraw()
        }

        updateSelectionVisuals()
    }

    // MARK: - Marquee Selection

    private func updateMarqueeLayer(from start: CGPoint, to end: CGPoint) {
        removeMarqueeLayer()

        let rect = CGRect(
            x: min(start.x, end.x),
            y: min(start.y, end.y),
            width: abs(end.x - start.x),
            height: abs(end.y - start.y)
        )

        let shapeLayer = CAShapeLayer()
        shapeLayer.path = PlatformBezierPath(roundedRect: rect, cornerRadius: 4).cgPath
        shapeLayer.fillColor = selectionColor.withAlphaComponent(0.06).cgColor
        shapeLayer.strokeColor = selectionColor.withAlphaComponent(0.6).cgColor
        shapeLayer.lineWidth = 1.5
        shapeLayer.lineDashPattern = [6, 4]
        layer.addSublayer(shapeLayer)
        marqueeLayer = shapeLayer
    }

    private func removeMarqueeLayer() {
        marqueeLayer?.removeFromSuperlayer()
        marqueeLayer = nil
    }

    /// Find all annotations whose bounds intersect the marquee rectangle.
    private func annotationsInMarquee(from start: CGPoint, to end: CGPoint) -> [(PDFAnnotation, PDFPage)] {
        guard let pdfView = pdfView else { return [] }

        // Find which page the marquee center is on
        let centerInSelf = CGPoint(
            x: (start.x + end.x) / 2,
            y: (start.y + end.y) / 2
        )
        let centerInPDFView = convert(centerInSelf, to: pdfView)
        guard let page = pdfView.page(for: centerInPDFView, nearest: true) else { return [] }

        // Build marquee rect in selection-view (self) coordinates
        let marqueeRect = CGRect(
            x: min(start.x, end.x),
            y: min(start.y, end.y),
            width: abs(end.x - start.x),
            height: abs(end.y - start.y)
        )

        // Convert each annotation's bounds to view coordinates and check intersection.
        // This uses the same conversion path as updateSelectionVisuals / updateMultiSelectionVisuals.
        var results: [(PDFAnnotation, PDFPage)] = []
        for annotation in page.annotations {
            if let subtype = annotation.type, Self.protectedSubtypes.contains(subtype) {
                continue
            }
            let rectInPDFView = pdfView.convert(annotation.bounds, from: page)
            let rectInSelf = convert(rectInPDFView, from: pdfView)
            if rectInSelf.intersects(marqueeRect) {
                results.append((annotation, page))
            }
        }
        return results
    }

    // MARK: - Multi-Selection Visual Updates

    private func updateMultiSelectionVisuals() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)

        removeMultiSelectionVisuals()

        guard let pdfView = pdfView, let page = multiSelectedPage else {
            CATransaction.commit()
            return
        }

        pdfView.layoutIfNeeded()

        for annotation in multiSelectedAnnotations {
            let rectInPDFView = pdfView.convert(annotation.bounds, from: page)
            let rectInSelf = convert(rectInPDFView, from: pdfView)

            let border = CAShapeLayer()
            border.path = PlatformBezierPath(rect: rectInSelf).cgPath
            border.strokeColor = selectionColor.cgColor
            border.fillColor = selectionColor.withAlphaComponent(0.05).cgColor
            border.lineWidth = 1.5
            border.lineDashPattern = [4, 3]
            layer.addSublayer(border)
            multiBorderLayers.append(border)
        }

        CATransaction.commit()
    }

    private func removeMultiSelectionVisuals() {
        for borderLayer in multiBorderLayers {
            borderLayer.removeFromSuperlayer()
        }
        multiBorderLayers.removeAll()
    }

    // MARK: - Single Selection Visual Updates

    private func updateSelectionVisuals() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)

        removeBorderAndHandles()

        guard let annotation = selectedAnnotation,
              let page = selectedPage,
              let pdfView = pdfView else {
            CATransaction.commit()
            return
        }

        // Ensure PDFView layout is settled before coordinate conversion
        pdfView.layoutIfNeeded()

        // Convert annotation bounds to view coordinates
        let pageBounds = annotation.bounds
        let rectInPDFView = pdfView.convert(pageBounds, from: page)
        let rectInSelf = convert(rectInPDFView, from: pdfView)

        // Draw border
        let border = CAShapeLayer()
        border.path = PlatformBezierPath(rect: rectInSelf).cgPath
        border.strokeColor = selectionColor.cgColor
        border.fillColor = nil
        border.lineWidth = 1.5
        border.lineDashPattern = [4, 3]
        layer.addSublayer(border)
        borderLayer = border

        // Draw handles
        for position in STHandlePosition.allCases {
            let center = handleCenter(for: position, in: rectInSelf)
            let handleLayer = CAShapeLayer()
            let handleRect = CGRect(
                x: center.x - handleRadius,
                y: center.y - handleRadius,
                width: handleRadius * 2,
                height: handleRadius * 2
            )
            handleLayer.path = PlatformBezierPath(ovalIn: handleRect).cgPath
            handleLayer.fillColor = PlatformColor.white.cgColor
            handleLayer.strokeColor = selectionColor.cgColor
            handleLayer.lineWidth = 2
            handleLayer.shadowColor = PlatformColor.black.cgColor
            handleLayer.shadowOffset = CGSize(width: 0, height: 1)
            handleLayer.shadowOpacity = 0.2
            handleLayer.shadowRadius = 2
            layer.addSublayer(handleLayer)
            handleLayers[position] = handleLayer
        }

        // Rotation handle (ink annotations only)
        addRotationHandle(for: rectInSelf)

        CATransaction.commit()
    }

    private func removeBorderAndHandles() {
        borderLayer?.removeFromSuperlayer()
        borderLayer = nil
        for (_, layer) in handleLayers {
            layer.removeFromSuperlayer()
        }
        handleLayers.removeAll()
        removeRotationHandle()
    }

    private func handleCenter(for position: STHandlePosition, in rect: CGRect) -> CGPoint {
        CGPoint(
            x: rect.origin.x + rect.width * position.offset.x,
            y: rect.origin.y + rect.height * position.offset.y
        )
    }

    private func handleAt(_ point: CGPoint) -> STHandlePosition? {
        guard let rect = annotationRectInView() else { return nil }
        for position in STHandlePosition.allCases {
            let center = handleCenter(for: position, in: rect)
            let distance = hypot(point.x - center.x, point.y - center.y)
            if distance <= handleHitRadius {
                return position
            }
        }
        return nil
    }

    private func annotationRectInView() -> CGRect? {
        guard let annotation = selectedAnnotation,
              let page = selectedPage,
              let pdfView = pdfView else { return nil }
        let rectInPDFView = pdfView.convert(annotation.bounds, from: page)
        return convert(rectInPDFView, from: pdfView)
    }

    // MARK: - Rotation

    private func performRotation(to point: CGPoint) {
        guard let rect = annotationRectInView(),
              let inkAnnotation = selectedAnnotation as? STInkAnnotation else { return }

        let center = CGPoint(x: rect.midX, y: rect.midY)
        let startAngle = atan2(dragStartPoint.y - center.y, dragStartPoint.x - center.x)
        let currentAngle = atan2(point.y - center.y, point.x - center.x)
        let delta = currentAngle - startAngle

        inkAnnotation.rotationAngle = rotationStartAngle + delta
        forcePDFViewRedraw()
        updateSelectionVisuals()
    }

    /// Center of the rotation handle in this view's coordinate space.
    private func rotationHandleCenter() -> CGPoint? {
        guard let rect = annotationRectInView() else { return nil }
        return CGPoint(x: rect.midX, y: rect.minY - rotationHandleDistance)
    }

    /// Draw the rotation handle (stem line + circular handle) above the selection box.
    private func addRotationHandle(for rect: CGRect) {
        guard selectedAnnotation is STInkAnnotation else { return }

        let topCenter = CGPoint(x: rect.midX, y: rect.minY)
        let handleCenter = CGPoint(x: rect.midX, y: rect.minY - rotationHandleDistance)

        // Connecting stem line
        let linePath = PlatformBezierPath()
        linePath.move(to: topCenter)
        linePath.addLine(to: handleCenter)
        let lineLayer = CAShapeLayer()
        lineLayer.path = linePath.cgPath
        lineLayer.strokeColor = selectionColor.cgColor
        lineLayer.lineWidth = 1
        lineLayer.lineDashPattern = [3, 2]
        layer.addSublayer(lineLayer)
        rotationLineLayer = lineLayer

        // Rotation handle circle
        let handleLayer = CAShapeLayer()
        let handleRect = CGRect(
            x: handleCenter.x - handleRadius,
            y: handleCenter.y - handleRadius,
            width: handleRadius * 2,
            height: handleRadius * 2
        )
        handleLayer.path = PlatformBezierPath(ovalIn: handleRect).cgPath
        handleLayer.fillColor = PlatformColor.white.cgColor
        handleLayer.strokeColor = PlatformColor.systemGreen.cgColor
        handleLayer.lineWidth = 2
        handleLayer.shadowColor = PlatformColor.black.cgColor
        handleLayer.shadowOffset = CGSize(width: 0, height: 1)
        handleLayer.shadowOpacity = 0.2
        handleLayer.shadowRadius = 2
        layer.addSublayer(handleLayer)
        rotationHandleLayer = handleLayer
    }

    private func removeRotationHandle() {
        rotationLineLayer?.removeFromSuperlayer()
        rotationLineLayer = nil
        rotationHandleLayer?.removeFromSuperlayer()
        rotationHandleLayer = nil
    }

    /// Walk the entire PDFView subtree to force CATiledLayer tile redraw.
    /// Needed for custom-drawn annotations (STInkAnnotation) after move/resize.
    private func forcePDFViewRedraw() {
        guard let pdfView = pdfView else { return }
        pdfView.layoutDocumentView()
        func invalidate(_ view: UIView) {
            view.setNeedsDisplay()
            view.layer.setNeedsDisplay()
            for sublayer in view.layer.sublayers ?? [] {
                sublayer.setNeedsDisplay()
            }
            for child in view.subviews {
                invalidate(child)
            }
        }
        invalidate(pdfView)
    }
}

#elseif os(macOS)
/// macOS annotation selection overlay using NSView with mouse event handling.
/// Supports move, resize (8 handles), and proper visual feedback.
final class STAnnotationSelectionView: NSView {

    var onAnnotationSelected: ((_ annotation: PDFAnnotation, _ page: PDFPage) -> Void)?
    var onAnnotationModified: ((_ annotation: PDFAnnotation, _ page: PDFPage, _ oldBounds: CGRect) -> Void)?
    var onSelectionCleared: (() -> Void)?

    weak var pdfView: PDFView?
    weak var annotationManager: STAnnotationManager?

    private static let protectedSubtypes: Set<String> = ["Link", "Widget"]

    // Gesture state
    private var isDragging = false
    private var isResizing = false
    private var activeHandle: STHandlePosition?
    private var dragStart: CGPoint?
    private var originalBoundsInPage: CGRect = .zero

    // Visual layers
    private var borderLayer: CAShapeLayer?
    private var fillLayer: CAShapeLayer?
    private var handleLayers: [STHandlePosition: CAShapeLayer] = [:]
    private let handleSize: CGFloat = 10
    private let handleCornerRadius: CGFloat = 2.5
    private let handleHitRadius: CGFloat = 22
    private let selectionColor: NSColor = .systemBlue

    override var isFlipped: Bool { true }

    override init(frame: CGRect) {
        super.init(frame: frame)
        wantsLayer = true
        layer?.backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
        layer?.backgroundColor = .clear
    }

    // MARK: - Public

    func updateSelection() {
        updateSelectionVisuals()
    }

    func clearSelection() {
        removeBorderAndHandles()
    }

    // MARK: - Hit Test

    override func hitTest(_ point: NSPoint) -> NSView? {
        guard !isHidden, frame.contains(point) else { return nil }
        // Capture all mouse events when in selection mode.
        // This ensures empty-space clicks can clear selection.
        // Scroll/zoom events are forwarded to PDFView below.
        return self
    }

    // Forward scroll and zoom events to PDFView so user can still navigate
    override func scrollWheel(with event: NSEvent) {
        pdfView?.scrollWheel(with: event)
    }

    override func magnify(with event: NSEvent) {
        pdfView?.magnify(with: event)
    }

    override func smartMagnify(with event: NSEvent) {
        pdfView?.smartMagnify(with: event)
    }

    // MARK: - Mouse Events

    override func mouseDown(with event: NSEvent) {
        let pt = convert(event.locationInWindow, from: nil)

        // If an annotation is already selected, check handles then body
        if annotationManager?.selectedAnnotation != nil {
            if let handle = handleAt(pt) {
                activeHandle = handle
                isResizing = true
                isDragging = false
                dragStart = pt
                originalBoundsInPage = annotationManager?.selectedAnnotation?.bounds ?? .zero
                return
            }
            if let rect = annotationRectInView(), rect.insetBy(dx: -8, dy: -8).contains(pt) {
                isDragging = true
                isResizing = false
                dragStart = pt
                originalBoundsInPage = annotationManager?.selectedAnnotation?.bounds ?? .zero
                return
            }
        }

        // Hit test for new annotation — prefer smallest matching annotation (most precise)
        guard let (annotation, page) = hitTestAnnotation(at: pt) else {
            onSelectionCleared?()
            return
        }
        isDragging = true
        isResizing = false
        dragStart = pt
        originalBoundsInPage = annotation.bounds
        onAnnotationSelected?(annotation, page)
    }

    override func mouseDragged(with event: NSEvent) {
        guard let pdfView = pdfView,
              let annotation = annotationManager?.selectedAnnotation,
              let page = annotationManager?.selectedAnnotationPage,
              let start = dragStart else { return }

        let pt = convert(event.locationInWindow, from: nil)

        if isResizing, let handle = activeHandle {
            performResize(to: pt, start: start, handle: handle, annotation: annotation, page: page)
        } else if isDragging {
            performMove(to: pt, start: start, annotation: annotation, page: page)
        }
    }

    override func mouseUp(with event: NSEvent) {
        defer { resetState() }
        guard let annotation = annotationManager?.selectedAnnotation,
              let page = annotationManager?.selectedAnnotationPage else { return }

        if annotation.bounds != originalBoundsInPage {
            if let ink = annotation as? STInkAnnotation { ink.applyBoundsOffset() }
            else if let line = annotation as? STLineAnnotation { line.applyBoundsOffset() }

            if isResizing, annotation.type == "FreeText", originalBoundsInPage.height > 0 {
                let scale = annotation.bounds.height / originalBoundsInPage.height
                if let currentFont = annotation.font {
                    annotation.font = currentFont.withSize(max(8, min(currentFont.pointSize * scale, 200)))
                }
            }

            onAnnotationModified?(annotation, page, originalBoundsInPage)
        }

        updateSelectionVisuals()
    }

    // MARK: - Move

    private func performMove(to pt: CGPoint, start: CGPoint, annotation: PDFAnnotation, page: PDFPage) {
        guard let pdfView = pdfView else { return }
        let startInPDF = pdfView.convert(convert(start, to: pdfView), to: page)
        let currentInPDF = pdfView.convert(convert(pt, to: pdfView), to: page)
        let pageDx = currentInPDF.x - startInPDF.x
        let pageDy = currentInPDF.y - startInPDF.y

        var newBounds = CGRect(
            x: originalBoundsInPage.origin.x + pageDx,
            y: originalBoundsInPage.origin.y + pageDy,
            width: originalBoundsInPage.width,
            height: originalBoundsInPage.height
        )

        // Clamp to page
        let pageBounds = page.bounds(for: .mediaBox)
        newBounds.origin.x = max(pageBounds.minX, min(newBounds.origin.x, pageBounds.maxX - newBounds.width))
        newBounds.origin.y = max(pageBounds.minY, min(newBounds.origin.y, pageBounds.maxY - newBounds.height))

        annotation.bounds = newBounds

        if annotation is STInkAnnotation || annotation is STLineAnnotation || annotation is STImageAnnotation || annotation is STStampAnnotation {
            forcePDFViewRedraw(pdfView)
        }
        updateSelectionVisuals()
        pdfView.needsDisplay = true
    }

    // MARK: - Resize

    private func performResize(to pt: CGPoint, start: CGPoint, handle: STHandlePosition, annotation: PDFAnnotation, page: PDFPage) {
        guard let pdfView = pdfView else { return }
        let startInPDF = pdfView.convert(convert(start, to: pdfView), to: page)
        let currentInPDF = pdfView.convert(convert(pt, to: pdfView), to: page)
        let pageDX = currentInPDF.x - startInPDF.x
        let pageDY = currentInPDF.y - startInPDF.y

        var newBounds = originalBoundsInPage
        let minSize: CGFloat = 20

        switch handle {
        case .topLeft:
            newBounds.origin.x += pageDX
            newBounds.size.width -= pageDX
            newBounds.size.height += pageDY
        case .topCenter:
            newBounds.size.height += pageDY
        case .topRight:
            newBounds.size.width += pageDX
            newBounds.size.height += pageDY
        case .midLeft:
            newBounds.origin.x += pageDX
            newBounds.size.width -= pageDX
        case .midRight:
            newBounds.size.width += pageDX
        case .bottomLeft:
            newBounds.origin.x += pageDX
            newBounds.size.width -= pageDX
            newBounds.origin.y += pageDY
            newBounds.size.height -= pageDY
        case .bottomCenter:
            newBounds.origin.y += pageDY
            newBounds.size.height -= pageDY
        case .bottomRight:
            newBounds.size.width += pageDX
            newBounds.origin.y += pageDY
            newBounds.size.height -= pageDY
        }

        // Enforce minimum size
        if newBounds.width < minSize {
            newBounds.size.width = minSize
            if handle == .topLeft || handle == .midLeft || handle == .bottomLeft {
                newBounds.origin.x = originalBoundsInPage.maxX - minSize
            }
        }
        if newBounds.height < minSize {
            newBounds.size.height = minSize
            if handle == .bottomLeft || handle == .bottomCenter || handle == .bottomRight {
                newBounds.origin.y = originalBoundsInPage.maxY - minSize
            }
        }

        // Clamp to page
        let pageBounds = page.bounds(for: .mediaBox)
        newBounds.origin.x = max(pageBounds.minX, min(newBounds.origin.x, pageBounds.maxX - newBounds.width))
        newBounds.origin.y = max(pageBounds.minY, min(newBounds.origin.y, pageBounds.maxY - newBounds.height))
        newBounds.size.width = min(newBounds.width, pageBounds.width - (newBounds.origin.x - pageBounds.minX))
        newBounds.size.height = min(newBounds.height, pageBounds.height - (newBounds.origin.y - pageBounds.minY))

        annotation.bounds = newBounds

        if annotation is STInkAnnotation || annotation is STLineAnnotation || annotation is STImageAnnotation || annotation is STStampAnnotation {
            forcePDFViewRedraw(pdfView)
        }
        updateSelectionVisuals()
    }

    // MARK: - Hit Testing

    private func hitTestAnnotation(at point: CGPoint) -> (PDFAnnotation, PDFPage)? {
        guard let pdfView = pdfView else { return nil }
        let pointInPDFView = convert(point, to: pdfView)
        guard let page = pdfView.page(for: pointInPDFView, nearest: false) else { return nil }
        let pointInPage = pdfView.convert(pointInPDFView, to: page)

        let eligible = page.annotations.filter { annotation in
            if let subtype = annotation.type, Self.protectedSubtypes.contains(subtype) { return false }
            return true
        }

        // Pass 1: exact contains — prefer smallest area (most precise annotation)
        var bestExact: PDFAnnotation?
        var bestExactArea: CGFloat = .greatestFiniteMagnitude
        for annotation in eligible {
            if annotation.bounds.contains(pointInPage) {
                let area = annotation.bounds.width * annotation.bounds.height
                if area < bestExactArea {
                    bestExact = annotation
                    bestExactArea = area
                }
            }
        }
        if let best = bestExact { return (best, page) }

        // Pass 2: intersects with tolerance — prefer smallest area
        let hitRect = CGRect(x: pointInPage.x - 10, y: pointInPage.y - 10, width: 20, height: 20)
        var bestNear: PDFAnnotation?
        var bestNearArea: CGFloat = .greatestFiniteMagnitude
        for annotation in eligible {
            if annotation.bounds.intersects(hitRect) {
                let area = annotation.bounds.width * annotation.bounds.height
                if area < bestNearArea {
                    bestNear = annotation
                    bestNearArea = area
                }
            }
        }
        if let best = bestNear { return (best, page) }

        return nil
    }

    private func handleAt(_ point: CGPoint) -> STHandlePosition? {
        guard let rect = annotationRectInView() else { return nil }
        for position in STHandlePosition.allCases {
            let center = handleCenter(for: position, in: rect)
            if hypot(point.x - center.x, point.y - center.y) <= handleHitRadius {
                return position
            }
        }
        return nil
    }

    private func annotationRectInView() -> CGRect? {
        guard let annotation = annotationManager?.selectedAnnotation,
              let page = annotationManager?.selectedAnnotationPage,
              let pdfView = pdfView else { return nil }
        let rectInPDFView = pdfView.convert(annotation.bounds, from: page)
        return convert(rectInPDFView, from: pdfView)
    }

    private func handleCenter(for position: STHandlePosition, in rect: CGRect) -> CGPoint {
        CGPoint(
            x: rect.origin.x + rect.width * position.offset.x,
            y: rect.origin.y + rect.height * position.offset.y
        )
    }

    // MARK: - Visuals

    private func updateSelectionVisuals() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        removeBorderAndHandles()

        guard let annotation = annotationManager?.selectedAnnotation,
              let page = annotationManager?.selectedAnnotationPage,
              let pdfView = pdfView else {
            CATransaction.commit()
            return
        }

        pdfView.layoutSubtreeIfNeeded()

        let pageBounds = annotation.bounds
        let rectInPDFView = pdfView.convert(pageBounds, from: page)
        let rectInSelf = convert(rectInPDFView, from: pdfView)

        // Subtle fill
        let fill = CAShapeLayer()
        fill.path = NSBezierPath(rect: rectInSelf).cgPath
        fill.fillColor = selectionColor.withAlphaComponent(0.05).cgColor
        fill.strokeColor = nil
        layer?.addSublayer(fill)
        fillLayer = fill

        // Border — solid, clean line
        let border = CAShapeLayer()
        let borderRect = rectInSelf.insetBy(dx: -0.5, dy: -0.5)
        border.path = NSBezierPath(rect: borderRect).cgPath
        border.strokeColor = selectionColor.withAlphaComponent(0.8).cgColor
        border.fillColor = nil
        border.lineWidth = 1.0
        layer?.addSublayer(border)
        borderLayer = border

        // Handles — rounded squares
        for position in STHandlePosition.allCases {
            let center = handleCenter(for: position, in: rectInSelf)
            let handleLayer = CAShapeLayer()
            let handleRect = CGRect(
                x: center.x - handleSize / 2,
                y: center.y - handleSize / 2,
                width: handleSize,
                height: handleSize
            )
            handleLayer.path = NSBezierPath(roundedRect: handleRect, xRadius: handleCornerRadius, yRadius: handleCornerRadius).cgPath
            handleLayer.fillColor = NSColor.white.cgColor
            handleLayer.strokeColor = selectionColor.cgColor
            handleLayer.lineWidth = 1.5
            handleLayer.shadowColor = NSColor.black.cgColor
            handleLayer.shadowOffset = CGSize(width: 0, height: 0.5)
            handleLayer.shadowOpacity = 0.15
            handleLayer.shadowRadius = 1.5
            layer?.addSublayer(handleLayer)
            handleLayers[position] = handleLayer
        }

        CATransaction.commit()
    }

    private func removeBorderAndHandles() {
        fillLayer?.removeFromSuperlayer()
        fillLayer = nil
        borderLayer?.removeFromSuperlayer()
        borderLayer = nil
        for (_, l) in handleLayers { l.removeFromSuperlayer() }
        handleLayers.removeAll()
    }

    // MARK: - Helpers

    private func resetState() {
        isDragging = false
        isResizing = false
        activeHandle = nil
        dragStart = nil
    }

    private func forcePDFViewRedraw(_ pdfView: PDFView) {
        pdfView.layoutDocumentView()
        func invalidate(_ view: NSView) {
            view.needsDisplay = true
            view.layer?.setNeedsDisplay()
            for sublayer in view.layer?.sublayers ?? [] { sublayer.setNeedsDisplay() }
            for child in view.subviews { invalidate(child) }
        }
        invalidate(pdfView)
    }
}
#endif

/// Actions available in the selection context menu
enum STSelectionAction {
    case copy
    case delete
    case inspector
    case note
}
