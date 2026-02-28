import Foundation
import STKit

/// STExcel — SwiftUI-native Excel Viewer & Editor SDK for iOS
@MainActor
public enum STExcelKit {

    /// Current module version
    public static let version = "0.1.0"

    /// Feature identifier for license checks
    public static let featureId = "excel"

    /// Whether this module is licensed
    public static var isLicensed: Bool {
        STKitSDK.isLicensed && STKitSDK.isFeatureLicensed(featureId)
    }
}
