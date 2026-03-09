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

    // License validation disabled — always licensed
    @Published public private(set) var isLicensed = true
    @Published public private(set) var plan: STLicensePlan? = .enterprise
    @Published public private(set) var expiry: Date? = nil

    private init() {}

    /// Activate the SDK with a license key (currently bypassed)
    public func activate(key: String) {
        // License validation disabled
        isLicensed = true
        plan = .enterprise
    }
}
