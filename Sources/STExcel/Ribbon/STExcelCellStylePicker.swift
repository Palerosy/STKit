import SwiftUI
import STKit

/// Preset cell styles picker — matches Excel iOS Cell Style sheet
struct STExcelCellStylePicker: View {
    @ObservedObject var viewModel: STExcelEditorViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Spacer()
                Text(STExcelStrings.cellStyle)
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

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    styleSection(STExcelStrings.goodBadNeutral, styles: Self.statusStyles)
                    styleSection(STExcelStrings.dataModel, styles: Self.dataStyles)
                    styleSection(STExcelStrings.titlesHeadings, styles: Self.headingStyles)
                    styleSection(STExcelStrings.numberFormat, styles: Self.numberStyles)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
        }
    }

    private func styleSection(_ title: String, styles: [CellStylePreset]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.leading, 4)

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3),
                spacing: 8
            ) {
                ForEach(styles) { preset in
                    Button {
                        applyPreset(preset)
                        dismiss()
                    } label: {
                        Text(preset.name)
                            .font(.system(size: 13, weight: preset.style.isBold ? .bold : .regular))
                            .italic(preset.style.isItalic)
                            .foregroundColor(Color(hex: preset.style.textColor ?? "#000000") ?? .primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color(hex: preset.style.fillColor ?? "") ?? Color.gray.opacity(0.08))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func applyPreset(_ preset: CellStylePreset) {
        let s = preset.style
        if s.isBold != viewModel.currentStyle.isBold { viewModel.toggleBold() }
        if s.isItalic != viewModel.currentStyle.isItalic { viewModel.toggleItalic() }
        if let tc = s.textColor { viewModel.setTextColor(tc) }
        if let fc = s.fillColor {
            viewModel.setFillColor(fc)
        } else {
            viewModel.setFillColor("none")
        }
        viewModel.setFontSize(s.fontSize)
        if s.borders.hasAny {
            viewModel.setBorders(s.borders)
        }
        if s.numberFormatId != 0 {
            viewModel.setNumberFormat(STNumberFormat(rawValue: s.numberFormatId) ?? .general)
        }
    }

    // MARK: - Preset Definitions

    struct CellStylePreset: Identifiable {
        let id: String
        let name: String
        let style: STExcelCellStyle

        init(_ name: String, configure: (inout STExcelCellStyle) -> Void) {
            self.id = name
            self.name = name
            var s = STExcelCellStyle()
            configure(&s)
            self.style = s
        }
    }

    private static var statusStyles: [CellStylePreset] = [
        CellStylePreset(STExcelStrings.presetNormal) { _ in },
        CellStylePreset(STExcelStrings.presetGood) { s in
            s.textColor = "#006100"
            s.fillColor = "#C6EFCE"
        },
        CellStylePreset(STExcelStrings.presetBad) { s in
            s.textColor = "#9C0006"
            s.fillColor = "#FFC7CE"
        },
        CellStylePreset(STExcelStrings.presetNeutral) { s in
            s.textColor = "#9C5700"
            s.fillColor = "#FFEB9C"
        },
        CellStylePreset(STExcelStrings.presetInput) { s in
            s.textColor = "#3F3F76"
            s.fillColor = "#FFCC99"
            s.borders = .allThin
        },
        CellStylePreset(STExcelStrings.presetOutput) { s in
            s.textColor = "#3F3F3F"
            s.fillColor = "#F2F2F2"
            s.borders = STCellBorders(left: .medium, right: .medium, top: .medium, bottom: .medium)
        },
    ]

    private static var dataStyles: [CellStylePreset] = [
        CellStylePreset(STExcelStrings.presetCalculation) { s in
            s.textColor = "#FA7D00"
            s.fillColor = "#F2F2F2"
            s.isBold = true
            s.borders = .allThin
        },
        CellStylePreset(STExcelStrings.presetCheckCell) { s in
            s.textColor = "#FFFFFF"
            s.fillColor = "#A5A5A5"
            s.isBold = true
            s.borders = STCellBorders(left: .medium, right: .medium, top: .medium, bottom: .medium)
        },
        CellStylePreset(STExcelStrings.presetNote) { s in
            s.textColor = "#3F3F3F"
            s.fillColor = "#FFFFCC"
            s.borders = .allThin
        },
        CellStylePreset(STExcelStrings.presetWarning) { s in
            s.textColor = "#FF0000"
        },
        CellStylePreset(STExcelStrings.presetLinkedCell) { s in
            s.textColor = "#FA7D00"
            s.borders = STCellBorders(bottom: .medium)
        },
        CellStylePreset(STExcelStrings.presetExplanatory) { s in
            s.textColor = "#7F7F7F"
            s.isItalic = true
        },
    ]

    private static var headingStyles: [CellStylePreset] = [
        CellStylePreset(STExcelStrings.presetTitle) { s in
            s.fontSize = 18
            s.isBold = true
            s.textColor = "#44546A"
        },
        CellStylePreset(STExcelStrings.presetHeading1) { s in
            s.fontSize = 15
            s.isBold = true
            s.textColor = "#44546A"
            s.borders = STCellBorders(bottom: .thick, color: "#5B9BD5")
        },
        CellStylePreset(STExcelStrings.presetHeading2) { s in
            s.fontSize = 13
            s.isBold = true
            s.textColor = "#44546A"
            s.borders = STCellBorders(bottom: .medium, color: "#5B9BD5")
        },
        CellStylePreset(STExcelStrings.presetHeading3) { s in
            s.isBold = true
            s.textColor = "#44546A"
            s.borders = STCellBorders(bottom: .thin, color: "#A9D18E")
        },
        CellStylePreset(STExcelStrings.presetHeading4) { s in
            s.isBold = true
            s.textColor = "#44546A"
        },
        CellStylePreset(STExcelStrings.presetTotal) { s in
            s.isBold = true
            s.borders = STCellBorders(top: .thin, bottom: .medium)
        },
    ]

    private static var numberStyles: [CellStylePreset] = [
        CellStylePreset(STExcelStrings.presetComma) { s in
            s.numberFormatId = 1
            s.numberFormatCode = "#,##0.00"
        },
        CellStylePreset(STExcelStrings.presetCurrency) { s in
            s.numberFormatId = 2
            s.numberFormatCode = "$#,##0.00"
        },
        CellStylePreset(STExcelStrings.presetPercent) { s in
            s.numberFormatId = 3
            s.numberFormatCode = "0.00%"
        },
    ]
}
