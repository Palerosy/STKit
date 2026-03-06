import SwiftUI
import STKit

/// Number format picker — matches competitor "Format Cells > Number" layout
struct STExcelNumberFormatPicker: View {
    let onSelect: (STNumberFormat) -> Void
    var onSelectCode: ((Int, String) -> Void)?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                ForEach(STNumberFormat.allCases, id: \.rawValue) { format in
                    if format.hasSubOptions {
                        NavigationLink {
                            formatDetailView(format)
                        } label: {
                            formatRow(format)
                        }
                    } else {
                        Button {
                            onSelect(format)
                        } label: {
                            formatRow(format)
                        }
                    }
                }
            }
            .navigationTitle(STExcelStrings.numberFormat)
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
    }

    private func formatRow(_ format: STNumberFormat) -> some View {
        HStack {
            Text(format.displayName)
                .font(.system(size: 16))
                .foregroundColor(.primary)
            Spacer()
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private func formatDetailView(_ format: STNumberFormat) -> some View {
        switch format {
        case .number:
            NFNumberDetailView { code in applyCode(format, code) }
        case .currency:
            NFCurrencyDetailView { code in applyCode(format, code) }
        case .accounting:
            NFAccountingDetailView { code in applyCode(format, code) }
        case .date:
            NFDateDetailView { code in applyCode(format, code) }
        case .time:
            NFTimeDetailView { code in applyCode(format, code) }
        case .percent:
            NFPercentDetailView { code in applyCode(format, code) }
        case .fraction:
            NFFractionDetailView { code in applyCode(format, code) }
        case .scientific:
            NFScientificDetailView { code in applyCode(format, code) }
        case .special:
            NFSpecialDetailView { code in applyCode(format, code) }
        case .custom:
            NFCustomDetailView { code in applyCode(.custom, code) }
        default:
            EmptyView()
        }
    }

    private func applyCode(_ format: STNumberFormat, _ code: String) {
        if let onSelectCode {
            onSelectCode(format.rawValue, code)
        } else {
            onSelect(format)
        }
    }
}

// MARK: - Number Detail

private struct NFNumberDetailView: View {
    let onApply: (String) -> Void
    @State private var decimalPlaces: Int = 2
    @State private var use1000Separator = true
    @State private var negativeStyle = 0
    @Environment(\.dismiss) private var dismiss

    private var formatCode: String {
        let decimals = decimalPlaces > 0 ? "." + String(repeating: "0", count: decimalPlaces) : ""
        let base = use1000Separator ? "#,##0\(decimals)" : "0\(decimals)"
        return base
    }

    var body: some View {
        List {
            HStack {
                Text(STExcelStrings.decimalPlaces)
                Spacer()
                Text("\(decimalPlaces)")
                    .foregroundColor(.stExcelAccent)
                    .frame(width: 30)
                Stepper("", value: $decimalPlaces, in: 0...30).labelsHidden()
            }
            Toggle(STExcelStrings.use1000Separator, isOn: $use1000Separator)
            NavigationLink {
                NFNegativeStylePicker(selection: $negativeStyle)
            } label: {
                HStack {
                    Text(STExcelStrings.negativeNumbers)
                    Spacer()
                    Text(negativePreview)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle(STExcelStrings.number)
        .stNavigationBarTitleDisplayMode()
        .toolbar {
            ToolbarItem(placement: .stTrailing) {
                Button(STStrings.done) { onApply(formatCode); dismiss() }
                    .fontWeight(.semibold).foregroundColor(.stExcelAccent)
            }
        }
    }

    private var negativePreview: String {
        switch negativeStyle {
        case 1: return "(1,234.00)"
        case 2: return "-1,234.00"
        default: return "-1,234.00"
        }
    }
}

// MARK: - Currency Detail

private struct NFCurrencyDetailView: View {
    let onApply: (String) -> Void
    @State private var decimalPlaces: Int = 2
    @State private var negativeStyle = 0
    @State private var symbol = "$"
    @Environment(\.dismiss) private var dismiss

    private static let symbols: [(label: String, symbol: String)] = [
        ("$ English (United States)", "$"),
        ("€ Euro (123 €)", "€"),
        ("€ Euro (€ 123)", "€"),
        ("£ English (United Kingdom)", "£"),
        ("¥ Japanese (Japan)", "¥"),
        ("None", ""),
    ]

    private var formatCode: String {
        let decimals = decimalPlaces > 0 ? "." + String(repeating: "0", count: decimalPlaces) : ""
        if symbol.isEmpty { return "#,##0\(decimals)" }
        return "\(symbol)#,##0\(decimals)"
    }

    var body: some View {
        List {
            HStack {
                Text(STExcelStrings.decimalPlaces)
                Spacer()
                Text("\(decimalPlaces)")
                    .foregroundColor(.stExcelAccent)
                    .frame(width: 30)
                Stepper("", value: $decimalPlaces, in: 0...30).labelsHidden()
            }
            NavigationLink {
                NFNegativeStylePicker(selection: $negativeStyle)
            } label: {
                HStack {
                    Text(STExcelStrings.negativeNumbers)
                    Spacer()
                    Text("-\(symbol) 1,234.00")
                        .foregroundColor(.secondary)
                }
            }

            ForEach(Self.symbols.indices, id: \.self) { i in
                Button {
                    symbol = Self.symbols[i].symbol
                } label: {
                    HStack {
                        Text(Self.symbols[i].label)
                            .foregroundColor(.primary)
                        Spacer()
                        if symbol == Self.symbols[i].symbol && (i == 0 || Self.symbols[i].symbol != symbol || i == Self.symbols.indices.first(where: { Self.symbols[$0].symbol == symbol })) {
                            Image(systemName: "checkmark")
                                .foregroundColor(.stExcelAccent)
                        }
                    }
                }
            }
        }
        .navigationTitle(STExcelStrings.currency)
        .stNavigationBarTitleDisplayMode()
        .toolbar {
            ToolbarItem(placement: .stTrailing) {
                Button(STStrings.done) { onApply(formatCode); dismiss() }
                    .fontWeight(.semibold).foregroundColor(.stExcelAccent)
            }
        }
    }
}

// MARK: - Accounting Detail

private struct NFAccountingDetailView: View {
    let onApply: (String) -> Void
    @State private var decimalPlaces: Int = 2
    @State private var symbol = "$"
    @Environment(\.dismiss) private var dismiss

    private static let symbols: [(label: String, symbol: String)] = [
        ("$ English (United States)", "$"),
        ("€ Euro (123 €)", "€"),
        ("€ Euro (€ 123)", "€"),
        ("£ English (United Kingdom)", "£"),
        ("¥ Japanese (Japan)", "¥"),
    ]

    private var formatCode: String {
        let decimals = decimalPlaces > 0 ? "." + String(repeating: "0", count: decimalPlaces) : ""
        return "_(\(symbol)* #,##0\(decimals)_)"
    }

    var body: some View {
        List {
            HStack {
                Text(STExcelStrings.decimalPlaces)
                Spacer()
                Text("\(decimalPlaces)")
                    .foregroundColor(.stExcelAccent)
                    .frame(width: 30)
                Stepper("", value: $decimalPlaces, in: 0...30).labelsHidden()
            }

            ForEach(Self.symbols.indices, id: \.self) { i in
                Button {
                    symbol = Self.symbols[i].symbol
                } label: {
                    HStack {
                        Text(Self.symbols[i].label).foregroundColor(.primary)
                        Spacer()
                        if symbol == Self.symbols[i].symbol {
                            Image(systemName: "checkmark").foregroundColor(.stExcelAccent)
                        }
                    }
                }
            }
        }
        .navigationTitle(STExcelStrings.accounting)
        .stNavigationBarTitleDisplayMode()
        .toolbar {
            ToolbarItem(placement: .stTrailing) {
                Button(STStrings.done) { onApply(formatCode); dismiss() }
                    .fontWeight(.semibold).foregroundColor(.stExcelAccent)
            }
        }
    }
}

// MARK: - Date Detail

private struct NFDateDetailView: View {
    let onApply: (String) -> Void
    @State private var selected = "dd/mm/yyyy"
    @Environment(\.dismiss) private var dismiss

    private static let formats: [(display: String, code: String)] = [
        ("* 22/06/2015", "dd/mm/yyyy"),
        ("* Monday, June 22, 2015", "dddd, mmmm d, yyyy"),
        ("22/06/2015", "dd/mm/yyyy"),
        ("22/06/15", "dd/mm/yy"),
        ("22/6/15", "d/m/yy"),
        ("22.6.15", "d.m.yy"),
        ("22 June 2015", "d mmmm yyyy"),
        ("6/22", "m/d"),
        ("6/22/15", "m/d/yy"),
        ("6/22/2015", "m/d/yyyy"),
        ("06/22/15", "mm/dd/yy"),
        ("06/22/2015", "mm/dd/yyyy"),
        ("22-Jun", "d-mmm"),
        ("Jun-15", "mmm-yy"),
        ("June 2015", "mmmm yyyy"),
        ("2015-06-22", "yyyy-mm-dd"),
    ]

    var body: some View {
        List {
            ForEach(Self.formats, id: \.code) { fmt in
                Button {
                    selected = fmt.code
                    onApply(fmt.code)
                    dismiss()
                } label: {
                    HStack {
                        Text(fmt.display).foregroundColor(.primary)
                        Spacer()
                        if selected == fmt.code {
                            Image(systemName: "checkmark").foregroundColor(.stExcelAccent)
                        }
                    }
                }
            }
        }
        .navigationTitle(STExcelStrings.date)
        .stNavigationBarTitleDisplayMode()
    }
}

// MARK: - Time Detail

private struct NFTimeDetailView: View {
    let onApply: (String) -> Void
    @State private var selected = "h:mm:ss AM/PM"
    @Environment(\.dismiss) private var dismiss

    private static let formats: [(display: String, code: String)] = [
        ("* 1:30:00 pm", "h:mm:ss AM/PM"),
        ("1:30 PM", "h:mm AM/PM"),
        ("13:30", "h:mm"),
        ("1:30:00 PM", "h:mm:ss AM/PM"),
        ("13:30:00", "hh:mm:ss"),
        ("30:00.0", "mm:ss.0"),
        ("37:30:55", "[h]:mm:ss"),
        ("6/22/15 1:30 PM", "m/d/yy h:mm AM/PM"),
        ("6/22/15 13:30", "m/d/yy h:mm"),
        ("2015-06-22 13:30", "yyyy-mm-dd hh:mm"),
        ("01:30:00 PM", "hh:mm:ss AM/PM"),
    ]

    var body: some View {
        List {
            ForEach(Self.formats, id: \.code) { fmt in
                Button {
                    selected = fmt.code
                    onApply(fmt.code)
                    dismiss()
                } label: {
                    HStack {
                        Text(fmt.display).foregroundColor(.primary)
                        Spacer()
                        if selected == fmt.code {
                            Image(systemName: "checkmark").foregroundColor(.stExcelAccent)
                        }
                    }
                }
            }
        }
        .navigationTitle(STExcelStrings.time)
        .stNavigationBarTitleDisplayMode()
    }
}

// MARK: - Percentage Detail

private struct NFPercentDetailView: View {
    let onApply: (String) -> Void
    @State private var decimalPlaces: Int = 2
    @Environment(\.dismiss) private var dismiss

    private var formatCode: String {
        let decimals = decimalPlaces > 0 ? "." + String(repeating: "0", count: decimalPlaces) : ""
        return "0\(decimals)%"
    }

    var body: some View {
        List {
            HStack {
                Text(STExcelStrings.decimalPlaces)
                Spacer()
                Text("\(decimalPlaces)")
                    .foregroundColor(.stExcelAccent)
                    .frame(width: 30)
                Stepper("", value: $decimalPlaces, in: 0...30).labelsHidden()
            }
        }
        .navigationTitle(STExcelStrings.percentage)
        .stNavigationBarTitleDisplayMode()
        .toolbar {
            ToolbarItem(placement: .stTrailing) {
                Button(STStrings.done) { onApply(formatCode); dismiss() }
                    .fontWeight(.semibold).foregroundColor(.stExcelAccent)
            }
        }
    }
}

// MARK: - Fraction Detail

private struct NFFractionDetailView: View {
    let onApply: (String) -> Void
    @State private var selected = "# ?/?"
    @Environment(\.dismiss) private var dismiss

    private static let formats: [(display: String, code: String)] = [
        ("Up to one digit (1/4)", "# ?/?"),
        ("Up to two digits (10/25)", "# ??/??"),
        ("Up to three digits (300/850)", "# ???/???"),
        ("As halves (1/2)", "# ?/2"),
        ("As quarters (2/4)", "# ?/4"),
        ("As eighths (4/8)", "# ?/8"),
        ("As sixteenths (8/16)", "# ?/16"),
        ("As tenths (5/10)", "# ?/10"),
        ("As hundredths (50/100)", "# ??/100"),
    ]

    var body: some View {
        List {
            ForEach(Self.formats, id: \.code) { fmt in
                Button {
                    selected = fmt.code
                    onApply(fmt.code)
                    dismiss()
                } label: {
                    HStack {
                        Text(fmt.display).foregroundColor(.primary)
                        Spacer()
                        if selected == fmt.code {
                            Image(systemName: "checkmark").foregroundColor(.stExcelAccent)
                        }
                    }
                }
            }
        }
        .navigationTitle(STExcelStrings.fraction)
        .stNavigationBarTitleDisplayMode()
    }
}

// MARK: - Scientific Detail

private struct NFScientificDetailView: View {
    let onApply: (String) -> Void
    @State private var decimalPlaces: Int = 2
    @Environment(\.dismiss) private var dismiss

    private var formatCode: String {
        let decimals = decimalPlaces > 0 ? "." + String(repeating: "0", count: decimalPlaces) : ""
        return "0\(decimals)E+00"
    }

    var body: some View {
        List {
            HStack {
                Text(STExcelStrings.decimalPlaces)
                Spacer()
                Text("\(decimalPlaces)")
                    .foregroundColor(.stExcelAccent)
                    .frame(width: 30)
                Stepper("", value: $decimalPlaces, in: 0...30).labelsHidden()
            }
        }
        .navigationTitle(STExcelStrings.scientific)
        .stNavigationBarTitleDisplayMode()
        .toolbar {
            ToolbarItem(placement: .stTrailing) {
                Button(STStrings.done) { onApply(formatCode); dismiss() }
                    .fontWeight(.semibold).foregroundColor(.stExcelAccent)
            }
        }
    }
}

// MARK: - Special Detail

private struct NFSpecialDetailView: View {
    let onApply: (String) -> Void
    @State private var selected = "00000"
    @Environment(\.dismiss) private var dismiss

    private static let formats: [(display: String, code: String)] = [
        ("Postcode", "00000"),
        ("Phone Number", "[<=9999999]###-####;(###) ###-####"),
        ("Social Security Number", "000-00-0000"),
    ]

    var body: some View {
        List {
            ForEach(Self.formats, id: \.code) { fmt in
                Button {
                    selected = fmt.code
                    onApply(fmt.code)
                    dismiss()
                } label: {
                    HStack {
                        Text(fmt.display).foregroundColor(.primary)
                        Spacer()
                        if selected == fmt.code {
                            Image(systemName: "checkmark").foregroundColor(.stExcelAccent)
                        }
                    }
                }
            }
        }
        .navigationTitle(STExcelStrings.special)
        .stNavigationBarTitleDisplayMode()
    }
}

// MARK: - Custom Detail

private struct NFCustomDetailView: View {
    let onApply: (String) -> Void
    @State private var customCode = ""
    @Environment(\.dismiss) private var dismiss

    private static let presets: [String] = [
        "General", "0", "0.00", "#,##0", "#,##0.00",
        "\"$\"#,##0_);(\"$\"#,##0)",
        "\"$\"#,##0_);[Red](\"$\"#,##0)",
        "\"$\"#,##0.00_);(\"$\"#,##0.00)",
        "\"$\"#,##0.00;[Red](\"$\"#,##0.00)",
        "0%", "0.00%", "0.00E+00", "# ?/?", "# ??/??",
        "mm/dd/yyyy", "d-mmm-yy", "d-mmm", "mmm-yy",
        "h:mm AM/PM", "h:mm:ss AM/PM", "hh:mm", "hh:mm:ss",
        "mm/dd/yyyy hh:mm",
    ]

    var body: some View {
        List {
            TextField(STExcelStrings.custom, text: $customCode)
                .font(.system(size: 15, design: .monospaced))
                .foregroundColor(.stExcelAccent)
                .padding(.vertical, 4)

            ForEach(Self.presets, id: \.self) { code in
                Button {
                    customCode = code
                } label: {
                    Text(code)
                        .font(.system(size: 15))
                        .foregroundColor(.primary)
                }
            }
        }
        .navigationTitle(STExcelStrings.custom)
        .stNavigationBarTitleDisplayMode()
        .toolbar {
            ToolbarItem(placement: .stTrailing) {
                Button(STStrings.done) {
                    let code = customCode.isEmpty ? "General" : customCode
                    onApply(code)
                    dismiss()
                }
                .fontWeight(.semibold).foregroundColor(.stExcelAccent)
            }
        }
    }
}

// MARK: - Negative Number Style Picker

private struct NFNegativeStylePicker: View {
    @Binding var selection: Int

    var body: some View {
        List {
            ForEach(0..<3, id: \.self) { i in
                Button {
                    selection = i
                } label: {
                    HStack {
                        Text(label(i))
                            .foregroundColor(i == 1 ? .red : .primary)
                        Spacer()
                        if selection == i {
                            Image(systemName: "checkmark").foregroundColor(.stExcelAccent)
                        }
                    }
                }
            }
        }
        .navigationTitle(STExcelStrings.negativeNumbers)
        .stNavigationBarTitleDisplayMode()
    }

    private func label(_ i: Int) -> String {
        switch i {
        case 0: return "-1,234.00"
        case 1: return "1,234.00"
        case 2: return "(1,234.00)"
        default: return "-1,234.00"
        }
    }
}
