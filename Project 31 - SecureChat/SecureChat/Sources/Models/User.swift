import Foundation
import CryptoKit

/// Represents a user account in the SecureChat system
struct User: Codable, Identifiable, Equatable {
    let id: String              // Derived from mnemonic (deterministic)
    var displayName: String     // Derived from mnemonic or user-chosen
    var avatarColor: String     // Hex color for default avatar
    let createdAt: Date

    static func == (lhs: User, rhs: User) -> Bool {
        lhs.id == rhs.id
    }
}

/// Represents a contact (another user we can chat with)
struct Contact: Codable, Identifiable, Equatable {
    let id: String              // The other user's ID
    var displayName: String
    var avatarColor: String
    /// The encryption key shared for this conversation (Base64 encoded)
    var conversationKeyBase64: String?
    let addedAt: Date

    static func == (lhs: Contact, rhs: Contact) -> Bool {
        lhs.id == rhs.id
    }
}

/// Represents a chat message
struct ChatMessage: Codable, Identifiable, Equatable {
    let id: String
    let senderID: String
    let recipientID: String
    /// Encrypted content (Base64 encoded AES-GCM ciphertext)
    let encryptedContent: String
    let timestamp: Date
    /// Whether this message has been read
    var isRead: Bool

    /// Unique ID for the message
    static func newID() -> String {
        UUID().uuidString
    }
}

/// Represents a conversation (chat thread between two users)
struct Conversation: Codable, Identifiable, Equatable {
    let id: String                  // Contact's user ID
    var contact: Contact
    var messages: [ChatMessage]
    var lastMessageTime: Date?
    var unreadCount: Int

    static func == (lhs: Conversation, rhs: Conversation) -> Bool {
        lhs.id == rhs.id
    }
}
