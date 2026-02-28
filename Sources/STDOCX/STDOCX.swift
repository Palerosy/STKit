import Foundation
import STKit

/// STDOCX — SwiftUI-native DOCX Editor SDK for iOS
@MainActor
public enum STDOCXKit {

    /// Current module version
    public static let version = "0.1.0"

    /// Feature identifier for license checks
    public static let featureId = "docx"

    /// Whether this module is licensed (via STKit license)
    public static var isLicensed: Bool {
        STLicenseManager.shared.isLicensed
    }

    /// Initialize STDOCX with a license key.
    public static func initialize(licenseKey: String) {
        STLicenseManager.shared.activate(key: licenseKey)
    }
}
