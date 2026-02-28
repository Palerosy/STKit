import Foundation
import STKit

/// Localized strings for STExcel module
public enum STExcelStrings {
    public static var sheet: String { loc("stexcel.sheet") }
    public static var cell: String { loc("stexcel.cell") }
    public static var row: String { loc("stexcel.row") }
    public static var column: String { loc("stexcel.column") }
    public static var value: String { loc("stexcel.value") }

    private static func loc(_ key: String) -> String {
        let bundle = STKitConfiguration.shared.languageBundle(for: STExcelBundleHelper.resourceBundle) ?? STExcelBundleHelper.resourceBundle
        return NSLocalizedString(key, bundle: bundle, comment: "")
    }
}

internal enum STExcelBundleHelper {
    static let resourceBundle: Bundle = {
        let bundleName = "STKit_STExcel"

        if let url = Bundle.main.url(forResource: bundleName, withExtension: "bundle"),
           let bundle = Bundle(url: url) {
            return bundle
        }

        if let frameworksURL = Bundle.main.privateFrameworksURL {
            let url = frameworksURL.appendingPathComponent("STExcel.framework/\(bundleName).bundle")
            if let bundle = Bundle(url: url) {
                return bundle
            }
        }

        return Bundle.main
    }()
}
