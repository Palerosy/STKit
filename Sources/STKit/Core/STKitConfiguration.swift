import Foundation
import SwiftUI

/// Global configuration for STKit SDK
public final class STKitConfiguration {
    public static let shared = STKitConfiguration()

    /// Whether the end-user has purchased / subscribed in the host app.
    /// Defaults to `true`. Set to `false` to gate premium features (Export, Print)
    /// behind your own in-app purchase / subscription.
    ///
    /// ```swift
    /// // Block features until user subscribes
    /// STKitConfiguration.shared.isPurchased = false
    ///
    /// // After purchase verified
    /// STKitConfiguration.shared.isPurchased = true
    /// ```
    public var isPurchased: Bool = true

    /// Optional callback invoked when an unlicensed user taps a premium feature.
    /// Use this to present your own paywall / purchase screen.
    /// If nil, a default "Premium Required" alert is shown.
    public var onPremiumFeatureTapped: (() -> Void)?

    /// Provide your paywall SwiftUI view. STKit will present it as a fullScreenCover
    /// so the editor state is preserved. Preferred over `onPremiumFeatureTapped`.
    /// The `String` parameter is a placement identifier (e.g. "excel_save", "pdf_export").
    ///
    /// ```swift
    /// STKitConfiguration.shared.premiumPaywallView = { placement in
    ///     AnyView(MyPaywallView(placement: placement))
    /// }
    /// ```
    public var premiumPaywallView: ((String) -> AnyView)?

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
}
