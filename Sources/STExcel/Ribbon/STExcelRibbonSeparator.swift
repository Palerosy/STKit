import SwiftUI

/// Thin vertical divider between tool groups in the ribbon
struct STExcelRibbonSeparator: View {
    var body: some View {
        Rectangle()
            .fill(.quaternary)
            .frame(width: 0.5, height: 32)
            .padding(.horizontal, 4)
    }
}
