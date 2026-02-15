import SwiftUI
import STKit

/// Font picker sheet for the DOCX editor
public struct STDOCXFontPicker: View {
    @ObservedObject var editorState: STDOCXEditorState
    @Environment(\.dismiss) private var dismiss

    private let fonts = [
        "Helvetica Neue", "Arial", "Times New Roman", "Georgia",
        "Courier New", "Verdana", "Trebuchet MS", "Palatino",
        "Avenir", "Avenir Next", "Futura", "Gill Sans",
        "American Typewriter", "Baskerville", "Didot", "Optima"
    ]

    public init(editorState: STDOCXEditorState) {
        self.editorState = editorState
    }

    public var body: some View {
        NavigationView {
            List(fonts, id: \.self) { fontName in
                Button {
                    editorState.setFontName(fontName)
                    dismiss()
                } label: {
                    HStack {
                        Text(fontName)
                            .font(.custom(fontName, size: 17))

                        Spacer()

                        if editorState.currentFontName == fontName {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
                .foregroundColor(.primary)
            }
            .navigationTitle(STDOCXStrings.font)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(STStrings.done) { dismiss() }
                }
            }
        }
    }
}
