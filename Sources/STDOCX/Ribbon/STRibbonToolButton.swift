import SwiftUI

/// Reusable ribbon tool button — icon on top, label below
struct STRibbonToolButton: View {
    let iconName: String
    let label: String
    var isActive: Bool = false
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: iconName)
                    .font(.system(size: 17, weight: .medium))
                    .frame(width: 24, height: 24)

                Text(label)
                    .font(.system(size: 9, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundColor(isActive ? .white : .primary)
            .opacity(isDisabled ? 0.3 : 1)
            .frame(width: 52, height: 50)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isActive ? Color.accentColor : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
}
