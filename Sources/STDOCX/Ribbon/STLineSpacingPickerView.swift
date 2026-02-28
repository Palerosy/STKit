import SwiftUI
import STKit

/// Compact line-spacing picker presented as a half-sheet
struct STLineSpacingPickerView: View {
    let onSelect: (Double) -> Void

    @Environment(\.dismiss) private var dismiss

    private let options: [(value: Double, label: String)] = [
        (1.0,  "1.0"),
        (1.15, "1.15"),
        (1.5,  "1.5"),
        (2.0,  "2.0"),
        (2.5,  "2.5"),
        (3.0,  "3.0"),
    ]

    var body: some View {
        NavigationView {
            List(options, id: \.value) { option in
                Button {
                    onSelect(option.value)
                    dismiss()
                } label: {
                    HStack(spacing: 14) {
                        spacingIcon(for: option.value)
                            .frame(width: 28, height: 20)
                        Text(option.label)
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .stInsetGroupedListStyle()
            .navigationTitle(STStrings.ribbonLineSpacing)
            .stNavigationBarTitleDisplayMode()
            .toolbar {
                ToolbarItem(placement: .stTrailing) {
                    Button(STStrings.done) { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private func spacingIcon(for value: Double) -> some View {
        let gap: CGFloat = value <= 1.1 ? 1 : value <= 1.3 ? 2 : value <= 1.6 ? 4 : value <= 2.1 ? 6 : value <= 2.6 ? 8 : 10
        VStack(spacing: gap) {
            ForEach(0..<3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.primary.opacity(0.55))
                    .frame(height: 2)
            }
        }
    }
}
