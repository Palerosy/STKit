import SwiftUI

/// Grid picker for selecting table dimensions (rows x columns)
struct STTableSizePickerView: View {
    let onSelect: (Int, Int) -> Void

    @State private var hoverRow: Int = 0
    @State private var hoverCol: Int = 0

    private let maxRows = 6
    private let maxCols = 6
    private let cellSize: CGFloat = 24

    var body: some View {
        VStack(spacing: 8) {
            Text("\(max(hoverRow, 1)) × \(max(hoverCol, 1))")
                .font(.caption)
                .foregroundColor(.secondary)

            VStack(spacing: 2) {
                ForEach(1...maxRows, id: \.self) { row in
                    HStack(spacing: 2) {
                        ForEach(1...maxCols, id: \.self) { col in
                            Rectangle()
                                .fill(row <= hoverRow && col <= hoverCol
                                      ? Color.accentColor.opacity(0.3)
                                      : Color.gray.opacity(0.1))
                                .frame(width: cellSize, height: cellSize)
                                .border(row <= hoverRow && col <= hoverCol
                                        ? Color.accentColor
                                        : Color.gray.opacity(0.3), width: 1)
                                .onTapGesture {
                                    onSelect(row, col)
                                }
                                .simultaneousGesture(
                                    DragGesture(minimumDistance: 0)
                                        .onChanged { _ in
                                            hoverRow = row
                                            hoverCol = col
                                        }
                                )
                        }
                    }
                }
            }
        }
        .padding(12)
        .modifier(CompactPopoverModifier3())
    }
}

/// Force popover presentation on iPhone (iOS 16.4+)
private struct CompactPopoverModifier3: ViewModifier {
    func body(content: Content) -> some View {
        content.stPresentationCompactAdaptation()
    }
}
