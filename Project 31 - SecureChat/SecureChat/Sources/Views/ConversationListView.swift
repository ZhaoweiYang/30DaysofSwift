import SwiftUI

/// WeChat-style conversation list (main chat screen)
struct ConversationListView: View {
    @EnvironmentObject var appState: AppState
    @State private var showAddContact = false
    @State private var showProfile = false

    var sortedConversations: [Conversation] {
        appState.conversations.sorted { a, b in
            (a.lastMessageTime ?? a.contact.addedAt) > (b.lastMessageTime ?? b.contact.addedAt)
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar (decorative)
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    Text("搜索")
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemBackground))

                if sortedConversations.isEmpty {
                    emptyStateView
                } else {
                    List {
                        ForEach(sortedConversations) { conversation in
                            NavigationLink(destination: ChatView(contactID: conversation.id)
                                .environmentObject(appState)
                            ) {
                                ConversationRow(conversation: conversation)
                                    .environmentObject(appState)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("消息")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showProfile = true }) {
                        if let user = appState.currentUser {
                            AvatarView(name: user.displayName, color: user.avatarColor, size: 30)
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddContact = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(Color(hex: "#4A90D9"))
                    }
                }
            }
            .sheet(isPresented: $showAddContact) {
                AddContactView()
                    .environmentObject(appState)
            }
            .sheet(isPresented: $showProfile) {
                ProfileView()
                    .environmentObject(appState)
            }
        }
    }

    var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("暂无会话")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.secondary)
            Text("添加联系人开始聊天")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            Button(action: { showAddContact = true }) {
                Text("添加联系人")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color(hex: "#4A90D9"))
            }
            Spacer()
        }
    }
}

/// Single conversation row in the list (WeChat style)
struct ConversationRow: View {
    @EnvironmentObject var appState: AppState
    let conversation: Conversation

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            AvatarView(name: conversation.contact.displayName, color: conversation.contact.avatarColor, size: 48)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.contact.displayName)
                        .font(.system(size: 16, weight: .medium))
                        .lineLimit(1)
                    Spacer()
                    if let time = conversation.lastMessageTime {
                        Text(timeString(time))
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }

                HStack {
                    if let lastMsg = conversation.messages.last {
                        // Show encrypted indicator
                        HStack(spacing: 4) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                            Text(lastMessagePreview(lastMsg))
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    } else {
                        Text("[加密会话已建立]")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    Spacer()

                    if conversation.unreadCount > 0 {
                        Text("\(conversation.unreadCount)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                            .frame(minWidth: 18, minHeight: 18)
                            .padding(.horizontal, 4)
                            .background(Color.red)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func lastMessagePreview(_ message: ChatMessage) -> String {
        let decrypted = appState.decryptMessage(message, forContact: conversation.id)
        if message.senderID == appState.currentUser?.id {
            return decrypted
        }
        return decrypted
    }

    private func timeString(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "昨天"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MM/dd"
            return formatter.string(from: date)
        }
    }
}
