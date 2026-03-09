import Foundation
import STKit

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
        let bundle = STKitConfiguration.shared.languageBundle(for: STDOCXBundleHelper.resourceBundle) ?? STDOCXBundleHelper.resourceBundle
        return NSLocalizedString(key, bundle: bundle, comment: "")
    }
}

internal enum STDOCXBundleHelper {
    static let resourceBundle: Bundle = {
        let bundleName = "STKit_STDOCX"

        if let url = Bundle.main.url(forResource: bundleName, withExtension: "bundle"),
           let bundle = Bundle(url: url) {
            return bundle
        }

        if let frameworksURL = Bundle.main.privateFrameworksURL {
            let url = frameworksURL.appendingPathComponent("STDOCX.framework/\(bundleName).bundle")
            if let bundle = Bundle(url: url) {
                return bundle
            }
        }

        return Bundle.main
    }()
}
