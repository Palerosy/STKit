import SwiftUI
import STKit

/// Format Cells dialog — tabs: Number, Cell, Border, Protection (matches competitor layout)
struct STExcelFormatCellsView: View {
    @ObservedObject var viewModel: STExcelEditorViewModel
    var initialTab: Int = 0
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0

    private var tabs: [String] { [STExcelStrings.cellTab, STExcelStrings.borderTab, STExcelStrings.protection] }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab bar
                tabBar

                // Tab content
                switch selectedTab {
                case 0: cellTabContent
                case 1: borderTabContent
                case 2: protectionTabContent
                default: EmptyView()
                }

                Spacer(minLength: 0)
            }
            .navigationTitle(STExcelStrings.formatCells)
            .stNavigationBarTitleDisplayMode()
            .toolbar {
                ToolbarItem(placement: .stTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .onAppear { selectedTab = initialTab }
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(Array(tabs.enumerated()), id: \.offset) { i, tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { selectedTab = i }
                } label: {
                    Text(tab)
                        .font(.system(size: 14, weight: selectedTab == i ? .semibold : .regular))
                        .foregroundColor(selectedTab == i ? .primary : .secondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            selectedTab == i
                                ? AnyView(RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.2)))
                                : AnyView(Color.clear)
                        )
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }

    // MARK: - Cell Tab

    private var cellTabContent: some View {
        FCCellTabView(viewModel: viewModel)
    }

    // MARK: - Border Tab

    private var borderTabContent: some View {
        FCBorderTabView(viewModel: viewModel)
    }

    // MARK: - Protection Tab

    private var protectionTabContent: some View {
        VStack(spacing: 20) {
            Toggle(STExcelStrings.locked, isOn: Binding(
                get: { viewModel.currentStyle.isLocked },
                set: { _ in viewModel.toggleLocked() }
            ))
            .padding(.horizontal, 20)

            Toggle(STExcelStrings.hidden, isOn: Binding(
                get: { viewModel.currentStyle.isHidden },
                set: { _ in viewModel.toggleHidden() }
            ))
            .padding(.horizontal, 20)

            Text(STExcelStrings.lockingInfo)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .padding(.top, 20)
    }
}

// MARK: - Cell Tab View

private struct FCCellTabView: View {
    @ObservedObject var viewModel: STExcelEditorViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                fontRow
                boldItalicStrikeRow
                underlineRow
                sizeRow
                textColorRow
                cellColorRow
                horizontalAlignRow
                verticalAlignRow
                indentRow
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 20)
        }
    }

    // MARK: - Font Row

    private var fontRow: some View {
        NavigationLink {
            FCFontPickerView(viewModel: viewModel)
        } label: {
            HStack {
                Text(STExcelStrings.font)
                    .foregroundColor(.primary)
                Spacer()
                Text(viewModel.currentStyle.fontName)
                    .foregroundColor(.stExcelAccent)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Bold / Italic / Strikethrough

    private var boldItalicStrikeRow: some View {
        HStack(spacing: 0) {
            fcToggle("B", font: .system(size: 18, weight: .bold),
                     isActive: viewModel.currentStyle.isBold) { viewModel.toggleBold() }
            Divider().frame(height: 40)
            fcToggle("I", font: .system(size: 18, weight: .regular).italic(),
                     isActive: viewModel.currentStyle.isItalic) { viewModel.toggleItalic() }
            Divider().frame(height: 40)
            fcToggle("S", font: .system(size: 18, weight: .regular),
                     isActive: viewModel.currentStyle.isStrikethrough,
                     strikethrough: true) { viewModel.toggleStrikethrough() }
        }
        .background(Color.gray.opacity(0.15))
        .cornerRadius(10)
    }

    // MARK: - Underline Row

    private var underlineRow: some View {
        HStack(spacing: 0) {
            fcToggle("U", font: .system(size: 18, weight: .regular),
                     isActive: viewModel.currentStyle.isUnderline,
                     underline: true) { viewModel.toggleUnderline() }
            Divider().frame(height: 40)
            fcToggle("U", font: .system(size: 18, weight: .bold),
                     isActive: false,
                     underline: true) { viewModel.toggleUnderline() }
        }
        .background(Color.gray.opacity(0.15))
        .cornerRadius(10)
    }

    // MARK: - Size Row

    private var sizeRow: some View {
        HStack {
            Text(STExcelStrings.size)
            Spacer()
            Text("\(Int(viewModel.currentStyle.fontSize)) pt")
                .foregroundColor(.stExcelAccent)
                .font(.system(size: 15))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.gray.opacity(0.15))
                .cornerRadius(6)
            HStack(spacing: 0) {
                Button { viewModel.decreaseFontSize() } label: {
                    Image(systemName: "minus").font(.system(size: 14)).frame(width: 36, height: 32)
                }
                Divider().frame(height: 24)
                Button { viewModel.increaseFontSize() } label: {
                    Image(systemName: "plus").font(.system(size: 14)).frame(width: 36, height: 32)
                }
            }
            .foregroundColor(.primary)
            .background(Color.gray.opacity(0.15))
            .cornerRadius(8)
        }
    }

    // MARK: - Text Color Row

    private var textColorRow: some View {
        NavigationLink {
            FCColorGridView(viewModel: viewModel, mode: .textColor)
        } label: {
            HStack {
                Text(STExcelStrings.textColor)
                    .foregroundColor(.primary)
                Spacer()
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hex: viewModel.currentStyle.textColor ?? "#000000") ?? .black)
                    .frame(width: 60, height: 28)
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.gray.opacity(0.3), lineWidth: 1))
                Image(systemName: "chevron.right")
                    .font(.caption).foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Cell Color Row

    private var cellColorRow: some View {
        NavigationLink {
            FCColorGridView(viewModel: viewModel, mode: .fillColor)
        } label: {
            HStack {
                Text(STExcelStrings.cellColor)
                    .foregroundColor(.primary)
                Spacer()
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hex: viewModel.currentStyle.fillColor ?? "") ?? Color.gray.opacity(0.15))
                    .frame(width: 60, height: 28)
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.gray.opacity(0.3), lineWidth: 1))
                Image(systemName: "chevron.right")
                    .font(.caption).foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Horizontal Alignment

    private var horizontalAlignRow: some View {
        HStack(spacing: 0) {
            fcAlignBtn(icon: "text.alignleft", isActive: viewModel.currentStyle.horizontalAlignment == .left) {
                viewModel.setHorizontalAlignment(.left)
            }
            Divider().frame(height: 40)
            fcAlignBtn(icon: "text.aligncenter", isActive: viewModel.currentStyle.horizontalAlignment == .center) {
                viewModel.setHorizontalAlignment(.center)
            }
            Divider().frame(height: 40)
            fcAlignBtn(icon: "text.alignright", isActive: viewModel.currentStyle.horizontalAlignment == .right) {
                viewModel.setHorizontalAlignment(.right)
            }
        }
        .background(Color.gray.opacity(0.15))
        .cornerRadius(10)
    }

    // MARK: - Vertical Alignment

    private var verticalAlignRow: some View {
        HStack(spacing: 0) {
            fcAlignBtn(icon: "arrow.up.to.line", isActive: viewModel.currentStyle.verticalAlignment == .top) {
                viewModel.setVerticalAlignment(.top)
            }
            Divider().frame(height: 40)
            fcAlignBtn(icon: "arrow.up.and.down", isActive: viewModel.currentStyle.verticalAlignment == .center) {
                viewModel.setVerticalAlignment(.center)
            }
            Divider().frame(height: 40)
            fcAlignBtn(icon: "arrow.down.to.line", isActive: viewModel.currentStyle.verticalAlignment == .bottom) {
                viewModel.setVerticalAlignment(.bottom)
            }
        }
        .background(Color.gray.opacity(0.15))
        .cornerRadius(10)
    }

    // MARK: - Indent Row

    private var indentRow: some View {
        HStack {
            Text(STExcelStrings.indent)
            Spacer()
            Text("\(viewModel.currentStyle.indent)")
                .foregroundColor(.stExcelAccent)
                .font(.system(size: 15))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.gray.opacity(0.15))
                .cornerRadius(6)
            HStack(spacing: 0) {
                Button { viewModel.decreaseIndent() } label: {
                    Image(systemName: "minus").font(.system(size: 14)).frame(width: 36, height: 32)
                }
                Divider().frame(height: 24)
                Button { viewModel.increaseIndent() } label: {
                    Image(systemName: "plus").font(.system(size: 14)).frame(width: 36, height: 32)
                }
            }
            .foregroundColor(.primary)
            .background(Color.gray.opacity(0.15))
            .cornerRadius(8)
        }
    }

    // MARK: - Helpers

    private func fcToggle(_ label: String, font: Font, isActive: Bool,
                          strikethrough: Bool = false, underline: Bool = false,
                          action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(font)
                .strikethrough(strikethrough)
                .underline(underline)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(isActive ? Color.stExcelAccent : Color.clear)
                .foregroundColor(isActive ? .white : .primary)
        }
    }

    private func fcAlignBtn(icon: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(isActive ? Color.stExcelAccent : Color.clear)
                .foregroundColor(isActive ? .white : .primary)
        }
    }
}

// MARK: - Font Picker

private struct FCFontPickerView: View {
    @ObservedObject var viewModel: STExcelEditorViewModel
    @Environment(\.dismiss) private var dismiss

    private static let fonts = [
        "Calibri", "Arial", "Helvetica", "Helvetica Neue",
        "Times New Roman", "Georgia", "Courier New", "Menlo",
        "Verdana", "Trebuchet MS", "Tahoma", "Palatino",
        "Gill Sans", "Futura", "Optima", "Avenir", "Avenir Next",
        "American Typewriter", "Didot", "Baskerville",
        "Rockwell", "Copperplate", "Papyrus", "Comic Sans MS"
    ]

    var body: some View {
        List {
            ForEach(Self.fonts, id: \.self) { font in
                Button {
                    viewModel.setFontName(font)
                    dismiss()
                } label: {
                    HStack {
                        Text(font)
                            .font(.custom(font, size: 17))
                            .foregroundColor(.primary)
                        Spacer()
                        if viewModel.currentStyle.fontName == font {
                            Image(systemName: "checkmark")
                                .foregroundColor(.stExcelAccent)
                        }
                    }
                }
            }
        }
        .navigationTitle(STExcelStrings.font)
        .stNavigationBarTitleDisplayMode()
    }
}

// MARK: - Color Grid (Full Page)

private enum FCColorMode {
    case textColor, fillColor
}

private struct FCColorGridView: View {
    @ObservedObject var viewModel: STExcelEditorViewModel
    let mode: FCColorMode
    @Environment(\.dismiss) private var dismiss
    @State private var customColor = Color.black

    private var title: String {
        mode == .textColor ? STExcelStrings.textColor : STExcelStrings.cellColor
    }

    private var currentHex: String? {
        mode == .textColor ? viewModel.currentStyle.textColor : viewModel.currentStyle.fillColor
    }

    private var showNone: Bool {
        mode == .fillColor
    }

    private func applyColor(_ hex: String) {
        if mode == .textColor {
            viewModel.setTextColor(hex)
        } else {
            viewModel.setFillColor(hex)
        }
    }

    private static let standardColors: [(String, Color)] = {
        var colors: [(String, Color)] = []
        let rows: [[String]] = [
            ["#D5B4D6", "#B07DB4", "#9966A3", "#7B4F8A", "#5C3D70", "#3D1F4E"],
            ["#B0BEC5", "#7E99A7", "#607D8B", "#516E7C", "#37575E", "#1C3B47"],
            ["#90CAF9", "#64B5F6", "#42A5F5", "#2196F3", "#1976D2", "#0D47A1"],
            ["#80DEEA", "#4DD0E1", "#26C6DA", "#00BCD4", "#0097A7", "#006064"],
            ["#80CBC4", "#4DB6AC", "#26A69A", "#009688", "#00796B", "#004D40"],
            ["#A5D6A7", "#81C784", "#66BB6A", "#4CAF50", "#388E3C", "#1B5E20"],
            ["#C5E1A5", "#AED581", "#9CCC65", "#8BC34A", "#689F38", "#33691E"],
            ["#FFF59D", "#FFF176", "#FFEE58", "#FFEB3B", "#FBC02D", "#F57F17"],
            ["#FFCC80", "#FFB74D", "#FFA726", "#FF9800", "#F57C00", "#E65100"],
            ["#EF9A9A", "#E57373", "#EF5350", "#F44336", "#D32F2F", "#B71C1C"],
            ["#BCAAA4", "#A1887F", "#8D6E63", "#795548", "#5D4037", "#3E2723"],
            ["#F5F5F5", "#E0E0E0", "#BDBDBD", "#9E9E9E", "#616161", "#212121"],
        ]
        for row in rows {
            for hex in row {
                if let c = Color(hex: hex) { colors.append((hex, c)) }
            }
        }
        return colors
    }()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if showNone {
                    Button {
                        applyColor("none")
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "xmark").foregroundColor(.secondary)
                            Text(STExcelStrings.noColor).foregroundColor(.primary)
                            Spacer()
                        }
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .background(Color.gray.opacity(0.15))
                        .cornerRadius(10)
                    }
                    .padding(.horizontal, 16)
                }

                Text(STExcelStrings.standardColors)
                    .font(.caption).foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)

                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 6),
                    spacing: 4
                ) {
                    ForEach(Self.standardColors, id: \.0) { hex, color in
                        Button {
                            applyColor(hex)
                            dismiss()
                        } label: {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(color)
                                .aspectRatio(1, contentMode: .fit)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(currentHex == hex ? Color.stExcelAccent : Color.clear, lineWidth: 2)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)

                Divider().padding(.horizontal, 16)

                HStack(spacing: 12) {
                    ColorPicker("", selection: $customColor, supportsOpacity: false)
                        .labelsHidden().frame(width: 36, height: 36)
                    Button {
                        applyColor(customColor.toExcelHex())
                        dismiss()
                    } label: {
                        Text(STStrings.custom)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.stExcelAccent)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
            }
            .padding(.top, 12).padding(.bottom, 20)
        }
        .navigationTitle(title)
        .stNavigationBarTitleDisplayMode()
    }
}

// MARK: - Border Tab View

private struct FCBorderTabView: View {
    @ObservedObject var viewModel: STExcelEditorViewModel
    @State private var selectedBorderStyle: STBorderStyle = .thin
    @State private var selectedPresetIndex: Int? = nil
    @State private var borderColorHex: String? = nil

    // Each preset has a unique index — selection tracked by index, not by data match
    private struct BorderPreset: Identifiable {
        let id: Int
        let icon: String
        let hasLeft: Bool
        let hasRight: Bool
        let hasTop: Bool
        let hasBottom: Bool
    }

    private static let presets: [BorderPreset] = [
        // Row 1: All, All Bold, Outside
        BorderPreset(id: 0, icon: "square.grid.3x3",                hasLeft: true, hasRight: true, hasTop: true, hasBottom: true),
        BorderPreset(id: 1, icon: "square.grid.3x3.fill",           hasLeft: true, hasRight: true, hasTop: true, hasBottom: true),
        BorderPreset(id: 2, icon: "square.grid.3x3.topleft.filled", hasLeft: true, hasRight: true, hasTop: true, hasBottom: true),
        // Row 2: Bottom, Top, Left
        BorderPreset(id: 3, icon: "square.bottomhalf.filled", hasLeft: false, hasRight: false, hasTop: false, hasBottom: true),
        BorderPreset(id: 4, icon: "square.tophalf.filled",    hasLeft: false, hasRight: false, hasTop: true,  hasBottom: false),
        BorderPreset(id: 5, icon: "square.lefthalf.filled",   hasLeft: true,  hasRight: false, hasTop: false, hasBottom: false),
        // Row 3: Right, Top+Bottom, Left+Right
        BorderPreset(id: 6, icon: "square.righthalf.filled", hasLeft: false, hasRight: true,  hasTop: false, hasBottom: false),
        BorderPreset(id: 7, icon: "square.split.1x2",       hasLeft: false, hasRight: false, hasTop: true,  hasBottom: true),
        BorderPreset(id: 8, icon: "square.split.2x1",       hasLeft: true,  hasRight: true,  hasTop: false, hasBottom: false),
    ]

    private func bordersFor(_ preset: BorderPreset) -> STCellBorders {
        // Preset id=1 is bold variant
        let style = preset.id == 1 ? STBorderStyle.medium : selectedBorderStyle
        return STCellBorders(
            left:   preset.hasLeft   ? style : .none,
            right:  preset.hasRight  ? style : .none,
            top:    preset.hasTop    ? style : .none,
            bottom: preset.hasBottom ? style : .none,
            color:  borderColorHex
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Border preset grid (3 columns)
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3),
                    spacing: 8
                ) {
                    ForEach(Self.presets) { preset in
                        Button {
                            selectedPresetIndex = preset.id
                            viewModel.setBorders(bordersFor(preset))
                        } label: {
                            Image(systemName: preset.icon)
                                .font(.system(size: 22))
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(selectedPresetIndex == preset.id ? Color.stExcelAccent : Color.gray.opacity(0.15))
                                .foregroundColor(selectedPresetIndex == preset.id ? .white : .primary)
                                .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)

                // Line Type
                NavigationLink {
                    FCLineTypePickerView(selected: $selectedBorderStyle)
                } label: {
                    HStack {
                        Text(STExcelStrings.lineType)
                            .foregroundColor(.primary)
                        Spacer()
                        fcLinePreview(selectedBorderStyle)
                            .frame(width: 100, height: 4)
                        Image(systemName: "chevron.right")
                            .font(.caption).foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                }

                // Clear Border
                Button {
                    selectedPresetIndex = nil
                    viewModel.setBorders(STCellBorders())
                } label: {
                    Text(STExcelStrings.clearBorder)
                        .font(.system(size: 16, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.gray.opacity(0.15))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                }
                .padding(.horizontal, 16)

                // Border Color
                Text(STExcelStrings.standardColors)
                    .font(.caption).foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)

                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 6),
                    spacing: 4
                ) {
                    ForEach(FCBorderColorPresets.colors, id: \.0) { hex, color in
                        Button {
                            borderColorHex = hex
                            viewModel.setBorderColor(hex)
                        } label: {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(color)
                                .aspectRatio(1, contentMode: .fit)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(borderColorHex == hex ? Color.white : Color.clear, lineWidth: 2)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(borderColorHex == hex ? Color.stExcelAccent : Color.clear, lineWidth: 3)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.top, 12)
            .padding(.bottom, 20)
        }
        .onAppear {
            borderColorHex = viewModel.currentStyle.borders.color
        }
    }
}

@ViewBuilder
private func fcLinePreview(_ style: STBorderStyle) -> some View {
    switch style {
    case .thin:
        Rectangle().fill(Color.primary).frame(height: 1)
    case .medium:
        Rectangle().fill(Color.primary).frame(height: 2)
    case .thick:
        Rectangle().fill(Color.primary).frame(height: 3)
    case .dashed:
        HStack(spacing: 3) {
            ForEach(0..<8, id: \.self) { _ in
                Rectangle().fill(Color.primary).frame(width: 8, height: 1)
            }
        }
    case .dotted:
        HStack(spacing: 2) {
            ForEach(0..<12, id: \.self) { _ in
                Circle().fill(Color.primary).frame(width: 2, height: 2)
            }
        }
    case .double_:
        VStack(spacing: 2) {
            Rectangle().fill(Color.primary).frame(height: 1)
            Rectangle().fill(Color.primary).frame(height: 1)
        }
    case .none:
        Rectangle().fill(Color.clear).frame(height: 1)
    }
}

// MARK: - Line Type Picker

private struct FCLineTypePickerView: View {
    @Binding var selected: STBorderStyle
    @Environment(\.dismiss) private var dismiss

    private static var styles: [(STBorderStyle, String)] { [
        (.thin, STExcelStrings.lineThin),
        (.medium, STExcelStrings.lineMedium),
        (.thick, STExcelStrings.lineThick),
        (.dashed, STExcelStrings.lineDashed),
        (.dotted, STExcelStrings.lineDotted),
        (.double_, STExcelStrings.lineDouble),
    ] }

    var body: some View {
        List {
            ForEach(Self.styles, id: \.0) { style, name in
                Button {
                    selected = style
                    dismiss()
                } label: {
                    HStack {
                        Text(name)
                            .foregroundColor(.primary)
                        Spacer()
                        linePreview(style)
                            .frame(width: 80)
                        if selected == style {
                            Image(systemName: "checkmark")
                                .foregroundColor(.stExcelAccent)
                        }
                    }
                }
            }
        }
        .navigationTitle(STExcelStrings.lineType)
        .stNavigationBarTitleDisplayMode()
    }

    @ViewBuilder
    private func linePreview(_ style: STBorderStyle) -> some View {
        switch style {
        case .thin:
            Rectangle().fill(Color.primary).frame(height: 1)
        case .medium:
            Rectangle().fill(Color.primary).frame(height: 2)
        case .thick:
            Rectangle().fill(Color.primary).frame(height: 3)
        case .dashed:
            HStack(spacing: 3) {
                ForEach(0..<6, id: \.self) { _ in
                    Rectangle().fill(Color.primary).frame(width: 8, height: 1)
                }
            }
        case .dotted:
            HStack(spacing: 2) {
                ForEach(0..<10, id: \.self) { _ in
                    Circle().fill(Color.primary).frame(width: 2, height: 2)
                }
            }
        case .double_:
            VStack(spacing: 2) {
                Rectangle().fill(Color.primary).frame(height: 1)
                Rectangle().fill(Color.primary).frame(height: 1)
            }
        case .none:
            Rectangle().fill(Color.clear).frame(height: 1)
        }
    }
}

// MARK: - Border Color Presets

private enum FCBorderColorPresets {
    static let colors: [(String, Color)] = {
        var result: [(String, Color)] = []
        let hexes = [
            // Same color matrix as cell/text colors
            "#D5B4D6", "#B07DB4", "#9966A3", "#7B4F8A", "#5C3D70", "#3D1F4E",
            "#B0BEC5", "#7E99A7", "#607D8B", "#516E7C", "#37575E", "#1C3B47",
            "#90CAF9", "#64B5F6", "#42A5F5", "#2196F3", "#1976D2", "#0D47A1",
            "#80DEEA", "#4DD0E1", "#26C6DA", "#00BCD4", "#0097A7", "#006064",
            "#80CBC4", "#4DB6AC", "#26A69A", "#009688", "#00796B", "#004D40",
            "#A5D6A7", "#81C784", "#66BB6A", "#4CAF50", "#388E3C", "#1B5E20",
            "#C5E1A5", "#AED581", "#9CCC65", "#8BC34A", "#689F38", "#33691E",
            "#FFF59D", "#FFF176", "#FFEE58", "#FFEB3B", "#FBC02D", "#F57F17",
            "#FFCC80", "#FFB74D", "#FFA726", "#FF9800", "#F57C00", "#E65100",
            "#EF9A9A", "#E57373", "#EF5350", "#F44336", "#D32F2F", "#B71C1C",
            "#BCAAA4", "#A1887F", "#8D6E63", "#795548", "#5D4037", "#3E2723",
            "#F5F5F5", "#E0E0E0", "#BDBDBD", "#9E9E9E", "#616161", "#212121",
        ]
        for hex in hexes {
            if let c = Color(hex: hex) {
                result.append((hex, c))
            }
        }
        return result
    }()
}
