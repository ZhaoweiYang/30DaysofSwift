import SwiftUI

@main
struct SecureChatApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            if appState.isLoggedIn {
                MainTabView()
                    .environmentObject(appState)
            } else {
                WelcomeView()
                    .environmentObject(appState)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appState.isLoggedIn)
    }
}

/// Main tab bar (WeChat-style bottom tabs)
struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab = 0

    var totalUnread: Int {
        appState.conversations.reduce(0) { $0 + $1.unreadCount }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            ConversationListView()
                .environmentObject(appState)
                .tabItem {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                    Text("消息")
                }
                .badge(totalUnread)
                .tag(0)

            ContactsListView()
                .environmentObject(appState)
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("通讯录")
                }
                .tag(1)

            DiscoverView()
                .tabItem {
                    Image(systemName: "safari.fill")
                    Text("发现")
                }
                .tag(2)

            ProfileView()
                .environmentObject(appState)
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("我")
                }
                .tag(3)
        }
        .accentColor(Color(hex: "#4A90D9"))
    }
}

/// Contacts list tab
struct ContactsListView: View {
    @EnvironmentObject var appState: AppState
    @State private var showAddContact = false

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("联系人 (\(appState.contacts.count))")) {
                    ForEach(appState.contacts) { contact in
                        NavigationLink(destination: ChatView(contactID: contact.id)
                            .environmentObject(appState)
                        ) {
                            HStack(spacing: 12) {
                                AvatarView(name: contact.displayName, color: contact.avatarColor, size: 40)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(contact.displayName)
                                        .font(.system(size: 16, weight: .medium))

                                    HStack(spacing: 4) {
                                        Image(systemName: contact.conversationKeyBase64 != nil ? "lock.fill" : "lock.open")
                                            .font(.system(size: 10))
                                            .foregroundColor(contact.conversationKeyBase64 != nil ? .green : .orange)
                                        Text(contact.conversationKeyBase64 != nil ? "加密已建立" : "待建立加密")
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("通讯录")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddContact = true }) {
                        Image(systemName: "person.badge.plus")
                    }
                }
            }
            .sheet(isPresented: $showAddContact) {
                AddContactView()
                    .environmentObject(appState)
            }
        }
    }
}

/// Discover tab (placeholder)
struct DiscoverView: View {
    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "qrcode.viewfinder")
                            .font(.system(size: 22))
                            .foregroundColor(Color(hex: "#4A90D9"))
                            .frame(width: 28)
                        Text("扫一扫")
                    }
                    .padding(.vertical, 4)

                    HStack(spacing: 12) {
                        Image(systemName: "shazam.logo.fill")
                            .font(.system(size: 22))
                            .foregroundColor(Color(hex: "#4A90D9"))
                            .frame(width: 28)
                        Text("摇一摇")
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "circle.grid.3x3.fill")
                            .font(.system(size: 22))
                            .foregroundColor(Color(hex: "#4A90D9"))
                            .frame(width: 28)
                        Text("小程序")
                    }
                    .padding(.vertical, 4)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("发现")
        }
    }
}
