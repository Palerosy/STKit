import SwiftUI
import UIKit
import Combine

/// Observable state for the DOCX rich text editor
@MainActor
public final class STDOCXEditorState: ObservableObject {
    @Published public var isBold = false
    @Published public var isItalic = false
    @Published public var isUnderline = false
    @Published public var isStrikethrough = false
    @Published public var currentFontSize: CGFloat = 14
    @Published public var currentFontName: String = "Helvetica Neue"
    @Published public var currentTextColor: UIColor = .label
    @Published public var currentAlignment: NSTextAlignment = .left
    @Published public var hasSelection = false
    @Published public var isEditing = false

    weak var textView: UITextView?

    public init() {}

    // MARK: - Formatting Actions

    public func toggleBold() {
        guard let textView else { return }
        applyTrait(.traitBold, to: textView)
    }

    public func toggleItalic() {
        guard let textView else { return }
        applyTrait(.traitItalic, to: textView)
    }

    public func toggleUnderline() {
        guard let textView else { return }
        let range = textView.selectedRange
        let storage = textView.textStorage

        if range.length > 0 {
            let current = storage.attribute(.underlineStyle, at: range.location, effectiveRange: nil) as? Int ?? 0
            let newValue = current == 0 ? NSUnderlineStyle.single.rawValue : 0
            storage.addAttribute(.underlineStyle, value: newValue, range: range)
            isUnderline = newValue != 0
        } else {
            isUnderline.toggle()
            var attrs = textView.typingAttributes
            attrs[.underlineStyle] = isUnderline ? NSUnderlineStyle.single.rawValue : 0
            textView.typingAttributes = attrs
        }
    }

    public func toggleStrikethrough() {
        guard let textView else { return }
        let range = textView.selectedRange
        let storage = textView.textStorage

        if range.length > 0 {
            let current = storage.attribute(.strikethroughStyle, at: range.location, effectiveRange: nil) as? Int ?? 0
            let newValue = current == 0 ? NSUnderlineStyle.single.rawValue : 0
            storage.addAttribute(.strikethroughStyle, value: newValue, range: range)
            isStrikethrough = newValue != 0
        } else {
            isStrikethrough.toggle()
            var attrs = textView.typingAttributes
            attrs[.strikethroughStyle] = isStrikethrough ? NSUnderlineStyle.single.rawValue : 0
            textView.typingAttributes = attrs
        }
    }

    public func setFontSize(_ size: CGFloat) {
        guard let textView else { return }
        currentFontSize = size
        applyFontChange(to: textView) { font in
            font.withSize(size)
        }
    }

    public func setFontName(_ name: String) {
        guard let textView else { return }
        currentFontName = name
        applyFontChange(to: textView) { font in
            UIFont(name: name, size: font.pointSize) ?? font
        }
    }

    public func setTextColor(_ color: UIColor) {
        guard let textView else { return }
        currentTextColor = color
        let range = textView.selectedRange

        if range.length > 0 {
            textView.textStorage.addAttribute(.foregroundColor, value: color, range: range)
        } else {
            var attrs = textView.typingAttributes
            attrs[.foregroundColor] = color
            textView.typingAttributes = attrs
        }
    }

    public func setAlignment(_ alignment: NSTextAlignment) {
        guard let textView else { return }
        currentAlignment = alignment
        let range = textView.selectedRange

        let nsString = textView.text as NSString
        let paraRange = nsString.paragraphRange(for: range)

        textView.textStorage.enumerateAttribute(.paragraphStyle, in: paraRange, options: []) { value, attrRange, _ in
            let style = (value as? NSParagraphStyle)?.mutableCopy() as? NSMutableParagraphStyle ?? NSMutableParagraphStyle()
            style.alignment = alignment
            textView.textStorage.addAttribute(.paragraphStyle, value: style, range: attrRange)
        }

        var attrs = textView.typingAttributes
        let style = (attrs[.paragraphStyle] as? NSParagraphStyle)?.mutableCopy() as? NSMutableParagraphStyle ?? NSMutableParagraphStyle()
        style.alignment = alignment
        attrs[.paragraphStyle] = style
        textView.typingAttributes = attrs
    }

    public func increaseFontSize() {
        setFontSize(min(currentFontSize + 1, 128))
    }

    public func decreaseFontSize() {
        setFontSize(max(currentFontSize - 1, 8))
    }

    public func undo() {
        textView?.undoManager?.undo()
    }

    public func redo() {
        textView?.undoManager?.redo()
    }

    // MARK: - State Update

    func updateState(from textView: UITextView) {
        let attrs: [NSAttributedString.Key: Any]
        if textView.selectedRange.length > 0 {
            attrs = textView.textStorage.attributes(at: textView.selectedRange.location, effectiveRange: nil)
            hasSelection = true
        } else if textView.selectedRange.location > 0 {
            attrs = textView.typingAttributes
            hasSelection = false
        } else {
            attrs = textView.typingAttributes
            hasSelection = false
        }

        if let font = attrs[.font] as? UIFont {
            let traits = font.fontDescriptor.symbolicTraits
            isBold = traits.contains(.traitBold)
            isItalic = traits.contains(.traitItalic)
            currentFontSize = font.pointSize
            currentFontName = font.familyName
        }

        isUnderline = (attrs[.underlineStyle] as? Int ?? 0) != 0
        isStrikethrough = (attrs[.strikethroughStyle] as? Int ?? 0) != 0

        if let color = attrs[.foregroundColor] as? UIColor {
            currentTextColor = color
        }

        if let pStyle = attrs[.paragraphStyle] as? NSParagraphStyle {
            currentAlignment = pStyle.alignment
        }
    }

    // MARK: - Private Helpers

    private func applyTrait(_ trait: UIFontDescriptor.SymbolicTraits, to textView: UITextView) {
        let range = textView.selectedRange

        if range.length > 0 {
            textView.textStorage.enumerateAttribute(.font, in: range, options: []) { value, attrRange, _ in
                guard let currentFont = value as? UIFont else { return }
                let traits = currentFont.fontDescriptor.symbolicTraits
                let newTraits = traits.contains(trait) ? traits.subtracting(trait) : traits.union(trait)
                if let descriptor = currentFont.fontDescriptor.withSymbolicTraits(newTraits) {
                    let newFont = UIFont(descriptor: descriptor, size: currentFont.pointSize)
                    textView.textStorage.addAttribute(.font, value: newFont, range: attrRange)
                }
            }
            updateState(from: textView)
        } else {
            var attrs = textView.typingAttributes
            if let currentFont = attrs[.font] as? UIFont {
                let traits = currentFont.fontDescriptor.symbolicTraits
                let newTraits = traits.contains(trait) ? traits.subtracting(trait) : traits.union(trait)
                if let descriptor = currentFont.fontDescriptor.withSymbolicTraits(newTraits) {
                    let newFont = UIFont(descriptor: descriptor, size: currentFont.pointSize)
                    attrs[.font] = newFont
                    textView.typingAttributes = attrs
                }
            }
            if trait == .traitBold { isBold.toggle() }
            if trait == .traitItalic { isItalic.toggle() }
        }
    }

    private func applyFontChange(to textView: UITextView, transform: (UIFont) -> UIFont) {
        let range = textView.selectedRange

        if range.length > 0 {
            textView.textStorage.enumerateAttribute(.font, in: range, options: []) { value, attrRange, _ in
                guard let currentFont = value as? UIFont else { return }
                let newFont = transform(currentFont)
                let traits = currentFont.fontDescriptor.symbolicTraits
                if let descriptor = newFont.fontDescriptor.withSymbolicTraits(traits) {
                    textView.textStorage.addAttribute(.font, value: UIFont(descriptor: descriptor, size: 0), range: attrRange)
                } else {
                    textView.textStorage.addAttribute(.font, value: newFont, range: attrRange)
                }
            }
        } else {
            var attrs = textView.typingAttributes
            if let currentFont = attrs[.font] as? UIFont {
                let newFont = transform(currentFont)
                let traits = currentFont.fontDescriptor.symbolicTraits
                if let descriptor = newFont.fontDescriptor.withSymbolicTraits(traits) {
                    attrs[.font] = UIFont(descriptor: descriptor, size: 0)
                } else {
                    attrs[.font] = newFont
                }
                textView.typingAttributes = attrs
            }
        }
    }
}
