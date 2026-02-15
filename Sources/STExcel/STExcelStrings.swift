import Foundation

/// Localized strings for STExcel module
public enum STExcelStrings {
    public static var sheet: String { loc("stexcel.sheet") }
    public static var cell: String { loc("stexcel.cell") }
    public static var row: String { loc("stexcel.row") }
    public static var column: String { loc("stexcel.column") }
    public static var value: String { loc("stexcel.value") }

    private static func loc(_ key: String) -> String {
        NSLocalizedString(key, bundle: .module, comment: "")
    }
}
