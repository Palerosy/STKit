#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif
import STKit
import PDFKit

// MARK: - STLineAnnotation

/// Custom PDFAnnotation subclass for line and arrow annotations.
///
/// Apple's PDFKit CATiledLayer does NOT reliably render dynamically-added
/// `.line` annotations (same problem as `.ink`). This subclass draws the
/// line (and optional arrowhead) directly in the page graphics context.
///
/// Supports move, proportional scale, and live style changes.
final class STLineAnnotation: PDFAnnotation {

    private(set) var lineStart: CGPoint
    private(set) var lineEnd: CGPoint
    private(set) var lineStrokeWidth: CGFloat
    private(set) var lineColor: PlatformColor
    private(set) var hasArrowHead: Bool

    /// Bounds at last bake — used to calculate transform deltas in draw(with:in:).
    private var originalBounds: CGRect

    init(bounds: CGRect, start: CGPoint, end: CGPoint, strokeWidth: CGFloat, color: PlatformColor, arrowHead: Bool) {
        self.lineStart = start
        self.lineEnd = end
        self.lineStrokeWidth = strokeWidth
        self.lineColor = color
        self.hasArrowHead = arrowHead
        self.originalBounds = bounds
        super.init(bounds: bounds, forType: .line, withProperties: nil)

        // Standard properties for PDF serialization
        self.startPoint = start
        self.endPoint = end
        self.color = color
        let border = PDFBorder()
        border.lineWidth = strokeWidth
        self.border = border
        if arrowHead {
            self.endLineStyle = .closedArrow
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public Accessors

    func getStartPoint() -> CGPoint { lineStart }
    func getEndPoint() -> CGPoint { lineEnd }

    // MARK: - Style

    func applyStyle(color: PlatformColor, strokeWidth: CGFloat) {
        lineColor = color
        lineStrokeWidth = strokeWidth
        self.color = color
        let border = PDFBorder()
        border.lineWidth = strokeWidth
        self.border = border
    }

    // MARK: - Transform (move + scale)

    /// Bake current bounds offset + scale into line endpoints permanently.
    func applyBoundsOffset() {
        let dx = bounds.origin.x - originalBounds.origin.x
        let dy = bounds.origin.y - originalBounds.origin.y
        let sx = originalBounds.width > 0 ? bounds.width / originalBounds.width : 1.0
        let sy = originalBounds.height > 0 ? bounds.height / originalBounds.height : 1.0

        let needsTranslation = dx != 0 || dy != 0
        let needsScale = abs(sx - 1.0) > 0.001 || abs(sy - 1.0) > 0.001
        guard needsTranslation || needsScale else { return }

        func transform(_ pt: CGPoint) -> CGPoint {
            CGPoint(
                x: originalBounds.origin.x + (pt.x - originalBounds.origin.x) * sx + dx,
                y: originalBounds.origin.y + (pt.y - originalBounds.origin.y) * sy + dy
            )
        }

        lineStart = transform(lineStart)
        lineEnd = transform(lineEnd)

        if needsScale {
            lineStrokeWidth *= min(sx, sy)
            let border = PDFBorder()
            border.lineWidth = lineStrokeWidth
            self.border = border
        }

        // Sync standard properties for serialization
        self.startPoint = lineStart
        self.endPoint = lineEnd
        originalBounds = bounds
    }

    // MARK: - Rendering

    override func draw(with box: PDFDisplayBox, in context: CGContext) {
        let dx = bounds.origin.x - originalBounds.origin.x
        let dy = bounds.origin.y - originalBounds.origin.y
        let sx = originalBounds.width > 0 ? bounds.width / originalBounds.width : 1.0
        let sy = originalBounds.height > 0 ? bounds.height / originalBounds.height : 1.0

        func transform(_ pt: CGPoint) -> CGPoint {
            CGPoint(
                x: originalBounds.origin.x + (pt.x - originalBounds.origin.x) * sx + dx,
                y: originalBounds.origin.y + (pt.y - originalBounds.origin.y) * sy + dy
            )
        }

        let start = transform(lineStart)
        let end = transform(lineEnd)
        let effectiveWidth = lineStrokeWidth * min(sx, sy)

        context.saveGState()
        context.setStrokeColor(lineColor.cgColor)
        context.setLineWidth(effectiveWidth)
        context.setLineCap(.round)
        context.setLineJoin(.round)

        // Main line
        context.move(to: start)
        context.addLine(to: end)
        context.strokePath()

        // Arrowhead
        if hasArrowHead {
            let headLength = max(10, effectiveWidth * 4)
            let headAngle: CGFloat = .pi / 6
            let angle = atan2(end.y - start.y, end.x - start.x)

            let p1 = CGPoint(
                x: end.x - headLength * cos(angle - headAngle),
                y: end.y - headLength * sin(angle - headAngle)
            )
            let p2 = CGPoint(
                x: end.x - headLength * cos(angle + headAngle),
                y: end.y - headLength * sin(angle + headAngle)
            )

            context.move(to: p1)
            context.addLine(to: end)
            context.addLine(to: p2)
            context.strokePath()
        }

        context.restoreGState()
    }
}

// MARK: - STShapeDrawingView

/// GPU-accelerated shape drawing overlay for PDFKit.
#if os(iOS)
final class STShapeDrawingView: UIView {

    var onShapeCommitted: ((_ annotation: PDFAnnotation, _ page: PDFPage) -> Void)?
    weak var pdfView: PDFView?
    var shapeType: STAnnotationType = .rectangle
    var strokeColor: PlatformColor = .systemBlue
    var strokeWidth: CGFloat = 2.0
    var strokeOpacity: CGFloat = 1.0

    private var startPoint: CGPoint?
    private var currentLayer: CAShapeLayer?

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

    func clearCurrentShape() {
        currentLayer?.removeFromSuperlayer()
        currentLayer = nil
        startPoint = nil
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        beginShape(at: touch.location(in: self))
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        updateShape(at: touch.location(in: self))
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { cancelShape(); return }
        finishShape(at: touch.location(in: self))
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        cancelShape()
    }

    private func beginShape(at pt: CGPoint) {
        startPoint = pt
        let shapeLayer = CAShapeLayer()
        shapeLayer.strokeColor = strokeColor.withAlphaComponent(strokeOpacity).cgColor
        shapeLayer.fillColor = nil
        shapeLayer.lineWidth = strokeWidth
        shapeLayer.lineCap = .round
        shapeLayer.lineJoin = .round
        layer.addSublayer(shapeLayer)
        currentLayer = shapeLayer
    }

    private func updateShape(at pt: CGPoint) {
        guard let start = startPoint, let shapeLayer = currentLayer else { return }
        shapeLayer.path = shapePath(from: start, to: pt).cgPath
    }

    private func finishShape(at pt: CGPoint) {
        guard let start = startPoint else { cancelShape(); return }
        let dx = abs(pt.x - start.x)
        let dy = abs(pt.y - start.y)
        let minDist: CGFloat = (shapeType == .line || shapeType == .arrow) ? 10 : 15
        guard max(dx, dy) >= minDist else { cancelShape(); return }
        currentLayer?.path = shapePath(from: start, to: pt).cgPath
        commitShape(start: start, end: pt)
    }

    private func cancelShape() {
        currentLayer?.removeFromSuperlayer()
        currentLayer = nil
        startPoint = nil
    }

    private func shapePath(from start: CGPoint, to end: CGPoint) -> PlatformBezierPath {
        let rect = CGRect(x: min(start.x, end.x), y: min(start.y, end.y), width: abs(end.x - start.x), height: abs(end.y - start.y))
        switch shapeType {
        case .rectangle: return PlatformBezierPath(rect: rect)
        case .circle: return PlatformBezierPath(ovalIn: rect)
        case .line:
            let path = PlatformBezierPath()
            path.move(to: start)
            path.addLine(to: end)
            return path
        case .arrow: return arrowPath(from: start, to: end)
        default: return PlatformBezierPath(rect: rect)
        }
    }

    private func arrowPath(from start: CGPoint, to end: CGPoint) -> PlatformBezierPath {
        let path = PlatformBezierPath()
        path.move(to: start)
        path.addLine(to: end)
        let headLength: CGFloat = max(15, strokeWidth * 4)
        let headAngle: CGFloat = .pi / 6
        let angle = atan2(end.y - start.y, end.x - start.x)
        let p1 = CGPoint(x: end.x - headLength * cos(angle - headAngle), y: end.y - headLength * sin(angle - headAngle))
        let p2 = CGPoint(x: end.x - headLength * cos(angle + headAngle), y: end.y - headLength * sin(angle + headAngle))
        path.move(to: p1)
        path.addLine(to: end)
        path.addLine(to: p2)
        return path
    }

    private func commitShape(start: CGPoint, end: CGPoint) {
        guard let pdfView = pdfView else { cancelShape(); return }
        let center = CGPoint(x: (start.x + end.x) / 2, y: (start.y + end.y) / 2)
        let centerInPDFView = convert(center, to: pdfView)
        guard let page = pdfView.page(for: centerInPDFView, nearest: true) else { cancelShape(); return }
        let startInPDF = convert(start, to: pdfView)
        let endInPDF = convert(end, to: pdfView)
        let pageStart = pdfView.convert(startInPDF, to: page)
        let pageEnd = pdfView.convert(endInPDF, to: page)
        let annotation = buildAnnotation(pageStart: pageStart, pageEnd: pageEnd, page: page)
        page.addAnnotation(annotation)
        onShapeCommitted?(annotation, page)
        currentLayer?.removeFromSuperlayer()
        currentLayer = nil
        startPoint = nil
        if annotation is STLineAnnotation {
            pdfView.layoutDocumentView()
            func invalidate(_ view: UIView) {
                view.setNeedsDisplay()
                view.layer.setNeedsDisplay()
                for sublayer in view.layer.sublayers ?? [] { sublayer.setNeedsDisplay() }
                for child in view.subviews { invalidate(child) }
            }
            invalidate(pdfView)
        } else {
            pdfView.setNeedsDisplay()
        }
    }

    private func buildAnnotation(pageStart: CGPoint, pageEnd: CGPoint, page: PDFPage) -> PDFAnnotation {
        let pad = max(strokeWidth, 2) * 2
        switch shapeType {
        case .line, .arrow: return buildLineAnnotation(start: pageStart, end: pageEnd, padding: pad)
        case .circle: return buildCircleAnnotation(start: pageStart, end: pageEnd)
        default: return buildRectAnnotation(start: pageStart, end: pageEnd)
        }
    }

    private func buildLineAnnotation(start: CGPoint, end: CGPoint, padding: CGFloat) -> PDFAnnotation {
        let bounds = CGRect(x: min(start.x, end.x) - padding, y: min(start.y, end.y) - padding,
                           width: max(abs(end.x - start.x), 1) + padding * 2, height: max(abs(end.y - start.y), 1) + padding * 2)
        return STLineAnnotation(bounds: bounds, start: start, end: end, strokeWidth: strokeWidth,
                               color: strokeColor.withAlphaComponent(strokeOpacity), arrowHead: shapeType == .arrow)
    }

    private func buildRectAnnotation(start: CGPoint, end: CGPoint) -> PDFAnnotation {
        let bounds = CGRect(x: min(start.x, end.x), y: min(start.y, end.y),
                           width: max(abs(end.x - start.x), 1), height: max(abs(end.y - start.y), 1))
        let annotation = PDFAnnotation(bounds: bounds, forType: .square, withProperties: nil)
        annotation.color = strokeColor.withAlphaComponent(strokeOpacity)
        let border = PDFBorder(); border.lineWidth = strokeWidth; annotation.border = border
        return annotation
    }

    private func buildCircleAnnotation(start: CGPoint, end: CGPoint) -> PDFAnnotation {
        let bounds = CGRect(x: min(start.x, end.x), y: min(start.y, end.y),
                           width: max(abs(end.x - start.x), 1), height: max(abs(end.y - start.y), 1))
        let annotation = PDFAnnotation(bounds: bounds, forType: .circle, withProperties: nil)
        annotation.color = strokeColor.withAlphaComponent(strokeOpacity)
        let border = PDFBorder(); border.lineWidth = strokeWidth; annotation.border = border
        return annotation
    }
}

#elseif os(macOS)
final class STShapeDrawingView: NSView {

    var onShapeCommitted: ((_ annotation: PDFAnnotation, _ page: PDFPage) -> Void)?
    weak var pdfView: PDFView?
    var shapeType: STAnnotationType = .rectangle
    var strokeColor: PlatformColor = .systemBlue
    var strokeWidth: CGFloat = 2.0
    var strokeOpacity: CGFloat = 1.0

    private var startPoint: CGPoint?
    private var currentLayer: CAShapeLayer?

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

    func clearCurrentShape() {
        currentLayer?.removeFromSuperlayer()
        currentLayer = nil
        startPoint = nil
    }

    override func mouseDown(with event: NSEvent) {
        let pt = convert(event.locationInWindow, from: nil)
        startPoint = pt
        let shapeLayer = CAShapeLayer()
        shapeLayer.strokeColor = strokeColor.withAlphaComponent(strokeOpacity).cgColor
        shapeLayer.fillColor = nil
        shapeLayer.lineWidth = strokeWidth
        shapeLayer.lineCap = .round
        shapeLayer.lineJoin = .round
        layer?.addSublayer(shapeLayer)
        currentLayer = shapeLayer
    }

    override func mouseDragged(with event: NSEvent) {
        let pt = convert(event.locationInWindow, from: nil)
        guard let start = startPoint, let shapeLayer = currentLayer else { return }
        shapeLayer.path = shapePath(from: start, to: pt).cgPath
    }

    override func mouseUp(with event: NSEvent) {
        let pt = convert(event.locationInWindow, from: nil)
        guard let start = startPoint else { cancelShape(); return }
        let dx = abs(pt.x - start.x)
        let dy = abs(pt.y - start.y)
        let minDist: CGFloat = (shapeType == .line || shapeType == .arrow) ? 10 : 15
        guard max(dx, dy) >= minDist else { cancelShape(); return }
        currentLayer?.path = shapePath(from: start, to: pt).cgPath
        commitShape(start: start, end: pt)
    }

    private func cancelShape() {
        currentLayer?.removeFromSuperlayer()
        currentLayer = nil
        startPoint = nil
    }

    private func shapePath(from start: CGPoint, to end: CGPoint) -> PlatformBezierPath {
        let rect = CGRect(x: min(start.x, end.x), y: min(start.y, end.y), width: abs(end.x - start.x), height: abs(end.y - start.y))
        switch shapeType {
        case .rectangle: return PlatformBezierPath(rect: rect)
        case .circle: return PlatformBezierPath(ovalIn: rect)
        case .line:
            let path = PlatformBezierPath()
            path.move(to: start)
            path.addLine(to: end)
            return path
        case .arrow: return arrowPath(from: start, to: end)
        default: return PlatformBezierPath(rect: rect)
        }
    }

    private func arrowPath(from start: CGPoint, to end: CGPoint) -> PlatformBezierPath {
        let path = PlatformBezierPath()
        path.move(to: start)
        path.addLine(to: end)
        let headLength: CGFloat = max(15, strokeWidth * 4)
        let headAngle: CGFloat = .pi / 6
        let angle = atan2(end.y - start.y, end.x - start.x)
        let p1 = CGPoint(x: end.x - headLength * cos(angle - headAngle), y: end.y - headLength * sin(angle - headAngle))
        let p2 = CGPoint(x: end.x - headLength * cos(angle + headAngle), y: end.y - headLength * sin(angle + headAngle))
        path.move(to: p1)
        path.addLine(to: end)
        path.addLine(to: p2)
        return path
    }

    private func commitShape(start: CGPoint, end: CGPoint) {
        guard let pdfView = pdfView else { cancelShape(); return }
        let center = CGPoint(x: (start.x + end.x) / 2, y: (start.y + end.y) / 2)
        let centerInPDFView = convert(center, to: pdfView)
        guard let page = pdfView.page(for: centerInPDFView, nearest: true) else { cancelShape(); return }
        let startInPDF = convert(start, to: pdfView)
        let endInPDF = convert(end, to: pdfView)
        let pageStart = pdfView.convert(startInPDF, to: page)
        let pageEnd = pdfView.convert(endInPDF, to: page)
        let annotation = buildAnnotation(pageStart: pageStart, pageEnd: pageEnd, page: page)
        page.addAnnotation(annotation)
        onShapeCommitted?(annotation, page)
        currentLayer?.removeFromSuperlayer()
        currentLayer = nil
        startPoint = nil
        if annotation is STLineAnnotation {
            pdfView.layoutDocumentView()
            func invalidate(_ view: NSView) {
                view.needsDisplay = true
                view.layer?.setNeedsDisplay()
                for sublayer in view.layer?.sublayers ?? [] { sublayer.setNeedsDisplay() }
                for child in view.subviews { invalidate(child) }
            }
            invalidate(pdfView)
        } else {
            pdfView.needsDisplay = true
        }
    }

    private func buildAnnotation(pageStart: CGPoint, pageEnd: CGPoint, page: PDFPage) -> PDFAnnotation {
        let pad = max(strokeWidth, 2) * 2
        switch shapeType {
        case .line, .arrow: return buildLineAnnotation(start: pageStart, end: pageEnd, padding: pad)
        case .circle: return buildCircleAnnotation(start: pageStart, end: pageEnd)
        default: return buildRectAnnotation(start: pageStart, end: pageEnd)
        }
    }

    private func buildLineAnnotation(start: CGPoint, end: CGPoint, padding: CGFloat) -> PDFAnnotation {
        let bounds = CGRect(x: min(start.x, end.x) - padding, y: min(start.y, end.y) - padding,
                           width: max(abs(end.x - start.x), 1) + padding * 2, height: max(abs(end.y - start.y), 1) + padding * 2)
        return STLineAnnotation(bounds: bounds, start: start, end: end, strokeWidth: strokeWidth,
                               color: strokeColor.withAlphaComponent(strokeOpacity), arrowHead: shapeType == .arrow)
    }

    private func buildRectAnnotation(start: CGPoint, end: CGPoint) -> PDFAnnotation {
        let bounds = CGRect(x: min(start.x, end.x), y: min(start.y, end.y),
                           width: max(abs(end.x - start.x), 1), height: max(abs(end.y - start.y), 1))
        let annotation = PDFAnnotation(bounds: bounds, forType: .square, withProperties: nil)
        annotation.color = strokeColor.withAlphaComponent(strokeOpacity)
        let border = PDFBorder(); border.lineWidth = strokeWidth; annotation.border = border
        return annotation
    }

    private func buildCircleAnnotation(start: CGPoint, end: CGPoint) -> PDFAnnotation {
        let bounds = CGRect(x: min(start.x, end.x), y: min(start.y, end.y),
                           width: max(abs(end.x - start.x), 1), height: max(abs(end.y - start.y), 1))
        let annotation = PDFAnnotation(bounds: bounds, forType: .circle, withProperties: nil)
        annotation.color = strokeColor.withAlphaComponent(strokeOpacity)
        let border = PDFBorder(); border.lineWidth = strokeWidth; annotation.border = border
        return annotation
    }
}
#endif
