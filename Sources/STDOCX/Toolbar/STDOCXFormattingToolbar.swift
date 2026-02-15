import SwiftUI

/// Horizontal formatting toolbar for the DOCX editor
public struct STDOCXFormattingToolbar: View {
    @ObservedObject var editorState: STDOCXEditorState
    let configuration: STDOCXConfiguration
    let onFontTap: () -> Void
    let onColorTap: () -> Void

    public init(
        editorState: STDOCXEditorState,
        configuration: STDOCXConfiguration = .default,
        onFontTap: @escaping () -> Void,
        onColorTap: @escaping () -> Void
    ) {
        self.editorState = editorState
        self.configuration = configuration
        self.onFontTap = onFontTap
        self.onColorTap = onColorTap
    }

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 2) {
                // Undo / Redo
                toolButton(icon: "arrow.uturn.backward", action: { editorState.undo() })
                toolButton(icon: "arrow.uturn.forward", action: { editorState.redo() })

                divider

                // Bold / Italic / Underline / Strikethrough
                toolButton(icon: "bold", isActive: editorState.isBold, action: { editorState.toggleBold() })
                toolButton(icon: "italic", isActive: editorState.isItalic, action: { editorState.toggleItalic() })
                toolButton(icon: "underline", isActive: editorState.isUnderline, action: { editorState.toggleUnderline() })
                toolButton(icon: "strikethrough", isActive: editorState.isStrikethrough, action: { editorState.toggleStrikethrough() })

                divider

                // Font Size
                toolButton(icon: "minus", action: { editorState.decreaseFontSize() })
                Text("\(Int(editorState.currentFontSize))")
                    .font(.system(size: 13, weight: .medium))
                    .frame(width: 28)
                toolButton(icon: "plus", action: { editorState.increaseFontSize() })

                divider

                // Font Name
                Button(action: onFontTap) {
                    Text(editorState.currentFontName)
                        .font(.system(size: 12, weight: .medium))
                        .lineLimit(1)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Color(.tertiarySystemFill))
                        .cornerRadius(6)
                }

                // Text Color
                Button(action: onColorTap) {
                    VStack(spacing: 2) {
                        Image(systemName: "textformat")
                            .font(.system(size: 14, weight: .medium))
                        Rectangle()
                            .fill(Color(editorState.currentTextColor))
                            .frame(width: 16, height: 3)
                            .cornerRadius(1)
                    }
                    .frame(width: 36, height: 36)
                }

                divider

                // Alignment
                toolButton(icon: "text.alignleft", isActive: editorState.currentAlignment == .left,
                           action: { editorState.setAlignment(.left) })
                toolButton(icon: "text.aligncenter", isActive: editorState.currentAlignment == .center,
                           action: { editorState.setAlignment(.center) })
                toolButton(icon: "text.alignright", isActive: editorState.currentAlignment == .right,
                           action: { editorState.setAlignment(.right) })
                toolButton(icon: "text.justify", isActive: editorState.currentAlignment == .justified,
                           action: { editorState.setAlignment(.justified) })
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
        .background(Color(configuration.appearance.toolbarBackgroundColor))
    }

    private func toolButton(icon: String, isActive: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(isActive ? configuration.appearance.accentColor : .primary)
                .frame(width: 36, height: 36)
                .background(isActive ? configuration.appearance.accentColor.opacity(0.12) : Color.clear)
                .cornerRadius(6)
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(Color(.separator))
            .frame(width: 1, height: 24)
            .padding(.horizontal, 4)
    }
}
