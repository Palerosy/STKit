import PDFKit

/// Utility for converting coordinates between screen space and PDF page space.
/// Leverages Apple's PDFView.convert methods which handle zoom, scroll, rotation automatically.
public enum STCoordinateMapper {

    /// Convert a screen point to PDF page coordinates
    public static func screenToPDF(point: CGPoint, in pdfView: PDFView, on page: PDFPage) -> CGPoint {
        pdfView.convert(point, to: page)
    }

    /// Convert a PDF page point to screen coordinates
    public static func pdfToScreen(point: CGPoint, in pdfView: PDFView, on page: PDFPage) -> CGPoint {
        pdfView.convert(point, from: page)
    }

    /// Convert a screen rect to PDF page coordinates
    public static func screenToPDF(rect: CGRect, in pdfView: PDFView, on page: PDFPage) -> CGRect {
        let topLeft = screenToPDF(point: rect.origin, in: pdfView, on: page)
        let bottomRight = screenToPDF(
            point: CGPoint(x: rect.maxX, y: rect.maxY),
            in: pdfView, on: page
        )
        return CGRect(
            x: min(topLeft.x, bottomRight.x),
            y: min(topLeft.y, bottomRight.y),
            width: abs(bottomRight.x - topLeft.x),
            height: abs(bottomRight.y - topLeft.y)
        )
    }

    /// Convert a PDF page rect to screen coordinates
    public static func pdfToScreen(rect: CGRect, in pdfView: PDFView, on page: PDFPage) -> CGRect {
        let topLeft = pdfToScreen(point: rect.origin, in: pdfView, on: page)
        let bottomRight = pdfToScreen(
            point: CGPoint(x: rect.maxX, y: rect.maxY),
            in: pdfView, on: page
        )
        return CGRect(
            x: min(topLeft.x, bottomRight.x),
            y: min(topLeft.y, bottomRight.y),
            width: abs(bottomRight.x - topLeft.x),
            height: abs(bottomRight.y - topLeft.y)
        )
    }

    /// Get the page at a given screen point
    public static func page(at point: CGPoint, in pdfView: PDFView) -> PDFPage? {
        pdfView.page(for: point, nearest: true)
    }
}
