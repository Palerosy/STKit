import STKit
import SwiftUI
import PDFKit
#if os(macOS)
import UniformTypeIdentifiers
#endif

// MARK: - Coordinate Conversion Helper

private extension PDFView {
    /// Convert a SwiftUI gesture location to PDFView coordinates.
    /// On macOS, SwiftUI uses flipped coordinates (y from top) but PDFView uses standard NSView coords (y from bottom).
    func pointFromSwiftUI(_ point: CGPoint) -> CGPoint {
        #if os(macOS)
        return CGPoint(x: point.x, y: bounds.height - point.y)
        #else
        return point
        #endif
    }
}

/// SwiftUI PDF viewer that combines the PDFView with overlays
struct STPDFViewerView: View {

    @ObservedObject var viewModel: STPDFViewerViewModel
    let configuration: STPDFConfiguration
    @ObservedObject var annotationManager: STAnnotationManager
    let isAnnotationModeActive: Bool

    var body: some View {
        ZStack {
            STPDFViewWrapper(
                document: viewModel.document.pdfDocument,
                currentPageIndex: $viewModel.currentPageIndex,
                configuration: configuration,
                annotationManager: annotationManager,
                isAnnotationModeActive: isAnnotationModeActive,
                activeTool: annotationManager.activeTool,
                activeStyle: annotationManager.activeStyle,
                hasSelection: annotationManager.selectedAnnotation != nil,
                hasMultiSelection: annotationManager.hasMultiSelection,
                isMarqueeSelectEnabled: annotationManager.isMarqueeSelectEnabled
            )

            // Text input overlay (when freeText tool is active)
            if annotationManager.activeTool == .freeText {
                STTextInputOverlay(
                    onSubmit: { text, screenPoint in
                        if let pdfView = annotationManager.pdfView {
                            let viewPoint = pdfView.pointFromSwiftUI(screenPoint)
                            guard let page = pdfView.page(for: viewPoint, nearest: true) else { return }
                            let pdfPoint = pdfView.convert(viewPoint, to: page)
                            if let annotation = annotationManager.addTextAnnotation(text: text, at: pdfPoint, on: page) {
                                // Switch to selection mode and auto-select the new annotation
                                annotationManager.setTool(nil)
                                annotationManager.selectAnnotation(annotation, on: page)
                            }
                        }
                    },
                    onCancel: { }
                )
            }

            // Text remove overlay (when textRemove tool is active)
            if annotationManager.activeTool == .textRemove {
                STTextRemoveOverlay(
                    hitTestText: { screenPoint, mode in
                        guard let pdfView = annotationManager.pdfView else { return nil }
                        let viewPoint = pdfView.pointFromSwiftUI(screenPoint)
                        guard let page = pdfView.page(for: viewPoint, nearest: true) else { return nil }
                        let pdfPoint = pdfView.convert(viewPoint, to: page)
                        let selection: PDFSelection?
                        switch mode {
                        case .word:
                            selection = page.selectionForWord(at: pdfPoint)
                        case .line:
                            selection = page.selectionForLine(at: pdfPoint)
                        }
                        guard let sel = selection,
                              let text = sel.string,
                              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                            return nil
                        }
                        let bounds = sel.bounds(for: page)
                        guard bounds.width > 0, bounds.height > 0 else { return nil }
                        return STTextHitResult(text: text, bounds: bounds, page: page, selection: sel)
                    },
                    onHighlight: { selection in
                        annotationManager.pdfView?.highlightedSelections = selection.map { [$0] }
                    },
                    onRemove: { originalText, originalBounds, page in
                        annotationManager.pdfView?.highlightedSelections = nil
                        annotationManager.removeText(
                            originalText: originalText,
                            bounds: originalBounds,
                            on: page
                        )
                    },
                    onCancel: {
                        annotationManager.pdfView?.highlightedSelections = nil
                    }
                )
                .onDisappear {
                    annotationManager.pdfView?.highlightedSelections = nil
                }
            }

            // Note input overlay (when note tool is active)
            if annotationManager.activeTool == .note {
                STNoteInputOverlay(
                    onSubmit: { text, screenPoint in
                        if let pdfView = annotationManager.pdfView {
                            let viewPoint = pdfView.pointFromSwiftUI(screenPoint)
                            guard let page = pdfView.page(for: viewPoint, nearest: true) else { return }
                            let pdfPoint = pdfView.convert(viewPoint, to: page)
                            annotationManager.addNoteAnnotation(text: text, at: pdfPoint, on: page)
                        }
                    },
                    onEditExisting: { annotation, text in
                        annotation.contents = text
                    },
                    hitTestNote: { screenPoint in
                        guard let pdfView = annotationManager.pdfView else { return nil }
                        let viewPoint = pdfView.pointFromSwiftUI(screenPoint)
                        guard let page = pdfView.page(for: viewPoint, nearest: true) else { return nil }
                        let pdfPoint = pdfView.convert(viewPoint, to: page)
                        let hitRadius: CGFloat = 15
                        let hitRect = CGRect(x: pdfPoint.x - hitRadius, y: pdfPoint.y - hitRadius,
                                             width: hitRadius * 2, height: hitRadius * 2)
                        return page.annotations.reversed().first {
                            $0.type == "Text" && $0.bounds.intersects(hitRect)
                        }
                    },
                    onCancel: { }
                )
            }

            // Photo placement overlay (when a photo is selected)
            if annotationManager.activeTool == .photo,
               annotationManager.selectedPhotoImage != nil {
                STPhotoPlacementOverlay(
                    onPlace: { screenPoint in
                        if let pdfView = annotationManager.pdfView {
                            let viewPoint = pdfView.pointFromSwiftUI(screenPoint)
                            guard let page = pdfView.page(for: viewPoint, nearest: true),
                                  let image = annotationManager.selectedPhotoImage else { return }
                            let pdfPoint = pdfView.convert(viewPoint, to: page)
                            annotationManager.addPhotoAnnotation(image: image, at: pdfPoint, on: page)
                        }
                    },
                    onCancel: {
                        annotationManager.selectedPhotoImage = nil
                    }
                )
            }

            // Stamp placement overlay (when stamp type is selected)
            if annotationManager.activeTool == .stamp,
               let stampType = annotationManager.selectedStampType {
                STStampPlacementOverlay(
                    stampType: stampType,
                    onPlace: { screenPoint in
                        if let pdfView = annotationManager.pdfView {
                            let viewPoint = pdfView.pointFromSwiftUI(screenPoint)
                            guard let page = pdfView.page(for: viewPoint, nearest: true) else { return }
                            let pdfPoint = pdfView.convert(viewPoint, to: page)
                            annotationManager.addStampAnnotation(type: stampType, at: pdfPoint, on: page)
                        }
                    },
                    onCancel: {
                        annotationManager.selectedStampType = nil
                    }
                )
            }

            // Markup apply button (when text is selected with a markup tool)
            if let tool = annotationManager.activeTool,
               tool.requiresTextSelection,
               annotationManager.hasTextSelection {
                VStack {
                    Spacer()
                    STMarkupApplyButton(
                        onApply: { annotationManager.applyMarkup() },
                        toolType: tool
                    )
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: annotationManager.hasTextSelection)
            }

            // Selection context menu (when a non-FreeText annotation is selected)
            if let selected = annotationManager.selectedAnnotation, selected.type != "FreeText" {
                VStack {
                    STSelectionMenuBar(
                        onCopy: {
                            annotationManager.copySelectedAnnotation()
                        },
                        onPaste: annotationManager.copiedAnnotation != nil ? {
                            annotationManager.pasteAnnotation()
                        } : nil,
                        onDelete: {
                            annotationManager.deleteSelectedAnnotation()
                        },
                        onInspector: {
                            annotationManager.populateStyleFromSelectedAnnotation()
                            annotationManager.isPropertyInspectorVisible = true
                        },
                        onNote: {
                            annotationManager.isAnnotationNoteEditorVisible = true
                        },
                        onBringToFront: {
                            annotationManager.bringAnnotationToFront()
                        },
                        onBringForward: {
                            annotationManager.bringAnnotationForward()
                        },
                        onSendBackward: {
                            annotationManager.sendAnnotationBackward()
                        },
                        onSendToBack: {
                            annotationManager.sendAnnotationToBack()
                        },
                        onDismiss: {
                            annotationManager.clearAnnotationSelection()
                        }
                    )
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))

                    Spacer()
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: annotationManager.selectedAnnotation != nil)
            }

            // FreeText editing bar (when a FreeText annotation is selected)
            if let selected = annotationManager.selectedAnnotation, selected.type == "FreeText" {
                VStack {
                    // Top row: Copy / Delete / Note / Order / Dismiss
                    STSelectionMenuBar(
                        onCopy: {
                            annotationManager.copySelectedAnnotation()
                        },
                        onPaste: annotationManager.copiedAnnotation != nil ? {
                            annotationManager.pasteAnnotation()
                        } : nil,
                        onDelete: {
                            annotationManager.deleteSelectedAnnotation()
                        },
                        onInspector: nil,
                        onNote: {
                            annotationManager.isAnnotationNoteEditorVisible = true
                        },
                        onBringToFront: {
                            annotationManager.bringAnnotationToFront()
                        },
                        onBringForward: {
                            annotationManager.bringAnnotationForward()
                        },
                        onSendBackward: {
                            annotationManager.sendAnnotationBackward()
                        },
                        onSendToBack: {
                            annotationManager.sendAnnotationToBack()
                        },
                        onDismiss: {
                            annotationManager.clearAnnotationSelection()
                        }
                    )
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))

                    Spacer()

                    // Bottom editing bar with font/size/color
                    STFreeTextEditingBar(annotationManager: annotationManager)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: annotationManager.selectedAnnotation != nil)
                .onAppear {
                    annotationManager.populateStyleFromSelectedAnnotation()
                }
            }

            // Multi-selection context menu (when annotations are selected via marquee)
            if annotationManager.hasMultiSelection {
                VStack {
                    HStack(spacing: 0) {
                        // Selected count badge
                        HStack(spacing: 5) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.accentColor)
                            Text("\(annotationManager.multiSelectedAnnotations.count)")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(.primary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 10)

                        Rectangle()
                            .fill(.quaternary)
                            .frame(width: 0.5, height: 24)

                        Button {
                            annotationManager.deleteMultiSelectedAnnotations()
                        } label: {
                            Text(STStrings.selectionDelete)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.red)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                        }

                        Rectangle()
                            .fill(.quaternary)
                            .frame(width: 0.5, height: 24)

                        Button {
                            annotationManager.clearAnnotationSelection()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                        }
                    }
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                    .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))

                    Spacer()
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: annotationManager.hasMultiSelection)
            }

            // Tool hint banner (small text at top when a tool is active)
            if let tool = annotationManager.activeTool,
               let hint = tool.hintText,
               annotationManager.selectedAnnotation == nil,
               !annotationManager.hasMultiSelection {
                VStack {
                    HStack(spacing: 6) {
                        Image(systemName: tool.iconName)
                            .font(.system(size: 12, weight: .medium))
                        Text(hint)
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .padding(.top, 8)

                    Spacer()
                }
                .allowsHitTesting(false)
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: annotationManager.activeTool)
            }

            // Text removal progress overlay
            if annotationManager.isProcessingTextRemoval {
                Color.black.opacity(0.15)
                    .ignoresSafeArea()
                    .overlay {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                            .padding(24)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .transition(.opacity)
            }

            // License watermark overlay (if unlicensed)
            if !STLicenseManager.shared.isLicensed {
                STLicenseWatermark()
            }
        }
        // Signature picker sheet (saved signatures + draw new)
        .sheet(isPresented: $annotationManager.isSignatureCaptureVisible) {
            STSignaturePickerView(
                strokeColor: annotationManager.activeStyle.color,
                strokeWidth: annotationManager.activeStyle.lineWidth,
                onSignatureSelected: { signatureImage in
                    annotationManager.isSignatureCaptureVisible = false
                    if let pdfView = annotationManager.pdfView,
                       let page = pdfView.currentPage {
                        let pageBounds = page.bounds(for: .mediaBox)
                        let center = CGPoint(x: pageBounds.midX, y: pageBounds.midY)
                        annotationManager.addSignatureAnnotation(image: signatureImage, at: center, on: page)
                    }
                },
                onCancel: {
                    annotationManager.isSignatureCaptureVisible = false
                }
            )
        }
        // Stamp picker sheet
        .sheet(isPresented: $annotationManager.isStampPickerVisible) {
            STStampPickerView(
                onStampSelected: { stampType in
                    annotationManager.isStampPickerVisible = false
                    annotationManager.selectedStampType = stampType
                },
                onCancel: {
                    annotationManager.isStampPickerVisible = false
                }
            )
        }
        // Photo picker
        #if os(macOS)
        .onChange(of: annotationManager.isPhotoPickerVisible) { visible in
            guard visible else { return }
            annotationManager.isPhotoPickerVisible = false
            let panel = NSOpenPanel()
            panel.allowedContentTypes = [.image]
            panel.allowsMultipleSelection = false
            panel.canChooseDirectories = false
            panel.canChooseFiles = true
            panel.begin { response in
                if response == .OK, let url = panel.url,
                   let image = NSImage(contentsOf: url) {
                    DispatchQueue.main.async {
                        annotationManager.selectedPhotoImage = image
                    }
                }
            }
        }
        #else
        .sheet(isPresented: $annotationManager.isPhotoPickerVisible) {
            STPHPickerView(
                onImageSelected: { image in
                    annotationManager.isPhotoPickerVisible = false
                    annotationManager.selectedPhotoImage = image
                },
                onCancel: {
                    annotationManager.isPhotoPickerVisible = false
                }
            )
        }
        #endif
        // Note editor sheet for selected annotation
        .sheet(isPresented: $annotationManager.isAnnotationNoteEditorVisible) {
            STAnnotationNoteEditor(
                currentText: annotationManager.selectedAnnotation?.contents ?? "",
                onSave: { text in
                    annotationManager.setNoteOnSelectedAnnotation(text)
                },
                onCancel: {
                    annotationManager.isAnnotationNoteEditorVisible = false
                }
            )
        }
    }
}

/// Simple note editor sheet for annotation comments
struct STAnnotationNoteEditor: View {
    let currentText: String
    let onSave: (String) -> Void
    let onCancel: () -> Void

    @State private var text: String = ""

    var body: some View {
        #if os(macOS)
        VStack(spacing: 0) {
            HStack {
                Button(STStrings.cancel) { onCancel() }
                    .buttonStyle(.plain)
                    .foregroundColor(.accentColor)
                Spacer()
                Text(STStrings.selectionNote)
                    .font(.headline)
                Spacer()
                Button(STStrings.done) { onSave(text) }
                    .buttonStyle(.plain)
                    .foregroundColor(.accentColor)
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            Divider()
            TextEditor(text: $text)
                .padding()
        }
        .frame(
            minWidth: (NSScreen.main?.frame.width ?? 1440) / 3,
            idealWidth: (NSScreen.main?.frame.width ?? 1440) / 2,
            minHeight: (NSScreen.main?.frame.height ?? 900) / 3,
            idealHeight: (NSScreen.main?.frame.height ?? 900) / 2
        )
        .onAppear { text = currentText }
        #else
        STNavigationView {
            TextEditor(text: $text)
                .padding()
                .navigationTitle(STStrings.selectionNote)
                .stNavigationBarTitleDisplayMode()
                .toolbar {
                    ToolbarItem(placement: .stLeading) {
                        Button(STStrings.cancel) { onCancel() }
                    }
                    ToolbarItem(placement: .stTrailing) {
                        Button(STStrings.done) { onSave(text) }
                            .fontWeight(.semibold)
                    }
                }
        }
        .onAppear { text = currentText }
        .stPresentationDetents([.medium])
        .stPresentationDragIndicator(.visible)
        #endif
    }
}
