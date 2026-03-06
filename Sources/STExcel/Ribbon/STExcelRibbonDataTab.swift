import SwiftUI
import STKit

/// Data tab — Sort, Filter, Reapply Filter, Data Validation, Circle Invalid Data,
/// Group, Ungroup, Subtotal, Remove All, Show Detail, Hide Detail, Text to Columns
/// (matches competitor ribbon layout)
struct STExcelRibbonDataTab: View {
    @ObservedObject var viewModel: STExcelEditorViewModel
    @State private var showSortMenu = false
    @State private var showDataValidation = false
    @State private var showTextToColumns = false
    @State private var showSubtotal = false

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 2) {
                // Sort
                STExcelRibbonToolButton(iconName: "arrow.up.arrow.down", label: STExcelStrings.sort) {
                    showSortMenu = true
                }
                .sheet(isPresented: $showSortMenu) {
                    STExcelSortMenu(viewModel: viewModel) {
                        showSortMenu = false
                    }
                    .stPresentationDetents([.medium, .large])
                }

                // Filter toggle
                STExcelRibbonToolButton(
                    iconName: "line.3.horizontal.decrease",
                    label: STExcelStrings.filter,
                    isActive: viewModel.isFilterActive
                ) {
                    viewModel.toggleFilter()
                }

                // Reapply Filter
                STExcelRibbonToolButton(iconName: "arrow.clockwise", label: STExcelStrings.reapplyFilter) {
                    viewModel.reapplyFilter()
                }

                STExcelRibbonSeparator()

                // Data Validation
                STExcelRibbonToolButton(iconName: "checkmark.shield", label: STExcelStrings.dataValidation) {
                    showDataValidation = true
                }
                .sheet(isPresented: $showDataValidation) {
                    STExcelDataValidationView(viewModel: viewModel) {
                        showDataValidation = false
                    }
                    .stPresentationDetents([.medium])
                }

                // Circle Invalid Data
                STExcelRibbonToolButton(iconName: "exclamationmark.circle", label: STExcelStrings.circleInvalid) {
                    viewModel.circleInvalidData()
                }

                STExcelRibbonSeparator()

                // Group
                STExcelRibbonToolButton(iconName: "rectangle.3.group", label: STExcelStrings.group) {
                    viewModel.groupRows()
                }

                // Ungroup
                STExcelRibbonToolButton(iconName: "rectangle.3.group.fill", label: STExcelStrings.ungroup) {
                    viewModel.ungroupRows()
                }

                // Subtotal
                STExcelRibbonToolButton(iconName: "sum", label: STExcelStrings.subtotal) {
                    showSubtotal = true
                }
                .sheet(isPresented: $showSubtotal) {
                    STExcelSubtotalView(viewModel: viewModel) {
                        showSubtotal = false
                    }
                    .stPresentationDetents([.height(300)])
                }

                // Remove All
                STExcelRibbonToolButton(iconName: "xmark.circle", label: STExcelStrings.removeAll) {
                    viewModel.removeAllGroupsAndSubtotals()
                }

                STExcelRibbonSeparator()

                // Show Detail
                STExcelRibbonToolButton(iconName: "eye", label: STExcelStrings.showDetail) {
                    viewModel.showDetail()
                }

                // Hide Detail
                STExcelRibbonToolButton(iconName: "eye.slash", label: STExcelStrings.hideDetail) {
                    viewModel.hideDetail()
                }

                // Text to Columns
                STExcelRibbonToolButton(iconName: "text.append", label: STExcelStrings.textToColumns) {
                    showTextToColumns = true
                }
                .sheet(isPresented: $showTextToColumns) {
                    STExcelTextToColumnsView(viewModel: viewModel) {
                        showTextToColumns = false
                    }
                    .stPresentationDetents([.height(350)])
                }
            }
            .padding(.horizontal, 8)
        }
    }
}

// MARK: - Sort Menu (matches competitor: Columns/Rows, Headers, Case Sensitive, Sort by + Then by)

private struct STExcelSortMenu: View {
    @ObservedObject var viewModel: STExcelEditorViewModel
    let onDismiss: () -> Void

    @State private var sortMode = 0  // 0=Columns, 1=Rows
    @State private var hasHeaders = true
    @State private var caseSensitive = false

    // Sort levels: (column index, ascending)
    @State private var sortByCol: Int = 0
    @State private var sortByAsc: Bool = true
    @State private var thenByCol1: Int = -1  // -1 = none
    @State private var thenByAsc1: Bool = true
    @State private var thenByCol2: Int = -1  // -1 = none
    @State private var thenByAsc2: Bool = true

    private var columnCount: Int { viewModel.sheet?.columnCount ?? 26 }

    var body: some View {
        VStack(spacing: 0) {
            // Header: X — Sort — Apply
            HStack {
                Button { onDismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(width: 32, height: 32)
                        .background(Color.gray.opacity(0.15))
                        .clipShape(Circle())
                }

                Spacer()

                Text(STExcelStrings.sort)
                    .font(.headline)

                Spacer()

                Button {
                    applySort()
                    onDismiss()
                } label: {
                    Text(STExcelStrings.apply)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color.stExcelAccent)
                        .cornerRadius(18)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    // Columns / Rows toggle
                    Picker("", selection: $sortMode) {
                        Text(STExcelStrings.columns).tag(0)
                        Text(STExcelStrings.rows).tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)

                    // Toggles
                    VStack(spacing: 0) {
                        if sortMode == 0 {
                            Toggle(STExcelStrings.myDataHasHeaders, isOn: $hasHeaders)
                                .font(.system(size: 16))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                            Divider().padding(.leading, 20)
                        }

                        Toggle(STExcelStrings.caseSensitive, isOn: $caseSensitive)
                            .font(.system(size: 16))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                    }

                    // Sort by
                    sortLevelRow(
                        label: STExcelStrings.sortBy,
                        col: $sortByCol,
                        ascending: $sortByAsc,
                        allowNone: false
                    )

                    // Then by (1)
                    sortLevelRow(
                        label: STExcelStrings.thenBy,
                        col: $thenByCol1,
                        ascending: $thenByAsc1,
                        allowNone: true
                    )

                    // Then by (2)
                    sortLevelRow(
                        label: STExcelStrings.thenBy,
                        col: $thenByCol2,
                        ascending: $thenByAsc2,
                        allowNone: true
                    )
                }
                .padding(.bottom, 20)
            }
        }
        .onAppear {
            // Default to selected column
            if let col = viewModel.selectedCol {
                sortByCol = col
            }
        }
    }

    @ViewBuilder
    private func sortLevelRow(label: String, col: Binding<Int>, ascending: Binding<Bool>, allowNone: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                Spacer()

                // Column picker
                Menu {
                    if allowNone {
                        Button(STExcelStrings.none) { col.wrappedValue = -1 }
                    }
                    ForEach(0..<min(columnCount, 50), id: \.self) { i in
                        Button(columnLabel(i)) { col.wrappedValue = i }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(col.wrappedValue < 0 ? "" : columnLabel(col.wrappedValue))
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
            }

            if col.wrappedValue >= 0 {
                // Order picker
                Picker("", selection: ascending) {
                    Text(STExcelStrings.sortAZ).tag(true)
                    Text(STExcelStrings.sortZA).tag(false)
                }
                .pickerStyle(.segmented)
            }
        }
        .padding(.horizontal, 20)
    }

    private func columnLabel(_ i: Int) -> String {
        let letter = STExcelSheet.columnLetter(i)
        if hasHeaders, let sheet = viewModel.sheet, sheet.rowCount > 0,
           i < sheet.cells[0].count, !sheet.cells[0][i].value.isEmpty {
            return "\(letter) — \(sheet.cells[0][i].value)"
        }
        return "Column \(letter)"
    }

    private func applySort() {
        var levels: [(col: Int, ascending: Bool)] = []
        levels.append((sortByCol, sortByAsc))
        if thenByCol1 >= 0 { levels.append((thenByCol1, thenByAsc1)) }
        if thenByCol2 >= 0 { levels.append((thenByCol2, thenByAsc2)) }

        viewModel.sortMultiLevel(
            levels: levels,
            hasHeaders: hasHeaders,
            caseSensitive: caseSensitive
        )
    }
}

// MARK: - Data Validation

private struct STExcelDataValidationView: View {
    @ObservedObject var viewModel: STExcelEditorViewModel
    let onDismiss: () -> Void
    @State private var validationType = 0  // 0=Any, 1=WholeNumber, 2=Decimal, 3=List, 4=Date, 5=TextLength
    @State private var minValue = ""
    @State private var maxValue = ""
    @State private var listValues = ""

    private var types: [String] { [STExcelStrings.anyValue, STExcelStrings.wholeNumber, STExcelStrings.decimalType, STExcelStrings.listType, STExcelStrings.date, STExcelStrings.textLength] }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Text(STExcelStrings.dataValidation)
                    .font(.headline)
                Spacer()
                Button { onDismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)

            VStack(spacing: 16) {
                // Type picker
                VStack(alignment: .leading, spacing: 6) {
                    Text(STExcelStrings.allow)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    Picker("", selection: $validationType) {
                        ForEach(0..<types.count, id: \.self) { i in
                            Text(types[i]).tag(i)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.15))
                    .cornerRadius(8)
                }
                .padding(.horizontal, 20)

                if validationType == 1 || validationType == 2 || validationType == 5 {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Min").font(.caption).foregroundColor(.secondary)
                            TextField("0", text: $minValue)
                                .textFieldStyle(.roundedBorder)
                                .stKeyboardType(.decimalPad)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Max").font(.caption).foregroundColor(.secondary)
                            TextField("100", text: $maxValue)
                                .textFieldStyle(.roundedBorder)
                                .stKeyboardType(.decimalPad)
                        }
                    }
                    .padding(.horizontal, 20)
                }

                if validationType == 3 {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(STExcelStrings.sourceList)
                            .font(.caption).foregroundColor(.secondary)
                        TextField("Option1, Option2, Option3", text: $listValues)
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding(.horizontal, 20)
                }

                HStack(spacing: 12) {
                    Button {
                        viewModel.setDataValidation(
                            type: validationType,
                            min: minValue, max: maxValue,
                            list: listValues
                        )
                        onDismiss()
                    } label: {
                        Text(STExcelStrings.apply)
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.stExcelAccent)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }

                    Button {
                        viewModel.clearDataValidation()
                        onDismiss()
                    } label: {
                        Text(STExcelStrings.clear)
                            .font(.system(size: 16, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.gray.opacity(0.15))
                            .foregroundColor(.primary)
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal, 20)
            }

            Spacer()
        }
    }
}

// MARK: - Subtotal

private struct STExcelSubtotalView: View {
    @ObservedObject var viewModel: STExcelEditorViewModel
    let onDismiss: () -> Void
    @State private var functionType = 0  // 0=SUM, 1=COUNT, 2=AVERAGE, 3=MAX, 4=MIN

    private let functions = ["SUM", "COUNT", "AVERAGE", "MAX", "MIN"]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Text(STExcelStrings.subtotal)
                    .font(.headline)
                Spacer()
                Button { onDismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)

            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(STExcelStrings.useFunction)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    Picker("", selection: $functionType) {
                        ForEach(0..<functions.count, id: \.self) { i in
                            Text(functions[i]).tag(i)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.horizontal, 20)

                Button {
                    viewModel.insertSubtotal(function: functions[functionType])
                    onDismiss()
                } label: {
                    Text(STExcelStrings.insertSubtotal)
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.stExcelAccent)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal, 20)
            }

            Spacer()
        }
    }
}

// MARK: - Text to Columns

private struct STExcelTextToColumnsView: View {
    @ObservedObject var viewModel: STExcelEditorViewModel
    let onDismiss: () -> Void
    @State private var delimiter = 0  // 0=Comma, 1=Tab, 2=Semicolon, 3=Space, 4=Custom
    @State private var customDelimiter = ""

    private var delimiters: [String] { [STExcelStrings.commaDelimiter, STExcelStrings.tabDelimiter, STExcelStrings.semicolonDelimiter, STExcelStrings.spaceDelimiter, STExcelStrings.custom] }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Text(STExcelStrings.textToColumns)
                    .font(.headline)
                Spacer()
                Button { onDismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)

            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(STExcelStrings.delimiter)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)

                    ForEach(0..<delimiters.count, id: \.self) { i in
                        Button {
                            delimiter = i
                        } label: {
                            HStack {
                                Image(systemName: delimiter == i ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(delimiter == i ? .stExcelAccent : .secondary)
                                Text(delimiters[i])
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)

                if delimiter == 4 {
                    TextField(STExcelStrings.enterDelimiter, text: $customDelimiter)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal, 20)
                }

                Button {
                    let sep: String
                    switch delimiter {
                    case 0: sep = ","
                    case 1: sep = "\t"
                    case 2: sep = ";"
                    case 3: sep = " "
                    default: sep = customDelimiter.isEmpty ? "," : customDelimiter
                    }
                    viewModel.textToColumns(delimiter: sep)
                    onDismiss()
                } label: {
                    Text(STExcelStrings.convertAction)
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.stExcelAccent)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal, 20)
            }

            Spacer()
        }
    }
}
