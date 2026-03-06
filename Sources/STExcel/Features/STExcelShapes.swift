import SwiftUI

// MARK: - Triangle

struct STExcelTriangleShape: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.midX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            p.closeSubpath()
        }
    }
}

// MARK: - Right Triangle

struct STExcelRightTriangleShape: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.minX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            p.closeSubpath()
        }
    }
}

// MARK: - Diamond

struct STExcelDiamondShape: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.midX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
            p.closeSubpath()
        }
    }
}

// MARK: - Arrow

enum STExcelArrowDirection {
    case right, left, up, down
}

struct STExcelArrowShape: Shape {
    let direction: STExcelArrowDirection

    func path(in rect: CGRect) -> Path {
        // Draw in "right" orientation, then rotate
        let w = rect.width
        let h = rect.height
        var p = Path()

        switch direction {
        case .right:
            let shaft = h * 0.3
            p.move(to: CGPoint(x: 0, y: h / 2 - shaft))
            p.addLine(to: CGPoint(x: w * 0.6, y: h / 2 - shaft))
            p.addLine(to: CGPoint(x: w * 0.6, y: 0))
            p.addLine(to: CGPoint(x: w, y: h / 2))
            p.addLine(to: CGPoint(x: w * 0.6, y: h))
            p.addLine(to: CGPoint(x: w * 0.6, y: h / 2 + shaft))
            p.addLine(to: CGPoint(x: 0, y: h / 2 + shaft))
            p.closeSubpath()

        case .left:
            let shaft = h * 0.3
            p.move(to: CGPoint(x: w, y: h / 2 - shaft))
            p.addLine(to: CGPoint(x: w * 0.4, y: h / 2 - shaft))
            p.addLine(to: CGPoint(x: w * 0.4, y: 0))
            p.addLine(to: CGPoint(x: 0, y: h / 2))
            p.addLine(to: CGPoint(x: w * 0.4, y: h))
            p.addLine(to: CGPoint(x: w * 0.4, y: h / 2 + shaft))
            p.addLine(to: CGPoint(x: w, y: h / 2 + shaft))
            p.closeSubpath()

        case .up:
            let shaft = w * 0.3
            p.move(to: CGPoint(x: w / 2, y: 0))
            p.addLine(to: CGPoint(x: w, y: h * 0.4))
            p.addLine(to: CGPoint(x: w / 2 + shaft, y: h * 0.4))
            p.addLine(to: CGPoint(x: w / 2 + shaft, y: h))
            p.addLine(to: CGPoint(x: w / 2 - shaft, y: h))
            p.addLine(to: CGPoint(x: w / 2 - shaft, y: h * 0.4))
            p.addLine(to: CGPoint(x: 0, y: h * 0.4))
            p.closeSubpath()

        case .down:
            let shaft = w * 0.3
            p.move(to: CGPoint(x: w / 2 - shaft, y: 0))
            p.addLine(to: CGPoint(x: w / 2 + shaft, y: 0))
            p.addLine(to: CGPoint(x: w / 2 + shaft, y: h * 0.6))
            p.addLine(to: CGPoint(x: w, y: h * 0.6))
            p.addLine(to: CGPoint(x: w / 2, y: h))
            p.addLine(to: CGPoint(x: 0, y: h * 0.6))
            p.addLine(to: CGPoint(x: w / 2 - shaft, y: h * 0.6))
            p.closeSubpath()
        }

        return p.offsetBy(dx: rect.minX, dy: rect.minY)
    }
}

// MARK: - Star (5-point)

struct STExcelStarShape: Shape {
    func path(in rect: CGRect) -> Path {
        let cx = rect.midX
        let cy = rect.midY
        let outerR = min(rect.width, rect.height) / 2
        let innerR = outerR * 0.38
        var p = Path()

        for i in 0..<10 {
            let angle = Angle.degrees(Double(i) * 36.0 - 90)
            let r = i.isMultiple(of: 2) ? outerR : innerR
            let pt = CGPoint(
                x: cx + r * CGFloat(cos(angle.radians)),
                y: cy + r * CGFloat(sin(angle.radians))
            )
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        return p
    }
}

// MARK: - Hexagon

struct STExcelHexagonShape: Shape {
    func path(in rect: CGRect) -> Path {
        let cx = rect.midX
        let cy = rect.midY
        let r = min(rect.width, rect.height) / 2
        var p = Path()
        for i in 0..<6 {
            let angle = Angle.degrees(Double(i) * 60.0 - 90)
            let pt = CGPoint(
                x: cx + r * CGFloat(cos(angle.radians)),
                y: cy + r * CGFloat(sin(angle.radians))
            )
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        return p
    }
}

// MARK: - Pentagon

struct STExcelPentagonShape: Shape {
    func path(in rect: CGRect) -> Path {
        let cx = rect.midX
        let cy = rect.midY
        let r = min(rect.width, rect.height) / 2
        var p = Path()
        for i in 0..<5 {
            let angle = Angle.degrees(Double(i) * 72.0 - 90)
            let pt = CGPoint(
                x: cx + r * CGFloat(cos(angle.radians)),
                y: cy + r * CGFloat(sin(angle.radians))
            )
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        return p
    }
}

// MARK: - Dashed Line

struct STExcelDashedLineShape: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.minX, y: rect.midY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        }
    }
}
