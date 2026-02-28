import STKit
import SwiftUI
import PDFKit

/// In-document text search view
struct STSearchView: View {

    let document: PDFDocument
    let onResultSelected: (PDFSelection) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""
    @State private var results: [PDFSelection] = []
    @State private var isSearching = false

    var body: some View {
        #if os(macOS)
        macOSBody
        #else
        iOSBody
        #endif
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField(STStrings.searchInDocument, text: $searchText)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
                .onSubmit { performSearch() }
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    results = []
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(Color.stSecondarySystemGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Results Content

    @ViewBuilder
    private var resultsContent: some View {
        if isSearching {
            VStack { Spacer(); ProgressView(STStrings.searching); Spacer() }
                .frame(minHeight: 120)
        } else if results.isEmpty && !searchText.isEmpty {
            VStack { Spacer(); Text(STStrings.noResultsFound).foregroundColor(.secondary); Spacer() }
                .frame(minHeight: 120)
        } else if !results.isEmpty {
            List(Array(results.enumerated()), id: \.offset) { index, selection in
                Button {
                    onResultSelected(selection)
                    dismiss()
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        if let page = selection.pages.first {
                            let pageIndex = document.index(for: page)
                            Text(STStrings.page(pageIndex + 1))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Text(contextString(for: selection))
                            .font(.subheadline)
                            .lineLimit(2)
                    }
                }
                .foregroundColor(.primary)
            }
            .listStyle(.plain)
        }
    }

    // MARK: - macOS

    #if os(macOS)
    private var macOSBody: some View {
        let sw = NSScreen.main?.frame.width ?? 1440
        let sh = NSScreen.main?.frame.height ?? 900
        return VStack(spacing: 0) {
            HStack {
                Text(STStrings.search)
                    .font(.headline)
                Spacer()
                Button(STStrings.done) { dismiss() }
                    .buttonStyle(.plain)
                    .foregroundColor(.accentColor)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            Divider()

            searchBar
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

            Divider()

            resultsContent
                .frame(height: sh * 0.4)
        }
        .frame(width: sw * 0.35)
    }
    #endif

    // MARK: - iOS

    private var iOSBody: some View {
        STNavigationView {
            VStack(spacing: 0) {
                searchBar
                    .padding()
                Divider()
                resultsContent
            }
            .navigationTitle(STStrings.search)
            .stNavigationBarTitleDisplayMode()
            .toolbar {
                ToolbarItem(placement: .stTrailing) {
                    Button(STStrings.done) { dismiss() }
                }
            }
        }
    }

    private func performSearch() {
        guard !searchText.isEmpty else { return }
        isSearching = true
        results = []

        DispatchQueue.global(qos: .userInitiated).async {
            let found = document.findString(searchText, withOptions: .caseInsensitive)
            DispatchQueue.main.async {
                results = found
                isSearching = false
            }
        }
    }

    private func contextString(for selection: PDFSelection) -> String {
        selection.string ?? searchText
    }
}
