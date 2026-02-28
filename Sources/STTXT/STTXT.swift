import Foundation
import STKit

/// STTXT — SwiftUI-native Plain Text Editor SDK for iOS
@MainActor
public enum STTXTKit {

    /// Current module version
    public static let version = "0.1.0"

    /// Feature identifier for license checks
    public static let featureId = "txt"

    /// Whether this module is licensed
    public static var isLicensed: Bool {
        STLicenseManager.shared.isLicensed
    }

    /// Initialize STTXT with a license key.
    public static func initialize(licenseKey: String) {
        STLicenseManager.shared.activate(key: licenseKey)
    }
}
