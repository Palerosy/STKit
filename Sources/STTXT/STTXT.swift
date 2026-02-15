import Foundation
import STKit

/// STTXT — SwiftUI-native Plain Text Editor SDK for iOS
@MainActor
public enum STTXT {

    /// Current module version
    public static let version = "0.1.0"

    /// Feature identifier for license checks
    public static let featureId = "txt"

    /// Whether this module is licensed
    public static var isLicensed: Bool {
        STKit.isLicensed && STKit.isFeatureLicensed(featureId)
    }
}
