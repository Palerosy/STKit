import STKit
import SwiftUI
import PDFKit

/// View for placing a free text annotation on the PDF.
/// Tap anywhere to place a text input popup at that location.
struct STTextInputOverlay: View {

    let onSubmit: (_ text: String, _ screenPoint: CGPoint) -> Void
    let onCancel: () -> Void

    @State private var text = ""
    @State private var tapLocation: CGPoint? = nil
    @State private var isEditing = false
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack {
            // Tap capture layer
            if !isEditing {
                Color.black.opacity(0.001)
                    .contentShape(Rectangle())
                    .onTapGesture { location in
                        tapLocation = location
                        isEditing = true
                        isFocused = true
                    }
            }

            // Alert-style text input dialog
            if isEditing, let location = tapLocation {
                // Dim background
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture { dismiss() }

                VStack(spacing: 0) {
                    // Title
                    Text(STStrings.toolText)
                        .font(.headline)
                        .padding(.top, 20)
                        .padding(.bottom, 12)

                    // Text field
                    TextField(STStrings.enterText, text: $text, axis: .vertical)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(Color.stSystemBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .lineLimit(1...6)
                        .focused($isFocused)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)

                    Divider()

                    // Buttons
                    HStack(spacing: 0) {
                        Button {
                            dismiss()
                        } label: {
                            Text(STStrings.cancel)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .foregroundColor(.accentColor)
                        }

                        Divider()
                            .frame(height: 44)

                        Button {
                            if !text.isEmpty {
                                onSubmit(text, location)
                            }
                            dismiss()
                        } label: {
                            Text(STStrings.add)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .foregroundColor(text.isEmpty ? .gray : .accentColor)
                        }
                        .disabled(text.isEmpty)
                    }
                    .font(.body)
                }
                .frame(width: 270)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 8)
                .transition(.scale(scale: 0.85).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.25, dampingFraction: 0.85), value: isEditing)
    }

    private func dismiss() {
        text = ""
        isEditing = false
        tapLocation = nil
        isFocused = false
        onCancel()
    }
}

// MARK: - Text Edit Overlay (Redact + Replace)

/// Data returned from a text hit-test on the PDF
struct STTextHitResult {
    let text: String
    let bounds: CGRect
    let page: PDFPage
    var selection: PDFSelection? = nil
}

/// Word vs line selection mode for text editing
enum STTextSelectionMode: String, CaseIterable {
    case word
    case line
}

/// Overlay for editing existing PDF text.
/// Tap on text → popup with pre-filled text → Done → white-background FreeText replaces original.
struct STTextEditOverlay: View {

    let hitTestText: (_ screenPoint: CGPoint, _ mode: STTextSelectionMode) -> STTextHitResult?
    let onReplace: (_ editedText: String, _ originalText: String, _ originalBounds: CGRect, _ page: PDFPage) -> Void
    let onCancel: () -> Void

    @State private var editText = ""
    @State private var hitResult: STTextHitResult?
    @State private var isEditing = false
    @State private var selectionMode: STTextSelectionMode = .word
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack {
            // Tap capture layer
            if !isEditing {
                Color.black.opacity(0.001)
                    .contentShape(Rectangle())
                    .onTapGesture { location in
                        if let result = hitTestText(location, selectionMode) {
                            hitResult = result
                            editText = result.text
                            isEditing = true
                            isFocused = true
                        } else {
                            STHaptics.impact(.light)
                        }
                    }

                // Hint + mode picker at top
                hintBanner
            }

            // Alert-style edit dialog
            if isEditing, let result = hitResult {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture { dismiss() }

                VStack(spacing: 0) {
                    // Title
                    Text(STStrings.toolTextEdit)
                        .font(.headline)
                        .padding(.top, 20)
                        .padding(.bottom, 12)

                    // Text field (pre-filled with detected text)
                    TextField(STStrings.enterText, text: $editText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(Color.stSystemBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .lineLimit(1...6)
                        .focused($isFocused)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)

                    Divider()

                    // Buttons
                    HStack(spacing: 0) {
                        Button {
                            dismiss()
                        } label: {
                            Text(STStrings.cancel)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .foregroundColor(.accentColor)
                        }

                        Divider()
                            .frame(height: 44)

                        Button {
                            let trimmed = editText.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !trimmed.isEmpty {
                                onReplace(trimmed, result.text, result.bounds, result.page)
                            }
                            dismiss()
                        } label: {
                            Text(STStrings.done)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .foregroundColor(editText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .accentColor)
                        }
                        .disabled(editText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .font(.body)
                }
                .frame(width: 270)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 8)
                .transition(.scale(scale: 0.85).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.25, dampingFraction: 0.85), value: isEditing)
    }

    private var hintBanner: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "hand.tap")
                Text(STStrings.tapOnTextToEdit)
            }
            .font(.callout.weight(.medium))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.7))
            .clipShape(Capsule())

            // Word / Line segmented toggle
            HStack(spacing: 0) {
                modeButton(.word, icon: "textformat.abc", label: STStrings.selectionWord)
                modeButton(.line, icon: "text.line.first.and.arrowtriangle.forward", label: STStrings.selectionLine)
            }
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.12), radius: 4, x: 0, y: 2)
        }
        .padding(.top, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    @ViewBuilder
    private func modeButton(_ mode: STTextSelectionMode, icon: String, label: String) -> some View {
        Button {
            selectionMode = mode
            STHaptics.impact(.light)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(label)
                    .font(.caption.weight(.medium))
            }
            .foregroundColor(selectionMode == mode ? .white : .primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(selectionMode == mode ? Color.accentColor : .clear)
            .clipShape(Capsule())
        }
    }

    private func dismiss() {
        editText = ""
        hitResult = nil
        isEditing = false
        isFocused = false
    }
}

// MARK: - Text Remove Overlay (Tap to select, confirm to delete)

/// Overlay for removing existing PDF text.
/// Tap on text → highlight it → confirm with Delete button → text is removed.
struct STTextRemoveOverlay: View {

    let hitTestText: (_ screenPoint: CGPoint, _ mode: STTextSelectionMode) -> STTextHitResult?
    let onHighlight: (_ selection: PDFSelection?) -> Void
    let onRemove: (_ originalText: String, _ originalBounds: CGRect, _ page: PDFPage) -> Void
    let onCancel: () -> Void

    @State private var selectionMode: STTextSelectionMode = .line
    @State private var hasSelection = false
    @State private var selectedText = ""
    @State private var selectedBounds = CGRect.zero
    @State private var selectedPage: PDFPage?

    var body: some View {
        ZStack {
            // Tap capture layer — always present to intercept ALL taps
            Color.black.opacity(0.01)
                .contentShape(Rectangle())
                .allowsHitTesting(true)
                .onTapGesture { location in
                    if let result = hitTestText(location, selectionMode) {
                        // Text tapped — highlight it, await confirmation
                        selectedText = result.text
                        selectedBounds = result.bounds
                        selectedPage = result.page
                        hasSelection = true
                        if let sel = result.selection {
                            sel.color = PlatformColor.systemYellow
                            onHighlight(sel)
                        }
                        STHaptics.impact(.light)
                    } else if hasSelection {
                        // Tapped empty space — clear selection
                        clearPending()
                    } else {
                        STHaptics.impact(.light)
                    }
                }

            // Hint + mode picker (when nothing selected)
            if !hasSelection {
                hintBanner
                    .transition(.opacity)
            }

            // Delete confirmation bar at TOP (when text is selected)
            if hasSelection {
                VStack {
                    deleteConfirmBar
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))

                    Spacer()
                }
            }
        }
        .animation(.spring(response: 0.25, dampingFraction: 0.85), value: hasSelection)
        .onChange(of: selectionMode) { _ in
            if hasSelection { clearPending() }
        }
    }

    private var deleteConfirmBar: some View {
        HStack(spacing: 0) {
            // Selected text preview
            Text(selectedText)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(1)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: 180, alignment: .leading)

            Rectangle()
                .fill(.quaternary)
                .frame(width: 0.5, height: 24)

            // Delete button
            Button {
                if let page = selectedPage {
                    onRemove(selectedText, selectedBounds, page)
                }
                clearPending()
            } label: {
                Text(STStrings.selectionDelete)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.red)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
            }

            Rectangle()
                .fill(.quaternary)
                .frame(width: 0.5, height: 24)

            // Cancel button
            Button {
                clearPending()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
            }
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
    }

    private var hintBanner: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "hand.tap")
                Text(STStrings.removeText)
            }
            .font(.callout.weight(.medium))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.red.opacity(0.8))
            .clipShape(Capsule())

            // Word / Line segmented toggle
            HStack(spacing: 0) {
                modeButton(.word, icon: "textformat.abc", label: STStrings.selectionWord)
                modeButton(.line, icon: "text.line.first.and.arrowtriangle.forward", label: STStrings.selectionLine)
            }
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.12), radius: 4, x: 0, y: 2)
        }
        .padding(.top, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    @ViewBuilder
    private func modeButton(_ mode: STTextSelectionMode, icon: String, label: String) -> some View {
        Button {
            selectionMode = mode
            STHaptics.impact(.light)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(label)
                    .font(.caption.weight(.medium))
            }
            .foregroundColor(selectionMode == mode ? .white : .primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(selectionMode == mode ? Color.accentColor : .clear)
            .clipShape(Capsule())
        }
    }

    private func clearPending() {
        hasSelection = false
        selectedText = ""
        selectedBounds = .zero
        selectedPage = nil
        onHighlight(nil)
    }
}
