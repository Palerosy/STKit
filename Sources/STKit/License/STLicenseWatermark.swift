import SwiftUI

/// Overlay watermark shown when no valid license is active
public struct STLicenseWatermark: View {

    let moduleName: String

    public init(moduleName: String = "STKit") {
        self.moduleName = moduleName
    }

    public var body: some View {
        GeometryReader { geometry in
            let text = "\(moduleName) \u{2014} Unlicensed"
            ZStack {
                ForEach(0..<3, id: \.self) { row in
                    ForEach(0..<2, id: \.self) { col in
                        Text(text)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.red.opacity(0.15))
                            .rotationEffect(.degrees(-30))
                            .position(
                                x: geometry.size.width * CGFloat(col + 1) / 3,
                                y: geometry.size.height * CGFloat(row + 1) / 4
                            )
                    }
                }
            }
            .allowsHitTesting(false)
        }
    }
}
