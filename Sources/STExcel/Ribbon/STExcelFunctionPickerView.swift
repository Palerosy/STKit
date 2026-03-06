import SwiftUI
import STKit

/// Function definition used by category pickers and Insert Function browser
struct STExcelFunctionDef: Identifiable {
    let id: String
    let name: String
    let syntax: String
    let description: String
    let category: STExcelFunctionCategory
    /// If true, selected range is auto-filled as argument (SUM, AVERAGE, etc.)
    let isRangeFunction: Bool

    init(_ name: String, syntax: String, description: String, category: STExcelFunctionCategory, isRange: Bool = false) {
        self.id = name
        self.name = name
        self.syntax = syntax
        self.description = description
        self.category = category
        self.isRangeFunction = isRange
    }
}

enum STExcelFunctionCategory: String, CaseIterable {
    case financial = "Financial"
    case logical = "Logical"
    case text = "Text"
    case dateTime = "Date & Time"
    case reference = "Reference"
    case math = "Math & Trig"

    var iconName: String {
        switch self {
        case .financial: return "dollarsign"
        case .logical: return "questionmark.diamond"
        case .text: return "textformat.abc"
        case .dateTime: return "calendar.circle"
        case .reference: return "magnifyingglass"
        case .math: return "x.squareroot"
        }
    }

    var displayName: String {
        switch self {
        case .financial: return STExcelStrings.financial
        case .logical: return STExcelStrings.logical
        case .text: return STExcelStrings.textFunctions
        case .dateTime: return STExcelStrings.dateTime
        case .reference: return STExcelStrings.reference
        case .math: return STExcelStrings.math
        }
    }
}

// MARK: - Function Database

enum STExcelFunctionDB {
    static var all: [STExcelFunctionDef] { financial + logical + text + dateTime + reference + math }

    static var financial: [STExcelFunctionDef] { [
        .init("PMT", syntax: "PMT(rate, nper, pv)", description: STExcelStrings.funcPMT, category: .financial),
        .init("FV", syntax: "FV(rate, nper, pmt)", description: STExcelStrings.funcFV, category: .financial),
        .init("PV", syntax: "PV(rate, nper, pmt)", description: STExcelStrings.funcPV, category: .financial),
        .init("RATE", syntax: "RATE(nper, pmt, pv)", description: STExcelStrings.funcRATE, category: .financial),
        .init("NPV", syntax: "NPV(rate, value1, value2, ...)", description: STExcelStrings.funcNPV, category: .financial),
        .init("IRR", syntax: "IRR(values)", description: STExcelStrings.funcIRR, category: .financial),
    ] }

    static var logical: [STExcelFunctionDef] { [
        .init("IF", syntax: "IF(condition, value_if_true, value_if_false)", description: STExcelStrings.funcIF, category: .logical),
        .init("AND", syntax: "AND(logical1, logical2, ...)", description: STExcelStrings.funcAND, category: .logical),
        .init("OR", syntax: "OR(logical1, logical2, ...)", description: STExcelStrings.funcOR, category: .logical),
        .init("NOT", syntax: "NOT(logical)", description: STExcelStrings.funcNOT, category: .logical),
        .init("IFERROR", syntax: "IFERROR(value, value_if_error)", description: STExcelStrings.funcIFERROR, category: .logical),
        .init("TRUE", syntax: "TRUE()", description: STExcelStrings.funcTRUE, category: .logical),
        .init("FALSE", syntax: "FALSE()", description: STExcelStrings.funcFALSE, category: .logical),
    ] }

    static var text: [STExcelFunctionDef] { [
        .init("CONCATENATE", syntax: "CONCATENATE(text1, text2, ...)", description: STExcelStrings.funcCONCATENATE, category: .text),
        .init("LEN", syntax: "LEN(text)", description: STExcelStrings.funcLEN, category: .text),
        .init("LEFT", syntax: "LEFT(text, num_chars)", description: STExcelStrings.funcLEFT, category: .text),
        .init("RIGHT", syntax: "RIGHT(text, num_chars)", description: STExcelStrings.funcRIGHT, category: .text),
        .init("MID", syntax: "MID(text, start, num_chars)", description: STExcelStrings.funcMID, category: .text),
        .init("UPPER", syntax: "UPPER(text)", description: STExcelStrings.funcUPPER, category: .text),
        .init("LOWER", syntax: "LOWER(text)", description: STExcelStrings.funcLOWER, category: .text),
        .init("TRIM", syntax: "TRIM(text)", description: STExcelStrings.funcTRIM, category: .text),
        .init("FIND", syntax: "FIND(find_text, within_text)", description: STExcelStrings.funcFIND, category: .text),
        .init("REPLACE", syntax: "REPLACE(old_text, start, num_chars, new_text)", description: STExcelStrings.funcREPLACE, category: .text),
        .init("SUBSTITUTE", syntax: "SUBSTITUTE(text, old_text, new_text)", description: STExcelStrings.funcSUBSTITUTE, category: .text),
    ] }

    static var dateTime: [STExcelFunctionDef] { [
        .init("NOW", syntax: "NOW()", description: STExcelStrings.funcNOW, category: .dateTime),
        .init("TODAY", syntax: "TODAY()", description: STExcelStrings.funcTODAY, category: .dateTime),
        .init("DATE", syntax: "DATE(year, month, day)", description: STExcelStrings.funcDATE, category: .dateTime),
        .init("YEAR", syntax: "YEAR(serial_number)", description: STExcelStrings.funcYEAR, category: .dateTime),
        .init("MONTH", syntax: "MONTH(serial_number)", description: STExcelStrings.funcMONTH, category: .dateTime),
        .init("DAY", syntax: "DAY(serial_number)", description: STExcelStrings.funcDAY, category: .dateTime),
        .init("HOUR", syntax: "HOUR(serial_number)", description: STExcelStrings.funcHOUR, category: .dateTime),
        .init("MINUTE", syntax: "MINUTE(serial_number)", description: STExcelStrings.funcMINUTE, category: .dateTime),
        .init("SECOND", syntax: "SECOND(serial_number)", description: STExcelStrings.funcSECOND, category: .dateTime),
    ] }

    static var reference: [STExcelFunctionDef] { [
        .init("VLOOKUP", syntax: "VLOOKUP(lookup_value, table_array, col_index, range_lookup)", description: STExcelStrings.funcVLOOKUP, category: .reference),
        .init("HLOOKUP", syntax: "HLOOKUP(lookup_value, table_array, row_index, range_lookup)", description: STExcelStrings.funcHLOOKUP, category: .reference),
        .init("INDEX", syntax: "INDEX(array, row_num, col_num)", description: STExcelStrings.funcINDEX, category: .reference),
        .init("MATCH", syntax: "MATCH(lookup_value, lookup_array, match_type)", description: STExcelStrings.funcMATCH, category: .reference),
        .init("CHOOSE", syntax: "CHOOSE(index_num, value1, value2, ...)", description: STExcelStrings.funcCHOOSE, category: .reference),
        .init("INDIRECT", syntax: "INDIRECT(ref_text)", description: STExcelStrings.funcINDIRECT, category: .reference),
    ] }

    static var math: [STExcelFunctionDef] { [
        .init("SUM", syntax: "SUM(number1, number2, ...)", description: STExcelStrings.funcSUM, category: .math, isRange: true),
        .init("AVERAGE", syntax: "AVERAGE(number1, number2, ...)", description: STExcelStrings.funcAVERAGE, category: .math, isRange: true),
        .init("COUNT", syntax: "COUNT(value1, value2, ...)", description: STExcelStrings.funcCOUNT, category: .math, isRange: true),
        .init("COUNTA", syntax: "COUNTA(value1, value2, ...)", description: STExcelStrings.funcCOUNTA, category: .math, isRange: true),
        .init("MIN", syntax: "MIN(number1, number2, ...)", description: STExcelStrings.funcMIN, category: .math, isRange: true),
        .init("MAX", syntax: "MAX(number1, number2, ...)", description: STExcelStrings.funcMAX, category: .math, isRange: true),
        .init("ABS", syntax: "ABS(number)", description: STExcelStrings.funcABS, category: .math),
        .init("ROUND", syntax: "ROUND(number, num_digits)", description: STExcelStrings.funcROUND, category: .math),
        .init("INT", syntax: "INT(number)", description: STExcelStrings.funcINT, category: .math),
        .init("MOD", syntax: "MOD(number, divisor)", description: STExcelStrings.funcMOD, category: .math),
        .init("POWER", syntax: "POWER(number, power)", description: STExcelStrings.funcPOWER, category: .math),
        .init("SQRT", syntax: "SQRT(number)", description: STExcelStrings.funcSQRT, category: .math),
        .init("SUMIF", syntax: "SUMIF(range, criteria, sum_range)", description: STExcelStrings.funcSUMIF, category: .math),
        .init("COUNTIF", syntax: "COUNTIF(range, criteria)", description: STExcelStrings.funcCOUNTIF, category: .math),
        .init("PRODUCT", syntax: "PRODUCT(number1, number2, ...)", description: STExcelStrings.funcPRODUCT, category: .math, isRange: true),
    ] }

    static func functions(for category: STExcelFunctionCategory) -> [STExcelFunctionDef] {
        switch category {
        case .financial: return financial
        case .logical: return logical
        case .text: return text
        case .dateTime: return dateTime
        case .reference: return reference
        case .math: return math
        }
    }
}

// MARK: - Category Function Picker (single category)

struct STExcelCategoryFunctionPicker: View {
    let category: STExcelFunctionCategory
    @ObservedObject var viewModel: STExcelEditorViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Spacer()
                Text(category.displayName)
                    .font(.headline)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)

            List {
                ForEach(STExcelFunctionDB.functions(for: category)) { fn in
                    Button {
                        insertFunction(fn)
                        dismiss()
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(fn.name)
                                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                                .foregroundColor(.stExcelAccent)
                            Text(fn.syntax)
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundColor(.secondary)
                            Text(fn.description)
                                .font(.system(size: 13))
                                .foregroundColor(.primary)
                                .lineLimit(2)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .listStyle(.plain)
        }
    }

    private func insertFunction(_ fn: STExcelFunctionDef) {
        // Set the formula text first, then dismiss — isEditing will be set after sheet closes
        viewModel.pendingFunction = (fn.name, fn.isRangeFunction)
        dismiss()
    }
}

// MARK: - Insert Function (all categories browser)

struct STExcelInsertFunctionView: View {
    @ObservedObject var viewModel: STExcelEditorViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedCategory: STExcelFunctionCategory? = nil

    private var filteredFunctions: [STExcelFunctionDef] {
        var fns: [STExcelFunctionDef]
        if let cat = selectedCategory {
            fns = STExcelFunctionDB.functions(for: cat)
        } else {
            fns = STExcelFunctionDB.all
        }
        if !searchText.isEmpty {
            fns = fns.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        return fns
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Category filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        categoryChip(STExcelStrings.chartAll, isSelected: selectedCategory == nil) {
                            selectedCategory = nil
                        }
                        ForEach(STExcelFunctionCategory.allCases, id: \.rawValue) { cat in
                            categoryChip(cat.displayName, isSelected: selectedCategory == cat) {
                                selectedCategory = cat
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }

                List {
                    ForEach(filteredFunctions) { fn in
                        Button {
                            viewModel.pendingFunction = (fn.name, fn.isRangeFunction)
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(fn.name)
                                        .font(.system(size: 16, weight: .semibold, design: .monospaced))
                                        .foregroundColor(.stExcelAccent)
                                    Spacer()
                                    Text(fn.category.displayName)
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Color.gray.opacity(0.15))
                                        .cornerRadius(4)
                                }
                                Text(fn.syntax)
                                    .font(.system(size: 13, design: .monospaced))
                                    .foregroundColor(.secondary)
                                Text(fn.description)
                                    .font(.system(size: 13))
                                    .foregroundColor(.primary)
                                    .lineLimit(2)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle(STExcelStrings.insertFunction)
            .stNavigationBarTitleDisplayMode()
            .toolbar {
                ToolbarItem(placement: .stTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .searchable(text: $searchText, prompt: STExcelStrings.searchFunctions)
        }
    }

    private func categoryChip(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.stExcelAccent : Color.gray.opacity(0.15))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}
