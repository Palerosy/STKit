import STKit
import SwiftUI
import PDFKit

/// Full-screen signature capture view.
/// The user draws their signature, then it's placed as an ink annotation on the PDF.
struct STSignatureCaptureView: View {

    let strokeColor: PlatformColor
    let strokeWidth: CGFloat
    let onSave: (_ signatureImage: PlatformImage, _ paths: [[CGPoint]]) -> Void
    let onCancel: () -> Void

    @State private var paths: [[CGPoint]] = []
    @State private var currentPath: [CGPoint] = []

    var body: some View {
        #if os(macOS)
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(STStrings.cancel) { onCancel() }
                    .buttonStyle(.plain)
                    .foregroundColor(.accentColor)
                Spacer()
                Text(STStrings.toolSignature)
                    .font(.headline)
                Spacer()
                Color.clear.frame(width: 50)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            Divider()

            // Drawing canvas — fixed height so sheet sizes to content
            drawingCanvas
                .frame(height: (NSScreen.main?.frame.height ?? 900) * 0.3)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.secondary.opacity(0.3), lineWidth: 1)
                )
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)

            // Buttons
            actionButtons
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
        }
        .frame(width: (NSScreen.main?.frame.width ?? 1440) * 0.35)
        #else
        STNavigationView {
            VStack(spacing: 0) {
                drawingCanvas
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
                    .padding(16)

                actionButtons
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
            }
            .navigationTitle(STStrings.toolSignature)
            .stNavigationBarTitleDisplayMode()
            .toolbar {
                ToolbarItem(placement: .stLeading) {
                    Button(STStrings.cancel) {
                        onCancel()
                    }
                }
            }
        }
        #endif
    }

    // MARK: - Drawing Canvas

    private var drawingCanvas: some View {
        ZStack {
            Color.stSystemBackground

            VStack {
                Spacer()
                Rectangle()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(height: 1)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 60)
            }

            Canvas { context, _ in
                var allPaths = paths
                if !currentPath.isEmpty {
                    allPaths.append(currentPath)
                }

                for points in allPaths {
                    guard points.count >= 2 else { continue }
                    var path = Path()
                    path.move(to: points[0])
                    for i in 1..<points.count {
                        path.addLine(to: points[i])
                    }
                    context.stroke(
                        path,
                        with: .color(Color(platformColor: strokeColor)),
                        lineWidth: strokeWidth
                    )
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        currentPath.append(value.location)
                    }
                    .onEnded { _ in
                        if currentPath.count >= 2 {
                            paths.append(currentPath)
                        }
                        currentPath = []
                    }
            )
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 16) {
            Button {
                paths.removeAll()
                currentPath.removeAll()
            } label: {
                Text(STStrings.signatureClear)
                    .font(.body.weight(.medium))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
            .disabled(paths.isEmpty)

            Button {
                if let image = renderSignature() {
                    onSave(image, paths)
                }
            } label: {
                Text(STStrings.done)
                    .font(.body.weight(.semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(paths.isEmpty ? Color.accentColor.opacity(0.4) : Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
            .disabled(paths.isEmpty)
        }
    }

    private func renderSignature() -> PlatformImage? {
        guard !paths.isEmpty else { return nil }

        // Find bounding box of all points
        let allPoints = paths.flatMap { $0 }
        guard !allPoints.isEmpty else { return nil }

        let minX = allPoints.map(\.x).min()!
        let minY = allPoints.map(\.y).min()!
        let maxX = allPoints.map(\.x).max()!
        let maxY = allPoints.map(\.y).max()!

        let padding: CGFloat = strokeWidth * 2
        let width = maxX - minX + padding * 2
        let height = maxY - minY + padding * 2

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height))
        return renderer.image { ctx in
            let cgContext = ctx.cgContext
            cgContext.setStrokeColor(strokeColor.cgColor)
            cgContext.setLineWidth(strokeWidth)
            cgContext.setLineCap(.round)
            cgContext.setLineJoin(.round)

            for points in paths {
                guard points.count >= 2 else { continue }
                cgContext.beginPath()
                cgContext.move(to: CGPoint(
                    x: points[0].x - minX + padding,
                    y: points[0].y - minY + padding
                ))
                for i in 1..<points.count {
                    cgContext.addLine(to: CGPoint(
                        x: points[i].x - minX + padding,
                        y: points[i].y - minY + padding
                    ))
                }
                cgContext.strokePath()
            }
        }
    }
}

// MARK: - Signature Annotation (image-based with recolorable paths)

/// Signature annotation that renders as an image (like STImageAnnotation) but stores
/// the original stroke paths so the signature can be re-rendered with a different color.
final class STSignatureAnnotation: PDFAnnotation {

    /// Original stroke paths in normalized coordinates (0…1 range, Y-down).
    let normalizedStrokes: [[CGPoint]]
    private(set) var inkColor: PlatformColor
    private(set) var inkStrokeWidth: CGFloat
    private(set) var signatureImage: PlatformImage

    init(bounds: CGRect, normalizedStrokes: [[CGPoint]], color: PlatformColor, strokeWidth: CGFloat, image: PlatformImage) {
        self.normalizedStrokes = normalizedStrokes
        self.inkColor = color
        self.inkStrokeWidth = strokeWidth
        self.signatureImage = image
        super.init(bounds: bounds, forType: .stamp, withProperties: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not supported") }

    // MARK: - Style

    func applyStyle(color: PlatformColor, strokeWidth: CGFloat) {
        inkColor = color
        inkStrokeWidth = strokeWidth
        // Re-render signature image with new color
        signatureImage = Self.renderImage(
            strokes: normalizedStrokes, color: color, strokeWidth: strokeWidth,
            size: CGSize(width: bounds.width * 3, height: bounds.height * 3)
        )
    }

    // MARK: - Rendering

    override func draw(with box: PDFDisplayBox, in context: CGContext) {
        context.saveGState()
        context.translateBy(x: 0, y: bounds.maxY + bounds.minY)
        context.scaleBy(x: 1, y: -1)
        UIGraphicsPushContext(context)
        signatureImage.draw(in: bounds)
        UIGraphicsPopContext()
        context.restoreGState()
    }

    // MARK: - Image Rendering

    /// Render signature strokes into an image at the given size.
    static func renderImage(strokes: [[CGPoint]], color: PlatformColor, strokeWidth: CGFloat, size: CGSize) -> PlatformImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let cgContext = ctx.cgContext
            cgContext.setStrokeColor(color.cgColor)
            cgContext.setLineWidth(strokeWidth * 3) // size is 3x annotation bounds
            cgContext.setLineCap(.round)
            cgContext.setLineJoin(.round)

            for stroke in strokes {
                guard stroke.count >= 2 else { continue }
                cgContext.beginPath()
                // Normalized coords (0…1), scale to image size
                cgContext.move(to: CGPoint(x: stroke[0].x * size.width, y: stroke[0].y * size.height))
                for i in 1..<stroke.count {
                    cgContext.addLine(to: CGPoint(x: stroke[i].x * size.width, y: stroke[i].y * size.height))
                }
                cgContext.strokePath()
            }
        }
    }
}

// MARK: - Signature Placer

/// Helper to place a signature on a PDF page.
enum STSignaturePlacer {

    /// Create a signature annotation from raw capture-view paths, with recolorable strokes.
    static func placeVectorSignature(
        paths: [[CGPoint]],
        at pdfPoint: CGPoint,
        strokeColor: PlatformColor,
        strokeWidth: CGFloat,
        maxWidth: CGFloat = 200,
        maxHeight: CGFloat = 100
    ) -> STSignatureAnnotation {
        let allPoints = paths.flatMap { $0 }
        let minX = allPoints.map(\.x).min() ?? 0
        let minY = allPoints.map(\.y).min() ?? 0
        let maxX = allPoints.map(\.x).max() ?? 1
        let maxY = allPoints.map(\.y).max() ?? 1

        let rawW = max(maxX - minX, 1)
        let rawH = max(maxY - minY, 1)
        let scale = min(maxWidth / rawW, maxHeight / rawH, 1.0)
        let scaledW = rawW * scale
        let scaledH = rawH * scale
        let pad = strokeWidth * 2
        let totalW = scaledW + pad * 2
        let totalH = scaledH + pad * 2

        let bounds = CGRect(
            x: pdfPoint.x - totalW / 2,
            y: pdfPoint.y - totalH / 2,
            width: totalW,
            height: totalH
        )

        // Normalize strokes to 0…1 range (relative to content area, excluding padding)
        let normalized = paths.map { stroke in
            stroke.map { pt -> CGPoint in
                let nx = ((pt.x - minX) * scale + pad) / totalW
                let ny = ((pt.y - minY) * scale + pad) / totalH
                return CGPoint(x: nx, y: ny)
            }
        }

        // Render initial image
        let imageSize = CGSize(width: totalW * 3, height: totalH * 3)
        let image = STSignatureAnnotation.renderImage(
            strokes: normalized, color: strokeColor, strokeWidth: strokeWidth, size: imageSize
        )

        return STSignatureAnnotation(
            bounds: bounds,
            normalizedStrokes: normalized,
            color: strokeColor,
            strokeWidth: strokeWidth,
            image: image
        )
    }

    /// Create a stamp annotation from a signature image (legacy/photo).
    static func placeSignature(
        image: PlatformImage,
        at pdfPoint: CGPoint,
        on page: PDFPage,
        maxWidth: CGFloat = 200,
        maxHeight: CGFloat = 100
    ) -> PDFAnnotation {
        let scale = min(maxWidth / image.size.width, maxHeight / image.size.height, 1.0)
        let width = image.size.width * scale
        let height = image.size.height * scale
        let downsampledImage = downsample(image, to: CGSize(width: width * 3, height: height * 3))
        let bounds = CGRect(
            x: pdfPoint.x - width / 2,
            y: pdfPoint.y - height / 2,
            width: width,
            height: height
        )
        return STImageAnnotation(bounds: bounds, image: downsampledImage)
    }

    private static func downsample(_ image: PlatformImage, to targetSize: CGSize) -> PlatformImage {
        let currentSize = image.size
        guard currentSize.width > targetSize.width || currentSize.height > targetSize.height else {
            return image
        }
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}

/// Custom PDFAnnotation that renders an image via appearance stream.
final class STImageAnnotation: PDFAnnotation {

    let image: PlatformImage

    init(bounds: CGRect, image: PlatformImage) {
        self.image = image
        super.init(bounds: bounds, forType: .stamp, withProperties: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not supported")
    }

    override func draw(with box: PDFDisplayBox, in context: CGContext) {
        context.saveGState()
        context.translateBy(x: 0, y: bounds.maxY + bounds.minY)
        context.scaleBy(x: 1, y: -1)
        UIGraphicsPushContext(context)
        image.draw(in: bounds)
        UIGraphicsPopContext()
        context.restoreGState()
    }
}

// MARK: - Signature Storage

/// Persists signature images to disk for reuse.
final class STSignatureStorage {

    static let shared = STSignatureStorage()
    private let directoryName = "STPDFKit_Signatures"

    private var storageDirectory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent(directoryName)
    }

    @discardableResult
    func save(_ image: PlatformImage) -> String {
        let id = UUID().uuidString
        ensureDirectory()
        if let data = image.pngData() {
            let url = storageDirectory.appendingPathComponent("\(id).png")
            try? data.write(to: url)
        }
        return id
    }

    func loadAll() -> [(id: String, image: PlatformImage)] {
        ensureDirectory()
        guard let files = try? FileManager.default.contentsOfDirectory(atPath: storageDirectory.path) else { return [] }
        var results: [(String, PlatformImage)] = []
        for file in files.sorted().reversed() where file.hasSuffix(".png") {
            let id = String(file.dropLast(4))
            let url = storageDirectory.appendingPathComponent(file)
            if let data = try? Data(contentsOf: url),
               let image = PlatformImage(data: data) {
                results.append((id, image))
            }
        }
        return results
    }

    func delete(id: String) {
        let url = storageDirectory.appendingPathComponent("\(id).png")
        try? FileManager.default.removeItem(at: url)
    }

    private func ensureDirectory() {
        if !FileManager.default.fileExists(atPath: storageDirectory.path) {
            try? FileManager.default.createDirectory(at: storageDirectory, withIntermediateDirectories: true)
        }
    }
}
