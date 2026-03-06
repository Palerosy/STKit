import SwiftUI
import STKit

/// Spreadsheet settings — On Enter direction, Auto-Calculate, Formula Bar, Gridlines, Headings
struct STExcelSettingsView: View {
    @ObservedObject var viewModel: STExcelEditorViewModel
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
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

                Text(STStrings.settings)
                    .font(.headline)

                Spacer()

                Color.clear.frame(width: 32, height: 32)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)

            // Settings list
            VStack(spacing: 0) {
                // On Enter
                settingsRow(title: STExcelStrings.onEnter) {
                    Picker("", selection: $viewModel.enterDirection) {
                        Text(STExcelStrings.moveDown).tag(STExcelEditorViewModel.EnterDirection.down)
                        Text(STExcelStrings.moveRight).tag(STExcelEditorViewModel.EnterDirection.right)
                        Text(STExcelStrings.stay).tag(STExcelEditorViewModel.EnterDirection.stay)
                    }
                    .pickerStyle(.menu)
                    .tint(.stExcelAccent)
                }

                Divider().padding(.leading, 20)

                // Auto-Calculate
                settingsRow(title: STExcelStrings.autoCalculate) {
                    Toggle("", isOn: $viewModel.autoCalculate)
                        .tint(.stExcelAccent)
                        .labelsHidden()
                }

                Divider().padding(.leading, 20)

                // Gridlines
                settingsRow(title: STExcelStrings.gridlines) {
                    Toggle("", isOn: $viewModel.showGridlines)
                        .tint(.stExcelAccent)
                        .labelsHidden()
                }

                Divider().padding(.leading, 20)

                // Headings
                settingsRow(title: STExcelStrings.headings) {
                    Toggle("", isOn: $viewModel.showHeadings)
                        .tint(.stExcelAccent)
                        .labelsHidden()
                }

                Divider().padding(.leading, 20)

                // Formula Bar
                settingsRow(title: STExcelStrings.formulaBar) {
                    Toggle("", isOn: $viewModel.showFormulaBar)
                        .tint(.stExcelAccent)
                        .labelsHidden()
                }
            }
            .background(Color.stSecondarySystemGroupedBackground)
            .cornerRadius(12)
            .padding(.horizontal, 20)

            Spacer()
        }
    }

    private func settingsRow<Content: View>(title: String, @ViewBuilder trailing: () -> Content) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 16))
            Spacer()
            trailing()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}
