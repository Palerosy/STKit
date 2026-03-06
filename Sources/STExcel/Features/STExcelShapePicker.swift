import SwiftUI
import STKit

/// Grid picker for inserting shapes
struct STExcelShapePicker: View {
    let onSelect: (STExcelShapeType) -> Void
    let onDismiss: () -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    shapeSection(STExcelStrings.basicShapes, shapes: STExcelShapeType.basicShapes)
                    shapeSection(STExcelStrings.arrowsTriangles, shapes: STExcelShapeType.trianglesAndArrows)
                    shapeSection(STExcelStrings.starsMore, shapes: STExcelShapeType.starsAndMisc)
                    shapeSection(STExcelStrings.lineShapes, shapes: STExcelShapeType.lines)
                }
                .padding(16)
            }
            .navigationTitle(STStrings.ribbonShape)
            .stNavigationBarTitleDisplayMode()
            .toolbar {
                ToolbarItem(placement: .stTrailing) {
                    Button { onDismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    private func shapeSection(_ title: String, shapes: [STExcelShapeType]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(shapes) { shape in
                    Button {
                        onSelect(shape)
                    } label: {
                        VStack(spacing: 4) {
                            shapePreview(shape)
                                .frame(width: 44, height: 44)
                            Text(shape.displayName)
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.primary)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                                .minimumScaleFactor(0.7)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.stSecondarySystemBackground)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private func shapePreview(_ type: STExcelShapeType) -> some View {
        switch type {
        case .rectangle:
            Rectangle()
                .fill(Color.blue.opacity(0.3))
                .overlay(Rectangle().stroke(Color.blue, lineWidth: 1.5))
        case .roundedRectangle:
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue.opacity(0.3))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.blue, lineWidth: 1.5))
        case .circle:
            Circle()
                .fill(Color.blue.opacity(0.3))
                .overlay(Circle().stroke(Color.blue, lineWidth: 1.5))
        case .oval:
            Ellipse()
                .fill(Color.blue.opacity(0.3))
                .overlay(Ellipse().stroke(Color.blue, lineWidth: 1.5))
                .frame(width: 44, height: 28)
        case .triangle:
            STExcelTriangleShape()
                .fill(Color.blue.opacity(0.3))
                .overlay(STExcelTriangleShape().stroke(Color.blue, lineWidth: 1.5))
        case .rightTriangle:
            STExcelRightTriangleShape()
                .fill(Color.blue.opacity(0.3))
                .overlay(STExcelRightTriangleShape().stroke(Color.blue, lineWidth: 1.5))
        case .diamond:
            STExcelDiamondShape()
                .fill(Color.blue.opacity(0.3))
                .overlay(STExcelDiamondShape().stroke(Color.blue, lineWidth: 1.5))
        case .arrowRight:
            STExcelArrowShape(direction: .right)
                .fill(Color.blue.opacity(0.3))
                .overlay(STExcelArrowShape(direction: .right).stroke(Color.blue, lineWidth: 1.5))
        case .arrowLeft:
            STExcelArrowShape(direction: .left)
                .fill(Color.blue.opacity(0.3))
                .overlay(STExcelArrowShape(direction: .left).stroke(Color.blue, lineWidth: 1.5))
        case .arrowUp:
            STExcelArrowShape(direction: .up)
                .fill(Color.blue.opacity(0.3))
                .overlay(STExcelArrowShape(direction: .up).stroke(Color.blue, lineWidth: 1.5))
        case .arrowDown:
            STExcelArrowShape(direction: .down)
                .fill(Color.blue.opacity(0.3))
                .overlay(STExcelArrowShape(direction: .down).stroke(Color.blue, lineWidth: 1.5))
        case .star:
            STExcelStarShape()
                .fill(Color.blue.opacity(0.3))
                .overlay(STExcelStarShape().stroke(Color.blue, lineWidth: 1.5))
        case .hexagon:
            STExcelHexagonShape()
                .fill(Color.blue.opacity(0.3))
                .overlay(STExcelHexagonShape().stroke(Color.blue, lineWidth: 1.5))
        case .pentagon:
            STExcelPentagonShape()
                .fill(Color.blue.opacity(0.3))
                .overlay(STExcelPentagonShape().stroke(Color.blue, lineWidth: 1.5))
        case .line:
            Rectangle()
                .fill(Color.blue)
                .frame(height: 2)
        case .dashedLine:
            STExcelDashedLineShape()
                .stroke(Color.blue, style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                .frame(height: 2)
        }
    }
}
