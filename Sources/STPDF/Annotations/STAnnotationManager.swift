import SwiftUI
import PDFKit
import STKit

/// Central manager for annotation state and operations
@MainActor
final class STAnnotationManager: ObservableObject {

    /// Currently active annotation tool (nil = viewer mode)
    @Published var activeTool: STAnnotationType? = nil

    /// Current style for the active tool
    @Published var activeStyle: STAnnotationStyle = .defaultStyle(for: .ink)

    /// Selected tool within each group (remembers last used variant)
    @Published var selectedToolPerGroup: [STAnnotationGroup: STAnnotationType] = [
        .drawing: .ink,
        .shapes: .rectangle,
        .text: .freeText,
        .markup: .textHighlight,
        .extras: .signature
    ]

    /// Whether the property inspector is showing
    @Published var isPropertyInspectorVisible = false

    /// Whether the user has selected text (for markup tools)
    @Published var hasTextSelection = false

    /// Whether the signature capture sheet is showing
    @Published var isSignatureCaptureVisible = false

    /// Whether the stamp picker sheet is showing
    @Published var isStampPickerVisible = false

    /// Whether the photo picker sheet is showing
    @Published var isPhotoPickerVisible = false

    /// Selected photo image (for placement mode)
    @Published var selectedPhotoImage: PlatformImage?

    /// Selected stamp type (for placement mode)
    @Published var selectedStampType: STStampType?

    /// Currently selected annotation (for move/resize/context menu)
    @Published var selectedAnnotation: PDFAnnotation?

    /// The page of the selected annotation
    @Published var selectedAnnotationPage: PDFPage?

    /// Currently multi-selected annotations (marquee selection)
    @Published var multiSelectedAnnotations: [PDFAnnotation] = []

    /// The page of multi-selected annotations
    @Published var multiSelectionPage: PDFPage?

    /// Whether multiple annotations are selected
    var hasMultiSelection: Bool { !multiSelectedAnnotations.isEmpty }

    /// Whether marquee (drag-to-select) mode is enabled
    @Published var isMarqueeSelectEnabled = false

    /// Whether a note editor for a selected annotation is showing
    @Published var isAnnotationNoteEditorVisible = false

    /// Whether a text removal operation is in progress (for progress overlay)
    @Published var isProcessingTextRemoval = false

    /// Reference to the PDF view (set by STPDFViewWrapper)
    weak var pdfView: PDFView?

    /// The undo manager
    let undoManager = STUndoManager()

    /// The document being annotated
    let document: STPDFDocument

    /// Whether the PDFView is currently using page view controller (for zoom toggle)
    private var isPageVCEnabled = true

    // MARK: - Markup observation
    private var selectionObserver: NSObjectProtocol?

    init(document: STPDFDocument) {
        self.document = document
    }

    // MARK: - Tool Management

    /// Whether selection mode is active (annotation mode on, no specific tool selected)
    var isSelectionMode: Bool {
        activeTool == nil
    }

    /// Toggle marquee (drag-to-select) mode. Switches to selection mode if a tool is active.
    func toggleMarqueeSelect() {
        if isMarqueeSelectEnabled {
            isMarqueeSelectEnabled = false
        } else {
            if activeTool != nil {
                setTool(nil)
            }
            isMarqueeSelectEnabled = true
        }
    }

    /// Select an annotation for editing
    func selectAnnotation(_ annotation: PDFAnnotation, on page: PDFPage) {
        multiSelectedAnnotations.removeAll()
        multiSelectionPage = nil
        selectedAnnotation = annotation
        selectedAnnotationPage = page
    }

    /// Clear the current annotation selection (single + multi)
    func clearAnnotationSelection() {
        selectedAnnotation = nil
        selectedAnnotationPage = nil
        isAnnotationNoteEditorVisible = false
        multiSelectedAnnotations.removeAll()
        multiSelectionPage = nil
    }

    /// Delete the currently selected annotation
    func deleteSelectedAnnotation() {
        guard let annotation = selectedAnnotation,
              let page = selectedAnnotationPage else { return }
        let needsNuclear = annotation is STImageAnnotation || annotation is STStampAnnotation
        clearAnnotationSelection()
        page.removeAnnotation(annotation)
        undoManager.record(.remove(annotation: annotation, page: page))
        if needsNuclear {
            nuclearPDFViewRedraw()
        } else {
            forcePDFViewRedraw()
        }
        STHaptics.impact(.medium)
    }

    // MARK: - Multi-Selection

    /// Select multiple annotations (from marquee selection)
    func selectMultipleAnnotations(_ annotations: [PDFAnnotation], on page: PDFPage) {
        selectedAnnotation = nil
        selectedAnnotationPage = nil
        isAnnotationNoteEditorVisible = false
        multiSelectedAnnotations = annotations
        multiSelectionPage = page
    }

    /// Delete all multi-selected annotations
    func deleteMultiSelectedAnnotations() {
        guard let page = multiSelectionPage else { return }
        let annotations = multiSelectedAnnotations
        let needsNuclear = annotations.contains { $0 is STImageAnnotation || $0 is STStampAnnotation }
        multiSelectedAnnotations.removeAll()
        multiSelectionPage = nil
        for annotation in annotations {
            page.removeAnnotation(annotation)
            undoManager.record(.remove(annotation: annotation, page: page))
        }
        if needsNuclear {
            nuclearPDFViewRedraw()
        } else {
            forcePDFViewRedraw()
        }
        STHaptics.impact(.medium)
    }

    // MARK: - Copy / Paste

    /// Internal annotation clipboard
    private(set) var copiedAnnotation: PDFAnnotation?
    private(set) var copiedAnnotationPage: PDFPage?

    /// Copy the currently selected annotation to the internal clipboard.
    func copySelectedAnnotation() {
        guard let annotation = selectedAnnotation,
              let page = selectedAnnotationPage else { return }
        copiedAnnotation = annotation
        copiedAnnotationPage = page
        STHaptics.impact(.light)
    }

    /// Paste the copied annotation onto the given page (or same page) with a small offset.
    func pasteAnnotation(on targetPage: PDFPage? = nil) {
        guard let source = copiedAnnotation,
              let sourcePage = copiedAnnotationPage else { return }
        let page = targetPage ?? sourcePage
        let offset: CGFloat = 20

        let clone = cloneAnnotation(source, offset: CGPoint(x: offset, y: -offset))
        page.addAnnotation(clone)
        undoManager.record(.add(annotation: clone, page: page))

        // Select the newly pasted annotation
        selectAnnotation(clone, on: page)

        // Force redraw for custom-drawn annotations
        if clone is STInkAnnotation || clone is STLineAnnotation || clone is STImageAnnotation || clone is STStampAnnotation {
            forcePDFViewRedraw()
        }

        STHaptics.impact(.light)
    }

    private func cloneAnnotation(_ source: PDFAnnotation, offset: CGPoint) -> PDFAnnotation {
        var newBounds = source.bounds
        newBounds.origin.x += offset.x
        newBounds.origin.y += offset.y

        // Clone STStampAnnotation with offset bounds
        if let stampSource = source as? STStampAnnotation {
            let clone = STStampAnnotation(bounds: newBounds, text: stampSource.stampText, color: stampSource.stampColor)
            clone.contents = source.contents
            return clone
        }

        // Clone STImageAnnotation (signature) with offset bounds
        if let imageSource = source as? STImageAnnotation {
            let clone = STImageAnnotation(bounds: newBounds, image: imageSource.image)
            clone.contents = source.contents
            return clone
        }

        // Clone STInkAnnotation with offset points
        if let inkSource = source as? STInkAnnotation {
            let points = inkSource.getInkPoints()
            let offsetPoints = points.map { CGPoint(x: $0.x + offset.x, y: $0.y + offset.y) }
            let clone = STInkAnnotation(
                bounds: newBounds,
                points: offsetPoints,
                strokeWidth: inkSource.inkStrokeWidth,
                color: inkSource.inkColor
            )
            clone.contents = source.contents
            return clone
        }

        // Clone STLineAnnotation with offset points
        if let lineSource = source as? STLineAnnotation {
            let clone = STLineAnnotation(
                bounds: newBounds,
                start: CGPoint(x: lineSource.lineStart.x + offset.x, y: lineSource.lineStart.y + offset.y),
                end: CGPoint(x: lineSource.lineEnd.x + offset.x, y: lineSource.lineEnd.y + offset.y),
                strokeWidth: lineSource.lineStrokeWidth,
                color: lineSource.lineColor,
                arrowHead: lineSource.hasArrowHead
            )
            clone.contents = source.contents
            return clone
        }

        // Standard annotation types
        let subtypeRaw = source.type ?? "Square"
        let clone = PDFAnnotation(bounds: newBounds, forType: PDFAnnotationSubtype(rawValue: subtypeRaw), withProperties: nil)
        clone.color = source.color
        if let srcBorder = source.border {
            let newBorder = PDFBorder()
            newBorder.lineWidth = srcBorder.lineWidth
            newBorder.style = srcBorder.style
            clone.border = newBorder
        }
        clone.contents = source.contents
        // FreeText: copy font/color
        if source.type == "FreeText" {
            clone.font = source.font
            clone.fontColor = source.fontColor
            clone.alignment = source.alignment
        }

        return clone
    }

    // MARK: - Inspector → Selected Annotation

    /// Populate activeStyle from the currently selected annotation's properties.
    /// Call this before opening the inspector from the selection menu.
    func populateStyleFromSelectedAnnotation() {
        guard let annotation = selectedAnnotation else { return }

        if let inkAnnotation = annotation as? STInkAnnotation {
            activeStyle.color = inkAnnotation.inkColor
            activeStyle.lineWidth = inkAnnotation.inkStrokeWidth
            let alpha = inkAnnotation.inkColor.cgColor.alpha
            activeStyle.opacity = alpha > 0 ? alpha : 1.0
        } else if let lineAnnotation = annotation as? STLineAnnotation {
            activeStyle.color = lineAnnotation.lineColor
            activeStyle.lineWidth = lineAnnotation.lineStrokeWidth
            let alpha = lineAnnotation.lineColor.cgColor.alpha
            activeStyle.opacity = alpha > 0 ? alpha : 1.0
        } else if annotation.type == "FreeText" {
            activeStyle.color = annotation.fontColor ?? .black
            activeStyle.fontSize = annotation.font?.pointSize ?? 16
            activeStyle.fontName = annotation.font?.fontName ?? "Helvetica"
            activeStyle.opacity = 1.0
        } else {
            activeStyle.color = annotation.color
            activeStyle.lineWidth = annotation.border?.lineWidth ?? 2.0
            let alpha = annotation.color.cgColor.alpha
            activeStyle.opacity = alpha > 0 ? alpha : 1.0
        }
    }

    /// Apply the current activeStyle to the selected annotation.
    /// Called when the inspector's style controls change while an annotation is selected.
    func applyStyleToSelectedAnnotation() {
        guard let annotation = selectedAnnotation else { return }

        let color = activeStyle.color.withAlphaComponent(activeStyle.opacity)

        if let inkAnnotation = annotation as? STInkAnnotation {
            inkAnnotation.applyStyle(color: color, strokeWidth: activeStyle.lineWidth)
        } else if let lineAnnotation = annotation as? STLineAnnotation {
            lineAnnotation.applyStyle(color: color, strokeWidth: activeStyle.lineWidth)
        } else if annotation.type == "FreeText" {
            annotation.fontColor = activeStyle.color
            annotation.font = PlatformFont(name: activeStyle.fontName, size: activeStyle.fontSize)
                ?? .systemFont(ofSize: activeStyle.fontSize)
            // freeText background stays clear
        } else {
            annotation.color = color
            if annotation.border != nil {
                let newBorder = PDFBorder()
                newBorder.lineWidth = activeStyle.lineWidth
                annotation.border = newBorder
            }
        }

        forcePDFViewRedraw()
    }

    /// Force PDFView to re-render all tiles (needed after style/ink/image changes).
    func forcePDFViewRedraw() {
        guard let pdfView = pdfView else { return }
        pdfView.layoutDocumentView()
        #if os(iOS)
        func invalidate(_ view: UIView) {
            view.setNeedsDisplay()
            view.layer.setNeedsDisplay()
            for sublayer in view.layer.sublayers ?? [] { sublayer.setNeedsDisplay() }
            for child in view.subviews { invalidate(child) }
        }
        #elseif os(macOS)
        func invalidate(_ view: NSView) {
            view.needsDisplay = true
            view.layer?.setNeedsDisplay()
            for sublayer in view.layer?.sublayers ?? [] { sublayer.setNeedsDisplay() }
            for child in view.subviews { invalidate(child) }
        }
        #endif
        invalidate(pdfView)
    }

    // MARK: - Zoom

    func zoomIn() {
        guard let pdfView = pdfView else { return }
        let currentPage = pdfView.currentPage
        // Disable page view controller so horizontal pan/scroll works when zoomed
        #if os(iOS)
        if isPageVCEnabled {
            pdfView.usePageViewController(false)
            isPageVCEnabled = false
        }
        #endif
        pdfView.autoScales = false
        let maxZoom = pdfView.scaleFactorForSizeToFit * 3
        let newScale = min(pdfView.scaleFactor * 1.15, maxZoom)
        pdfView.scaleFactor = newScale
        if let page = currentPage { pdfView.go(to: page) }
    }

    func zoomOut() {
        guard let pdfView = pdfView else { return }
        let currentPage = pdfView.currentPage
        let fitScale = pdfView.scaleFactorForSizeToFit
        let newScale = max(pdfView.scaleFactor / 1.15, pdfView.minScaleFactor)
        if newScale <= fitScale {
            // Back to fit — re-enable autoScales + page view controller
            pdfView.autoScales = true
            #if os(iOS)
            if !isPageVCEnabled {
                pdfView.usePageViewController(true)
                isPageVCEnabled = true
            }
            #endif
            if let page = currentPage { pdfView.go(to: page) }
        } else {
            pdfView.scaleFactor = newScale
        }
    }

    /// Nuclear redraw: re-set the document on the PDFView to force CATiledLayer
    /// to completely discard all cached tiles and re-render from scratch.
    /// Use for operations where standard invalidation fails (removing custom-drawn annotations).
    func nuclearPDFViewRedraw() {
        guard let pdfView = pdfView else { return }
        let doc = pdfView.document
        let currentPage = pdfView.currentPage
        pdfView.document = nil
        pdfView.document = doc
        if let page = currentPage {
            pdfView.go(to: page)
        }
    }

    // MARK: - Annotation Ordering (Z-Order)

    func bringAnnotationToFront() {
        guard let annotation = selectedAnnotation,
              let page = selectedAnnotationPage else { return }
        reorderAnnotation(annotation, on: page, toIndex: page.annotations.count)
    }

    func bringAnnotationForward() {
        guard let annotation = selectedAnnotation,
              let page = selectedAnnotationPage else { return }
        guard let idx = page.annotations.firstIndex(where: { $0 === annotation }),
              idx < page.annotations.count - 1 else { return }
        reorderAnnotation(annotation, on: page, toIndex: idx + 1)
    }

    func sendAnnotationBackward() {
        guard let annotation = selectedAnnotation,
              let page = selectedAnnotationPage else { return }
        guard let idx = page.annotations.firstIndex(where: { $0 === annotation }),
              idx > 0 else { return }
        reorderAnnotation(annotation, on: page, toIndex: idx - 1)
    }

    func sendAnnotationToBack() {
        guard let annotation = selectedAnnotation,
              let page = selectedAnnotationPage else { return }
        reorderAnnotation(annotation, on: page, toIndex: 0)
    }

    private func reorderAnnotation(_ annotation: PDFAnnotation, on page: PDFPage, toIndex: Int) {
        let annotations = page.annotations
        for a in annotations { page.removeAnnotation(a) }
        var newOrder = annotations.filter { $0 !== annotation }
        let clamped = max(0, min(toIndex, newOrder.count))
        newOrder.insert(annotation, at: clamped)
        for a in newOrder { page.addAnnotation(a) }
        nuclearPDFViewRedraw()
        // Re-select so visuals refresh
        selectAnnotation(annotation, on: page)
    }

    /// Add/edit a note on the selected annotation
    func setNoteOnSelectedAnnotation(_ text: String) {
        guard let annotation = selectedAnnotation else { return }
        annotation.contents = text
        isAnnotationNoteEditorVisible = false
    }

    /// Set the active tool and update style to match
    func setTool(_ type: STAnnotationType?) {
        stopMarkupObservation()
        clearAnnotationSelection()
        // Clear stamp/photo placement state when switching tools
        if type != .stamp {
            selectedStampType = nil
        }
        if type != .photo {
            selectedPhotoImage = nil
        }
        // Disable marquee mode when a specific tool is selected
        if type != nil {
            isMarqueeSelectEnabled = false
        }
        activeTool = type
        if let type = type {
            activeStyle = STAnnotationStyle.defaultStyle(for: type)
            if type.requiresTextSelection {
                startMarkupObservation()
            }
            // Show capture/picker for these tools
            if type == .signature {
                isSignatureCaptureVisible = true
            } else if type == .stamp {
                isStampPickerVisible = true
            } else if type == .photo {
                isPhotoPickerVisible = true
            }
        }
    }

    /// Toggle a tool on/off
    func toggleTool(_ type: STAnnotationType) {
        if activeTool == type {
            stopMarkupObservation()
            activeTool = nil
        } else {
            setTool(type)
            // Remember selected variant in group
            for group in STAnnotationGroup.allCases where group.tools.contains(type) {
                selectedToolPerGroup[group] = type
            }
        }
    }

    /// Exit annotation mode
    func deactivate() {
        stopMarkupObservation()
        clearAnnotationSelection()
        activeTool = nil
        isMarqueeSelectEnabled = false
        isPropertyInspectorVisible = false
        isSignatureCaptureVisible = false
        isStampPickerVisible = false
        isPhotoPickerVisible = false
        selectedStampType = nil
        selectedPhotoImage = nil
    }

    // MARK: - Ink Annotation

    /// Add an ink annotation from collected points
    func addInkAnnotation(points: [[CGPoint]], on page: PDFPage) {
        guard !points.isEmpty else { return }

        let allPoints = points.flatMap { $0 }
        guard !allPoints.isEmpty else { return }

        let padding = activeStyle.lineWidth * 2
        let minX = allPoints.map(\.x).min()! - padding
        let minY = allPoints.map(\.y).min()! - padding
        let maxX = allPoints.map(\.x).max()! + padding
        let maxY = allPoints.map(\.y).max()! + padding
        let bounds = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)

        let annotation = PDFAnnotation(bounds: bounds, forType: .ink, withProperties: nil)

        for stroke in points {
            guard stroke.count >= 2 else { continue }
            let path = PlatformBezierPath()
            path.move(to: stroke[0])
            for i in 1..<stroke.count {
                path.addLine(to: stroke[i])
            }
            annotation.add(path)
        }

        annotation.color = activeStyle.color.withAlphaComponent(activeStyle.opacity)
        let border = PDFBorder()
        border.lineWidth = activeStyle.lineWidth
        annotation.border = border

        page.addAnnotation(annotation)
        undoManager.record(.add(annotation: annotation, page: page))
    }

    // MARK: - Free Text Annotation

    /// Add a free text annotation. Returns the annotation for auto-selection.
    @discardableResult
    func addTextAnnotation(text: String, at pdfPoint: CGPoint, on page: PDFPage) -> PDFAnnotation? {
        guard !text.isEmpty else { return nil }

        let font = PlatformFont(name: activeStyle.fontName, size: activeStyle.fontSize) ?? .systemFont(ofSize: activeStyle.fontSize)
        let textSize = (text as NSString).size(withAttributes: [.font: font])
        let padding: CGFloat = 8

        let bounds = CGRect(
            x: pdfPoint.x,
            y: pdfPoint.y - textSize.height - padding,
            width: textSize.width + padding * 2,
            height: textSize.height + padding * 2
        )

        let annotation = PDFAnnotation(bounds: bounds, forType: .freeText, withProperties: nil)
        annotation.contents = text
        annotation.font = font
        annotation.fontColor = activeStyle.color
        annotation.color = .clear
        annotation.alignment = .left

        page.addAnnotation(annotation)
        undoManager.record(.add(annotation: annotation, page: page))
        return annotation
    }

    // MARK: - Markup Annotation (Highlight / Underline / Strikethrough)

    /// Add a text markup annotation
    func addMarkupAnnotation(type: STAnnotationType, selections: [PDFSelection], on page: PDFPage) {
        guard let subtype = type.pdfSubtype else { return }

        for selection in selections {
            let bounds = selection.bounds(for: page)
            guard bounds.width > 0 && bounds.height > 0 else { continue }

            let annotation = PDFAnnotation(bounds: bounds, forType: subtype, withProperties: nil)
            annotation.color = activeStyle.color.withAlphaComponent(activeStyle.opacity)

            page.addAnnotation(annotation)
            undoManager.record(.add(annotation: annotation, page: page))
        }
    }

    /// Apply the current markup tool to the selected text, then clear selection
    func applyMarkup() {
        guard let pdfView = pdfView,
              let selection = pdfView.currentSelection,
              let tool = activeTool,
              tool.requiresTextSelection else { return }

        let lineSelections = selection.selectionsByLine()
        for page in selection.pages {
            addMarkupAnnotation(type: tool, selections: lineSelections, on: page)
        }

        pdfView.clearSelection()
        hasTextSelection = false

        STHaptics.impact(.light)
    }

    // MARK: - Note Annotation

    /// Add a sticky note annotation
    func addNoteAnnotation(text: String, at pdfPoint: CGPoint, on page: PDFPage) {
        guard !text.isEmpty else { return }

        let size: CGFloat = 24
        let bounds = CGRect(
            x: pdfPoint.x - size / 2,
            y: pdfPoint.y - size / 2,
            width: size,
            height: size
        )

        let annotation = PDFAnnotation(bounds: bounds, forType: .text, withProperties: nil)
        annotation.contents = text
        annotation.color = activeStyle.color

        page.addAnnotation(annotation)
        undoManager.record(.add(annotation: annotation, page: page))

        STHaptics.impact(.light)
    }

    // MARK: - Stamp Annotation

    /// Add a stamp annotation
    func addStampAnnotation(type: STStampType, at pdfPoint: CGPoint, on page: PDFPage) {
        let annotation = STStampBuilder.buildStamp(type: type, at: pdfPoint, on: page)
        page.addAnnotation(annotation)
        undoManager.record(.add(annotation: annotation, page: page))

        // Switch to selection mode and auto-select the new annotation
        selectedStampType = nil
        activeTool = nil
        selectAnnotation(annotation, on: page)
        forcePDFViewRedraw()

        STHaptics.impact(.light)
    }

    // MARK: - Signature Annotation

    /// Add a signature image as an annotation
    func addSignatureAnnotation(image: PlatformImage, at pdfPoint: CGPoint, on page: PDFPage) {
        let annotation = STSignaturePlacer.placeSignature(image: image, at: pdfPoint, on: page)
        page.addAnnotation(annotation)
        undoManager.record(.add(annotation: annotation, page: page))

        // Switch to selection mode and auto-select the new annotation
        activeTool = nil
        selectAnnotation(annotation, on: page)
        forcePDFViewRedraw()

        STHaptics.impact(.light)
    }

    // MARK: - Photo Annotation

    /// Add a photo image as an annotation
    func addPhotoAnnotation(image: PlatformImage, at pdfPoint: CGPoint, on page: PDFPage) {
        let annotation = STSignaturePlacer.placeSignature(
            image: image, at: pdfPoint, on: page,
            maxWidth: 300, maxHeight: 300
        )
        page.addAnnotation(annotation)
        undoManager.record(.add(annotation: annotation, page: page))

        selectedPhotoImage = nil
        activeTool = nil
        selectAnnotation(annotation, on: page)
        forcePDFViewRedraw()

        STHaptics.impact(.light)
    }

    // MARK: - Text Edit (CSP + Annotation Fallback)

    /// Replace PDF text. Tries Content Stream Parsing first (true edit),
    /// falls back to white-background FreeText annotation if CSP fails.
    func replaceText(
        editedText: String,
        originalText: String,
        originalBounds: CGRect,
        on page: PDFPage
    ) {
        guard !editedText.isEmpty else { return }
        guard let pdfView = pdfView,
              let pdfDoc = pdfView.document else { return }

        let pageIndex = pdfDoc.index(for: page)
        let occIdx = occurrenceIndex(of: originalText, at: originalBounds, on: page)

        // Try CSP (Content Stream Parsing) — true text replacement
        if editedText != originalText,
           let _ = STPDFTextReplacer.replaceText(
               in: pdfDoc,
               pageIndex: pageIndex,
               oldText: originalText,
               newText: editedText,
               occurrenceIndex: occIdx,
               targetBounds: originalBounds
           ) {
            // CSP succeeded — text is directly modified in the content stream
            activeTool = nil
            // Force PDFView to reload the modified document
            pdfView.document = pdfDoc
            if let newPage = pdfDoc.page(at: pageIndex) {
                pdfView.go(to: newPage)
            }
            STHaptics.impact(.medium)
            return
        }

        // Fallback: annotation-based replacement (white background FreeText)
        replaceTextWithAnnotation(editedText: editedText, originalBounds: originalBounds, on: page)
    }

    /// Annotation-based text replacement (fallback when CSP fails).
    /// Uses transparent background — original text may show through but no ugly white rectangle.
    @discardableResult
    private func replaceTextWithAnnotation(editedText: String, originalBounds: CGRect, on page: PDFPage) -> PDFAnnotation? {
        // Calculate font size to fit within original bounds
        var fontSize = max(originalBounds.height * 0.65, 8)
        let font = PlatformFont.systemFont(ofSize: fontSize)
        let textSize = (editedText as NSString).size(withAttributes: [.font: font])

        // Scale down if replacement text is significantly wider
        if textSize.width > originalBounds.width * 1.5 && originalBounds.width > 0 {
            fontSize *= (originalBounds.width / textSize.width)
        }

        let finalFont = PlatformFont.systemFont(ofSize: max(fontSize, 6))
        let finalTextSize = (editedText as NSString).size(withAttributes: [.font: finalFont])
        let newWidth = max(finalTextSize.width + 2, originalBounds.width)

        let bounds = CGRect(
            x: originalBounds.origin.x,
            y: originalBounds.origin.y,
            width: newWidth,
            height: originalBounds.height
        )

        let annotation = PDFAnnotation(bounds: bounds, forType: .freeText, withProperties: nil)
        annotation.contents = editedText
        annotation.font = finalFont
        annotation.fontColor = .black
        annotation.color = PlatformColor.clear
        annotation.alignment = .left

        let border = PDFBorder()
        border.lineWidth = 0
        annotation.border = border

        page.addAnnotation(annotation)
        undoManager.record(.add(annotation: annotation, page: page))

        activeTool = nil
        selectAnnotation(annotation, on: page)
        forcePDFViewRedraw()

        STHaptics.impact(.light)
        return annotation
    }

    /// Remove text via CSP (Content Stream Parsing) — directly removes text from the PDF binary.
    func removeText(originalText: String, bounds: CGRect, on page: PDFPage) {
        guard !isProcessingTextRemoval else { return }

        let pdfDocument = document.pdfDocument
        let pageIndex = pdfDocument.index(for: page)
        guard pageIndex >= 0, pageIndex < pdfDocument.pageCount else { return }

        let occIdx = occurrenceIndex(of: originalText, at: bounds, on: page)
        let targetBounds = bounds
        isProcessingTextRemoval = true

        // Defer to next run loop so SwiftUI can render the progress overlay
        Task {
            try? await Task.sleep(nanoseconds: 50_000_000) // Let overlay appear

            // CSP: replace text with empty string in content stream
            if let originalPage = STPDFTextReplacer.replaceText(
                in: pdfDocument,
                pageIndex: pageIndex,
                oldText: originalText,
                newText: "",
                occurrenceIndex: occIdx,
                targetBounds: targetBounds
            ) {
                undoManager.record(.replacePage(
                    document: pdfDocument,
                    pageIndex: pageIndex,
                    previousPage: originalPage
                ))
                // Nuclear redraw — overlay hides CATiledLayer flicker.
                // Must use nuclear (nil→re-set) so PDFView refreshes its internal
                // page references; direct re-set of same reference is ignored.
                nuclearPDFViewRedraw()
                // Wait for CATiledLayer to render new tiles behind overlay
                try? await Task.sleep(nanoseconds: 300_000_000)
                STHaptics.impact(.medium)
            } else {
                STHaptics.notification(.error)
            }

            isProcessingTextRemoval = false
        }
    }

    // MARK: - Occurrence Index Helper

    /// Determine which occurrence of `text` the user tapped, by comparing
    /// PDFSelection bounds of each occurrence against the tapped `bounds`.
    private func occurrenceIndex(of text: String, at bounds: CGRect, on page: PDFPage) -> Int {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let pageText = page.string else { return 0 }

        let nsText = pageText as NSString
        var occurrences: [(index: Int, range: NSRange)] = []
        var searchRange = NSRange(location: 0, length: nsText.length)
        var idx = 0

        while searchRange.location < nsText.length {
            let found = nsText.range(of: trimmed, options: [], range: searchRange)
            if found.location == NSNotFound { break }
            occurrences.append((index: idx, range: found))
            searchRange = NSRange(
                location: found.location + found.length,
                length: nsText.length - found.location - found.length
            )
            idx += 1
        }

        // Single or no occurrence — no disambiguation needed
        guard occurrences.count > 1 else { return 0 }

        // Find the occurrence whose PDFSelection bounds are closest to tapped bounds
        var bestIndex = 0
        var bestDist = CGFloat.greatestFiniteMagnitude
        for occ in occurrences {
            if let sel = page.selection(for: occ.range) {
                let selBounds = sel.bounds(for: page)
                let dist = hypot(selBounds.midX - bounds.midX, selBounds.midY - bounds.midY)
                if dist < bestDist {
                    bestDist = dist
                    bestIndex = occ.index
                }
            }
        }

        return bestIndex
    }

    // MARK: - Eraser

    /// Remove an annotation (eraser)
    func removeAnnotation(_ annotation: PDFAnnotation, from page: PDFPage) {
        page.removeAnnotation(annotation)
        undoManager.record(.remove(annotation: annotation, page: page))
    }

    // MARK: - Markup Observation (private)

    private func startMarkupObservation() {
        guard let pdfView = pdfView else { return }

        selectionObserver = NotificationCenter.default.addObserver(
            forName: .PDFViewSelectionChanged,
            object: pdfView,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                let selected = self.pdfView?.currentSelection?.string?.isEmpty == false
                if self.hasTextSelection != selected {
                    self.hasTextSelection = selected
                }
            }
        }
    }

    private func stopMarkupObservation() {
        if let observer = selectionObserver {
            NotificationCenter.default.removeObserver(observer)
            selectionObserver = nil
        }
        if hasTextSelection {
            hasTextSelection = false
        }
        pdfView?.clearSelection()
    }
}
