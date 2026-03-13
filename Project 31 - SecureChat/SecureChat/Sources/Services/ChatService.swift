import Foundation
import CryptoKit
import Combine

/// Simulates a chat relay platform that only sees encrypted messages.
/// In production, this would be a WebSocket / REST API backend.
/// The platform NEVER has access to plaintext or encryption keys.
class ChatService: ObservableObject {
    static let shared = ChatService()

    /// Simulated "server" message queue - in production this is the backend
    @Published var incomingMessages: [ChatMessage] = []

    /// Send an encrypted message through the platform
    /// The platform only relays ciphertext - it cannot read the content
    func sendMessage(
        from senderID: String,
        to recipientID: String,
        plaintext: String,
        conversationKey: SymmetricKey
    ) -> ChatMessage? {
        // Step 1: Encrypt locally (on sender's device)
        guard let encrypted = CryptoService.encrypt(plaintext, with: conversationKey) else {
            return nil
        }

        // Step 2: Create message with encrypted content
        let message = ChatMessage(
            id: ChatMessage.newID(),
            senderID: senderID,
            recipientID: recipientID,
            encryptedContent: encrypted,
            timestamp: Date(),
            isRead: false
        )

        // Step 3: Platform relays the encrypted message (no decryption possible)
        // In production: POST to server, server forwards to recipient via push/websocket
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.incomingMessages.append(message)
        }

        return message
    }

    /// Decrypt a received message locally (on recipient's device)
    static func decryptMessage(_ message: ChatMessage, with key: SymmetricKey) -> String? {
        return CryptoService.decrypt(message.encryptedContent, with: key)
    }

    /// Simulate receiving a reply (for demo purposes)
    func simulateReply(to senderID: String, from contact: Contact, conversationKey: SymmetricKey) {
        let replies = [
            "收到！", "好的，明白了", "👍", "稍等一下",
            "没问题", "我看看", "这个不错", "同意",
            "OK!", "马上处理", "谢谢", "晚点再聊"
        ]
        let reply = replies.randomElement() ?? "收到"

        DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 1.5...3.0)) {
            if let encrypted = CryptoService.encrypt(reply, with: conversationKey) {
                let message = ChatMessage(
                    id: ChatMessage.newID(),
                    senderID: contact.id,
                    recipientID: senderID,
                    encryptedContent: encrypted,
                    timestamp: Date(),
                    isRead: false
                )
                self.incomingMessages.append(message)
            }
        }
    }
}
