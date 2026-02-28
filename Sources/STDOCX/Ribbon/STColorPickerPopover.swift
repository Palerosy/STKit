import SwiftUI
import STKit

/// Compact color picker for text color and highlight color
struct STColorPickerPopover: View {
    let title: String
    let colors: [(String, Color)]
    let showNone: Bool
    let onSelect: (String) -> Void

    @State private var customColor = Color.black

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            LazyVGrid(columns: Array(repeating: GridItem(.fixed(36), spacing: 6), count: 4), spacing: 6) {
                if showNone {
                    Button {
                        onSelect("none")
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white)
                                .frame(width: 32, height: 32)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                            Image(systemName: "xmark")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                }

                ForEach(colors, id: \.0) { hex, color in
                    Button {
                        onSelect(hex)
                    } label: {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(color)
                            .frame(width: 32, height: 32)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            Divider()

            HStack(spacing: 8) {
                ColorPicker("", selection: $customColor, supportsOpacity: false)
                    .labelsHidden()
                    .frame(width: 32, height: 32)

                Button {
                    onSelect(customColor.toHex())
                } label: {
                    Text(STStrings.custom)
                        .font(.caption)
                        .foregroundColor(.accentColor)
                }
            }
        }
        .padding(12)
        .modifier(CompactPopoverModifier())
    }
}

/// Force popover presentation on iPhone (iOS 16.4+)
private struct CompactPopoverModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.stPresentationCompactAdaptation()
    }
}

/// Preset colors for text color
enum STColorPresets {
    static let textColors: [(String, Color)] = [
        ("#000000", .black),
        ("#FF0000", .red),
        ("#0000FF", .blue),
        ("#008000", .green),
        ("#FF8C00", .orange),
        ("#800080", .purple),
        ("#8B4513", .brown),
        ("#808080", .gray),
    ]

    static let highlightColors: [(String, Color)] = [
        ("#FFFF00", .yellow),
        ("#00FF00", .green),
        ("#00FFFF", .cyan),
        ("#FF69B4", .pink),
        ("#FFA500", .orange),
    ]
}

// MARK: - Color to Hex

private extension Color {
    func toHex() -> String {
        let platformColor = PlatformColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        #if os(macOS)
        let color = platformColor.usingColorSpace(.sRGB) ?? platformColor
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        #else
        platformColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        #endif
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}
