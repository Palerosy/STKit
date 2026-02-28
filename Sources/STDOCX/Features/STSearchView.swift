import SwiftUI
import STKit

/// Find & Replace view for the WKWebView DOCX editor
struct STSearchView: View {

    @ObservedObject var webEditorViewModel: STWebEditorViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""
    @State private var replaceText = ""
    @State private var matchCount = 0
    @State private var currentIndex = -1
    @State private var showReplace = false
    @State private var caseSensitive = false

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
                Text(STStrings.search)
                    .font(.headline)
                Spacer()
                Button(STStrings.done) {
                    webEditorViewModel.clearFindHighlights()
                    dismiss()
                }
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            Divider()

            searchBar
            if showReplace { replaceBar }
            optionsRow
            Divider()

            VStack {
                Spacer()
                if matchCount > 0 {
                    Text("\(currentIndex + 1) / \(matchCount)")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.secondary)
                } else if !searchText.isEmpty {
                    Text(STStrings.noResultsFound)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .frame(height: sh * 0.2)
        }
        .frame(width: sw * 0.35)
    }
    #endif

    private var iOSBody: some View {
        NavigationView {
            VStack(spacing: 0) {
                searchBar
                if showReplace { replaceBar }
                optionsRow
                Divider()
                Spacer()
                if matchCount > 0 {
                    Text("\(currentIndex + 1) / \(matchCount)")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.secondary)
                } else if !searchText.isEmpty {
                    Text(STStrings.noResultsFound)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .navigationTitle(STStrings.search)
            .stNavigationBarTitleDisplayMode()
            .toolbar {
                ToolbarItem(placement: .stTrailing) {
                    Button(STStrings.done) {
                        webEditorViewModel.clearFindHighlights()
                        dismiss()
                    }
                }
            }
        }
        .stPresentationDetents([.medium, .large])
        .stPresentationDragIndicator(.visible)
    }

    // MARK: - Search Bar

    @ViewBuilder
    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField(STStrings.searchInDocument, text: $searchText)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
                #if os(iOS)
                    .textInputAutocapitalization(.never)
                    #endif
                .onSubmit { performSearch() }
                .onChange(of: searchText) { _ in
                    performSearch()
                }

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    matchCount = 0
                    currentIndex = -1
                    webEditorViewModel.clearFindHighlights()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }

            // Navigation buttons
            if matchCount > 0 {
                Button { goToPrevious() } label: {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 14, weight: .semibold))
                }

                Button { goToNext() } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                }
            }
        }
        .padding(12)
        .background(Color.stSecondarySystemGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal)
        .padding(.top, 12)
    }

    // MARK: - Replace Bar

    @ViewBuilder
    private var replaceBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.2.squarepath")
                .foregroundColor(.secondary)

            TextField(STStrings.replaceWith, text: $replaceText)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
                #if os(iOS)
                    .textInputAutocapitalization(.never)
                    #endif

            // Replace one
            Button {
                Task {
                    let remaining = await webEditorViewModel.replaceCurrent(with: replaceText)
                    matchCount = remaining
                    if remaining > 0 {
                        currentIndex = min(currentIndex, remaining - 1)
                    } else {
                        currentIndex = -1
                    }
                }
            } label: {
                Text(STStrings.replace)
                    .font(.system(size: 13, weight: .medium))
            }
            .disabled(matchCount == 0)

            // Replace all
            Button {
                Task {
                    let count = await webEditorViewModel.replaceAll(with: replaceText)
                    matchCount = 0
                    currentIndex = -1
                    if count > 0 {
                        // brief feedback could go here
                    }
                }
            } label: {
                Text(STStrings.replaceAll)
                    .font(.system(size: 13, weight: .medium))
            }
            .disabled(matchCount == 0)
        }
        .padding(12)
        .background(Color.stSecondarySystemGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal)
        .padding(.top, 6)
    }

    // MARK: - Options Row

    @ViewBuilder
    private var optionsRow: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showReplace.toggle()
                }
            } label: {
                Label(
                    showReplace ? STStrings.hideReplace : STStrings.showReplace,
                    systemImage: "arrow.2.squarepath"
                )
                .font(.system(size: 13))
            }

            Spacer()

            Button {
                caseSensitive.toggle()
                performSearch()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: caseSensitive ? "textformat.abc" : "textformat")
                        .font(.system(size: 13))
                    Text(caseSensitive ? "Aa" : "aa")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundStyle(caseSensitive ? .primary : .secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - Actions

    private func performSearch() {
        guard !searchText.isEmpty else {
            matchCount = 0
            currentIndex = -1
            return
        }
        Task {
            let count = await webEditorViewModel.findInContent(searchText, caseSensitive: caseSensitive)
            matchCount = count
            currentIndex = count > 0 ? 0 : -1
        }
    }

    private func goToNext() {
        webEditorViewModel.findNext()
        if matchCount > 0 {
            currentIndex = (currentIndex + 1) % matchCount
        }
    }

    private func goToPrevious() {
        webEditorViewModel.findPrevious()
        if matchCount > 0 {
            currentIndex = (currentIndex - 1 + matchCount) % matchCount
        }
    }
}
