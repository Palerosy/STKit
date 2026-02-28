import STKit
import SwiftUI
import PDFKit

/// Full-screen signature capture view.
/// The user draws their signature, then it's placed as an ink annotation on the PDF.
struct STSignatureCaptureView: View {

    let strokeColor: PlatformColor
    let strokeWidth: CGFloat
    let onSave: (_ signatureImage: PlatformImage) -> Void
    let onCancel: () -> Void

    @State private var paths: [[CGPoint]] = []
    @State private var currentPath: [CGPoint] = []

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Signature drawing area
                ZStack {
                    Color.stSystemBackground

                    // Signature line
                    VStack {
                        Spacer()
                        Rectangle()
                            .fill(Color.secondary.opacity(0.3))
                            .frame(height: 1)
                            .padding(.horizontal, 40)
                            .padding(.bottom, 60)
                    }

                    // Drawing canvas
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
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.secondary.opacity(0.3), lineWidth: 1)
                )
                .padding(16)

                // Buttons
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
                    .disabled(paths.isEmpty)

                    Button {
                        if let image = renderSignature() {
                            onSave(image)
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
                    .disabled(paths.isEmpty)
                }
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

/// Helper to place a signature image as a stamp annotation on a PDF page.
enum STSignaturePlacer {

    /// Create a stamp annotation from a signature image, centered at a given PDF point.
    static func placeSignature(
        image: PlatformImage,
        at pdfPoint: CGPoint,
        on page: PDFPage,
        maxWidth: CGFloat = 200,
        maxHeight: CGFloat = 100
    ) -> PDFAnnotation {
        // Scale image to fit within max bounds
        let scale = min(maxWidth / image.size.width, maxHeight / image.size.height, 1.0)
        let width = image.size.width * scale
        let height = image.size.height * scale

        let bounds = CGRect(
            x: pdfPoint.x - width / 2,
            y: pdfPoint.y - height / 2,
            width: width,
            height: height
        )

        let annotation = STImageAnnotation(bounds: bounds, image: image)
        return annotation
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
        // Flip CG context to UIKit coordinates, then use PlatformImage.draw
        // which handles image orientation metadata correctly.
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
