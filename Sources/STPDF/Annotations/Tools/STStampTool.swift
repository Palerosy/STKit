import STKit
import SwiftUI
import PDFKit

/// Predefined stamp types
enum STStampType: String, CaseIterable, Identifiable {
    case approved = "Approved"
    case rejected = "Rejected"
    case draft = "Draft"
    case confidential = "Confidential"
    case forComment = "ForComment"
    case asIs = "AsIs"
    case final_ = "Final"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .approved: return STStrings.stampApproved
        case .rejected: return STStrings.stampRejected
        case .draft: return STStrings.stampDraft
        case .confidential: return STStrings.stampConfidential
        case .forComment: return STStrings.stampForComment
        case .asIs: return STStrings.stampAsIs
        case .final_: return STStrings.stampFinal
        }
    }

    var color: PlatformColor {
        switch self {
        case .approved: return .systemGreen
        case .rejected: return .systemRed
        case .draft: return .systemOrange
        case .confidential: return .systemRed
        case .forComment: return .systemBlue
        case .asIs: return .systemGray
        case .final_: return .systemPurple
        }
    }

    /// The standard PDFKit stamp name (mapped to built-in PDF stamps when available)
    var stampName: String { rawValue }
}

/// Sheet view for selecting a stamp type, then tap to place on PDF.
struct STStampPickerView: View {

    let onStampSelected: (STStampType) -> Void
    let onCancel: () -> Void

    var body: some View {
        #if os(macOS)
        VStack(spacing: 0) {
            HStack {
                Button(STStrings.cancel) { onCancel() }
                    .buttonStyle(.plain)
                    .foregroundColor(.accentColor)
                Spacer()
                Text(STStrings.toolStamp)
                    .font(.headline)
                Spacer()
                Color.clear.frame(width: 50)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            Divider()

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(STStampType.allCases) { stamp in
                    Button {
                        onStampSelected(stamp)
                    } label: {
                        stampCard(stamp)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
        }
        .frame(width: (NSScreen.main?.frame.width ?? 1440) * 0.35)
        #else
        let grid = ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(STStampType.allCases) { stamp in
                    Button {
                        onStampSelected(stamp)
                    } label: {
                        stampCard(stamp)
                    }
                }
            }
            .padding(16)
        }
        STNavigationView {
            grid
                .navigationTitle(STStrings.toolStamp)
                .stNavigationBarTitleDisplayMode()
                .toolbar {
                    ToolbarItem(placement: .stLeading) {
                        Button(STStrings.cancel) {
                            onCancel()
                        }
                    }
                }
        }
        .stPresentationDetents([.medium])
        .stPresentationDragIndicator(.visible)
        #endif
    }

    @ViewBuilder
    private func stampCard(_ stamp: STStampType) -> some View {
        #if os(macOS)
        Text(stamp.displayName.uppercased())
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(Color(platformColor: stamp.color))
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(Color(platformColor: stamp.color).opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(Color(platformColor: stamp.color), lineWidth: 1.5)
            )
        #else
        VStack(spacing: 8) {
            Text(stamp.displayName.uppercased())
                .font(.system(size: 14, weight: .bold, design: .default))
                .foregroundColor(Color(platformColor: stamp.color))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(Color(platformColor: stamp.color), lineWidth: 2)
                )
        }
        .padding(8)
        .background(Color(platformColor: stamp.color).opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        #endif
    }
}

/// Overlay for placing a stamp at a tapped location.
struct STStampPlacementOverlay: View {

    let stampType: STStampType
    let onPlace: (_ screenPoint: CGPoint) -> Void
    let onCancel: () -> Void

    var body: some View {
        GeometryReader { _ in
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { location in
                    onPlace(location)
                }
        }
        // Hint at top
        .overlay(alignment: .top) {
            HStack {
                Image(systemName: "hand.tap")
                Text(STStrings.tapToPlace)
            }
            .font(.callout.weight(.medium))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.7))
            .clipShape(Capsule())
            .padding(.top, 12)
        }
    }
}

/// Custom PDFAnnotation that renders a stamp with text, border, and background.
/// Uses custom draw(with:in:) because iOS PDFKit's built-in stamp rendering is unreliable.
final class STStampAnnotation: PDFAnnotation {

    let stampText: String
    let stampColor: PlatformColor

    init(bounds: CGRect, text: String, color: PlatformColor) {
        self.stampText = text
        self.stampColor = color
        super.init(bounds: bounds, forType: .stamp, withProperties: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not supported")
    }

    override func draw(with box: PDFDisplayBox, in context: CGContext) {
        context.saveGState()

        // Flip to UIKit coordinates for text drawing
        context.translateBy(x: 0, y: bounds.maxY + bounds.minY)
        context.scaleBy(x: 1, y: -1)

        UIGraphicsPushContext(context)

        let rect = bounds.insetBy(dx: 2, dy: 2)

        // Background fill
        stampColor.withAlphaComponent(0.1).setFill()
        PlatformBezierPath(rect: rect).fill()

        // Border
        stampColor.setStroke()
        let borderPath = PlatformBezierPath(rect: rect)
        borderPath.lineWidth = 2
        borderPath.stroke()

        // Text — scale font to fit bounds
        let fontSize = bounds.height * 0.42
        let font = PlatformFont.systemFont(ofSize: fontSize, weight: .bold)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: stampColor,
            .paragraphStyle: paragraphStyle
        ]

        let textSize = (stampText as NSString).size(withAttributes: attributes)
        let textRect = CGRect(
            x: rect.origin.x,
            y: rect.origin.y + (rect.height - textSize.height) / 2,
            width: rect.width,
            height: textSize.height
        )

        (stampText as NSString).draw(in: textRect, withAttributes: attributes)

        UIGraphicsPopContext()
        context.restoreGState()
    }
}

/// Helper to create a stamp annotation.
enum STStampBuilder {

    static func buildStamp(
        type: STStampType,
        at pdfPoint: CGPoint,
        on page: PDFPage
    ) -> STStampAnnotation {
        let stampWidth: CGFloat = 150
        let stampHeight: CGFloat = 40
        let bounds = CGRect(
            x: pdfPoint.x - stampWidth / 2,
            y: pdfPoint.y - stampHeight / 2,
            width: stampWidth,
            height: stampHeight
        )

        return STStampAnnotation(
            bounds: bounds,
            text: type.displayName.uppercased(),
            color: type.color
        )
    }
}
