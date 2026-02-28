#!/usr/bin/env swift

import Foundation
import CryptoKit

// MARK: - Configuration
let bundleId = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "com.word.editor"
let plan = CommandLine.arguments.count > 2 ? CommandLine.arguments[2] : "enterprise"
let expiryYears = 10  // License valid for 10 years

// MARK: - Key pair file path
let scriptDir = URL(fileURLWithPath: #file).deletingLastPathComponent().path
let privateKeyPath = scriptDir + "/ed25519_private.key"

// MARK: - Load or generate key pair
let privateKey: Curve25519.Signing.PrivateKey

if FileManager.default.fileExists(atPath: privateKeyPath),
   let savedKeyData = try? Data(contentsOf: URL(fileURLWithPath: privateKeyPath)) {
    privateKey = try! Curve25519.Signing.PrivateKey(rawRepresentation: savedKeyData)
    print("Loaded existing private key")
} else {
    privateKey = Curve25519.Signing.PrivateKey()
    try! privateKey.rawRepresentation.write(to: URL(fileURLWithPath: privateKeyPath))
    print("Generated NEW key pair — private key saved to: \(privateKeyPath)")
}

let publicKey = privateKey.publicKey
let publicKeyBase64 = publicKey.rawRepresentation.base64EncodedString()

print("")
print("=== Key Pair ===")
print("Public Key (Base64):  \(publicKeyBase64)")
print("Private Key location: \(privateKeyPath)")
print("")

// MARK: - Create license payload
let dateFormatter = ISO8601DateFormatter()
dateFormatter.formatOptions = [.withFullDate]

let now = Date()
let expiry = Calendar.current.date(byAdding: .year, value: expiryYears, to: now)!

let payload: [String: Any] = [
    "bundleId": bundleId,
    "plan": plan,
    "expiry": dateFormatter.string(from: expiry),
    "features": ["docx", "excel", "txt", "pdf"],
    "issuedAt": dateFormatter.string(from: now)
]

let payloadData = try! JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys])
let payloadString = String(data: payloadData, encoding: .utf8)!

print("=== License Payload ===")
print(payloadString)
print("")

// MARK: - Sign
let signature = try! privateKey.signature(for: payloadData)

// MARK: - Combine: signature (64 bytes) + payload
var licenseData = Data()
licenseData.append(signature)
licenseData.append(payloadData)

let licenseKey = licenseData.base64EncodedString()

print("=== License Key ===")
print(licenseKey)
print("")

// MARK: - Verify (self-test)
let testKeyData = Data(base64Encoded: licenseKey)!
let testSignature = testKeyData.prefix(64)
let testPayload = testKeyData.dropFirst(64)
let isValid = publicKey.isValidSignature(testSignature, for: testPayload)

print("=== Verification ===")
print("Self-test: \(isValid ? "PASSED" : "FAILED")")
print("")
print("=== For STLicenseValidator.swift ===")
print("private static let publicKeyBase64 = \"\(publicKeyBase64)\"")
print("")
print("=== Usage ===")
print("swift scripts/generate-license.swift <bundleId> <plan>")
print("  bundleId: app bundle identifier (default: com.word.editor)")
print("  plan: free | pro | enterprise (default: enterprise)")
