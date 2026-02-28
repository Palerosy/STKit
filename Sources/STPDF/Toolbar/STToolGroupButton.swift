import SwiftUI

/// A toolbar button representing a tool group
/// Tap: activate the last-used tool in this group
/// Long press: show variant popover
struct STToolGroupButton: View {
    
    let group: STAnnotationGroup
    @ObservedObject var annotationManager: STAnnotationManager
    @State private var showVariantPopover = false
    
    private var selectedTool: STAnnotationType {
        annotationManager.selectedToolPerGroup[group] ?? group.defaultTool
    }
    
    private var isActive: Bool {
        guard let activeTool = annotationManager.activeTool else { return false }
        return group.tools.contains(activeTool)
    }
    
    var body: some View {
        Button {
            annotationManager.toggleTool(selectedTool)
        } label: {
            Image(systemName: selectedTool.iconName)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(isActive ? .white : .primary)
                .frame(width: 44, height: 36)
                .background(isActive ? Color.accentColor : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .onLongPressGesture(minimumDuration: 0.4) {
            if group.tools.count > 1 {
                showVariantPopover = true
            }
        }
        .popover(isPresented: $showVariantPopover) {
            STToolVariantPopover(
                group: group,
                annotationManager: annotationManager,
                isPresented: $showVariantPopover
            )
        }
    }
}
