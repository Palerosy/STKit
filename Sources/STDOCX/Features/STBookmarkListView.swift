import SwiftUI
import STKit

/// Sheet view that lists all bookmarks in the document
struct STBookmarkListView: View {
    @ObservedObject var webEditorViewModel: STWebEditorViewModel
    @State private var bookmarks: [(id: String, name: String)] = []
    @Environment(\.dismiss) var dismiss

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
                Text(STStrings.ribbonBookmarks)
                    .font(.headline)
                Spacer()
                Button(STStrings.done) { dismiss() }
                    .buttonStyle(.plain)
                    .foregroundColor(.accentColor)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            Divider()

            Group {
                if bookmarks.isEmpty {
                    VStack(spacing: 12) {
                        Spacer()
                        Image(systemName: "bookmark")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text(STStrings.ribbonBookmarks)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 150)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(Array(bookmarks.enumerated()), id: \.element.id) { index, bookmark in
                                HStack {
                                    Button {
                                        webEditorViewModel.scrollToBookmark(id: bookmark.id)
                                        dismiss()
                                    } label: {
                                        Label(bookmark.name, systemImage: "bookmark.fill")
                                            .foregroundColor(.primary)
                                    }
                                    .buttonStyle(.plain)
                                    Spacer()
                                    Button {
                                        webEditorViewModel.removeBookmark(id: bookmark.id)
                                        bookmarks.remove(at: index)
                                    } label: {
                                        Image(systemName: "trash")
                                            .font(.caption)
                                            .foregroundColor(.red)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                if index < bookmarks.count - 1 {
                                    Divider().padding(.leading, 16)
                                }
                            }
                        }
                    }
                    .frame(maxHeight: sh * 0.4)
                }
            }
        }
        .frame(width: sw * 0.3)
        .task {
            bookmarks = await webEditorViewModel.getBookmarks()
        }
    }
    #endif

    private var iOSBody: some View {
        NavigationView {
            Group {
                if bookmarks.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "bookmark")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text(STStrings.ribbonBookmarks)
                            .foregroundColor(.secondary)
                    }
                } else {
                    List {
                        ForEach(bookmarks, id: \.id) { bookmark in
                            Button {
                                webEditorViewModel.scrollToBookmark(id: bookmark.id)
                                dismiss()
                            } label: {
                                Label(bookmark.name, systemImage: "bookmark.fill")
                                    .foregroundColor(.primary)
                            }
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                webEditorViewModel.removeBookmark(id: bookmarks[index].id)
                            }
                            bookmarks.remove(atOffsets: indexSet)
                        }
                    }
                }
            }
            .navigationTitle(STStrings.ribbonBookmarks)
            .stNavigationBarTitleDisplayMode()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(STStrings.done) { dismiss() }
                }
            }
        }
        .task {
            bookmarks = await webEditorViewModel.getBookmarks()
        }
    }
}
