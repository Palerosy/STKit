import SwiftUI
import STKit

private struct STFontCategory: Identifiable {
    let id = UUID()
    let name: String
    let fonts: [String]
}

private let fontCategories: [STFontCategory] = [
    STFontCategory(name: "Sans-Serif", fonts: [
        "Calibri", "Arial", "Helvetica Neue", "Helvetica",
        "Verdana", "Tahoma", "Trebuchet MS", "Gill Sans",
        "Optima", "Avenir", "Avenir Next", "Futura",
    ]),
    STFontCategory(name: "Serif", fonts: [
        "Times New Roman", "Georgia", "Palatino",
        "Baskerville", "Cochin", "Hoefler Text",
        "Didot", "American Typewriter",
    ]),
    STFontCategory(name: "Monospace", fonts: [
        "Courier New", "Courier", "Menlo", "Monaco",
    ]),
    STFontCategory(name: "Display", fonts: [
        "Impact", "Chalkboard SE", "Noteworthy", "Marker Felt", "Zapfino",
    ]),
]

private struct STFontRow: View {
    let fontName: String
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(fontName)
                        .font(.custom(fontName, size: 17))
                        .foregroundColor(.primary)
                    Text("AaBbCc 123")
                        .font(.custom(fontName, size: 12))
                        .foregroundColor(.secondary)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.accentColor)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// Full-screen font picker sheet with categories, live preview and search
struct STRibbonFontPickerView: View {
    let currentFont: String
    let onSelect: (String) -> Void

    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss

    private var filtered: [STFontCategory] {
        guard !searchText.isEmpty else { return fontCategories }
        let q = searchText.lowercased()
        return fontCategories.compactMap { cat in
            let matched = cat.fonts.filter { $0.lowercased().contains(q) }
            return matched.isEmpty ? nil : STFontCategory(name: cat.name, fonts: matched)
        }
    }

    var body: some View {
        #if os(macOS)
        macOSBody
        #else
        iOSBody
        #endif
    }

    #if os(macOS)
    private var macOSBody: some View {
        let sw = NSScreen.main?.frame.width ?? 1440
        let sh = NSScreen.main?.frame.height ?? 900
        return VStack(spacing: 0) {
            HStack {
                Text("Font")
                    .font(.headline)
                Spacer()
                Button(STStrings.close) { dismiss() }
                    .buttonStyle(.plain)
                    .foregroundColor(.accentColor)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            Divider()

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search fonts", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(10)
            .background(Color.stSecondarySystemGroupedBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal, 16)
            .padding(.top, 8)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(filtered) { category in
                        Text(category.name)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                            .padding(.bottom, 4)

                        ForEach(category.fonts, id: \.self) { fontName in
                            STFontRow(
                                fontName: fontName,
                                isSelected: fontName == currentFont
                            ) {
                                onSelect(fontName)
                                dismiss()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .frame(maxHeight: sh * 0.5)
        }
        .frame(width: sw * 0.3)
    }
    #endif

    private var iOSBody: some View {
        NavigationView {
            List {
                ForEach(filtered) { category in
                    Section(header: Text(category.name).font(.caption).foregroundColor(.secondary)) {
                        ForEach(category.fonts, id: \.self) { fontName in
                            STFontRow(
                                fontName: fontName,
                                isSelected: fontName == currentFont
                            ) {
                                onSelect(fontName)
                                dismiss()
                            }
                        }
                    }
                }
            }
            .stInsetGroupedListStyle()
            .searchable(text: $searchText, prompt: "Search fonts")
            .navigationTitle("Font")
            .stNavigationBarTitleDisplayMode()
            .toolbar {
                ToolbarItem(placement: .stTrailing) {
                    Button(STStrings.close) { dismiss() }
                }
            }
        }
    }
}
