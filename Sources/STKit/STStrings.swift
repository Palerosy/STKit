import Foundation

/// Type-safe localized strings for STKit core
public enum STStrings {
    // MARK: - Common
    public static var done: String { loc("stkit.done") }
    public static var cancel: String { loc("stkit.cancel") }
    public static var save: String { loc("stkit.save") }
    public static var share: String { loc("stkit.share") }
    public static var export: String { loc("stkit.export") }
    public static var delete: String { loc("stkit.delete") }
    public static var close: String { loc("stkit.close") }
    public static var untitled: String { loc("stkit.untitled") }
    public static var search: String { loc("stkit.search") }
    public static var undo: String { loc("stkit.undo") }
    public static var redo: String { loc("stkit.redo") }

    // MARK: - License
    public static var unlicensed: String { loc("stkit.unlicensed") }

    // MARK: - Word Count
    public static var wordCount: String { loc("stkit.wordCount") }
    public static var words: String { loc("stkit.words") }
    public static var characters: String { loc("stkit.characters") }
    public static var charactersWithSpaces: String { loc("stkit.charactersWithSpaces") }
    public static var paragraphs: String { loc("stkit.paragraphs") }
    public static var lines: String { loc("stkit.lines") }

    // MARK: - Document
    public static var newDocument: String { loc("stkit.newDocument") }
    public static var unsavedChanges: String { loc("stkit.unsavedChanges") }
    public static var unsavedChangesMessage: String { loc("stkit.unsavedChangesMessage") }
    public static var discard: String { loc("stkit.discard") }
    public static var saveAndClose: String { loc("stkit.saveAndClose") }

    // MARK: - Helper
    public static func loc(_ key: String) -> String {
        NSLocalizedString(key, bundle: STKitBundleHelper.resourceBundle, comment: "")
    }
}

internal enum STKitBundleHelper {
    static let resourceBundle: Bundle = {
        let bundleName = "STKit_STKit"

        // 1. Standard SPM resource bundle in main app bundle
        if let url = Bundle.main.url(forResource: bundleName, withExtension: "bundle"),
           let bundle = Bundle(url: url) {
            return bundle
        }

        // 2. Inside framework in Frameworks directory (static xcframework)
        if let frameworksURL = Bundle.main.privateFrameworksURL {
            let url = frameworksURL.appendingPathComponent("STKit.framework/\(bundleName).bundle")
            if let bundle = Bundle(url: url) {
                return bundle
            }
        }

        // 3. Fallback to main bundle
        return Bundle.main
    }()
}
