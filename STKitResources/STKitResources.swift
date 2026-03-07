import Foundation

/// Provides access to STKit resource bundles when using binary xcframeworks.
/// SPM source targets automatically copy resources to the app bundle.
public enum STKitResources {
    /// The resource bundle containing all STKit localization files.
    public static let bundle: Bundle = Bundle.module
}
