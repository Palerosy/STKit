import SwiftUI
import UIKit

/// UIViewRepresentable wrapper for UITextView — the core rich text editing surface
public struct STDOCXTextView: UIViewRepresentable {
    @ObservedObject var editorState: STDOCXEditorState
    @Binding var attributedText: NSAttributedString
    let configuration: STDOCXConfiguration

    public init(
        editorState: STDOCXEditorState,
        attributedText: Binding<NSAttributedString>,
        configuration: STDOCXConfiguration = .default
    ) {
        self.editorState = editorState
        self._attributedText = attributedText
        self.configuration = configuration
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = configuration.isEditable
        textView.isScrollEnabled = true
        textView.allowsEditingTextAttributes = true
        textView.backgroundColor = UIColor(configuration.appearance.backgroundColor)
        textView.textContainerInset = UIEdgeInsets(
            top: configuration.textInsets.top,
            left: configuration.textInsets.leading,
            bottom: configuration.textInsets.bottom,
            right: configuration.textInsets.trailing
        )
        textView.font = UIFont(name: configuration.defaultFontName, size: configuration.defaultFontSize)
            ?? UIFont.systemFont(ofSize: configuration.defaultFontSize)
        textView.delegate = context.coordinator
        textView.attributedText = attributedText

        textView.typingAttributes = [
            .font: UIFont(name: configuration.defaultFontName, size: configuration.defaultFontSize)
                ?? UIFont.systemFont(ofSize: configuration.defaultFontSize),
            .foregroundColor: UIColor.label
        ]

        editorState.textView = textView
        return textView
    }

    public func updateUIView(_ textView: UITextView, context: Context) {
        if !context.coordinator.isUpdating && textView.attributedText != attributedText {
            context.coordinator.isUpdating = true
            textView.attributedText = attributedText
            context.coordinator.isUpdating = false
        }
    }

    public class Coordinator: NSObject, UITextViewDelegate {
        var parent: STDOCXTextView
        var isUpdating = false

        init(_ parent: STDOCXTextView) {
            self.parent = parent
        }

        public func textViewDidChange(_ textView: UITextView) {
            guard !isUpdating else { return }
            isUpdating = true
            parent.attributedText = textView.attributedText
            isUpdating = false
        }

        public func textViewDidChangeSelection(_ textView: UITextView) {
            DispatchQueue.main.async { [weak self] in
                self?.parent.editorState.updateState(from: textView)
            }
        }

        public func textViewDidBeginEditing(_ textView: UITextView) {
            parent.editorState.isEditing = true
        }

        public func textViewDidEndEditing(_ textView: UITextView) {
            parent.editorState.isEditing = false
        }
    }
}
