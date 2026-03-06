import SwiftUI
import STKit

/// Formulas tab — AutoSum, Financial, Logical, Text, Date & Time, Reference, Math,
/// Insert Function, Define Name, Name Manager, Recalculate
/// (matches competitor ribbon layout)
struct STExcelRibbonFormulasTab: View {
    @ObservedObject var viewModel: STExcelEditorViewModel
    @State private var showAutoSumMenu = false
    @State private var showFinancial = false
    @State private var showLogical = false
    @State private var showText = false
    @State private var showDateTime = false
    @State private var showReference = false
    @State private var showMath = false
    @State private var showInsertFunction = false
    @State private var showDefineName = false
    @State private var showNameManager = false

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 2) {
                // Auto Sum
                STExcelRibbonToolButton(iconName: "sum", label: STExcelStrings.autoSum) {
                    showAutoSumMenu = true
                }
                .sheet(isPresented: $showAutoSumMenu) {
                    STExcelAutoSumMenu(viewModel: viewModel) {
                        showAutoSumMenu = false
                    }
                    .stPresentationDetents([.height(340)])
                }

                // Financial
                STExcelRibbonToolButton(iconName: "dollarsign", label: STExcelStrings.financial) {
                    showFinancial = true
                }
                .sheet(isPresented: $showFinancial, onDismiss: applyPendingFormula) {
                    STExcelCategoryFunctionPicker(category: .financial, viewModel: viewModel)
                        .stPresentationDetents([.medium])
                }

                // Logical
                STExcelRibbonToolButton(iconName: "questionmark.diamond", label: STExcelStrings.logical) {
                    showLogical = true
                }
                .sheet(isPresented: $showLogical, onDismiss: applyPendingFormula) {
                    STExcelCategoryFunctionPicker(category: .logical, viewModel: viewModel)
                        .stPresentationDetents([.medium])
                }

                // Text
                STExcelRibbonToolButton(iconName: "textformat.abc", label: STExcelStrings.textFunctions) {
                    showText = true
                }
                .sheet(isPresented: $showText, onDismiss: applyPendingFormula) {
                    STExcelCategoryFunctionPicker(category: .text, viewModel: viewModel)
                        .stPresentationDetents([.medium])
                }

                // Date & Time
                STExcelRibbonToolButton(iconName: "calendar.circle", label: STExcelStrings.dateTime) {
                    showDateTime = true
                }
                .sheet(isPresented: $showDateTime, onDismiss: applyPendingFormula) {
                    STExcelCategoryFunctionPicker(category: .dateTime, viewModel: viewModel)
                        .stPresentationDetents([.medium])
                }

                // Reference
                STExcelRibbonToolButton(iconName: "magnifyingglass", label: STExcelStrings.reference) {
                    showReference = true
                }
                .sheet(isPresented: $showReference, onDismiss: applyPendingFormula) {
                    STExcelCategoryFunctionPicker(category: .reference, viewModel: viewModel)
                        .stPresentationDetents([.medium])
                }

                // Math
                STExcelRibbonToolButton(iconName: "x.squareroot", label: STExcelStrings.math) {
                    showMath = true
                }
                .sheet(isPresented: $showMath, onDismiss: applyPendingFormula) {
                    STExcelCategoryFunctionPicker(category: .math, viewModel: viewModel)
                        .stPresentationDetents([.medium])
                }

                STExcelRibbonSeparator()

                // Insert Function
                STExcelRibbonToolButton(iconName: "function", label: STExcelStrings.insertFunction) {
                    showInsertFunction = true
                }
                .sheet(isPresented: $showInsertFunction, onDismiss: applyPendingFormula) {
                    STExcelInsertFunctionView(viewModel: viewModel)
                        .stPresentationDetents([.large])
                }

                // Define Name
                STExcelRibbonToolButton(iconName: "pencil.and.list.clipboard", label: STExcelStrings.defineName) {
                    showDefineName = true
                }
                .sheet(isPresented: $showDefineName) {
                    STExcelDefineNameView(viewModel: viewModel) {
                        showDefineName = false
                    }
                    .stPresentationDetents([.height(300)])
                }

                // Name Manager
                STExcelRibbonToolButton(iconName: "list.clipboard", label: STExcelStrings.nameManager) {
                    showNameManager = true
                }
                .sheet(isPresented: $showNameManager) {
                    STExcelNameManagerView(viewModel: viewModel) {
                        showNameManager = false
                    }
                    .stPresentationDetents([.medium])
                }

                STExcelRibbonSeparator()

                // Recalculate
                STExcelRibbonToolButton(iconName: "arrow.clockwise", label: STExcelStrings.recalculate) {
                    viewModel.objectWillChange.send()
                }
            }
            .padding(.horizontal, 8)
        }
    }

    /// Called when a function picker sheet dismisses — applies any pending function
    private func applyPendingFormula() {
        guard let pending = viewModel.pendingFunction else { return }
        viewModel.pendingFunction = nil
        // Small delay to let sheet fully dismiss before activating formula bar
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            // All functions use insertAutoFormula — it handles range vs single cell
            viewModel.insertAutoFormula(pending.name)
        }
    }
}

// MARK: - AutoSum Menu

private struct STExcelAutoSumMenu: View {
    @ObservedObject var viewModel: STExcelEditorViewModel
    let onDismiss: () -> Void

    private var functions: [(String, String, String)] { [
        (STExcelStrings.sum, "SUM", "sum"),
        (STExcelStrings.average, "AVERAGE", "divide"),
        (STExcelStrings.count, "COUNT", "number"),
        (STExcelStrings.max, "MAX", "arrow.up"),
        (STExcelStrings.min, "MIN", "arrow.down"),
        (STExcelStrings.median, "MEDIAN", "chart.bar"),
    ] }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Text(STExcelStrings.autoSum)
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

            ForEach(functions, id: \.0) { label, funcName, icon in
                Button {
                    viewModel.insertAutoFormula(funcName)
                    onDismiss()
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: icon)
                            .font(.system(size: 16))
                            .foregroundColor(.stExcelAccent)
                            .frame(width: 28)
                        Text(label)
                            .font(.system(size: 17))
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }
            }
            Spacer()
        }
    }
}

// MARK: - Define Name

private struct STExcelDefineNameView: View {
    @ObservedObject var viewModel: STExcelEditorViewModel
    let onDismiss: () -> Void
    @State private var name = ""
    @State private var refersTo = ""

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Text(STExcelStrings.defineName)
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
                    Text("Name")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    TextField("e.g. TotalSales", text: $name)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(.horizontal, 20)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Refers to")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    TextField(cellReference, text: $refersTo)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(.horizontal, 20)

                Button {
                    guard !name.isEmpty, !refersTo.isEmpty else { return }
                    viewModel.defineName(name, refersTo: refersTo)
                    onDismiss()
                } label: {
                    Text("OK")
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
        .onAppear {
            if let row = viewModel.selectedRow, let col = viewModel.selectedCol,
               let sheet = viewModel.sheet {
                let colLetter = STExcelSheet.columnLetter(col)
                refersTo = "=\(sheet.name)!$\(colLetter)$\(row + 1)"
            }
        }
    }

    private var cellReference: String {
        guard let row = viewModel.selectedRow, let col = viewModel.selectedCol else { return "=Sheet1!$A$1" }
        let colLetter = STExcelSheet.columnLetter(col)
        return "=Sheet1!$\(colLetter)$\(row + 1)"
    }
}

// MARK: - Name Manager

private struct STExcelNameManagerView: View {
    @ObservedObject var viewModel: STExcelEditorViewModel
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Text(STExcelStrings.nameManager)
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

            if viewModel.definedNames.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text(STExcelStrings.noDefinedNames)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(Array(viewModel.definedNames.sorted(by: { $0.key < $1.key })), id: \.key) { name, refersTo in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(name)
                                    .font(.system(size: 16, weight: .medium))
                                Text(refersTo)
                                    .font(.system(size: 13, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button {
                                viewModel.removeName(name)
                            } label: {
                                Image(systemName: "trash")
                                    .font(.system(size: 14))
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
    }
}
