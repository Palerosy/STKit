import SwiftUI
import STKit

/// Horizontal row of ribbon tab buttons — Home, Insert, Draw, Design, Layout, Review, View
struct STRibbonTabBar: View {
    @Binding var selectedTab: STRibbonTab
    let availableTabs: [STRibbonTab]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(availableTabs) { tab in
                    tabButton(tab)
                }
            }
            .padding(.horizontal, 8)
        }
        .frame(height: 36)
    }

    private func tabButton(_ tab: STRibbonTab) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 0) {
                Text(tab.displayName)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)

                // Active indicator bar
                Rectangle()
                    .fill(isSelected ? Color.accentColor : .clear)
                    .frame(height: 2)
            }
        }
        .buttonStyle(.plain)
    }
}
