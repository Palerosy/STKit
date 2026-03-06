import SwiftUI
import STKit

/// Compact color picker for text and fill colors
struct STExcelColorPicker: View {
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

            LazyVGrid(columns: Array(repeating: GridItem(.fixed(36), spacing: 6), count: 5), spacing: 6) {
                if showNone {
                    Button { onSelect("none") } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white)
                                .frame(width: 32, height: 32)
                                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.gray.opacity(0.3), lineWidth: 1))
                            Image(systemName: "xmark")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                }

                ForEach(colors, id: \.0) { hex, color in
                    Button { onSelect(hex) } label: {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(color)
                            .frame(width: 32, height: 32)
                            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.gray.opacity(0.3), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }

            Divider()

            HStack(spacing: 8) {
                ColorPicker("", selection: $customColor, supportsOpacity: false)
                    .labelsHidden()
                    .frame(width: 32, height: 32)
                Button { onSelect(customColor.toExcelHex()) } label: {
                    Text(STStrings.custom)
                        .font(.caption)
                        .foregroundColor(.stExcelAccent)
                }
            }
        }
        .padding(12)
        .stPresentationCompactAdaptation()
    }
}

/// Preset color grids for spreadsheets
enum STExcelColorPresets {
    static let textColors: [(String, Color)] = [
        ("#000000", .black),
        ("#FF0000", .red),
        ("#0000FF", .blue),
        ("#008000", Color(red: 0, green: 0.5, blue: 0)),
        ("#FF8C00", .orange),
        ("#800080", .purple),
        ("#8B4513", .brown),
        ("#808080", .gray),
        ("#FFFFFF", .white),
        ("#1F4E79", Color(red: 0.12, green: 0.31, blue: 0.47)),
    ]

    static let fillColors: [(String, Color)] = [
        ("#FFFF00", .yellow),
        ("#00FF00", .green),
        ("#00FFFF", .cyan),
        ("#FF69B4", .pink),
        ("#FFA500", .orange),
        ("#E6E6FA", Color(red: 0.9, green: 0.9, blue: 0.98)),
        ("#FFE4B5", Color(red: 1, green: 0.89, blue: 0.71)),
        ("#90EE90", Color(red: 0.56, green: 0.93, blue: 0.56)),
        ("#ADD8E6", Color(red: 0.68, green: 0.85, blue: 0.9)),
        ("#D3D3D3", Color(red: 0.83, green: 0.83, blue: 0.83)),
    ]

    static let shapeColors: [(String, Color)] = [
        ("#0000FF", .blue),
        ("#FF0000", .red),
        ("#008000", Color(red: 0, green: 0.5, blue: 0)),
        ("#FFA500", .orange),
        ("#800080", .purple),
        ("#000000", .black),
        ("#00BFFF", Color(red: 0, green: 0.75, blue: 1)),
        ("#FF69B4", .pink),
        ("#FFD700", Color(red: 1, green: 0.84, blue: 0)),
        ("#808080", .gray),
    ]
}

// MARK: - STExcel Accent Color

extension Color {
    /// STExcel branded accent color (#138046 green)
    static let stExcelAccent = Color(red: 0x13 / 255.0, green: 0x80 / 255.0, blue: 0x46 / 255.0)
}

// MARK: - Color to Hex

extension Color {
    func toExcelHex() -> String {
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

    init?(hex: String) {
        let clean = hex.trimmingCharacters(in: .init(charactersIn: "#"))
        guard clean.count == 6,
              let val = UInt64(clean, radix: 16) else { return nil }
        let r = Double((val >> 16) & 0xFF) / 255
        let g = Double((val >> 8) & 0xFF) / 255
        let b = Double(val & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
