import SwiftUI

/// A ribbon button that represents a tool group — tap for default, long-press for variant popover
struct STRibbonToolGroup: View {
    let tools: [STAnnotationType]
    let activeTool: STAnnotationType?
    let onSelect: (STAnnotationType) -> Void

    @State private var showPopover = false

    /// The currently "remembered" tool for this group
    private var displayTool: STAnnotationType {
        // Show active tool if it's in this group, otherwise show first
        if let active = activeTool, tools.contains(active) {
            return active
        }
        return tools.first ?? .rectangle
    }

    private var isActive: Bool {
        guard let active = activeTool else { return false }
        return tools.contains(active)
    }

    var body: some View {
        Button {
            onSelect(displayTool)
        } label: {
            VStack(spacing: 2) {
                ZStack(alignment: .bottomTrailing) {
                    Image(systemName: displayTool.iconName)
                        .font(.system(size: 17, weight: .medium))
                        .frame(width: 24, height: 24)

                    // Chevron indicator for group
                    if tools.count > 1 {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 6, weight: .bold))
                            .offset(x: 4, y: 2)
                    }
                }

                Text(displayTool.displayName)
                    .font(.system(size: 9, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundColor(isActive ? .white : .primary)
            .frame(width: 52, height: 50)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isActive ? Color.accentColor : .clear)
            )
        }
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.4)
                .onEnded { _ in
                    if tools.count > 1 {
                        showPopover = true
                    }
                }
        )
        .popover(isPresented: $showPopover) {
            VStack(spacing: 2) {
                ForEach(tools) { tool in
                    Button {
                        showPopover = false
                        onSelect(tool)
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: tool.iconName)
                                .font(.system(size: 16))
                                .frame(width: 24)
                            Text(tool.displayName)
                                .font(.system(size: 14))
                            Spacer()
                            if activeTool == tool {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 6)
            .frame(minWidth: 180)
        }
    }
}
