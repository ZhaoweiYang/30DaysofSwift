import Foundation
import CryptoKit
import Combine

/// Central app state managing user session, contacts, and conversations
class AppState: ObservableObject {
    @Published var currentUser: User?
    @Published var contacts: [Contact] = []
    @Published var conversations: [Conversation] = []
    @Published var isLoggedIn: Bool = false

    private let storage = StorageService.shared
    private let chatService = ChatService.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        loadSession()
        observeIncomingMessages()
    }

    // MARK: - Session

    func loadSession() {
        if let user = storage.loadUser() {
            currentUser = user
            contacts = storage.loadContacts()
            conversations = storage.loadConversations()
            isLoggedIn = true
        }
    }

    // MARK: - Account Creation (Mnemonic-based)

    func createAccount(with mnemonic: String, displayName: String? = nil) {
        let userID = MnemonicGenerator.deriveUserID(from: mnemonic)
        let name = displayName ?? MnemonicGenerator.deriveDisplayName(from: mnemonic)
        let colors = ["#4A90D9", "#E74C3C", "#2ECC71", "#F39C12", "#9B59B6", "#1ABC9C", "#E67E22", "#3498DB"]
        let colorIndex = abs(userID.hashValue) % colors.count

        let user = User(
            id: userID,
            displayName: name,
            avatarColor: colors[colorIndex],
            createdAt: Date()
        )

        storage.saveUser(user)
        storage.saveMnemonic(mnemonic)
        currentUser = user
        isLoggedIn = true
    }

    func restoreAccount(with mnemonic: String) -> Bool {
        guard MnemonicGenerator.validate(mnemonic: mnemonic) else { return false }
        createAccount(with: mnemonic)
        return true
    }

    func logout() {
        storage.clearAll()
        currentUser = nil
        contacts = []
        conversations = []
        isLoggedIn = false
    }

    // MARK: - Contacts

    func addContact(id: String, displayName: String, keyBase64: String?) {
        let colors = ["#E74C3C", "#2ECC71", "#F39C12", "#9B59B6", "#1ABC9C", "#4A90D9"]
        let colorIndex = abs(id.hashValue) % colors.count

        let contact = Contact(
            id: id,
            displayName: displayName,
            avatarColor: colors[colorIndex],
            conversationKeyBase64: keyBase64,
            addedAt: Date()
        )

        if !contacts.contains(where: { $0.id == id }) {
            contacts.append(contact)
            storage.saveContacts(contacts)

            // Create conversation
            let conversation = Conversation(
                id: contact.id,
                contact: contact,
                messages: [],
                lastMessageTime: nil,
                unreadCount: 0
            )
            conversations.append(conversation)
            storage.saveConversations(conversations)
        }
    }

    func updateContactKey(contactID: String, keyBase64: String) {
        if let idx = contacts.firstIndex(where: { $0.id == contactID }) {
            contacts[idx].conversationKeyBase64 = keyBase64
            storage.saveContacts(contacts)

            if let convIdx = conversations.firstIndex(where: { $0.id == contactID }) {
                conversations[convIdx].contact.conversationKeyBase64 = keyBase64
                storage.saveConversations(conversations)
            }
        }
    }

    // MARK: - Messaging

    func sendMessage(to contactID: String, plaintext: String) -> Bool {
        guard let user = currentUser,
              let convIdx = conversations.firstIndex(where: { $0.id == contactID }),
              let keyBase64 = conversations[convIdx].contact.conversationKeyBase64,
              let key = CryptoService.importKey(keyBase64) else {
            return false
        }

        guard let message = chatService.sendMessage(
            from: user.id,
            to: contactID,
            plaintext: plaintext,
            conversationKey: key
        ) else {
            return false
        }

        conversations[convIdx].messages.append(message)
        conversations[convIdx].lastMessageTime = message.timestamp
        storage.saveConversations(conversations)

        // Simulate auto-reply for demo
        chatService.simulateReply(
            to: user.id,
            from: conversations[convIdx].contact,
            conversationKey: key
        )

        return true
    }

    func decryptMessage(_ message: ChatMessage, forContact contactID: String) -> String {
        guard let convIdx = conversations.firstIndex(where: { $0.id == contactID }),
              let keyBase64 = conversations[convIdx].contact.conversationKeyBase64,
              let key = CryptoService.importKey(keyBase64) else {
            return "[无法解密 - 需要密钥]"
        }
        return ChatService.decryptMessage(message, with: key) ?? "[解密失败]"
    }

    func markConversationRead(_ contactID: String) {
        if let idx = conversations.firstIndex(where: { $0.id == contactID }) {
            conversations[idx].unreadCount = 0
            for i in conversations[idx].messages.indices {
                conversations[idx].messages[i].isRead = true
            }
            storage.saveConversations(conversations)
        }
    }

    // MARK: - Incoming Messages

    private func observeIncomingMessages() {
        chatService.$incomingMessages
            .receive(on: DispatchQueue.main)
            .sink { [weak self] messages in
                guard let self = self, let user = self.currentUser else { return }
                for message in messages {
                    // Only process messages for us that we don't already have
                    if message.recipientID == user.id,
                       let convIdx = self.conversations.firstIndex(where: { $0.id == message.senderID }),
                       !self.conversations[convIdx].messages.contains(where: { $0.id == message.id }) {
                        self.conversations[convIdx].messages.append(message)
                        self.conversations[convIdx].lastMessageTime = message.timestamp
                        self.conversations[convIdx].unreadCount += 1
                        self.storage.saveConversations(self.conversations)
                    }
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Demo Data

    func addDemoContacts() {
        let key = CryptoService.generateConversationKey()
        let keyBase64 = CryptoService.exportKey(key)

        addContact(id: "demo001", displayName: "Alice", keyBase64: keyBase64)

        let key2 = CryptoService.generateConversationKey()
        let keyBase64_2 = CryptoService.exportKey(key2)
        addContact(id: "demo002", displayName: "Bob", keyBase64: keyBase64_2)

        let key3 = CryptoService.generateConversationKey()
        let keyBase64_3 = CryptoService.exportKey(key3)
        addContact(id: "demo003", displayName: "小明", keyBase64: keyBase64_3)
    }
}
