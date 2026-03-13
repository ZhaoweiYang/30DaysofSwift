import SwiftUI

/// WeChat-style chat view with encrypted messaging
struct ChatView: View {
    @EnvironmentObject var appState: AppState
    @State private var messageText = ""
    @State private var showKeyInfo = false
    @State private var showKeyInput = false

    let contactID: String

    var conversation: Conversation? {
        appState.conversations.first(where: { $0.id == contactID })
    }

    var hasKey: Bool {
        conversation?.contact.conversationKeyBase64 != nil
    }

    var body: some View {
        VStack(spacing: 0) {
            // Key status banner
            if !hasKey {
                keyRequiredBanner
            }

            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 2) {
                        if let conv = conversation {
                            ForEach(conv.messages) { message in
                                MessageBubble(
                                    message: message,
                                    decryptedText: appState.decryptMessage(message, forContact: contactID),
                                    isMine: message.senderID == appState.currentUser?.id,
                                    contactName: conv.contact.displayName,
                                    contactColor: conv.contact.avatarColor,
                                    myColor: appState.currentUser?.avatarColor ?? "#4A90D9"
                                )
                                .id(message.id)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                .background(Color(hex: "#EDEDED"))
                .onChange(of: conversation?.messages.count) { _ in
                    if let lastID = conversation?.messages.last?.id {
                        withAnimation {
                            proxy.scrollTo(lastID, anchor: .bottom)
                        }
                    }
                }
            }

            // Input bar
            inputBar
        }
        .navigationTitle(conversation?.contact.displayName ?? "聊天")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showKeyInfo = true }) {
                    Image(systemName: "lock.circle")
                        .foregroundColor(hasKey ? .green : .orange)
                }
            }
        }
        .sheet(isPresented: $showKeyInfo) {
            KeyInfoView(contactID: contactID)
                .environmentObject(appState)
        }
        .sheet(isPresented: $showKeyInput) {
            KeyInputView(contactID: contactID)
                .environmentObject(appState)
        }
        .onAppear {
            appState.markConversationRead(contactID)
        }
    }

    // MARK: - Key Required Banner

    var keyRequiredBanner: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            Text("需要输入加密密钥才能发送消息")
                .font(.system(size: 13))
            Spacer()
            Button("输入密钥") {
                showKeyInput = true
            }
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(Color(hex: "#4A90D9"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.orange.opacity(0.1))
    }

    // MARK: - Input Bar

    var inputBar: some View {
        HStack(spacing: 8) {
            // Text input
            HStack {
                TextField("输入消息...", text: $messageText)
                    .font(.system(size: 16))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
            }
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color(.systemGray4), lineWidth: 0.5)
            )

            // Send button
            Button(action: sendMessage) {
                if messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.secondary)
                } else {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(Color(hex: "#4A90D9"))
                }
            }
            .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !hasKey)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(hex: "#F7F7F7"))
    }

    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        if appState.sendMessage(to: contactID, plaintext: text) {
            messageText = ""
        }
    }
}

/// A single message bubble (WeChat style)
struct MessageBubble: View {
    let message: ChatMessage
    let decryptedText: String
    let isMine: Bool
    let contactName: String
    let contactColor: String
    let myColor: String

    @State private var showEncrypted = false

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if isMine { Spacer(minLength: 60) }

            if !isMine {
                AvatarView(name: contactName, color: contactColor, size: 36)
            }

            VStack(alignment: isMine ? .trailing : .leading, spacing: 2) {
                // Message bubble
                Text(showEncrypted ? message.encryptedContent.prefix(60) + "..." : decryptedText)
                    .font(.system(size: 16))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(isMine ? Color(hex: "#95EC69") : Color.white)
                    .cornerRadius(8)
                    .onTapGesture {
                        showEncrypted.toggle()
                    }

                // Timestamp
                HStack(spacing: 4) {
                    if showEncrypted {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                    Text(timeString(message.timestamp))
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }

            if isMine {
                AvatarView(name: "我", color: myColor, size: 36)
            }

            if !isMine { Spacer(minLength: 60) }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 2)
    }

    private func timeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
