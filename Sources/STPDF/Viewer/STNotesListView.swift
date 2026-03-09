import STKit
import SwiftUI
import PDFKit

/// Sheet view that lists all note (sticky) annotations in the document.
struct STNotesListView: View {

    let document: PDFDocument
    let onNoteSelected: (_ pageIndex: Int) -> Void
    let onNoteDeleted: (() -> Void)?
    @Environment(\.dismiss) private var dismiss

    @State private var noteItems: [NoteItem] = []
    @State private var editingNote: NoteItem?
    @State private var editText: String = ""

    var body: some View {
        STNavigationView {
            Group {
                if noteItems.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "note.text")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text(STStrings.noResultsFound)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(noteItems) { item in
                            Button {
                                editingNote = item
                                editText = item.annotation.contents ?? ""
                            } label: {
                                HStack(spacing: 12) {
                                    Circle()
                                        .fill(Color(platformColor: item.annotation.color))
                                        .frame(width: 12, height: 12)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.annotation.contents ?? "")
                                            .font(.body)
                                            .foregroundColor(.primary)
                                            .lineLimit(3)
                                            .multilineTextAlignment(.leading)

                                        Text("\(item.pageIndex + 1). \(STStrings.pages.lowercased())")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary.opacity(0.5))
                                }
                                .padding(.vertical, 4)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    deleteNote(item)
                                } label: {
                                    Label(STStrings.delete, systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(STStrings.toolNotes)
            .stNavigationBarTitleDisplayMode()
            .toolbar {
                ToolbarItem(placement: .stTrailing) {
                    Button(STStrings.done) { dismiss() }
                }
            }
            .alert(STStrings.selectionNote, isPresented: .init(
                get: { editingNote != nil },
                set: { if !$0 { editingNote = nil } }
            )) {
                TextField("", text: $editText)
                Button(STStrings.cancel, role: .cancel) {
                    editingNote = nil
                }
                Button(STStrings.done) {
                    if let item = editingNote {
                        if editText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            deleteNote(item)
                        } else {
                            item.annotation.contents = editText
                            reloadNotes()
                        }
                    }
                    editingNote = nil
                }
            }
        }
        .onAppear { reloadNotes() }
    }

    // MARK: - Actions

    private func deleteNote(_ item: NoteItem) {
        if let page = document.page(at: item.pageIndex) {
            page.removeAnnotation(item.annotation)
        }
        reloadNotes()
        onNoteDeleted?()
    }

    private func reloadNotes() {
        var result: [NoteItem] = []
        for i in 0..<document.pageCount {
            guard let page = document.page(at: i) else { continue }
            for annotation in page.annotations where annotation.type == "Text" {
                if let text = annotation.contents, !text.isEmpty {
                    result.append(NoteItem(annotation: annotation, pageIndex: i))
                }
            }
        }
        noteItems = result
    }

    // MARK: - Data

    private struct NoteItem: Identifiable {
        let id = UUID()
        let annotation: PDFAnnotation
        let pageIndex: Int
    }
}
