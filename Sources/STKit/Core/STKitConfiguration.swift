import Foundation
import SwiftUI

/// Global configuration for STKit SDK
public final class STKitConfiguration {
    public static let shared = STKitConfiguration()

    /// Whether the user has an active premium subscription
    public var isPurchased: Bool = false

    /// Default paywall placement identifier (each app can override, e.g. "main.macos")
    public var paywallPlacement: String = "main"

    /// Closure that returns a paywall view for a given placement
    public var premiumPaywallView: ((String) -> AnyView)?

    /// Alternative: simple callback when a premium feature is tapped (no paywall UI)
    public var onPremiumFeatureTapped: (() -> Void)?

    /// Called before printing — return true to allow, false to block
    public var onPrint: (() -> Bool)?

    /// Override language code (e.g. "tr", "sv", "de"). Set to nil to use system default.
    public var languageCode: String? {
        didSet {
            updateLanguageBundle()
        }
    }

    /// Resolved language bundle for the given module resource bundle.
    /// Returns the sub-bundle for the selected language, or nil to use default NSLocalizedString behavior.
    public func languageBundle(for resourceBundle: Bundle) -> Bundle? {
        guard let code = languageCode else { return nil }
        if let path = resourceBundle.path(forResource: code, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle
        }
        // Fallback: try base language code (e.g. "pt" for "pt-BR")
        if code.contains("-"),
           let basePath = resourceBundle.path(forResource: String(code.prefix(while: { $0 != "-" })), ofType: "lproj"),
           let bundle = Bundle(path: basePath) {
            return bundle
        }
        return nil
    }

    private func updateLanguageBundle() {
        // Post notification so views can refresh if needed
        NotificationCenter.default.post(name: .stKitLanguageChanged, object: nil)
    }

    private init() {}
}

public extension Notification.Name {
    static let stKitLanguageChanged = Notification.Name("STKitLanguageChanged")
    static let purchaseStatusChanged = Notification.Name("purchaseStatusChanged")
}
