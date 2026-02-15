import Foundation

/// Type-safe localized strings for STDOCX module
public enum STDOCXStrings {
    // MARK: - Editor
    public static var font: String { loc("stdocx.font") }
    public static var textColor: String { loc("stdocx.textColor") }
    public static var exportAs: String { loc("stdocx.exportAs") }
    public static var findReplace: String { loc("stdocx.findReplace") }

    // MARK: - Formatting
    public static var bold: String { loc("stdocx.bold") }
    public static var italic: String { loc("stdocx.italic") }
    public static var underline: String { loc("stdocx.underline") }
    public static var strikethrough: String { loc("stdocx.strikethrough") }
    public static var alignment: String { loc("stdocx.alignment") }
    public static var alignLeft: String { loc("stdocx.alignLeft") }
    public static var alignCenter: String { loc("stdocx.alignCenter") }
    public static var alignRight: String { loc("stdocx.alignRight") }
    public static var justify: String { loc("stdocx.justify") }

    // MARK: - Helper
    private static func loc(_ key: String) -> String {
        NSLocalizedString(key, bundle: .module, comment: "")
    }
}
