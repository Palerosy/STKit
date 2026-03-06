import SwiftUI
import STKit

/// Add/Edit comment sheet for a cell
struct STExcelCommentView: View {
    @State var comment: String
    let onSave: (String) -> Void
    let onDelete: () -> Void
    let onCancel: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                TextEditor(text: $comment)
                    .font(.system(size: 15))
                    .focused($isFocused)
                    .frame(minHeight: 100)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.stSeparator, lineWidth: 1)
                    )

                HStack(spacing: 12) {
                    if !comment.isEmpty {
                        Button(role: .destructive) {
                            onDelete()
                        } label: {
                            Text(STExcelStrings.deleteComment)
                                .font(.system(size: 14))
                        }
                    }
                    Spacer()
                    Button(STStrings.save) {
                        onSave(comment)
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .disabled(comment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding(16)
            .navigationTitle(STExcelStrings.addComment)
            .stNavigationBarTitleDisplayMode()
            .toolbar {
                ToolbarItem(placement: .stTrailing) {
                    Button(STStrings.cancel) { onCancel() }
                }
            }
        }
        .onAppear { isFocused = true }
    }
}
