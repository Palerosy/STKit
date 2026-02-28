import Foundation
import SwiftUI

#if os(iOS)
import UIKit
public typealias PlatformImage = UIImage
public typealias PlatformColor = UIColor
public typealias PlatformView = UIView
public typealias PlatformFont = UIFont
public typealias PlatformBezierPath = UIBezierPath
public typealias PlatformEdgeInsets = UIEdgeInsets
public typealias PlatformViewController = UIViewController

#elseif os(macOS)
import AppKit
public typealias PlatformImage = NSImage
public typealias PlatformColor = NSColor
public typealias PlatformView = NSView
public typealias PlatformFont = NSFont
public typealias PlatformBezierPath = NSBezierPath
public typealias PlatformEdgeInsets = NSEdgeInsets
public typealias PlatformViewController = NSViewController
#endif

// MARK: - SwiftUI Image Extension

extension Image {
    public init(platformImage: PlatformImage) {
        #if os(iOS)
        self.init(uiImage: platformImage)
        #elseif os(macOS)
        self.init(nsImage: platformImage)
        #endif
    }
}

// MARK: - SwiftUI Color Extension

extension Color {
    public init(platformColor: PlatformColor) {
        #if os(iOS)
        self.init(uiColor: platformColor)
        #elseif os(macOS)
        self.init(nsColor: platformColor)
        #endif
    }
}

// MARK: - PlatformImage Helpers

extension PlatformImage {
    #if os(macOS)
    /// Convenience to match UIImage's pngData() on macOS
    public func pngData() -> Data? {
        guard let tiffRep = tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffRep) else { return nil }
        return bitmapImage.representation(using: .png, properties: [:])
    }

    /// Convenience to match UIImage's jpegData(compressionQuality:) on macOS
    public func jpegData(compressionQuality: CGFloat) -> Data? {
        guard let tiffRep = tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffRep) else { return nil }
        return bitmapImage.representation(using: .jpeg, properties: [.compressionFactor: compressionQuality])
    }
    #endif
}

// MARK: - NSBezierPath UIKit-compatible API

// MARK: - macOS UIKit Compatibility Shims

#if os(macOS)
/// macOS shim for UIGraphicsPushContext (sets the current NSGraphicsContext)
public func UIGraphicsPushContext(_ context: CGContext) {
    let nsContext = NSGraphicsContext(cgContext: context, flipped: true)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = nsContext
}

/// macOS shim for UIGraphicsPopContext (restores the previous NSGraphicsContext)
public func UIGraphicsPopContext() {
    NSGraphicsContext.restoreGraphicsState()
}

/// macOS shim for UIGraphicsImageRenderer
public class UIGraphicsImageRenderer {
    public class RendererContext {
        public let cgContext: CGContext
        init(cgContext: CGContext) { self.cgContext = cgContext }
        public func fill(_ rect: CGRect) { cgContext.fill(rect) }
    }

    public let size: CGSize
    public init(size: CGSize) { self.size = size }

    public func image(actions: (RendererContext) -> Void) -> NSImage {
        let image = NSImage(size: size)
        image.lockFocusFlipped(true)
        if let context = NSGraphicsContext.current?.cgContext {
            actions(RendererContext(cgContext: context))
        }
        image.unlockFocus()
        return image
    }
}

/// macOS shim for UIGraphicsPDFRenderer
public class UIGraphicsPDFRenderer {
    public class RendererContext {
        public let cgContext: CGContext
        public let pdfContextBounds: CGRect
        private var hasOpenPage = false
        init(cgContext: CGContext, pdfContextBounds: CGRect) {
            self.cgContext = cgContext
            self.pdfContextBounds = pdfContextBounds
        }
        public func beginPage() {
            if hasOpenPage {
                cgContext.endPDFPage()
            }
            var mediaBox = pdfContextBounds
            withUnsafePointer(to: &mediaBox) { ptr in
                let cfData = CFDataCreate(nil, UnsafeRawPointer(ptr).assumingMemoryBound(to: UInt8.self), MemoryLayout<CGRect>.size)!
                cgContext.beginPDFPage([kCGPDFContextMediaBox: cfData] as CFDictionary)
            }
            hasOpenPage = true
        }
        public func beginPage(withBounds bounds: CGRect, pageInfo: [String: Any] = [:]) {
            if hasOpenPage {
                cgContext.endPDFPage()
            }
            var mediaBox = bounds
            withUnsafePointer(to: &mediaBox) { ptr in
                let cfData = CFDataCreate(nil, UnsafeRawPointer(ptr).assumingMemoryBound(to: UInt8.self), MemoryLayout<CGRect>.size)!
                cgContext.beginPDFPage([kCGPDFContextMediaBox: cfData] as CFDictionary)
            }
            hasOpenPage = true
        }
        /// End the current page if one is open (called before closePDF)
        func endCurrentPageIfNeeded() {
            if hasOpenPage {
                cgContext.endPDFPage()
                hasOpenPage = false
            }
        }
    }

    public struct Format {
        public var bounds: CGRect
        public init(bounds: CGRect = .zero) { self.bounds = bounds }
        public static func standard() -> Format { Format() }
    }

    let bounds: CGRect

    public init(bounds: CGRect, format: Format = .standard()) {
        self.bounds = bounds
    }

    public func pdfData(actions: (RendererContext) -> Void) -> Data {
        let data = NSMutableData()
        var mediaBox = bounds
        guard let consumer = CGDataConsumer(data: data as CFMutableData),
              let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            return Data()
        }
        let rendererContext = RendererContext(cgContext: context, pdfContextBounds: bounds)
        actions(rendererContext)
        rendererContext.endCurrentPageIfNeeded()
        context.closePDF()
        return data as Data
    }
}

/// macOS shim for UIGraphicsBeginPDFContextToData
public func UIGraphicsBeginPDFContextToData(_ data: NSMutableData, _ bounds: CGRect, _ documentInfo: [String: Any]?) {
    // This is a simplified shim — actual implementation uses Core Graphics PDF context
}

/// macOS shim for UIGraphicsEndPDFContext
public func UIGraphicsEndPDFContext() {
    // Paired with UIGraphicsBeginPDFContextToData
}

/// macOS shim for UIGraphicsBeginPDFPage
public func UIGraphicsBeginPDFPage() {
    // Begins a new PDF page
}

/// macOS shim for UIGraphicsGetPDFContextBounds
public func UIGraphicsGetPDFContextBounds() -> CGRect {
    return .zero
}

/// PlatformFontDescriptor typealias
public typealias PlatformFontDescriptor = NSFontDescriptor

// NSColor convenience extensions to match UIColor API
extension NSColor {
    /// Match UIColor.systemBackground
    public static var systemBackground: NSColor { .windowBackgroundColor }
    /// Match UIColor.secondarySystemBackground
    public static var secondarySystemBackground: NSColor { .controlBackgroundColor }
    /// Match UIColor.label
    public static var label: NSColor { .labelColor }
    /// Match UIColor.secondaryLabel
    public static var secondaryLabel: NSColor { .secondaryLabelColor }
    /// Match UIColor.tertiaryLabel
    public static var tertiaryLabel: NSColor { .tertiaryLabelColor }
    /// Match UIColor.placeholderText
    public static var placeholderText: NSColor { .placeholderTextColor }
    /// Match UIColor.separator
    public static var separator: NSColor { .separatorColor }
}

// NSFontDescriptor.SymbolicTraits iOS compatibility
extension NSFontDescriptor.SymbolicTraits {
    public static var traitBold: NSFontDescriptor.SymbolicTraits { .bold }
    public static var traitItalic: NSFontDescriptor.SymbolicTraits { .italic }
}
#endif

#if os(iOS)
import UIKit
public typealias PlatformFontDescriptor = UIFontDescriptor
#endif

// MARK: - NSBezierPath UIKit-compatible API

#if os(macOS)
extension NSBezierPath {
    /// Match UIBezierPath's addLine(to:) API
    public func addLine(to point: CGPoint) {
        line(to: point)
    }

    /// Match UIBezierPath's addCurve(to:controlPoint1:controlPoint2:) API
    public func addCurve(to endPoint: CGPoint, controlPoint1: CGPoint, controlPoint2: CGPoint) {
        curve(to: endPoint, controlPoint1: controlPoint1, controlPoint2: controlPoint2)
    }

    /// Match UIBezierPath's addQuadCurve(to:controlPoint:) API
    public func addQuadCurve(to endPoint: CGPoint, controlPoint: CGPoint) {
        // NSBezierPath doesn't have quad curves, convert to cubic
        let cp1 = CGPoint(
            x: currentPoint.x + 2.0/3.0 * (controlPoint.x - currentPoint.x),
            y: currentPoint.y + 2.0/3.0 * (controlPoint.y - currentPoint.y)
        )
        let cp2 = CGPoint(
            x: endPoint.x + 2.0/3.0 * (controlPoint.x - endPoint.x),
            y: endPoint.y + 2.0/3.0 * (controlPoint.y - endPoint.y)
        )
        curve(to: endPoint, controlPoint1: cp1, controlPoint2: cp2)
    }

    /// Match UIBezierPath's addArc API
    public func addArc(withCenter center: CGPoint, radius: CGFloat, startAngle: CGFloat, endAngle: CGFloat, clockwise: Bool) {
        let startDeg = startAngle * 180 / .pi
        let endDeg = endAngle * 180 / .pi
        appendArc(withCenter: center, radius: radius, startAngle: startDeg, endAngle: endDeg, clockwise: !clockwise)
    }

    /// Convert to CGPath
    public var cgPath: CGPath {
        let path = CGMutablePath()
        var points = [CGPoint](repeating: .zero, count: 3)
        for i in 0..<elementCount {
            let type = element(at: i, associatedPoints: &points)
            switch type {
            case .moveTo:
                path.move(to: points[0])
            case .lineTo:
                path.addLine(to: points[0])
            case .curveTo:
                path.addCurve(to: points[2], control1: points[0], control2: points[1])
            case .closePath:
                path.closeSubpath()
            case .cubicCurveTo:
                path.addCurve(to: points[2], control1: points[0], control2: points[1])
            case .quadraticCurveTo:
                path.addQuadCurve(to: points[1], control: points[0])
            @unknown default:
                break
            }
        }
        return path
    }
}

extension NSBezierPath {
    /// Match UIBezierPath's convenience init for rounded rect
    public convenience init(roundedRect rect: CGRect, cornerRadius: CGFloat) {
        self.init(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
    }
}
#endif

// MARK: - Cross-platform Haptics

/// Cross-platform haptic feedback helper
public enum STHaptics {
    public enum Style {
        case light, medium, heavy
    }

    public static func impact(_ style: Style = .light) {
        #if os(iOS)
        let generator: UIImpactFeedbackGenerator
        switch style {
        case .light: generator = UIImpactFeedbackGenerator(style: .light)
        case .medium: generator = UIImpactFeedbackGenerator(style: .medium)
        case .heavy: generator = UIImpactFeedbackGenerator(style: .heavy)
        }
        generator.impactOccurred()
        #endif
    }

    public static func notification(_ type: NotificationType = .success) {
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        switch type {
        case .success: generator.notificationOccurred(.success)
        case .warning: generator.notificationOccurred(.warning)
        case .error: generator.notificationOccurred(.error)
        }
        #endif
    }

    public enum NotificationType {
        case success, warning, error
    }
}

// MARK: - Cross-platform system colors

extension Color {
    /// Cross-platform system background color
    public static var stSystemBackground: Color {
        #if os(iOS)
        Color(.systemBackground)
        #elseif os(macOS)
        Color(nsColor: .windowBackgroundColor)
        #endif
    }

    /// Cross-platform secondary system background color
    public static var stSecondarySystemBackground: Color {
        #if os(iOS)
        Color(.secondarySystemBackground)
        #elseif os(macOS)
        Color(nsColor: .controlBackgroundColor)
        #endif
    }

    /// Cross-platform secondary system grouped background color
    public static var stSecondarySystemGroupedBackground: Color {
        #if os(iOS)
        Color(.secondarySystemGroupedBackground)
        #elseif os(macOS)
        Color(nsColor: .controlBackgroundColor)
        #endif
    }

    /// Cross-platform tertiary fill color
    public static var stTertiaryFill: Color {
        #if os(iOS)
        Color(.tertiarySystemFill)
        #elseif os(macOS)
        Color.gray.opacity(0.1)
        #endif
    }

    /// Cross-platform separator color
    public static var stSeparator: Color {
        #if os(iOS)
        Color(.separator)
        #elseif os(macOS)
        Color(nsColor: .separatorColor)
        #endif
    }
}
