import SwiftUI
import STKit

/// Main Conditional Formatting sheet — matches competitor layout
struct STExcelConditionalFormatView: View {
    @ObservedObject var viewModel: STExcelEditorViewModel
    let onDismiss: () -> Void

    var body: some View {
        NavigationView {
            List {
                Section(STExcelStrings.newRule) {
                    NavigationLink {
                        STExcelCFHighlightView(viewModel: viewModel, onDismiss: onDismiss)
                    } label: {
                        Text(STExcelStrings.highlightCellsRules)
                    }

                    NavigationLink {
                        STExcelCFTopBottomView(viewModel: viewModel, onDismiss: onDismiss)
                    } label: {
                        Text(STExcelStrings.topBottomAvgRules)
                    }

                    NavigationLink {
                        STExcelCFCustomFormulaView(viewModel: viewModel, onDismiss: onDismiss)
                    } label: {
                        Text(STExcelStrings.customFormula)
                    }

                    NavigationLink {
                        STExcelCFDataBarView(viewModel: viewModel, onDismiss: onDismiss)
                    } label: {
                        Text(STExcelStrings.dataBars)
                    }

                    NavigationLink {
                        STExcelCFColorScaleView(viewModel: viewModel, onDismiss: onDismiss)
                    } label: {
                        Text(STExcelStrings.colorScales)
                    }
                }

                Section(STExcelStrings.clearRules) {
                    Button {
                        let sr = min(viewModel.selectionStartRow, viewModel.selectionActualEndRow)
                        let sc = min(viewModel.selectionStartCol, viewModel.selectionActualEndCol)
                        let er = max(viewModel.selectionStartRow, viewModel.selectionActualEndRow)
                        let ec = max(viewModel.selectionStartCol, viewModel.selectionActualEndCol)
                        viewModel.clearConditionalRules(for: (sr, sc, er, ec))
                    } label: {
                        Text(STExcelStrings.fromSelection)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                    }

                    Button {
                        viewModel.clearConditionalRules()
                    } label: {
                        Text(STExcelStrings.fromEntireSheet)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                    }
                }

                if !viewModel.conditionalRules.isEmpty {
                    Section("\(STExcelStrings.activeRules) (\(viewModel.conditionalRules.count))") {
                        ForEach(viewModel.conditionalRules) { rule in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(rule.ruleType.displayName)
                                        .font(.system(size: 14, weight: .medium))
                                    Text(rule.rangeString)
                                        .font(.system(size: 12))
                                        .foregroundColor(.stExcelAccent)
                                }
                                Spacer()
                                Button {
                                    viewModel.removeConditionalRule(rule.id)
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(STExcelStrings.conditionalFormatting)
            .stNavigationBarTitleDisplayMode()
            .toolbar {
                ToolbarItem(placement: .stTrailing) {
                    Button { onDismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

// MARK: - Range Header

private struct CFRangeHeader: View {
    @Binding var rangeText: String

    var body: some View {
        HStack {
            Text(STExcelStrings.range)
                .font(.system(size: 15))
            Spacer()
            TextField("e.g. A1:F10", text: $rangeText)
                .font(.system(size: 15, design: .monospaced))
                .foregroundColor(.stExcelAccent)
                .multilineTextAlignment(.trailing)
                #if canImport(UIKit)
                .autocapitalization(.allCharacters)
                #endif
        }
    }

    /// Default range string from current selection
    static func defaultRange(from viewModel: STExcelEditorViewModel) -> String {
        let sr = min(viewModel.selectionStartRow, viewModel.selectionActualEndRow)
        let sc = min(viewModel.selectionStartCol, viewModel.selectionActualEndCol)
        let er = max(viewModel.selectionStartRow, viewModel.selectionActualEndRow)
        let ec = max(viewModel.selectionStartCol, viewModel.selectionActualEndCol)
        return "\(STExcelSheet.columnLetter(sc))\(sr + 1):\(STExcelSheet.columnLetter(ec))\(er + 1)"
    }

    /// Parse "A1:F10" → (startRow, startCol, endRow, endCol) 0-indexed, or nil
    static func parseRange(_ text: String) -> (Int, Int, Int, Int)? {
        let parts = text.uppercased().split(separator: ":")
        guard parts.count == 2 else { return nil }
        guard let (sr, sc) = parseCellRef(String(parts[0])),
              let (er, ec) = parseCellRef(String(parts[1])) else { return nil }
        guard er >= sr && ec >= sc else { return nil }
        return (sr, sc, er, ec)
    }

    private static func parseCellRef(_ ref: String) -> (Int, Int)? {
        var colStr = ""
        var rowStr = ""
        for ch in ref {
            if ch.isLetter { colStr.append(ch) }
            else if ch.isNumber { rowStr.append(ch) }
        }
        guard !colStr.isEmpty, let row = Int(rowStr), row > 0 else { return nil }
        var col = 0
        for ch in colStr {
            guard let ascii = ch.asciiValue, let aVal = Character("A").asciiValue else { continue }
            col = col * 26 + Int(ascii - aVal) + 1
        }
        return (row - 1, col - 1)
    }
}

// MARK: - Preset Picker

private struct CFPresetPicker: View {
    @Binding var selectedPreset: STExcelCFPreset

    var body: some View {
        Section(STExcelStrings.presets) {
            ForEach(STExcelCFPreset.presets) { preset in
                Button {
                    selectedPreset = preset
                } label: {
                    Text("123.456")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(preset.textColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(preset.bgColor ?? Color.stSystemBackground)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(
                                    selectedPreset.id == preset.id ? Color.stExcelAccent :
                                    (preset.borderColor ?? Color.stSeparator.opacity(0.3)),
                                    lineWidth: selectedPreset.id == preset.id ? 2.5 : (preset.borderColor != nil ? 1.5 : 0.5)
                                )
                        )
                }
                .buttonStyle(.plain)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
            }
        }
    }
}

// MARK: - Highlight Cells Rules

struct STExcelCFHighlightView: View {
    @ObservedObject var viewModel: STExcelEditorViewModel
    let onDismiss: () -> Void

    @State private var rangeText = ""
    @State private var condition: STExcelCFCondition = .greaterThan
    @State private var value1 = ""
    @State private var value2 = ""
    @State private var preset = STExcelCFPreset.presets[0]

    var body: some View {
        List {
            Section {
                CFRangeHeader(rangeText: $rangeText)
            }

            Section(STExcelStrings.newRule) {
                Picker(STExcelStrings.condition, selection: $condition) {
                    ForEach(STExcelCFCondition.allCases) { c in
                        Text(c.displayName).tag(c)
                    }
                }

                if condition.needsValue1 {
                    HStack {
                        Text(STExcelStrings.value1Label)
                        TextField(STExcelStrings.enterValue1, text: $value1)
                            .multilineTextAlignment(.trailing)
                            #if canImport(UIKit)
                            .keyboardType(.decimalPad)
                            #endif
                    }
                }

                if condition.needsValue2 {
                    HStack {
                        Text(STExcelStrings.value2Label)
                        TextField(STExcelStrings.enterValue2, text: $value2)
                            .multilineTextAlignment(.trailing)
                            #if canImport(UIKit)
                            .keyboardType(.decimalPad)
                            #endif
                    }
                }
            }

            CFPresetPicker(selectedPreset: $preset)
        }
        .navigationTitle(STExcelStrings.highlightCellsRules)
        .stNavigationBarTitleDisplayMode()
        .toolbar {
            ToolbarItem(placement: .stTrailing) {
                Button(STExcelStrings.apply) { apply() }
                    .fontWeight(.semibold)
                    .foregroundColor(.stExcelAccent)
                    .disabled(CFRangeHeader.parseRange(rangeText) == nil)
            }
        }
        .onAppear { rangeText = CFRangeHeader.defaultRange(from: viewModel) }
    }

    private func apply() {
        guard let (sr, sc, er, ec) = CFRangeHeader.parseRange(rangeText) else { return }

        var rule = STExcelConditionalRule(
            startRow: sr, startCol: sc, endRow: er, endCol: ec,
            ruleType: .highlightCells
        )
        rule.condition = condition
        rule.value1 = value1
        rule.value2 = value2
        rule.preset = preset
        viewModel.addConditionalRule(rule)
        onDismiss()
    }
}

// MARK: - Top/Bottom/Average Rules

struct STExcelCFTopBottomView: View {
    @ObservedObject var viewModel: STExcelEditorViewModel
    let onDismiss: () -> Void

    @State private var rangeText = ""
    @State private var rank: STExcelCFRank = .top
    @State private var count: Int = 10
    @State private var isPercent = false
    @State private var preset = STExcelCFPreset.presets[0]

    var body: some View {
        List {
            Section {
                CFRangeHeader(rangeText: $rangeText)
            }

            Section(STExcelStrings.newRule) {
                Picker(STExcelStrings.rank, selection: $rank) {
                    ForEach(STExcelCFRank.allCases) { r in
                        Text(r.displayName).tag(r)
                    }
                }

                if rank.needsCount {
                    HStack {
                        Text(STExcelStrings.count)
                        Spacer()
                        Text("\(count)")
                            .foregroundColor(.stExcelAccent)
                            .frame(width: 40)
                        Stepper("", value: $count, in: 1...100)
                            .labelsHidden()
                    }

                    HStack {
                        Text(STExcelStrings.cfItems)
                            .foregroundColor(!isPercent ? .stExcelAccent : .primary)
                        Spacer()
                        Toggle("", isOn: $isPercent)
                            .labelsHidden()
                        Spacer()
                        Text(STExcelStrings.percent)
                            .foregroundColor(isPercent ? .stExcelAccent : .primary)
                    }
                }
            }

            CFPresetPicker(selectedPreset: $preset)
        }
        .navigationTitle(STExcelStrings.topBottomAvgRules)
        .stNavigationBarTitleDisplayMode()
        .toolbar {
            ToolbarItem(placement: .stTrailing) {
                Button(STExcelStrings.apply) { apply() }
                    .fontWeight(.semibold)
                    .foregroundColor(.stExcelAccent)
                    .disabled(CFRangeHeader.parseRange(rangeText) == nil)
            }
        }
        .onAppear { rangeText = CFRangeHeader.defaultRange(from: viewModel) }
    }

    private func apply() {
        guard let (sr, sc, er, ec) = CFRangeHeader.parseRange(rangeText) else { return }

        var rule = STExcelConditionalRule(
            startRow: sr, startCol: sc, endRow: er, endCol: ec,
            ruleType: .topBottom
        )
        rule.rank = rank
        rule.rankCount = count
        rule.rankIsPercent = isPercent
        rule.preset = preset
        viewModel.addConditionalRule(rule)
        onDismiss()
    }
}

// MARK: - Data Bars

struct STExcelCFDataBarView: View {
    @ObservedObject var viewModel: STExcelEditorViewModel
    let onDismiss: () -> Void

    @State private var rangeText = ""
    @State private var barColor: STExcelCFBarColor = .blue

    var body: some View {
        List {
            Section {
                CFRangeHeader(rangeText: $rangeText)
            }

            Section(STExcelStrings.barColor) {
                LazyVGrid(columns: [
                    GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()),
                ], spacing: 12) {
                    ForEach(STExcelCFBarColor.allCases) { color in
                        Button {
                            barColor = color
                        } label: {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(color.color.opacity(0.3))
                                .frame(height: 36)
                                .overlay(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(color.color.opacity(0.7))
                                        .frame(width: 50, height: 28)
                                        .padding(.leading, 4)
                                }
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(barColor == color ? Color.stExcelAccent : Color.stSeparator,
                                                lineWidth: barColor == color ? 2.5 : 0.5)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .navigationTitle(STExcelStrings.dataBars)
        .stNavigationBarTitleDisplayMode()
        .toolbar {
            ToolbarItem(placement: .stTrailing) {
                Button(STExcelStrings.apply) { apply() }
                    .fontWeight(.semibold)
                    .foregroundColor(.stExcelAccent)
                    .disabled(CFRangeHeader.parseRange(rangeText) == nil)
            }
        }
        .onAppear { rangeText = CFRangeHeader.defaultRange(from: viewModel) }
    }

    private func apply() {
        guard let (sr, sc, er, ec) = CFRangeHeader.parseRange(rangeText) else { return }

        var rule = STExcelConditionalRule(
            startRow: sr, startCol: sc, endRow: er, endCol: ec,
            ruleType: .dataBar
        )
        rule.barColor = barColor
        viewModel.addConditionalRule(rule)
        onDismiss()
    }
}

// MARK: - Color Scales

struct STExcelCFColorScaleView: View {
    @ObservedObject var viewModel: STExcelEditorViewModel
    let onDismiss: () -> Void

    @State private var rangeText = ""
    @State private var colorScale: STExcelCFColorScale = .greenYellowRed

    var body: some View {
        List {
            Section {
                CFRangeHeader(rangeText: $rangeText)
            }

            Section(STExcelStrings.colorScaleSection) {
                ForEach(STExcelCFColorScale.allCases) { scale in
                    Button {
                        colorScale = scale
                    } label: {
                        HStack(spacing: 0) {
                            LinearGradient(
                                colors: [scale.lowColor, scale.midColor, scale.highColor],
                                startPoint: .leading, endPoint: .trailing
                            )
                            .frame(height: 32)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(colorScale == scale ? Color.stExcelAccent : Color.stSeparator,
                                        lineWidth: colorScale == scale ? 2.5 : 0.5)
                        )
                    }
                    .buttonStyle(.plain)
                    .listRowSeparator(.hidden)
                }
            }
        }
        .navigationTitle(STExcelStrings.colorScales)
        .stNavigationBarTitleDisplayMode()
        .toolbar {
            ToolbarItem(placement: .stTrailing) {
                Button(STExcelStrings.apply) { apply() }
                    .fontWeight(.semibold)
                    .foregroundColor(.stExcelAccent)
                    .disabled(CFRangeHeader.parseRange(rangeText) == nil)
            }
        }
        .onAppear { rangeText = CFRangeHeader.defaultRange(from: viewModel) }
    }

    private func apply() {
        guard let (sr, sc, er, ec) = CFRangeHeader.parseRange(rangeText) else { return }

        var rule = STExcelConditionalRule(
            startRow: sr, startCol: sc, endRow: er, endCol: ec,
            ruleType: .colorScale
        )
        rule.colorScale = colorScale
        viewModel.addConditionalRule(rule)
        onDismiss()
    }
}

// MARK: - Custom Formula

struct STExcelCFCustomFormulaView: View {
    @ObservedObject var viewModel: STExcelEditorViewModel
    let onDismiss: () -> Void

    @State private var rangeText = ""
    @State private var formula = ""
    @State private var preset = STExcelCFPreset.presets[0]

    var body: some View {
        List {
            Section {
                CFRangeHeader(rangeText: $rangeText)
            }

            Section(STExcelStrings.formulaSection) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(STExcelStrings.formatCellsFormula)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    TextField("e.g. =A1>100", text: $formula)
                        .font(.system(size: 15, design: .monospaced))
                        #if canImport(UIKit)
                        .autocapitalization(.none)
                        #endif
                }
            }

            CFPresetPicker(selectedPreset: $preset)
        }
        .navigationTitle(STExcelStrings.customFormula)
        .stNavigationBarTitleDisplayMode()
        .toolbar {
            ToolbarItem(placement: .stTrailing) {
                Button(STExcelStrings.apply) { apply() }
                    .fontWeight(.semibold)
                    .foregroundColor(.stExcelAccent)
                    .disabled(formula.trimmingCharacters(in: .whitespaces).isEmpty || CFRangeHeader.parseRange(rangeText) == nil)
            }
        }
        .onAppear { rangeText = CFRangeHeader.defaultRange(from: viewModel) }
    }

    private func apply() {
        guard let (sr, sc, er, ec) = CFRangeHeader.parseRange(rangeText) else { return }

        var rule = STExcelConditionalRule(
            startRow: sr, startCol: sc, endRow: er, endCol: ec,
            ruleType: .customFormula
        )
        rule.formula = formula
        rule.preset = preset
        viewModel.addConditionalRule(rule)
        onDismiss()
    }
}
