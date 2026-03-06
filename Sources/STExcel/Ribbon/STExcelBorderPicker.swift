import SwiftUI
import STKit

/// Border style picker popover
struct STExcelBorderPicker: View {
    let onSelect: (STCellBorders) -> Void

    var body: some View {
        VStack(spacing: 8) {
            Text(STExcelStrings.borders)
                .font(.caption)
                .foregroundColor(.secondary)

            VStack(spacing: 4) {
                borderButton(STExcelStrings.noBorder, icon: "square.dashed", borders: STCellBorders())
                borderButton(STExcelStrings.allBorders, icon: "square", borders: .allThin)
                borderButton(STExcelStrings.outsideBorder, icon: "square.fill",
                             borders: STCellBorders(left: .thin, right: .thin, top: .thin, bottom: .thin))
                borderButton(STExcelStrings.bottomBorder, icon: "square.bottomhalf.filled",
                             borders: STCellBorders(bottom: .thin))
                borderButton(STExcelStrings.thickBorder, icon: "square.inset.filled",
                             borders: STCellBorders(left: .medium, right: .medium, top: .medium, bottom: .medium))
            }
        }
        .padding(12)
        .stPresentationCompactAdaptation()
    }

    private func borderButton(_ label: String, icon: String, borders: STCellBorders) -> some View {
        Button {
            onSelect(borders)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .frame(width: 24)
                Text(label)
                    .font(.system(size: 14))
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }
}
