import SwiftUI
import STKit

/// Review tab content — Word Count, Comment, Search, Track Changes
struct STRibbonReviewTab: View {
    @ObservedObject var webEditorViewModel: STWebEditorViewModel
    let onShowSearch: () -> Void
    let onShowWordCount: () -> Void

    @State private var showCommentInput = false
    @State private var commentText = ""
    @State private var showCommentList = false

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 2) {
                // Word Count
                STRibbonToolButton(
                    iconName: "textformat.123",
                    label: STStrings.wordCount
                ) {
                    onShowWordCount()
                }

                STRibbonSeparator()

                // Add Comment — save selection before alert steals focus
                STRibbonToolButton(
                    iconName: "text.bubble",
                    label: STStrings.ribbonComment
                ) {
                    webEditorViewModel.saveSelection()
                    commentText = ""
                    showCommentInput = true
                }
                .alert(STStrings.ribbonComment, isPresented: $showCommentInput) {
                    TextField(STStrings.ribbonComment, text: $commentText)
                    Button(STStrings.cancel, role: .cancel) { }
                    Button(STStrings.add) {
                        let text = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !text.isEmpty else { return }
                        webEditorViewModel.insertComment(text: text)
                    }
                } message: {
                    Text(STStrings.selectTextForComment)
                }

                // Comments List
                STRibbonToolButton(
                    iconName: "text.bubble.fill",
                    label: STStrings.ribbonComments
                ) {
                    showCommentList = true
                }
                .sheet(isPresented: $showCommentList) {
                    STCommentListView(webEditorViewModel: webEditorViewModel)
                }

                STRibbonSeparator()

                // Search
                STRibbonToolButton(
                    iconName: "magnifyingglass",
                    label: STStrings.search
                ) {
                    onShowSearch()
                }

                STRibbonSeparator()

                // Track Changes toggle
                STRibbonToolButton(
                    iconName: "pencil.and.list.clipboard",
                    label: STStrings.ribbonTrackChanges,
                    isActive: webEditorViewModel.isTrackChangesEnabled
                ) {
                    webEditorViewModel.toggleTrackChanges()
                }

                // Accept All
                STRibbonToolButton(
                    iconName: "checkmark.circle",
                    label: STStrings.ribbonAcceptChange
                ) {
                    webEditorViewModel.acceptAllChanges()
                }

                // Reject All
                STRibbonToolButton(
                    iconName: "xmark.circle",
                    label: STStrings.ribbonRejectChange
                ) {
                    webEditorViewModel.rejectAllChanges()
                }
            }
            .padding(.horizontal, 8)
        }
    }
}
