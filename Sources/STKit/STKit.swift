import Foundation

/// STKit — Unified Document SDK for iOS
/// Supports PDF, DOCX, Excel and more document formats.
///
/// ```swift
/// // Initialize with license key
/// STKit.initialize(licenseKey: "eyJidW5kbGVJZCI6Li4u...")
///
/// // Use STDOCX module
/// import STDOCX
/// STDOCXEditorView(url: docxURL)
/// ```
@MainActor
public enum STKit {

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

    /// Licensed features (e.g. ["pdf", "docx", "excel"])
    public static var licensedFeatures: [String] {
        STLicenseManager.shared.features
    }

    /// Initialize STKit with a license key.
    /// Call this in your app's `didFinishLaunchingWithOptions` or `init()`.
    ///
    /// ```swift
    /// STKit.initialize(licenseKey: "eyJidW5kbGVJZCI6Li4u...")
    /// ```
    ///
    /// - Parameter licenseKey: Base64-encoded license key tied to your bundle ID.
    public static func initialize(licenseKey: String) {
        STLicenseManager.shared.activate(key: licenseKey)
    }

    /// Check if a specific feature module is licensed
    /// - Parameter feature: Feature identifier (e.g. "pdf", "docx", "excel")
    /// - Returns: true if the feature is included in the license
    public static func isFeatureLicensed(_ feature: String) -> Bool {
        STLicenseManager.shared.isFeatureLicensed(feature)
    }
}
