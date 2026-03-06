import SwiftUI
import STKit

/// File Info sheet — shows file name, location, type, size, dates
struct STExcelFileInfoView: View {
    let fileURL: URL?
    let documentTitle: String
    let sheetCount: Int
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

                Text(STExcelStrings.fileInfo)
                    .font(.headline)

                Spacer()

                Color.clear.frame(width: 32, height: 32)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)

            // File icon + name
            VStack(spacing: 8) {
                Image(systemName: "tablecells.fill")
                    .font(.system(size: 44))
                    .foregroundColor(.stExcelAccent)

                Text(documentTitle)
                    .font(.system(size: 18, weight: .semibold))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .padding(.bottom, 16)

            // Info rows
            VStack(spacing: 0) {
                infoRow(title: STExcelStrings.fileName, value: fileURL?.lastPathComponent ?? documentTitle)
                Divider().padding(.leading, 20)
                infoRow(title: STExcelStrings.fileLocation, value: fileURL?.deletingLastPathComponent().path ?? "-")
                Divider().padding(.leading, 20)
                infoRow(title: STExcelStrings.fileType, value: "XLSX")
                Divider().padding(.leading, 20)
                infoRow(title: STExcelStrings.fileSize, value: fileSizeString)
                Divider().padding(.leading, 20)
                infoRow(title: STExcelStrings.createdDate, value: fileDate(for: .creationDateKey))
                Divider().padding(.leading, 20)
                infoRow(title: STExcelStrings.modifiedDate, value: fileDate(for: .contentModificationDateKey))
                Divider().padding(.leading, 20)
                infoRow(title: STExcelStrings.sheet, value: "\(sheetCount)")
            }
            .background(Color.stSecondarySystemGroupedBackground)
            .cornerRadius(12)
            .padding(.horizontal, 20)

            Spacer()
        }
    }

    private func infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 15))
                .foregroundColor(.primary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    private var fileSizeString: String {
        guard let url = fileURL,
              let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
              let size = attrs[.size] as? Int64 else { return STExcelStrings.unknown }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    private func fileDate(for key: URLResourceKey) -> String {
        guard let url = fileURL,
              let values = try? url.resourceValues(forKeys: [key]) else { return STExcelStrings.unknown }
        let date: Date?
        switch key {
        case .creationDateKey: date = values.creationDate
        case .contentModificationDateKey: date = values.contentModificationDate
        default: date = nil
        }
        guard let date else { return STExcelStrings.unknown }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
