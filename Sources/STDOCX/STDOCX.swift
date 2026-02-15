import Foundation
import STKit

/// STDOCX — SwiftUI-native DOCX Editor SDK for iOS
@MainActor
public enum STDOCX {

    /// Current module version
    public static let version = "0.1.0"

    /// Feature identifier for license checks
    public static let featureId = "docx"

    /// Whether this module is licensed (via STKit license)
    public static var isLicensed: Bool {
        STKit.isLicensed && STKit.isFeatureLicensed(featureId)
    }
}
