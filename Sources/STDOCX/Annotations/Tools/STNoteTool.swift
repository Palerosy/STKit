import SwiftUI
import STKit
import PDFKit
import STKit

/// Overlay for placing sticky note annotations on a PDF page.
/// Tap anywhere on the PDF → enter note text → place a sticky note annotation.
/// Tap on an existing note → edit its contents.
struct STNoteInputOverlay: View {

    let onSubmit: (_ text: String, _ screenPoint: CGPoint) -> Void
    let onEditExisting: (_ annotation: PDFAnnotation, _ text: String) -> Void
    let hitTestNote: (_ screenPoint: CGPoint) -> PDFAnnotation?
    let onCancel: () -> Void

    @State private var tapPoint: CGPoint?
    @State private var noteText = ""
    @State private var editingAnnotation: PDFAnnotation?
    @FocusState private var isEditing: Bool

    var body: some View {
        GeometryReader { geo in
            // Transparent tap catcher
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { location in
                    if let existing = hitTestNote(location) {
                        editingAnnotation = existing
                        noteText = existing.contents ?? ""
                    } else {
                        editingAnnotation = nil
                        noteText = ""
                    }
                    tapPoint = location
                    isEditing = true
                }

            // Note input popup
            if let point = tapPoint {
                noteInputPopup(at: point, in: geo.size)
            }
        }
    }

    @ViewBuilder
    private func noteInputPopup(at point: CGPoint, in size: CGSize) -> some View {
        let popupWidth: CGFloat = 240
        let popupHeight: CGFloat = 160
        let isEditMode = editingAnnotation != nil

        // Position near tap, but keep within bounds
        let x = min(max(point.x, popupWidth / 2 + 8), size.width - popupWidth / 2 - 8)
        let y = min(max(point.y - popupHeight / 2, 8), size.height - popupHeight - 8)

        VStack(spacing: 8) {
            // Color header (sticky note style)
            HStack {
                Image(systemName: "note.text")
                    .font(.caption.weight(.semibold))
                Text(STStrings.toolNote)
                    .font(.caption.weight(.semibold))
                Spacer()
            }
            .foregroundColor(.primary.opacity(0.7))
            .padding(.horizontal, 10)
            .padding(.top, 8)

            // Text editor
            TextEditor(text: $noteText)
                .font(.callout)
                .scrollContentBackground(.hidden)
                .focused($isEditing)
                .frame(maxHeight: .infinity)
                .padding(.horizontal, 6)

            // Buttons
            HStack {
                Button(STStrings.cancel) {
                    tapPoint = nil
                    noteText = ""
                    editingAnnotation = nil
                    isEditing = false
                }
                .font(.callout)
                .foregroundColor(.secondary)

                Spacer()

                Button(isEditMode ? STStrings.done : STStrings.add) {
                    let trimmed = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
                    if let existing = editingAnnotation {
                        onEditExisting(existing, trimmed)
                    } else if !trimmed.isEmpty {
                        onSubmit(trimmed, point)
                    }
                    tapPoint = nil
                    noteText = ""
                    editingAnnotation = nil
                    isEditing = false
                }
                .font(.callout.weight(.semibold))
                .disabled(!isEditMode && noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 8)
        }
        .frame(width: popupWidth, height: popupHeight)
        .background(Color.yellow.opacity(0.25))
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        .position(x: x, y: y + popupHeight / 2)
    }
}
