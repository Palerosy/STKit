import STKit
import SwiftUI

/// PDF Ribbon container — tab bar + collapsible tab content strip
/// Mirrors the STDOCX STRibbonView structure for a consistent experience
struct STPDFRibbonView: View {

    @ObservedObject var viewModel: STPDFEditorViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Tab bar row (always visible)
            STPDFRibbonTabBar(
                selectedTab: $viewModel.ribbonSelectedTab,
                isCollapsed: $viewModel.isRibbonCollapsed
            )

            Divider()

            // Collapsible tab content
            if !viewModel.isRibbonCollapsed {
                tabContent
                    .frame(height: 58)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            Divider()
        }
        .background(.ultraThinMaterial)
        .onChange(of: viewModel.ribbonSelectedTab) { newTab in
            handleTabChange(newTab)
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch viewModel.ribbonSelectedTab {
        case .draw:
            STPDFRibbonDrawTab(annotationManager: viewModel.annotationManager)
        case .markup:
            STPDFRibbonMarkupTab(annotationManager: viewModel.annotationManager)
        case .insert:
            STPDFRibbonInsertTab(annotationManager: viewModel.annotationManager)
        case .view:
            STPDFRibbonViewTab(viewModel: viewModel)
        case .pages:
            STPDFRibbonPagesTab(viewModel: viewModel)
        }
    }

    private func handleTabChange(_ tab: STPDFRibbonTab) {
        switch tab {
        case .draw, .markup, .insert:
            // Start auto-save when entering annotation mode
            viewModel.serializer.startAutoSave()
        case .view, .pages:
            // Deactivate current annotation tool (pan/hand mode)
            viewModel.annotationManager.setTool(nil)
            viewModel.annotationManager.isMarqueeSelectEnabled = false
        }
    }
}

// MARK: - Tab Bar

struct STPDFRibbonTabBar: View {
    @Binding var selectedTab: STPDFRibbonTab
    @Binding var isCollapsed: Bool

    var body: some View {
        HStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(STPDFRibbonTab.allCases) { tab in
                        tabButton(tab)
                    }
                }
                .padding(.horizontal, 8)
            }

            // Collapse toggle
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isCollapsed.toggle()
                }
            } label: {
                Image(systemName: isCollapsed ? "chevron.down" : "chevron.up")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 36, height: 36)
            }
            .padding(.trailing, 4)
        }
        .frame(height: 36)
    }

    private func tabButton(_ tab: STPDFRibbonTab) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 0) {
                Text(tab.displayName)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? Color.red : .secondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)

                Rectangle()
                    .fill(isSelected ? Color.red : .clear)
                    .frame(height: 2)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Shared Components

/// Ribbon tool button — icon on top, label below (PDF variant)
struct STPDFRibbonToolButton: View {
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
                    .fill(isActive ? Color.red : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
}

/// Thin vertical separator between ribbon button groups
struct STPDFRibbonSeparator: View {
    var body: some View {
        Rectangle()
            .fill(Color.secondary.opacity(0.2))
            .frame(width: 1, height: 32)
            .padding(.horizontal, 4)
    }
}
