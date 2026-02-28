import Foundation
import Combine

/// License plan tiers
public enum STLicensePlan: String, Codable {
    case free
    case pro
    case enterprise
}

/// Manages SDK license validation and state
@MainActor
public final class STLicenseManager: ObservableObject {

    public static let shared = STLicenseManager()

    @Published public private(set) var isLicensed = false
    @Published public private(set) var plan: STLicensePlan?
    @Published public private(set) var expiry: Date?
    @Published public private(set) var features: [String] = []

    private var payload: STLicensePayload?

    private init() {}

    /// Activate the SDK with a license key
    public func activate(key: String) {
        guard let result = STLicenseValidator.validate(key: key) else {
            printWarning("Invalid license key.")
            isLicensed = false
            return
        }

        // Check bundle ID
        let currentBundleId = Bundle.main.bundleIdentifier ?? ""
        guard result.bundleId == currentBundleId || result.bundleId == "*" else {
            printWarning("License key is not valid for bundle ID '\(currentBundleId)'. Expected '\(result.bundleId)'.")
            isLicensed = false
            return
        }

        // Check expiry
        if let expiryDate = result.expiry, expiryDate < Date() {
            printWarning("License key expired on \(expiryDate).")
            isLicensed = false
            return
        }

        // Valid
        payload = result
        plan = result.plan
        expiry = result.expiry
        features = result.features
        isLicensed = true
    }

    /// Check if a specific feature is licensed
    public func isFeatureLicensed(_ feature: String) -> Bool {
        guard isLicensed else { return false }
        // Enterprise has all features
        if plan == .enterprise { return true }
        // Wildcard
        if features.contains("*") { return true }
        return features.contains(feature.lowercased())
    }

    private func printWarning(_ message: String) {
        print("\u{26A0}\u{FE0F} [STKit] \(message) The SDK will show a watermark on all views.")
    }
}
