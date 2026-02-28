import SwiftUI
import STKit

/// Property inspector for adjusting annotation style (color, width, opacity)
struct STPropertyInspector: View {

    @ObservedObject var annotationManager: STAnnotationManager

    private var showLineWidth: Bool {
        // Selection mode: show for applicable annotation types
        if annotationManager.selectedAnnotation != nil && annotationManager.activeTool == nil {
            let type = annotationManager.selectedAnnotation?.type
            return type == "Ink" || type == "Square" || type == "Circle" || type == "Line"
        }
        guard let tool = annotationManager.activeTool else { return false }
        return tool.hasLineWidth
    }

    private var showFontSize: Bool {
        if annotationManager.selectedAnnotation != nil && annotationManager.activeTool == nil {
            return annotationManager.selectedAnnotation?.type == "FreeText"
        }
        return annotationManager.activeTool == .freeText
    }

    var body: some View {
        VStack(spacing: 16) {
            // Color picker
            VStack(alignment: .leading, spacing: 8) {
                Text(STStrings.color)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)

                LazyVGrid(columns: Array(repeating: GridItem(.fixed(32), spacing: 8), count: 6), spacing: 8) {
                    ForEach(Array(STAnnotationStyle.presetColors.enumerated()), id: \.offset) { _, color in
                        Circle()
                            .fill(Color(platformColor: color))
                            .frame(width: 28, height: 28)
                            .overlay(
                                Circle()
                                    .strokeBorder(
                                        annotationManager.activeStyle.color == color ? Color.primary : Color.clear,
                                        lineWidth: 2
                                    )
                            )
                            .onTapGesture {
                                annotationManager.activeStyle.color = color
                            }
                    }
                }
            }

            // Line width (for drawing tools)
            if showLineWidth {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(STStrings.width)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(String(format: "%.0fpt", annotationManager.activeStyle.lineWidth))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Slider(
                        value: $annotationManager.activeStyle.lineWidth,
                        in: 1...20,
                        step: 1
                    )
                    .tint(.accentColor)
                }
            }

            // Font size (for text tool)
            if showFontSize {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(STStrings.fontSize)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(String(format: "%.0fpt", annotationManager.activeStyle.fontSize))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Slider(
                        value: $annotationManager.activeStyle.fontSize,
                        in: 8...72,
                        step: 2
                    )
                    .tint(.accentColor)
                }
            }

            // Opacity
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(STStrings.opacity)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(String(format: "%.0f%%", annotationManager.activeStyle.opacity * 100))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Slider(
                    value: $annotationManager.activeStyle.opacity,
                    in: 0.1...1.0,
                    step: 0.1
                )
                .tint(.accentColor)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
    }
}
