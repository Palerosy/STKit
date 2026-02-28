import SwiftUI

/// Applies presentationCompactAdaptation on iOS 16.4+
private struct CompactPopoverModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.stPresentationCompactAdaptation()
    }
}

/// Popover for selecting a tool variant within a group
struct STToolVariantPopover: View {
    
    let group: STAnnotationGroup
    @ObservedObject var annotationManager: STAnnotationManager
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            ForEach(group.tools) { tool in
                Button {
                    annotationManager.toggleTool(tool)
                    isPresented = false
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: tool.iconName)
                            .font(.system(size: 16))
                            .frame(width: 24)
                        
                        Text(tool.displayName)
                            .font(.subheadline)
                        
                        Spacer()
                        
                        if annotationManager.activeTool == tool {
                            Image(systemName: "checkmark")
                                .font(.caption.weight(.bold))
                                .foregroundColor(.accentColor)
                        }
                    }
                    .foregroundColor(.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        annotationManager.activeTool == tool
                            ? Color.accentColor.opacity(0.1)
                            : Color.clear
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding(8)
        .frame(minWidth: 180)
        .modifier(CompactPopoverModifier())
    }
}
