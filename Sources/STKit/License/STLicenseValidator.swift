import Foundation
import CryptoKit

/// License payload decoded from the key
public struct STLicensePayload {
    public let bundleId: String
    public let expiry: Date?
    public let plan: STLicensePlan
    public let features: [String]
    public let issuedAt: Date?
}

/// Validates license keys using Ed25519 signature verification
public enum STLicenseValidator {

    // MARK: - Embedded Public Key (Base64)
    // The corresponding private key is kept securely by the SDK vendor.
    // Replace this with your actual Ed25519 public key.
    private static let publicKeyBase64 = "U7rsFHuSZgf+KrEsWIzq4TJ4fqs2hf0Fn8jDhJU6WbU="

    /// Validate a license key string
    /// - Parameter key: Base64-encoded license key
    /// - Returns: Decoded payload if valid, nil if invalid
    public static func validate(key: String) -> STLicensePayload? {
        guard let keyData = Data(base64Encoded: key) else { return nil }

        // Key format: first 64 bytes = Ed25519 signature, rest = JSON payload
        guard keyData.count > 64 else { return nil }

        let signatureData = keyData.prefix(64)
        let payloadData = keyData.dropFirst(64)

        // Verify signature
        guard verifySignature(signatureData, for: payloadData) else { return nil }

        // Parse payload
        return parsePayload(payloadData)
    }

    private static func verifySignature(_ signatureData: Data, for payloadData: Data) -> Bool {
        guard let publicKeyData = Data(base64Encoded: publicKeyBase64) else { return false }

        do {
            let publicKey = try Curve25519.Signing.PublicKey(rawRepresentation: publicKeyData)
            return publicKey.isValidSignature(signatureData, for: payloadData)
        } catch {
            return false
        }
    }

    private static func parsePayload(_ data: Data) -> STLicensePayload? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }

        guard let bundleId = json["bundleId"] as? String else { return nil }

        let plan = (json["plan"] as? String).flatMap { STLicensePlan(rawValue: $0) } ?? .free

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]

        let expiry = (json["expiry"] as? String).flatMap { dateFormatter.date(from: $0) }
        let issuedAt = (json["issuedAt"] as? String).flatMap { dateFormatter.date(from: $0) }
        let features = json["features"] as? [String] ?? []

        return STLicensePayload(
            bundleId: bundleId,
            expiry: expiry,
            plan: plan,
            features: features,
            issuedAt: issuedAt
        )
    }
}
