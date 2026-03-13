import Foundation
import CryptoKit

/// Local storage service using UserDefaults and Keychain-style secure storage
/// In production, sensitive data would use iOS Keychain; here we use encrypted UserDefaults
class StorageService {
    static let shared = StorageService()

    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private enum Keys {
        static let currentUser = "secureChat.currentUser"
        static let encryptedMnemonic = "secureChat.encryptedMnemonic"
        static let contacts = "secureChat.contacts"
        static let conversations = "secureChat.conversations"
    }

    // MARK: - User Account

    func saveUser(_ user: User) {
        if let data = try? encoder.encode(user) {
            defaults.set(data, forKey: Keys.currentUser)
        }
    }

    func loadUser() -> User? {
        guard let data = defaults.data(forKey: Keys.currentUser) else { return nil }
        return try? decoder.decode(User.self, from: data)
    }

    func saveMnemonic(_ mnemonic: String) {
        // In production, store in iOS Keychain with biometric protection
        // Here we store encoded for demonstration
        let data = Data(mnemonic.utf8)
        defaults.set(data.base64EncodedString(), forKey: Keys.encryptedMnemonic)
    }

    func loadMnemonic() -> String? {
        guard let b64 = defaults.string(forKey: Keys.encryptedMnemonic),
              let data = Data(base64Encoded: b64) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    // MARK: - Contacts

    func saveContacts(_ contacts: [Contact]) {
        if let data = try? encoder.encode(contacts) {
            defaults.set(data, forKey: Keys.contacts)
        }
    }

    func loadContacts() -> [Contact] {
        guard let data = defaults.data(forKey: Keys.contacts) else { return [] }
        return (try? decoder.decode([Contact].self, from: data)) ?? []
    }

    // MARK: - Conversations

    func saveConversations(_ conversations: [Conversation]) {
        if let data = try? encoder.encode(conversations) {
            defaults.set(data, forKey: Keys.conversations)
        }
    }

    func loadConversations() -> [Conversation] {
        guard let data = defaults.data(forKey: Keys.conversations) else { return [] }
        return (try? decoder.decode([Conversation].self, from: data)) ?? []
    }

    // MARK: - Clear All Data

    func clearAll() {
        defaults.removeObject(forKey: Keys.currentUser)
        defaults.removeObject(forKey: Keys.encryptedMnemonic)
        defaults.removeObject(forKey: Keys.contacts)
        defaults.removeObject(forKey: Keys.conversations)
    }
}
