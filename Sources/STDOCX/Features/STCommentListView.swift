import SwiftUI
import STKit

/// Sheet view that lists all comments in the document
struct STCommentListView: View {
    @ObservedObject var webEditorViewModel: STWebEditorViewModel
    @State private var comments: [(id: String, text: String, contextText: String)] = []
    @Environment(\.dismiss) var dismiss

    var body: some View {
        #if os(macOS)
        macOSBody
        #else
        iOSBody
        #endif
    }

    private var commentContent: some View {
        Group {
            if comments.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "text.bubble")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text(STStrings.ribbonComments)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(comments.enumerated()), id: \.element.id) { index, comment in
                            Button {
                                webEditorViewModel.scrollToComment(id: comment.id)
                                dismiss()
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(comment.text)
                                            .font(.subheadline)
                                            .foregroundColor(.primary)
                                        if !comment.contextText.isEmpty {
                                            Text("\"\(comment.contextText)\"")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .lineLimit(2)
                                        }
                                    }
                                    Spacer()
                                    #if os(macOS)
                                    Button {
                                        webEditorViewModel.deleteComment(id: comment.id)
                                        comments.remove(at: index)
                                    } label: {
                                        Image(systemName: "trash")
                                            .font(.caption)
                                            .foregroundColor(.red)
                                    }
                                    .buttonStyle(.plain)
                                    #endif
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                            }
                            .buttonStyle(.plain)
                            if index < comments.count - 1 {
                                Divider().padding(.leading, 16)
                            }
                        }
                    }
                }
            }
        }
    }

    #if os(macOS)
    private var macOSBody: some View {
        let sw = NSScreen.main?.frame.width ?? 1440
        let sh = NSScreen.main?.frame.height ?? 900
        return VStack(spacing: 0) {
            HStack {
                Text(STStrings.ribbonComments)
                    .font(.headline)
                Spacer()
                Button(STStrings.done) { dismiss() }
                    .buttonStyle(.plain)
                    .foregroundColor(.accentColor)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            Divider()

            commentContent
                .frame(maxHeight: sh * 0.45)
        }
        .frame(width: sw * 0.3)
        .task {
            comments = await webEditorViewModel.getComments()
        }
    }
    #endif

    private var iOSBody: some View {
        NavigationView {
            Group {
                if comments.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "text.bubble")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text(STStrings.ribbonComments)
                            .foregroundColor(.secondary)
                    }
                } else {
                    List {
                        ForEach(comments, id: \.id) { comment in
                            Button {
                                webEditorViewModel.scrollToComment(id: comment.id)
                                dismiss()
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(comment.text)
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                    if !comment.contextText.isEmpty {
                                        Text("\"\(comment.contextText)\"")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .lineLimit(2)
                                    }
                                }
                            }
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                webEditorViewModel.deleteComment(id: comments[index].id)
                            }
                            comments.remove(atOffsets: indexSet)
                        }
                    }
                }
            }
            .navigationTitle(STStrings.ribbonComments)
            .stNavigationBarTitleDisplayMode()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(STStrings.done) { dismiss() }
                }
            }
        }
        .task {
            comments = await webEditorViewModel.getComments()
        }
    }
}
