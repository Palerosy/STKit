import SwiftUI
import STKit

/// Review tab — Edit Comment, Delete Comment, Protect Sheet
/// (matches competitor ribbon layout)
struct STExcelRibbonReviewTab: View {
    @ObservedObject var viewModel: STExcelEditorViewModel
    @State private var showCommentSheet = false
    @State private var showProtectSheet = false

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 2) {
                // Edit Comment (opens add/edit sheet)
                STExcelRibbonToolButton(iconName: "text.bubble", label: STExcelStrings.editComment) {
                    showCommentSheet = true
                }
                .sheet(isPresented: $showCommentSheet) {
                    STExcelCommentView(
                        comment: viewModel.currentComment ?? "",
                        onSave: { text in
                            viewModel.addComment(text)
                            showCommentSheet = false
                        },
                        onDelete: {
                            viewModel.deleteComment()
                            showCommentSheet = false
                        },
                        onCancel: { showCommentSheet = false }
                    )
                    .stPresentationDetents([.height(250)])
                }

                // Delete Comment
                STExcelRibbonToolButton(
                    iconName: "text.bubble.fill",
                    label: STExcelStrings.deleteComment,
                    isDisabled: viewModel.currentComment == nil
                ) {
                    viewModel.deleteComment()
                }

                STExcelRibbonSeparator()

                // Protect Sheet
                STExcelRibbonToolButton(
                    iconName: "lock.shield",
                    label: STExcelStrings.protectSheet,
                    isActive: viewModel.isSheetProtected
                ) {
                    showProtectSheet = true
                }
                .sheet(isPresented: $showProtectSheet) {
                    STExcelProtectSheetView(viewModel: viewModel) {
                        showProtectSheet = false
                    }
                    .stPresentationDetents([.height(300)])
                }
            }
            .padding(.horizontal, 8)
        }
    }
}

// MARK: - Protect Sheet View

private struct STExcelProtectSheetView: View {
    @ObservedObject var viewModel: STExcelEditorViewModel
    let onDismiss: () -> Void
    @State private var password = ""

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button { onDismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(width: 32, height: 32)
                        .background(Color.gray.opacity(0.15))
                        .clipShape(Circle())
                }

                Spacer()

                Text(STExcelStrings.protectSheet)
                    .font(.headline)

                Spacer()

                // Spacer for centering title
                Color.clear.frame(width: 32, height: 32)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)

            VStack(spacing: 20) {
                if viewModel.isSheetProtected {
                    // Currently protected — offer to unprotect
                    VStack(spacing: 12) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.stExcelAccent)

                        Text(STExcelStrings.sheetIsProtected)
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)

                        Button {
                            viewModel.unprotectSheet()
                            onDismiss()
                        } label: {
                            Text(STExcelStrings.unprotectSheet)
                                .font(.system(size: 16, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.red.opacity(0.9))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                } else {
                    // Not protected — offer to protect
                    VStack(spacing: 12) {
                        Image(systemName: "lock.open.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)

                        Text(STExcelStrings.sheetNotProtected)
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)

                        Button {
                            viewModel.protectSheet()
                            onDismiss()
                        } label: {
                            Text(STExcelStrings.protectSheet)
                                .font(.system(size: 16, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.stExcelAccent)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)

            Spacer()
        }
    }
}
