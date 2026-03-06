import SwiftUI
import STKit

/// Horizontal scrollable tab bar with active underline indicator
struct STExcelRibbonTabBar: View {
    @Binding var selectedTab: STExcelRibbonTab
    let availableTabs: [STExcelRibbonTab]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(availableTabs) { tab in tabButton(tab) }
            }
            .padding(.horizontal, 8)
        }
        .frame(height: 36)
    }

    private func tabButton(_ tab: STExcelRibbonTab) -> some View {
        let isSelected = selectedTab == tab
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) { selectedTab = tab }
        } label: {
            VStack(spacing: 0) {
                Text(tab.displayName)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .stExcelAccent : .secondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                Rectangle()
                    .fill(isSelected ? Color.stExcelAccent : .clear)
                    .frame(height: 2)
            }
        }
        .buttonStyle(.plain)
    }
}
