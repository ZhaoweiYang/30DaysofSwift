import Foundation
import CryptoKit

/// Handles all encryption/decryption operations for the chat platform.
/// Implements the flow: User A creates key → encrypts locally → platform forwards → User B decrypts with key
struct CryptoService {

    /// Generate a random conversation key for encrypting messages to a specific user
    static func generateConversationKey() -> SymmetricKey {
        return SymmetricKey(size: .bits256)
    }

    /// Export a symmetric key as a Base64 string (for sharing with the recipient)
    static func exportKey(_ key: SymmetricKey) -> String {
        let keyData = key.withUnsafeBytes { Data($0) }
        return keyData.base64EncodedString()
    }

    /// Import a symmetric key from a Base64 string
    static func importKey(_ base64String: String) -> SymmetricKey? {
        guard let data = Data(base64Encoded: base64String) else { return nil }
        return SymmetricKey(data: data)
    }

    /// Encrypt a plaintext message using AES-GCM
    static func encrypt(_ plaintext: String, with key: SymmetricKey) -> String? {
        guard let data = plaintext.data(using: .utf8) else { return nil }
        do {
            let sealedBox = try AES.GCM.seal(data, using: key)
            guard let combined = sealedBox.combined else { return nil }
            return combined.base64EncodedString()
        } catch {
            return nil
        }
    }

    /// Decrypt a ciphertext message using AES-GCM
    static func decrypt(_ ciphertext: String, with key: SymmetricKey) -> String? {
        guard let data = Data(base64Encoded: ciphertext) else { return nil }
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: data)
            let decryptedData = try AES.GCM.open(sealedBox, using: key)
            return String(data: decryptedData, encoding: .utf8)
        } catch {
            return nil
        }
    }

    /// Generate a key fingerprint for display (short hash of the key)
    static func keyFingerprint(_ key: SymmetricKey) -> String {
        let keyData = key.withUnsafeBytes { Data($0) }
        let hash = SHA256.hash(data: keyData)
        return hash.prefix(4).map { String(format: "%02X", $0) }.joined(separator: ":")
    }
}
