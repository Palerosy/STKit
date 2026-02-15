import SwiftUI
import UIKit

/// UITextView wrapper for plain text editing
public struct STTXTTextView: UIViewRepresentable {
    @Binding var text: String
    let configuration: STTXTConfiguration

    public init(text: Binding<String>, configuration: STTXTConfiguration = .default) {
        self._text = text
        self.configuration = configuration
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = configuration.isEditable
        textView.isScrollEnabled = true
        textView.backgroundColor = UIColor(configuration.backgroundColor)
        textView.textContainerInset = UIEdgeInsets(
            top: configuration.textInsets.top,
            left: configuration.textInsets.leading,
            bottom: configuration.textInsets.bottom,
            right: configuration.textInsets.trailing
        )
        textView.font = UIFont(name: configuration.fontName, size: configuration.fontSize)
            ?? UIFont.monospacedSystemFont(ofSize: configuration.fontSize, weight: .regular)
        textView.textColor = UIColor(configuration.textColor)
        textView.delegate = context.coordinator
        textView.text = text
        return textView
    }

    public func updateUIView(_ textView: UITextView, context: Context) {
        if !context.coordinator.isUpdating && textView.text != text {
            context.coordinator.isUpdating = true
            textView.text = text
            context.coordinator.isUpdating = false
        }
    }

    public class Coordinator: NSObject, UITextViewDelegate {
        var parent: STTXTTextView
        var isUpdating = false

        init(_ parent: STTXTTextView) {
            self.parent = parent
        }

        public func textViewDidChange(_ textView: UITextView) {
            guard !isUpdating else { return }
            isUpdating = true
            parent.text = textView.text
            isUpdating = false
        }
    }
}
