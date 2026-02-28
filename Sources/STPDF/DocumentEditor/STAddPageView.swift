import STKit
import SwiftUI
import PDFKit

/// Sheet for adding new blank pages to the document
struct STAddPageView: View {

    @ObservedObject var viewModel: STPageEditorViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var numberOfPages = 1
    @State private var selectedFormat: STPageFormat = .a4
    @State private var selectedColor: STPageColor = .white
    @State private var addAfterPage: Int = 0

    var body: some View {
        STNavigationView {
            Form {
                // Number of pages
                Section {
                    Stepper(value: $numberOfPages, in: 1...50) {
                        HStack {
                            Text(STStrings.pageNumberOfPages)
                            Spacer()
                            Text("\(numberOfPages)")
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // Page format
                Section {
                    Picker(STStrings.pageFormat, selection: $selectedFormat) {
                        ForEach(STPageFormat.allCases) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                }

                // Page color
                Section {
                    Picker(STStrings.pageColor, selection: $selectedColor) {
                        ForEach(STPageColor.allCases) { color in
                            HStack {
                                Circle()
                                    .fill(Color(color.color))
                                    .frame(width: 20, height: 20)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                                    )
                                Text(color.displayName)
                            }
                            .tag(color)
                        }
                    }
                    .pickerStyle(.inline)
                }

                // Insert position
                Section {
                    Picker(STStrings.pageAddAfter, selection: $addAfterPage) {
                        Text(STStrings.pageBeginning).tag(-1)
                        ForEach(0..<viewModel.document.pageCount, id: \.self) { index in
                            Text(String(format: STStrings.page(index + 1))).tag(index)
                        }
                    }
                }
            }
            .navigationTitle(STStrings.pageNewPage)
            .stNavigationBarTitleDisplayMode()
            .toolbar {
                ToolbarItem(placement: .stLeading) {
                    Button(STStrings.cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .stTrailing) {
                    Button(STStrings.add) {
                        viewModel.addBlankPage(
                            count: numberOfPages,
                            format: selectedFormat,
                            color: selectedColor,
                            afterPage: addAfterPage
                        )
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            // Default to adding after last page
            addAfterPage = viewModel.document.pageCount - 1
        }
    }
}
