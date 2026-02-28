import SwiftUI
import STKit

/// A table style definition for the style picker
struct STTableStyle: Identifiable {
    let id: String
    let headerBg: Color
    let headerFg: Color
    let stripeBg: Color
    let bodyBg: Color
    let borderColor: Color
    // Hex values for JS
    let headerHex: String
    let stripeHex: String
    let borderHex: String
}

/// Pre-defined table styles matching Word-like themes
enum STTableStyles {
    /// All available styles grouped by category
    static let all: [STTableStyle] = [
        // Plain
        STTableStyle(id: "plain", headerBg: .white, headerFg: .black,
                     stripeBg: Color(hex: "F2F2F2"), bodyBg: .white, borderColor: Color(hex: "999999"),
                     headerHex: "#FFFFFF", stripeHex: "#F2F2F2", borderHex: "#999999"),

        // Blue theme
        STTableStyle(id: "header-blue", headerBg: Color(hex: "4472C4"), headerFg: .white,
                     stripeBg: Color(hex: "D6E4F0"), bodyBg: .white, borderColor: Color(hex: "4472C4"),
                     headerHex: "#4472C4", stripeHex: "#D6E4F0", borderHex: "#4472C4"),

        // Orange theme
        STTableStyle(id: "header-orange", headerBg: Color(hex: "ED7D31"), headerFg: .white,
                     stripeBg: Color(hex: "FCE4D6"), bodyBg: .white, borderColor: Color(hex: "ED7D31"),
                     headerHex: "#ED7D31", stripeHex: "#FCE4D6", borderHex: "#ED7D31"),

        // Green theme
        STTableStyle(id: "header-green", headerBg: Color(hex: "548235"), headerFg: .white,
                     stripeBg: Color(hex: "E2EFDA"), bodyBg: .white, borderColor: Color(hex: "548235"),
                     headerHex: "#548235", stripeHex: "#E2EFDA", borderHex: "#548235"),

        // Gold/Yellow theme
        STTableStyle(id: "header-gold", headerBg: Color(hex: "BF8F00"), headerFg: .white,
                     stripeBg: Color(hex: "FFF2CC"), bodyBg: .white, borderColor: Color(hex: "BF8F00"),
                     headerHex: "#BF8F00", stripeHex: "#FFF2CC", borderHex: "#BF8F00"),

        // Red theme
        STTableStyle(id: "header-red", headerBg: Color(hex: "C00000"), headerFg: .white,
                     stripeBg: Color(hex: "F4CCCC"), bodyBg: .white, borderColor: Color(hex: "C00000"),
                     headerHex: "#C00000", stripeHex: "#F4CCCC", borderHex: "#C00000"),

        // Purple theme
        STTableStyle(id: "header-purple", headerBg: Color(hex: "7030A0"), headerFg: .white,
                     stripeBg: Color(hex: "E4DFEC"), bodyBg: .white, borderColor: Color(hex: "7030A0"),
                     headerHex: "#7030A0", stripeHex: "#E4DFEC", borderHex: "#7030A0"),

        // Teal theme
        STTableStyle(id: "header-teal", headerBg: Color(hex: "2E75B6"), headerFg: .white,
                     stripeBg: Color(hex: "DAEEF3"), bodyBg: .white, borderColor: Color(hex: "2E75B6"),
                     headerHex: "#2E75B6", stripeHex: "#DAEEF3", borderHex: "#2E75B6"),

        // Dark theme
        STTableStyle(id: "header-dark", headerBg: Color(hex: "333333"), headerFg: .white,
                     stripeBg: Color(hex: "F2F2F2"), bodyBg: .white, borderColor: Color(hex: "999999"),
                     headerHex: "#333333", stripeHex: "#F2F2F2", borderHex: "#999999"),

        // Light grids
        STTableStyle(id: "grid-blue", headerBg: Color(hex: "D6E4F0"), headerFg: Color(hex: "1F3864"),
                     stripeBg: Color(hex: "EAF0F7"), bodyBg: .white, borderColor: Color(hex: "B4C6E7"),
                     headerHex: "#D6E4F0", stripeHex: "#EAF0F7", borderHex: "#B4C6E7"),

        STTableStyle(id: "grid-green", headerBg: Color(hex: "E2EFDA"), headerFg: Color(hex: "375623"),
                     stripeBg: Color(hex: "F0F7EC"), bodyBg: .white, borderColor: Color(hex: "A9D18E"),
                     headerHex: "#E2EFDA", stripeHex: "#F0F7EC", borderHex: "#A9D18E"),

        STTableStyle(id: "grid-orange", headerBg: Color(hex: "FCE4D6"), headerFg: Color(hex: "833C0B"),
                     stripeBg: Color(hex: "FDF0E8"), bodyBg: .white, borderColor: Color(hex: "F4B183"),
                     headerHex: "#FCE4D6", stripeHex: "#FDF0E8", borderHex: "#F4B183"),
    ]
}

/// Mini table thumbnail preview (Word-style)
struct STTableStyleThumbnail: View {
    let style: STTableStyle
    let isSelected: Bool

    private let thumbRows = 4
    private let thumbCols = 3
    private let cellW: CGFloat = 16
    private let cellH: CGFloat = 8

    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<thumbRows, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<thumbCols, id: \.self) { _ in
                        Rectangle()
                            .fill(cellColor(for: row))
                            .frame(width: cellW, height: cellH)
                            .border(style.borderColor.opacity(0.6), width: 0.5)
                    }
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 2))
        .overlay(
            RoundedRectangle(cornerRadius: 2)
                .stroke(isSelected ? Color.accentColor : Color.gray.opacity(0.3),
                        lineWidth: isSelected ? 2 : 0.5)
        )
        .shadow(color: isSelected ? Color.accentColor.opacity(0.3) : .clear, radius: 2)
    }

    private func cellColor(for row: Int) -> Color {
        if row == 0 { return style.headerBg }
        return row % 2 == 0 ? style.stripeBg : style.bodyBg
    }
}

/// Table style picker sheet — grid of mini table thumbnails
/// mode: .insert = insert new table, .restyle = restyle active table
struct STTableStylePickerView: View {
    enum Mode { case insert, restyle }

    let mode: Mode
    let onSelectInsert: ((STTableStyle, Int, Int) -> Void)?
    let onSelectRestyle: ((STTableStyle) -> Void)?

    init(mode: Mode = .insert,
         onSelectInsert: ((STTableStyle, Int, Int) -> Void)? = nil,
         onSelectRestyle: ((STTableStyle) -> Void)? = nil) {
        self.mode = mode
        self.onSelectInsert = onSelectInsert
        self.onSelectRestyle = onSelectRestyle
    }

    @State private var selectedStyle: STTableStyle?
    @State private var rows = 4
    @State private var cols = 3
    @Environment(\.dismiss) private var dismiss

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)

    var body: some View {
        #if os(macOS)
        macOSBody
        #else
        iOSBody
        #endif
    }

    private var styleContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Style grid
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(STTableStyles.all) { style in
                        STTableStyleThumbnail(
                            style: style,
                            isSelected: selectedStyle?.id == style.id
                        )
                        .onTapGesture {
                            selectedStyle = style
                            if mode == .restyle {
                                onSelectRestyle?(style)
                                dismiss()
                            }
                        }
                    }
                }
                .padding(.horizontal)

                // Size picker (only for insert mode)
                if mode == .insert {
                    Divider().padding(.horizontal)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("\(rows) × \(cols)")
                                .font(.subheadline.bold())
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal)

                        HStack(spacing: 16) {
                            VStack(alignment: .leading) {
                                Text("Rows")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Stepper("\(rows)", value: $rows, in: 1...20)
                                    .labelsHidden()
                            }

                            VStack(alignment: .leading) {
                                Text("Columns")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Stepper("\(cols)", value: $cols, in: 1...10)
                                    .labelsHidden()
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Insert button
                    Button {
                        guard let style = selectedStyle else { return }
                        onSelectInsert?(style, rows, cols)
                        dismiss()
                    } label: {
                        Text(STStrings.add)
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(selectedStyle != nil ? Color.accentColor : Color.gray.opacity(0.3))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                    .disabled(selectedStyle == nil)
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }

    #if os(macOS)
    private var macOSBody: some View {
        let sw = NSScreen.main?.frame.width ?? 1440
        let sh = NSScreen.main?.frame.height ?? 900
        return VStack(spacing: 0) {
            HStack {
                Text(STStrings.tableStyles)
                    .font(.headline)
                Spacer()
                Button(STStrings.close) { dismiss() }
                    .buttonStyle(.plain)
                    .foregroundColor(.accentColor)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            Divider()

            styleContent
                .frame(maxHeight: sh * 0.5)
        }
        .frame(width: sw * 0.35)
    }
    #endif

    private var iOSBody: some View {
        NavigationView {
            styleContent
                .navigationTitle(STStrings.tableStyles)
                .stNavigationBarTitleDisplayMode()
                .toolbar {
                    ToolbarItem(placement: .stTrailing) {
                        Button(STStrings.close) { dismiss() }
                    }
                }
        }
    }
}

// MARK: - Color hex init helper
private extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var rgb: UInt64 = 0
        Scanner(string: h).scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
