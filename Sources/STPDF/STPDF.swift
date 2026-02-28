import Foundation

/// STPDF — SwiftUI-native PDF Editor SDK for iOS
@MainActor
public enum STPDFKit {

    /// Current SDK version
    public static let version = "0.1.0"

    /// Whether a valid license is active
    public static var isLicensed: Bool {
        STLicenseManager.shared.isLicensed
    }

    /// The active license plan, if any
    public static var licensePlan: STLicensePlan? {
        STLicenseManager.shared.plan
    }

    /// License expiry date, if any
    public static var licenseExpiry: Date? {
        STLicenseManager.shared.expiry
    }

    /// Initialize STPDFKit with a license key.
    /// Call this in your app's `didFinishLaunchingWithOptions` or `init()`.
    ///
    /// ```swift
    /// STPDF.initialize(licenseKey: "eyJidW5kbGVJZCI6Li4u...")
    /// ```
    ///
    /// - Parameter licenseKey: Base64-encoded license key tied to your bundle ID.
    public static func initialize(licenseKey: String) {
        STLicenseManager.shared.activate(key: licenseKey)
    }
}
