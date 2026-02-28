import Foundation

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
        isLicensed = true
    }

    private func printWarning(_ message: String) {
        print("⚠️ [STPDFKit] \(message) The SDK will show a watermark on all pages.")
    }
}
