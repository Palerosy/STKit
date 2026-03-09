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

    // License validation disabled — always licensed
    @Published public private(set) var isLicensed = true
    @Published public private(set) var plan: STLicensePlan? = .enterprise
    @Published public private(set) var expiry: Date? = nil
    @Published public private(set) var features: [String] = ["*"]

    private init() {}

    /// Activate the SDK with a license key (currently bypassed)
    public func activate(key: String) {
        // License validation disabled
        isLicensed = true
        plan = .enterprise
        features = ["*"]
    }

    /// Check if a specific feature is licensed
    public func isFeatureLicensed(_ feature: String) -> Bool {
        return true
    }
}
