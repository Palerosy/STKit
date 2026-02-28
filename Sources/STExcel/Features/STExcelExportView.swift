import SwiftUI
import STKit

/// Export options for Excel documents
public struct STExcelExportView: View {
    let document: STExcelDocument?
    let documentTitle: String
    let onExport: (URL) -> Void
    @Environment(\.dismiss) private var dismiss

    public init(document: STExcelDocument?, documentTitle: String, onExport: @escaping (URL) -> Void) {
        self.document = document
        self.documentTitle = documentTitle
        self.onExport = onExport
    }

    public var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                Text(STStrings.export)
                    .font(.system(size: 17, weight: .semibold))
                    .padding(.top, 20)

                VStack(spacing: 12) {
                    exportButton(title: "XLSX", icon: "tablecells.fill", color: .green) {
                        exportAsXLSX()
                    }

                    exportButton(title: "CSV", icon: "doc.text.fill", color: .orange) {
                        exportAsCSV()
                    }
                }
                .padding(.horizontal, 16)

                Spacer()
            }
            .toolbar {
                ToolbarItem(placement: .stTrailing) {
                    Button(STStrings.cancel) { dismiss() }
                }
            }
        }
    }

    private func exportButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(color)
                    .frame(width: 32)

                Text(title)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.stSecondarySystemGroupedBackground)
            .cornerRadius(12)
        }
    }

    private func exportAsXLSX() {
        guard let document else { return }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(documentTitle).xlsx")
        if document.save(to: url) {
            onExport(url)
        }
    }

    private func exportAsCSV() {
        guard let document else { return }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(documentTitle).csv")
        if document.exportAsCSV(to: url) {
            onExport(url)
        }
    }
}
