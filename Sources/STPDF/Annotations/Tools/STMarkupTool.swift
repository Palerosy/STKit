import STKit
import SwiftUI
import PDFKit

/// Floating pill button that appears when text is selected with a markup tool active.
/// Tapping applies the markup (highlight / underline / strikethrough) to the selection.
struct STMarkupApplyButton: View {

    let onApply: () -> Void
    let toolType: STAnnotationType

    var body: some View {
        Button {
            onApply()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: toolType.iconName)
                    .font(.system(size: 14, weight: .semibold))
                Text(STStrings.applyTool(toolType.displayName))
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.accentColor)
            .clipShape(Capsule())
            .shadow(color: .accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
            .shadow(color: .black.opacity(0.08), radius: 2, x: 0, y: 1)
        }
    }
}
