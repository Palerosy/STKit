import SwiftUI
import STKit

/// Go To Cell sheet — enter a cell reference like "A1"
struct STExcelGoToCellView: View {
    let onGo: (String) -> Void
    let onCancel: () -> Void

    @State private var cellRef = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text(STExcelStrings.goToCell)
                    .font(.headline)

                TextField("A1", text: $cellRef)
                    .font(.system(size: 18, design: .monospaced))
                    .textFieldStyle(.roundedBorder)
                    #if os(iOS)
                    .textInputAutocapitalization(.characters)
                    #endif
                    .focused($isFocused)
                    .onSubmit { go() }

                Button(action: go) {
                    Text(STExcelStrings.go)
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.stExcelAccent)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(cellRef.isEmpty)

                Spacer()
            }
            .padding(20)
            .toolbar {
                ToolbarItem(placement: .stTrailing) {
                    Button(STStrings.cancel) { onCancel() }
                }
            }
        }
        .onAppear { isFocused = true }
    }

    private func go() {
        guard !cellRef.isEmpty else { return }
        onGo(cellRef)
    }
}
