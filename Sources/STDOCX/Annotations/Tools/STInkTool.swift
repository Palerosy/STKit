#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif
import STKit
import PDFKit

// MARK: - Custom Ink Annotation

/// Custom ink annotation that guarantees rendering via draw(with:in:) override.
///
/// Apple's PDFKit does NOT reliably render dynamically-added `.ink` annotations
/// in its CATiledLayer tiles. Shape annotations (.square, .circle, .line) render
/// fine, but .ink annotations simply don't appear.
///
/// This subclass solves the problem by drawing the ink path directly in the
/// page's graphics context when PDFKit requests a tile redraw.
/// Standard properties (color, border, paths) are also set for PDF serialization.
///
/// Supports move, proportional scale, rotation, and live style changes.
/// All transforms are applied visually in `draw(with:in:)` during interaction,
/// then "baked in" to the actual point data when the gesture ends.
final class STInkAnnotation: PDFAnnotation {

    private var inkPoints: [CGPoint]
    private(set) var inkStrokeWidth: CGFloat
    private(set) var inkColor: PlatformColor

    /// The bounds at the time of last bake (creation or applyTransform).
    /// Used to calculate move/scale deltas in draw(with:in:).
    private var originalBounds: CGRect

    /// Current rotation angle in radians (interactive, baked on gesture end).
    var rotationAngle: CGFloat = 0

    init(bounds: CGRect, points: [CGPoint], strokeWidth: CGFloat, color: PlatformColor) {
        self.inkPoints = points
        self.inkStrokeWidth = strokeWidth
        self.inkColor = color
        self.originalBounds = bounds
        super.init(bounds: bounds, forType: .ink, withProperties: nil)

        // Standard properties for PDF save/load compatibility
        self.color = color
        let border = PDFBorder()
        border.lineWidth = strokeWidth
        self.border = border

        // Add path for standard ink annotation compatibility
        rebuildPaths()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public Accessors

    /// Get a copy of the current ink points (for copy/paste).
    func getInkPoints() -> [CGPoint] { inkPoints }

    // MARK: - Style

    /// Update ink color and stroke width (for inspector changes on selected annotation).
    func applyStyle(color: PlatformColor, strokeWidth: CGFloat) {
        inkColor = color
        inkStrokeWidth = strokeWidth
        self.color = color
        let border = PDFBorder()
        border.lineWidth = strokeWidth
        self.border = border
    }

    // MARK: - Transform (move + scale)

    /// Bake the current bounds offset + scale into ink points permanently.
    /// Call this after a move/resize gesture ends.
    func applyBoundsOffset() {
        let dx = bounds.origin.x - originalBounds.origin.x
        let dy = bounds.origin.y - originalBounds.origin.y
        let sx = originalBounds.width > 0 ? bounds.width / originalBounds.width : 1.0
        let sy = originalBounds.height > 0 ? bounds.height / originalBounds.height : 1.0

        let needsTranslation = dx != 0 || dy != 0
        let needsScale = abs(sx - 1.0) > 0.001 || abs(sy - 1.0) > 0.001
        guard needsTranslation || needsScale else { return }

        inkPoints = inkPoints.map { pt in
            CGPoint(
                x: originalBounds.origin.x + (pt.x - originalBounds.origin.x) * sx + dx,
                y: originalBounds.origin.y + (pt.y - originalBounds.origin.y) * sy + dy
            )
        }
        // Scale stroke width proportionally
        if needsScale {
            inkStrokeWidth *= min(sx, sy)
            let border = PDFBorder()
            border.lineWidth = inkStrokeWidth
            self.border = border
        }
        originalBounds = bounds
        rebuildPaths()
    }

    // MARK: - Rotation

    /// Bake the current rotation into ink points permanently.
    /// Recomputes bounds to fit the rotated points, then resets angle to 0.
    func applyRotation() {
        // First bake any pending move/scale
        applyBoundsOffset()

        guard abs(rotationAngle) > 0.001 else { return }

        let centerX = bounds.midX
        let centerY = bounds.midY
        let cosA = cos(rotationAngle)
        let sinA = sin(rotationAngle)

        inkPoints = inkPoints.map { pt in
            let relX = pt.x - centerX
            let relY = pt.y - centerY
            return CGPoint(
                x: centerX + relX * cosA - relY * sinA,
                y: centerY + relX * sinA + relY * cosA
            )
        }

        // Recompute bounds to fit rotated points
        let pad = max(inkStrokeWidth, 2) * 2
        let xs = inkPoints.map(\.x)
        let ys = inkPoints.map(\.y)
        guard let minX = xs.min(), let maxX = xs.max(),
              let minY = ys.min(), let maxY = ys.max() else { return }

        let newBounds = CGRect(
            x: minX - pad, y: minY - pad,
            width: max(maxX - minX, 1) + pad * 2,
            height: max(maxY - minY, 1) + pad * 2
        )
        bounds = newBounds
        originalBounds = newBounds
        rotationAngle = 0
        rebuildPaths()
    }

    // MARK: - Rendering

    override func draw(with box: PDFDisplayBox, in context: CGContext) {
        guard inkPoints.count >= 2 else { return }

        // Calculate move + scale deltas
        let dx = bounds.origin.x - originalBounds.origin.x
        let dy = bounds.origin.y - originalBounds.origin.y
        let sx = originalBounds.width > 0 ? bounds.width / originalBounds.width : 1.0
        let sy = originalBounds.height > 0 ? bounds.height / originalBounds.height : 1.0

        let centerX = bounds.midX
        let centerY = bounds.midY
        let hasRotation = abs(rotationAngle) > 0.001

        context.saveGState()
        context.setStrokeColor(inkColor.cgColor)
        context.setLineWidth(inkStrokeWidth * min(sx, sy))
        context.setLineCap(.round)
        context.setLineJoin(.round)

        func transform(_ pt: CGPoint) -> CGPoint {
            // 1. Scale relative to original bounds origin, then translate
            var x = originalBounds.origin.x + (pt.x - originalBounds.origin.x) * sx + dx
            var y = originalBounds.origin.y + (pt.y - originalBounds.origin.y) * sy + dy

            // 2. Rotate around current bounds center
            if hasRotation {
                let relX = x - centerX
                let relY = y - centerY
                let cosA = cos(rotationAngle)
                let sinA = sin(rotationAngle)
                x = centerX + relX * cosA - relY * sinA
                y = centerY + relX * sinA + relY * cosA
            }
            return CGPoint(x: x, y: y)
        }

        context.move(to: transform(inkPoints[0]))
        for i in 1..<inkPoints.count {
            context.addLine(to: transform(inkPoints[i]))
        }
        context.strokePath()
        context.restoreGState()
    }

    // MARK: - Private

    /// Rebuild the standard PDFAnnotation paths from inkPoints (for PDF save compatibility).
    private func rebuildPaths() {
        // PDFAnnotation has no removePath — each add() appends.
        // The last path added wins for serialization purposes.
        let path = PlatformBezierPath()
        if let first = inkPoints.first {
            path.move(to: first)
            for i in 1..<inkPoints.count {
                path.addLine(to: inkPoints[i])
            }
        }
        self.add(path)
    }
}

// MARK: - Ink Drawing View

/// GPU-accelerated ink drawing overlay for PDFKit.
///
/// Strategy — immediate commit with custom annotation + temporary overlay:
/// - During drawing: CAShapeLayer provides 60fps visual feedback.
/// - On touchesEnded: STInkAnnotation (custom draw) committed to page.
/// - Overlay kept briefly (500ms) while CATiledLayer re-renders asynchronously.
/// - Tool switch: drawing view stays visible (just interaction disabled), overlays persist.
/// - Annotation mode exit / zoom: all overlays cleared immediately.
#if os(iOS)
final class STInkDrawingView: UIView {

    var onStrokeCommitted: ((_ annotation: PDFAnnotation, _ page: PDFPage) -> Void)?
    weak var pdfView: PDFView?
    var strokeColor: PlatformColor = .systemBlue
    var strokeWidth: CGFloat = 3.0
    var strokeOpacity: CGFloat = 1.0

    private var currentPoints: [CGPoint] = []
    private var currentLayer: CAShapeLayer?
    private var currentPath: PlatformBezierPath?
    private var overlayLayers: [CAShapeLayer] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isMultipleTouchEnabled = false
        clipsToBounds = false
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
        isMultipleTouchEnabled = false
        clipsToBounds = false
    }

    func clearOverlayLayers() {
        for layer in overlayLayers { layer.removeFromSuperlayer() }
        overlayLayers.removeAll()
        clearCurrentStroke()
    }

    func clearCurrentStroke() {
        currentLayer?.removeFromSuperlayer()
        currentLayer = nil
        currentPath = nil
        currentPoints = []
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        beginStroke(at: touch.location(in: self))
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let allTouches = event?.coalescedTouches(for: touch) ?? [touch]
        for ct in allTouches {
            continueStroke(at: ct.location(in: self))
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            endStroke(at: touch.location(in: self))
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        clearCurrentStroke()
    }

    private func beginStroke(at pt: CGPoint) {
        currentPoints = [pt]
        let shapeLayer = CAShapeLayer()
        shapeLayer.strokeColor = strokeColor.withAlphaComponent(strokeOpacity).cgColor
        shapeLayer.fillColor = nil
        shapeLayer.lineWidth = strokeWidth
        shapeLayer.lineCap = .round
        shapeLayer.lineJoin = .round
        layer.addSublayer(shapeLayer)
        currentLayer = shapeLayer
        let path = PlatformBezierPath()
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        path.move(to: pt)
        currentPath = path
        shapeLayer.path = path.cgPath
    }

    private func continueStroke(at pt: CGPoint) {
        guard let path = currentPath, let shapeLayer = currentLayer else { return }
        currentPoints.append(pt)
        path.addLine(to: pt)
        shapeLayer.path = path.cgPath
    }

    private func endStroke(at pt: CGPoint) {
        if pt != currentPoints.last {
            currentPoints.append(pt)
            currentPath?.addLine(to: pt)
            currentLayer?.path = currentPath?.cgPath
        }
        commitStroke()
    }

    private func commitStroke() {
        guard let pdfView = pdfView, currentPoints.count >= 2 else {
            clearCurrentStroke()
            return
        }
        let mid = currentPoints[currentPoints.count / 2]
        let midInPDFView = convert(mid, to: pdfView)
        guard let page = pdfView.page(for: midInPDFView, nearest: true) else {
            clearCurrentStroke()
            return
        }
        let pagePoints = currentPoints.map { pt -> CGPoint in
            let viewPt = convert(pt, to: pdfView)
            return pdfView.convert(viewPt, to: page)
        }
        let originInView = convert(CGPoint.zero, to: pdfView)
        let unitInView = convert(CGPoint(x: 1, y: 0), to: pdfView)
        let pageOrigin = pdfView.convert(originInView, to: page)
        let pageUnit = pdfView.convert(unitInView, to: page)
        let screenToPageScale = hypot(pageUnit.x - pageOrigin.x, pageUnit.y - pageOrigin.y)
        let pageStrokeWidth = strokeWidth * screenToPageScale

        let annotation = buildAnnotation(pagePoints: pagePoints, pageStrokeWidth: pageStrokeWidth)
        page.addAnnotation(annotation)
        onStrokeCommitted?(annotation, page)

        if let layer = currentLayer {
            overlayLayers.append(layer)
            let layerRef = layer
            CATransaction.begin()
            CATransaction.setAnimationDuration(0.25)
            CATransaction.setCompletionBlock { [weak self] in
                layerRef.removeFromSuperlayer()
                self?.overlayLayers.removeAll { $0 === layerRef }
            }
            layerRef.opacity = 0
            CATransaction.commit()
        }
        currentLayer = nil
        currentPath = nil
        currentPoints = []
        forcePDFViewRedraw(pdfView)
    }

    private func forcePDFViewRedraw(_ pdfView: PDFView) {
        pdfView.layoutDocumentView()
        func invalidate(_ view: UIView) {
            view.setNeedsDisplay()
            view.layer.setNeedsDisplay()
            for sublayer in view.layer.sublayers ?? [] { sublayer.setNeedsDisplay() }
            for child in view.subviews { invalidate(child) }
        }
        invalidate(pdfView)
    }

    private func buildAnnotation(pagePoints: [CGPoint], pageStrokeWidth: CGFloat) -> PDFAnnotation {
        let pad = max(pageStrokeWidth, 2) * 2
        let xs = pagePoints.map(\.x)
        let ys = pagePoints.map(\.y)
        let minX = xs.min()!, maxX = xs.max()!
        let minY = ys.min()!, maxY = ys.max()!
        let bounds = CGRect(x: minX - pad, y: minY - pad, width: max(maxX - minX, 1) + pad * 2, height: max(maxY - minY, 1) + pad * 2)
        return STInkAnnotation(bounds: bounds, points: pagePoints, strokeWidth: pageStrokeWidth, color: strokeColor.withAlphaComponent(strokeOpacity))
    }
}

#elseif os(macOS)
final class STInkDrawingView: NSView {

    var onStrokeCommitted: ((_ annotation: PDFAnnotation, _ page: PDFPage) -> Void)?
    weak var pdfView: PDFView?
    var strokeColor: PlatformColor = .systemBlue
    var strokeWidth: CGFloat = 3.0
    var strokeOpacity: CGFloat = 1.0

    private var currentPoints: [CGPoint] = []
    private var currentLayer: CAShapeLayer?
    private var currentPath: PlatformBezierPath?
    private var overlayLayers: [CAShapeLayer] = []

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

    func clearOverlayLayers() {
        for l in overlayLayers { l.removeFromSuperlayer() }
        overlayLayers.removeAll()
        clearCurrentStroke()
    }

    func clearCurrentStroke() {
        currentLayer?.removeFromSuperlayer()
        currentLayer = nil
        currentPath = nil
        currentPoints = []
    }

    override func mouseDown(with event: NSEvent) {
        beginStroke(at: convert(event.locationInWindow, from: nil))
    }

    override func mouseDragged(with event: NSEvent) {
        continueStroke(at: convert(event.locationInWindow, from: nil))
    }

    override func mouseUp(with event: NSEvent) {
        endStroke(at: convert(event.locationInWindow, from: nil))
    }

    private func beginStroke(at pt: CGPoint) {
        currentPoints = [pt]
        let shapeLayer = CAShapeLayer()
        shapeLayer.strokeColor = strokeColor.withAlphaComponent(strokeOpacity).cgColor
        shapeLayer.fillColor = nil
        shapeLayer.lineWidth = strokeWidth
        shapeLayer.lineCap = .round
        shapeLayer.lineJoin = .round
        layer?.addSublayer(shapeLayer)
        currentLayer = shapeLayer
        let path = PlatformBezierPath()
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        path.move(to: pt)
        currentPath = path
        shapeLayer.path = path.cgPath
    }

    private func continueStroke(at pt: CGPoint) {
        guard let path = currentPath, let shapeLayer = currentLayer else { return }
        currentPoints.append(pt)
        path.addLine(to: pt)
        shapeLayer.path = path.cgPath
    }

    private func endStroke(at pt: CGPoint) {
        if pt != currentPoints.last {
            currentPoints.append(pt)
            currentPath?.addLine(to: pt)
            currentLayer?.path = currentPath?.cgPath
        }
        commitStroke()
    }

    private func commitStroke() {
        guard let pdfView = pdfView, currentPoints.count >= 2 else {
            clearCurrentStroke()
            return
        }
        let mid = currentPoints[currentPoints.count / 2]
        let midInPDFView = convert(mid, to: pdfView)
        guard let page = pdfView.page(for: midInPDFView, nearest: true) else {
            clearCurrentStroke()
            return
        }
        let pagePoints = currentPoints.map { pt -> CGPoint in
            let viewPt = convert(pt, to: pdfView)
            return pdfView.convert(viewPt, to: page)
        }
        let originInView = convert(CGPoint.zero, to: pdfView)
        let unitInView = convert(CGPoint(x: 1, y: 0), to: pdfView)
        let pageOrigin = pdfView.convert(originInView, to: page)
        let pageUnit = pdfView.convert(unitInView, to: page)
        let screenToPageScale = hypot(pageUnit.x - pageOrigin.x, pageUnit.y - pageOrigin.y)
        let pageStrokeWidth = strokeWidth * screenToPageScale

        let annotation = buildAnnotation(pagePoints: pagePoints, pageStrokeWidth: pageStrokeWidth)
        page.addAnnotation(annotation)
        onStrokeCommitted?(annotation, page)

        if let layer = currentLayer {
            overlayLayers.append(layer)
            let layerRef = layer
            CATransaction.begin()
            CATransaction.setAnimationDuration(0.25)
            CATransaction.setCompletionBlock { [weak self] in
                layerRef.removeFromSuperlayer()
                self?.overlayLayers.removeAll { $0 === layerRef }
            }
            layerRef.opacity = 0
            CATransaction.commit()
        }
        currentLayer = nil
        currentPath = nil
        currentPoints = []
        forcePDFViewRedraw(pdfView)
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

    private func buildAnnotation(pagePoints: [CGPoint], pageStrokeWidth: CGFloat) -> PDFAnnotation {
        let pad = max(pageStrokeWidth, 2) * 2
        let xs = pagePoints.map(\.x)
        let ys = pagePoints.map(\.y)
        let minX = xs.min()!, maxX = xs.max()!
        let minY = ys.min()!, maxY = ys.max()!
        let bounds = CGRect(x: minX - pad, y: minY - pad, width: max(maxX - minX, 1) + pad * 2, height: max(maxY - minY, 1) + pad * 2)
        return STInkAnnotation(bounds: bounds, points: pagePoints, strokeWidth: pageStrokeWidth, color: strokeColor.withAlphaComponent(strokeOpacity))
    }
}
#endif
