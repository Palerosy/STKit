import SwiftUI

/// Thin vertical separator between tool groups within a ribbon tab
struct STRibbonSeparator: View {
    var body: some View {
        Rectangle()
            .fill(.quaternary)
            .frame(width: 0.5, height: 32)
            .padding(.horizontal, 4)
    }
}
