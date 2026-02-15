import SwiftUI
import STKit

/// Export options sheet — export as DOCX, PDF, or TXT
public struct STDOCXExportView: View {
    let attributedText: NSAttributedString
    let documentTitle: String
    let onExport: (URL) -> Void
    @Environment(\.dismiss) private var dismiss

    public init(
        attributedText: NSAttributedString,
        documentTitle: String,
        onExport: @escaping (URL) -> Void
    ) {
        self.attributedText = attributedText
        self.documentTitle = documentTitle
        self.onExport = onExport
    }

    public var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                Text(STDOCXStrings.exportAs)
                    .font(.system(size: 17, weight: .semibold))
                    .padding(.top, 20)

                VStack(spacing: 12) {
                    exportButton(title: "DOCX", icon: "doc.text.fill", color: .blue) {
                        exportAsDOCX()
                    }

                    exportButton(title: "PDF", icon: "doc.fill", color: .red) {
                        exportAsPDF()
                    }

                    exportButton(title: "TXT", icon: "doc.plaintext.fill", color: .gray) {
                        exportAsTXT()
                    }
                }
                .padding(.horizontal, 16)

                Spacer()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
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
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }

    private func exportAsDOCX() {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(documentTitle).docx")
        let doc = STDOCXConverter.toDocument(attributedText)
        if (try? doc.write(to: url)) != nil {
            onExport(url)
        }
    }

    private func exportAsPDF() {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(documentTitle).pdf")
        let tempDoc = STDOCXDocument(title: documentTitle)
        tempDoc.update(attributedString: attributedText)
        if tempDoc.exportAsPDF(to: url) {
            onExport(url)
        }
    }

    private func exportAsTXT() {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(documentTitle).txt")
        do {
            try attributedText.string.write(to: url, atomically: true, encoding: .utf8)
            onExport(url)
        } catch {
            print("[STDOCX] TXT export failed: \(error)")
        }
    }
}
